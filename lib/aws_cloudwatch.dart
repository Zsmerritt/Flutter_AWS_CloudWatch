library aws_cloudwatch;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aws_request/aws_request.dart';
import 'package:synchronized/synchronized.dart';
import 'package:universal_io/io.dart';

// AWS Hard Limits
const _GROUP_NAME_REGEX_PATTERN = r'^[\.\-_/#A-Za-z0-9]+$';
const _STREAM_NAME_REGEX_PATTERN = r'^[^:*]*$';
const int AWS_MAX_BYTE_MESSAGE_SIZE = 262118;
const int AWS_MAX_BYTE_BATCH_SIZE = 1048550;
const int AWS_MAX_MESSAGES_PER_BATCH = 10000;

class CloudWatchException implements Exception {
  String message;
  StackTrace stackTrace;

  /// A custom error to identify CloudWatch errors more easily
  ///
  /// message: the cause of the error
  /// stackTrace: the stack trace of the error
  CloudWatchException(this.message, this.stackTrace);
}

/// An enum representing what should happen to messages that are too big
/// to be sent as a single message. This limit is 262118 utf8 bytes
///
/// truncate: Replace the middle of the message with "...", making it 262118
///           utf8 bytes long. This is the default value.
///
/// ignore: Ignore large messages. They will not be sent
///
/// split: Split large messages into multiple smaller messages and send them
///
/// error: Throw an error when a large message is encountered
enum CloudWatchLargeMessages {
  /// Replace the middle of the message with "...", making it 262118 utf8 bytes
  /// long. This is the default value.
  truncate,

  /// Ignore large messages. They will not be sent
  ignore,

  /// Split large messages into multiple smaller messages and send them
  split,

  /// Throw an error when a large message is encountered
  error,
}

/// A CloudWatch handler class to easily manage multiple CloudWatch instances
class CloudWatchHandler {
  Map<String, CloudWatch> _logInstances = {};

  /// Your AWS Access key.
  String awsAccessKey;

  /// Your AWS Secret key.
  String awsSecretKey;

  /// Your AWS region.
  String region;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  Duration delay;

  /// How long to wait for request before triggering a timeout
  Duration requestTimeout;

  /// How many times an api request should be retired upon failure. Default is 3
  int retries;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  CloudWatchLargeMessages largeMessageBehavior;

  /// CloudWatchHandler Constructor
  CloudWatchHandler({
    required this.awsAccessKey,
    required this.awsSecretKey,
    required this.region,
    this.delay: const Duration(milliseconds: 0),
    this.requestTimeout: const Duration(seconds: 10),
    this.retries: 3,
    this.largeMessageBehavior: CloudWatchLargeMessages.truncate,
  }) {
    this.retries = max(1, this.retries);
  }

  /// Returns a specific instance of a CloudWatch class (or null if it doesnt
  /// exist) based on group name and stream name
  ///
  /// Uses the [logGroupName] and the [logStreamName] to find the correct
  /// CloudWatch instance. Returns null if it doesnt exist
  CloudWatch? getInstance({
    required String logGroupName,
    required String logStreamName,
  }) {
    String instanceName = '$logGroupName.$logStreamName';
    return _logInstances[instanceName];
  }

  /// Logs the provided message to the provided log group and log stream
  ///
  /// Logs a single [msg] to [logStreamName] under the group [logGroupName]
  Future<void> log({
    required String msg,
    required String logGroupName,
    required String logStreamName,
  }) async {
    await logMany(
      messages: [msg],
      logGroupName: logGroupName,
      logStreamName: logStreamName,
    );
  }

  /// Logs the provided message to the provided log group and log stream
  ///
  /// Logs a list of string [messages] to [logStreamName] under the group [logGroupName]
  ///
  /// Note: using logMany will result in all logs having the same timestamp
  Future<void> logMany({
    required List<String> messages,
    required String logGroupName,
    required String logStreamName,
  }) async {
    CloudWatch instance = getInstance(
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        ) ??
        _createInstance(
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        );
    await instance.logMany(messages);
  }

  CloudWatch _createInstance({
    required String logGroupName,
    required String logStreamName,
  }) {
    String instanceName = '$logGroupName.$logStreamName';
    CloudWatch instance = CloudWatch(
      awsAccessKey,
      awsSecretKey,
      region,
      groupName: logGroupName,
      streamName: logStreamName,
      delay: delay,
      requestTimeout: requestTimeout,
      retries: retries,
      largeMessageBehavior: largeMessageBehavior,
    );
    _logInstances[instanceName] = instance;
    return instance;
  }
}

/// An AWS CloudWatch class for sending logs more easily to AWS
class CloudWatch {
  // AWS Variables
  /// Public AWS access key
  String awsAccessKey;

  /// Private AWS access key
  String awsSecretKey;

  /// AWS region
  String region;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  Duration delay;

