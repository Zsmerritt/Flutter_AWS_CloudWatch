import 'dart:convert';
import 'package:http/http.dart' as http;

/// AWS Hard Limits
const String _GROUP_NAME_REGEX_PATTERN = r'^[\.\-_/#A-Za-z0-9]+$';
const String _STREAM_NAME_REGEX_PATTERN = r'^[^:*]*$';

/// Special exception class to identify exceptions from CloudWatch
class CloudWatchException implements Exception {
  String? message;
  StackTrace? stackTrace;
  String? type;
  String? raw;

  /// A custom error to identify CloudWatch errors more easily
  ///
  /// message: the cause of the error
  /// stackTrace: the stack trace of the error
  CloudWatchException(
      {required this.message, required this.stackTrace, this.type, this.raw});

  /// CloudWatchException toString
  String toString() {
    if (type != null) {
      return "CloudWatchException - type: $type, message: $message";
    }
    return "CloudWatchException - message: $message";
  }
}

/// Validates [streamName] based on aws restrictions
///
/// Throws [CloudWatchException] if bad name is found
void validateLogStreamName(String? streamName) {
  _validateName(
    streamName,
    'streamName',
    _STREAM_NAME_REGEX_PATTERN,
  );
}

/// Validates [groupName] based on aws restrictions
///
/// Throws [CloudWatchException] if bad name is found
void validateLogGroupName(String? groupName) {
  _validateName(
    groupName,
    'groupName',
    _GROUP_NAME_REGEX_PATTERN,
  );
}

/// Validates [name] to have a regex match with [pattern] and checks length requirements
void _validateName(String? name, String type, String pattern) {
  if (name == null) {
    throw CloudWatchException(
      message: 'No $type name provided. Set $type and then try again.',
      stackTrace: StackTrace.current,
    );
  }
  if (name.length > 512 || name.length == 0) {
    throw CloudWatchException(
      message:
          'Provided $type "$name" is invalid. $type must be between 1 and 512 characters.',
      stackTrace: StackTrace.current,
    );
  }
  if (!RegExp(pattern).hasMatch(name)) {
    throw CloudWatchException(
      message:
          'Provided $type "$name" doesnt match pattern $pattern required of $type',
      stackTrace: StackTrace.current,
    );
  }
}

/// An aws response object class that holds common response elements
class AwsResponse {
  int statusCode;
  String? type;
  String? message;
  String? nextSequenceToken;
  String? expectedSequenceToken;
  String? raw;

  AwsResponse._(this.statusCode);

  /// Attempts to parse aws response into its type and message parts
  static Future<AwsResponse> parseResponse(http.Response response) async {
    AwsResponse result = AwsResponse._(response.statusCode);
    if (response.contentLength != null && response.contentLength! > 0) {
      Map<String, dynamic>? reply = jsonDecode(
        response.body,
      );
      result.raw = reply.toString();
      if (reply != null) {
        if (reply.containsKey('nextSequenceToken')) {
          result.nextSequenceToken = reply['nextSequenceToken'];
        }
        if (reply.containsKey('__type')) {
          result.type = reply['__type'];
        }
        if (reply.containsKey('message')) {
          result.message = reply['message'];
        }
        if (reply.containsKey('expectedSequenceToken')) {
          result.expectedSequenceToken = reply['expectedSequenceToken'];
        }
      }
    }
    return result;
  }

  /// AwsResponse toString
  String toString() {
    StringBuffer sb = new StringBuffer('AwsResponse - statusCode: $statusCode');
    if (type != null) {
      sb.write(', type: $type');
    }
    if (message != null) {
      sb.write(', message: $message');
    }
    if (expectedSequenceToken != null) {
      sb.write(', expectedSequenceToken: $expectedSequenceToken');
    }
    if (nextSequenceToken != null) {
      sb.write(', nextSequenceToken: $nextSequenceToken');
    }
    return sb.toString();
  }
}