  /// How long to wait for request before triggering a timeout
  Duration requestTimeout;

  /// How many times an api request should be retired upon failure. Default is 3
  int retries;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  CloudWatchLargeMessages largeMessageBehavior;

  // Logging Variables
  /// The log group the log stream will appear under
  String? groupName;

  /// Synonym for groupName
  String? get logGroupName => groupName;

  set logGroupName(String? val) => groupName = val;

  /// The log stream name for log events to be filed in
  String? streamName;

  /// Synonym for streamName
  String? get logStreamName => streamName;

  set logStreamName(String? val) => streamName = val;

  int _verbosity = 0;
  String? _sequenceToken;
  late _LogStack _logStack;
  var _loggingLock = Lock();
  bool _logStreamCreated = false;
  bool _logGroupCreated = false;

  /// CloudWatch Constructor
  CloudWatch(
    this.awsAccessKey,
    this.awsSecretKey,
    this.region, {
    this.groupName,
    this.streamName,
    this.delay: const Duration(milliseconds: 0),
    this.requestTimeout: const Duration(seconds: 10),
    this.retries: 3,
    this.largeMessageBehavior: CloudWatchLargeMessages.truncate,
  }) {
    delay = !delay.isNegative ? delay : Duration(milliseconds: 0);
    this.retries = max(1, this.retries);
    this._logStack = _LogStack(largeMessageBehavior: largeMessageBehavior);
  }

  /// Sets how long to wait between requests to avoid rate limiting
  ///
  /// Sets the delay to be [delay]
  Duration setDelay(Duration delay) {
    this.delay = !delay.isNegative ? delay : Duration(milliseconds: 0);
    _debugPrint(
      2,
      'CloudWatch INFO: Set delay to $delay',
    );
    return delay;
  }

  /// Sets log group name and log stream name
  ///
  /// Sets the [groupName] and [streamName]
  void setLoggingParameters(String? groupName, String? streamName) {
    groupName = groupName;
    streamName = streamName;
  }

  /// Sends a log to AWS
  ///
  /// Sends the [logString] to AWS to be added to the CloudWatch logs
  ///
  /// Throws a [CloudWatchException] if [groupName] or [streamName] are not
  /// initialized or if aws returns an error.
  Future<void> log(String logString) async {
    await logMany([logString]);
  }

  /// Sends a log to AWS
  ///
  /// Sends a list of strings [logStrings] to AWS to be added to the CloudWatch logs
  ///
  /// Note: using logMany will result in all logs having the same timestamp
  ///
  /// Throws a [CloudWatchException] if [groupName] or [streamName] are not
  /// initialized or if aws returns an error.
  Future<void> logMany(List<String> logStrings) async {
    _debugPrint(
      2,
      'CloudWatch INFO: Attempting to log many',
    );
    if ([groupName, streamName].contains(null)) {
      _debugPrint(
        0,
        'CloudWatch ERROR: Please supply a Log Group and Stream names by '
        'calling setLoggingParameters(String? groupName, String? streamName)',
      );
      throw new CloudWatchException(
          'CloudWatch ERROR: Please supply a Log Group and Stream names by '
          'calling setLoggingParameters(String groupName, String streamName)',
          StackTrace.current);
    }
    _validateName(
      groupName!,
      'groupName',
      _GROUP_NAME_REGEX_PATTERN,
    );
    _validateName(
      streamName!,
      'streamName',
      _STREAM_NAME_REGEX_PATTERN,
    );
    await _log(logStrings);
  }

  /// Sets console verbosity level.
  /// Useful for debugging.
  /// Hidden by default. Get here with a debugger ;)
  void _setVerbosity(int level) {
    level = min(level, 3);
    level = max(level, 0);
    _verbosity = level;
    _debugPrint(
      2,
      'CloudWatch INFO: Set verbosity to $_verbosity',
    );
  }

  void _debugPrint(int v, String msg) {
    if (_verbosity > v) {
      print(msg);
    }
  }

  Future<void> _createLogStreamAndLogGroup() async {
    dynamic error;
    for (int i = 0; i < retries; i++) {
      try {
        await _createLogStream();
        return;
      } on CloudWatchException catch (e) {
        if (e.message.contains('ResourceNotFoundException')) {
          // Create a new log group and try stream creation again
          await _createLogGroup();
          await _createLogStream();
          return;
        }
        error = e;
      } catch (e) {
        error = e;
        _debugPrint(
          0,
          'CloudWatch ERROR: Failed _createLogStreamAndLogGroup. Retrying ${i + 1}',
        );
      }
    }
    return Future.error(error);
  }

  Future<void> _createLogStream() async {
    if (!_logStreamCreated) {
      _debugPrint(
        2,
        'CloudWatch INFO: Generating LogStream',
      );
      _logStreamCreated = true;
      String body =
          '{"logGroupName": "$groupName","logStreamName": "$streamName"}';
      HttpClientResponse log = await AwsRequest(
        awsAccessKey,
        awsSecretKey,
        region,
        service: 'logs',
        timeout: requestTimeout,
      ).send(
        'POST',
        jsonBody: body,
        target: 'Logs_20140328.CreateLogStream',
      );
      int statusCode = log.statusCode;
      _debugPrint(
        1,
        'CloudWatch Info: LogStream creation status code: $statusCode',
      );
      if (statusCode != 200) {
        Map<String, dynamic>? reply = jsonDecode(
          await log.transform(utf8.decoder).join(),
        );
        _debugPrint(
          0,
          'CloudWatch ERROR: StatusCode: $statusCode, CloudWatchResponse: $reply',
        );
        _logStreamCreated = false;
        throw new CloudWatchException(
            'CloudWatch ERROR: $reply', StackTrace.current);
      }
    }
    _debugPrint(
      2,
      'CloudWatch INFO: Got LogStream',
    );
  }

  Future<void> _createLogGroup() async {
    if (!_logGroupCreated) {
      _debugPrint(
        2,
        'CloudWatch INFO: creating LogGroup Exists',
      );
      _logGroupCreated = true;
      String body = '{"logGroupName": "$groupName"}';
      HttpClientResponse log = await AwsRequest(
        awsAccessKey,
        awsSecretKey,
        region,
        service: 'logs',
        timeout: requestTimeout,
      ).send(
        'POST',
        jsonBody: body,
        target: 'Logs_20140328.CreateLogGroup',
      );
      int statusCode = log.statusCode;
      _debugPrint(
        1,
        'CloudWatch Info: LogGroup creation status code: $statusCode',
      );
      if (statusCode != 200) {
        Map<String, dynamic>? reply = jsonDecode(
          await log.transform(utf8.decoder).join(),
        );
        _debugPrint(
          0,
          'CloudWatch ERROR: StatusCode: $statusCode, AWS Response: $reply',
        );
        _logGroupCreated = false;
        throw new CloudWatchException(
            'CloudWatch ERROR: $reply', StackTrace.current);
      }
    }
    _debugPrint(
      2,
      'CloudWatch INFO: created LogGroup',
    );
  }

  // turns a string into a cloudwatch event
  String _createBody(List<Map<String, dynamic>> logsToSend) {
    _debugPrint(
      2,
      'CloudWatch INFO: Generating CloudWatch request body',
    );
    Map<String, dynamic> body = {
      'logEvents': logsToSend,
      'logGroupName': groupName,
      'logStreamName': streamName,
    };
    if (_sequenceToken != null) {
      body['sequenceToken'] = _sequenceToken;
      _debugPrint(
        2,
        'CloudWatch INFO: Adding sequence token',
      );
    }
    String jsonBody = json.encode(body);
    _debugPrint(
      2,
      'CloudWatch INFO: Generated jsonBody with ${logsToSend.length} logs: $jsonBody',
    );
    return jsonBody;
  }

  Future<void> _log(List<String> logStrings) async {
    _logStack._addLogs(logStrings);
    _debugPrint(
      2,
      'CloudWatch INFO: Added messages to log stack',
    );
    dynamic error;
    if (!_logStreamCreated) {
      await _loggingLock
          .synchronized(_createLogStreamAndLogGroup)
          .catchError((e) {
        error = e;
      });
    }
    if (error != null) {
      return Future.error(error!);
    }
    await _sendAllLogs().catchError((e) {
      error = e;
    });
    if (error != null) {
      return Future.error(error);
    }
  }

  Future<void> _sendAllLogs() async {
    dynamic error;
    while (_logStack.length > 0 && error == null) {
      await Future.delayed(
        delay,
        () async => await _loggingLock.synchronized(_sendLogs),
      ).catchError((e) {
        error = e;
      });
    }
    if (error != null) {
      return Future.error(error);
    }
  }

  Future<void> _sendLogs() async {
    if (_logStack.length <= 0) {
      // logs already sent while this request was waiting for lock
      _debugPrint(
        2,
        'CloudWatch INFO: All logs have already been sent',
      );
      return;
    }
    // capture logs that are about to be sent in case the request fails
    __LogStack _logs = _logStack._pop();
    String body = _createBody(_logs.logs);
    HttpClientResponse? result;
    dynamic error;
    for (int i = 0; i < retries; i++) {
      try {
        result = await AwsRequest(
          awsAccessKey,
          awsSecretKey,
          region,
          service: 'logs',
          timeout: requestTimeout,
        ).send(
          'POST',
          jsonBody: body,
          target: 'Logs_20140328.PutLogEvents',
        );
        break;
      } catch (e) {
        error = e;
        _debugPrint(
          0,
          'CloudWatch ERROR: Failed making AwsRequest. Retrying ${i + 1}',
        );
      }
    }
    if (result == null) {
      // request failed, prepend failed logs to _logStack
      _logStack._prepend(_logs);
      _debugPrint(
        0,
        'CloudWatch ERROR: Could not complete AWS request: $error',
      );
      return Future.error(error);
    }
    int statusCode = result.statusCode;
    Map<String, dynamic>? reply = jsonDecode(
      await result.transform(utf8.decoder).join(),
    );
    if (statusCode == 200) {
      _debugPrint(
        1,
        'CloudWatch Info: StatusCode: $statusCode, AWS Response: $reply',
      );
      String? newSequenceToken = reply!['nextSequenceToken'];
      _sequenceToken = newSequenceToken;
    } else {
      // request failed, prepend failed logs to _logStack
      _logStack._prepend(_logs);
      _debugPrint(
        0,
        'CloudWatch ERROR: StatusCode: $statusCode, AWS Response: $reply',
      );
      throw new CloudWatchException(
          'CloudWatch ERROR: StatusCode: $statusCode, AWS Response: $reply',
          StackTrace.current);
    }
  }

  void _validateName(String name, String type, String pattern) {
    if (name.length > 512 || name.length == 0) {
      throw CloudWatchException(
        'Provided $type "$name" is too long. $type must be between 1 and 512 characters.',
        StackTrace.current,
      );
    }
    if (!RegExp(pattern).hasMatch(name)) {
      throw CloudWatchException(
        'Provided $type "$name" doesnt match pattern $pattern required of $type',
        StackTrace.current,
      );
    }
  }
}

class __LogStack {
  List<Map<String, dynamic>> logs = [];
  int messageSize = 0;

  __LogStack({required this.logs, required this.messageSize});
}

class _LogStack {
  _LogStack({
    required this.largeMessageBehavior,
  });

  CloudWatchLargeMessages largeMessageBehavior;

  List<__LogStack> _logStack = [];

  int get length => _logStack.length;

  void _addLogs(List<String> logStrings) {
    int time = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (String msg in logStrings) {
      List<int> bytes = utf8.encode(msg);
      // AWS hard limit on message size
      if (bytes.length <= AWS_MAX_BYTE_MESSAGE_SIZE) {
        _addToStack(time, bytes);
      } else {
        switch (largeMessageBehavior) {

          /// Truncate message by replacing middle with "..."
          case CloudWatchLargeMessages.truncate:
            // plus 3 to account for "..."
            int toRemove =
                ((bytes.length - AWS_MAX_BYTE_MESSAGE_SIZE + 3) / 2).ceil();
            int midPoint = (bytes.length / 2).floor();
            List<int> newMessage = bytes.sublist(0, midPoint - toRemove) +
                // "..." in bytes (2e)
                [46, 46, 46] +
                bytes.sublist(midPoint + toRemove);
            _addToStack(time, newMessage);
            break;

          /// Split up large message into multiple smaller ones
          case CloudWatchLargeMessages.split:
            while (bytes.length > AWS_MAX_BYTE_MESSAGE_SIZE) {
              _addToStack(
                time,
                bytes.sublist(0, AWS_MAX_BYTE_MESSAGE_SIZE),
              );
              bytes = bytes.sublist(AWS_MAX_BYTE_MESSAGE_SIZE);
            }
            _addToStack(time, bytes);
            break;

          /// Ignore the message
          case CloudWatchLargeMessages.ignore:
            continue;

          /// Throw an error
          case CloudWatchLargeMessages.error:
            throw CloudWatchException(
              'Provided log message is too long. Individual message size limit is '
              '$AWS_MAX_BYTE_MESSAGE_SIZE. log message: $msg',
              StackTrace.current,
            );
        }
      }
    }
  }

  void _addToStack(int time, List<int> bytes) {
    // empty list / aws hard limits on batch sizes
    if (_logStack.length == 0 ||
        _logStack.last.logs.length >= AWS_MAX_MESSAGES_PER_BATCH ||
        _logStack.last.messageSize + bytes.length > AWS_MAX_BYTE_BATCH_SIZE) {
      _logStack.add(
        __LogStack(
          logs: [
            {
              'timestamp': time,
              'message': utf8.decode(bytes),
            },
          ],
          messageSize: bytes.length,
        ),
      );
    } else {
      _logStack.last.logs
          .add({'timestamp': time, 'message': utf8.decode(bytes)});
      _logStack.last.messageSize += bytes.length;
    }
  }

  __LogStack _pop() {
    __LogStack result = _logStack.first;
    if (_logStack.length > 1) {
      _logStack = _logStack.sublist(1);
    } else {
      _logStack.clear();
    }
    return result;
  }

  void _prepend(__LogStack messages) {
    _logStack = [messages] + _logStack;
  }
}
