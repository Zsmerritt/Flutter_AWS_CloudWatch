import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aws_request/aws_request.dart';
import 'package:aws_request/testing.dart';
import 'package:http/http.dart';
import 'package:synchronized/synchronized.dart';

part 'log.dart';
part 'log_stack.dart';
part 'logger_handler.dart';
part 'util.dart';

/// An AWS CloudWatch class for sending logs more easily to AWS
class Logger {
  // AWS Variables
  /// Public AWS access key
  String awsAccessKey;

  /// Private AWS access key
  String awsSecretKey;

  /// AWS region
  String region;

  /// AWS session token (temporary credentials)
  String? awsSessionToken;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  Duration get delay => _delay;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  set delay(Duration d) {
    _delay = !d.isNegative ? d : const Duration();
  }

  /// How long to wait for request before triggering a timeout
  Duration get requestTimeout => _requestTimeout;

  /// How long to wait for request before triggering a timeout
  set requestTimeout(Duration d) {
    _requestTimeout = !d.isNegative ? d : const Duration();
  }

  /// How many times an api request should be retired upon failure. Default is 3
  int get retries => _retries;

  /// How many times an api request should be retired upon failure. Default is 3
  set retries(int d) {
    _retries = d >= 0 ? d : 0;
  }

  /// How messages larger than AWS limit should be handled. Default is truncate.
  CloudWatchLargeMessages get largeMessageBehavior => _largeMessageBehavior;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  set largeMessageBehavior(CloudWatchLargeMessages val) {
    _largeMessageBehavior = val;
    logStack.largeMessageBehavior = val;
  }

  /// Private version of largeMessageBehavior to set _logStack
  CloudWatchLargeMessages _largeMessageBehavior;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  bool raiseFailedLookups;

  // Logging Variables
  /// The log group the log stream will appear under
  String groupName;

  /// Synonym for groupName
  String get logGroupName => groupName;

  /// Synonym for groupName
  set logGroupName(String val) => groupName = val;

  /// The log stream name for log events to be filed in
  String streamName;

  /// Synonym for streamName
  String get logStreamName => streamName;

  /// Synonym for streamName
  set logStreamName(String val) => streamName = val;

  /// Bool to skip log stream creation
  bool logStreamCreated = false;

  /// Bool to skip log group creation
  bool logGroupCreated = false;

  /// A log stack that holds queued logs ready to be sent
  CloudWatchLogStack logStack;

  /// Sets console verbosity level.
  /// Useful for debugging.
  ///
  /// 0 - Errors only
  /// 1 - Status Codes
  /// 2 - General Info
  set verbosity(int level) {
    int newLevel = min(level, 3);
    newLevel = max(newLevel, 0);
    _verbosity = newLevel;
    debugPrint(
      2,
      'CloudWatch INFO: Set verbosity to $verbosity',
    );
  }

  int get verbosity => _verbosity;

  /// Verbosity for debugging
  int _verbosity = 0;

  /// Token provided by aws to ensure logs are received in the correct order
  String? sequenceToken;

  /// Synchronous lock to enforce synchronous request order
  Lock lock = Lock();

  /// Private version of delay
  Duration _delay;

  /// Private version of requestTimeout
  Duration _requestTimeout;

  /// Private version of retries
  int _retries;

  /// Testing Variables

  /// Function used to mock requests
  Future<Response> Function(Request)? mockFunction;

  /// Whether we are mocking requests
  bool mockCloudWatch;

  /// CloudWatch Constructor
  Logger({
    required this.awsAccessKey,
    required this.awsSecretKey,
    required this.region,
    required this.groupName,
    required this.streamName,
    required this.awsSessionToken,
    required delay,
    required requestTimeout,
    required retries,
    required largeMessageBehavior,
    required this.raiseFailedLookups,
    this.mockCloudWatch = false,
    this.mockFunction,
  })  : _largeMessageBehavior = largeMessageBehavior,
        _delay = !delay.isNegative ? delay : const Duration(),
        _requestTimeout =
            !requestTimeout.isNegative ? requestTimeout : const Duration(),
        _retries = max(0, retries),
        logStack =
            CloudWatchLogStack(largeMessageBehavior: largeMessageBehavior) {
    validateLogGroupName(groupName);
    validateLogStreamName(streamName);
  }

  /// prints [message] if [v] is greater than the verbosity level
  bool debugPrint(int v, String message) {
    if (verbosity > v) {
      print(message);
      return true;
    }
    return false;
  }

  /// Creates a log stream if one hasn't been created yet
  ///
  /// Throws [CloudWatchException] if API returns something other than 200
  Future<void> createLogStream() async {
    await createLogResource(
      body: '{"logGroupName": "$groupName","logStreamName": "$streamName"}',
      target: 'Logs_20140328.CreateLogStream',
      type: 'LogStream',
    );
  }

  /// Creates a log group if one hasn't been created yet
  ///
  /// Throws [CloudWatchException] if API returns something other than 200
  Future<void> createLogGroup() async {
    await createLogResource(
      body: '{"logGroupName": "$groupName"}',
      target: 'Logs_20140328.CreateLogGroup',
      type: 'LogGroup',
    );
  }

  /// Creates a specified log resource
  ///
  /// and throws a [CloudWatchException] if it cant.
  Future<void> createLogResource({
    required String body,
    required String target,
    required String type,
  }) async {
    final bool isLogGroup = type == 'LogGroup';
    if (!(isLogGroup ? logGroupCreated : logStreamCreated)) {
      debugPrint(
        2,
        'CloudWatch INFO: creating $type Exists',
      );
      if (isLogGroup) {
        logGroupCreated = true;
      } else {
        logStreamCreated = true;
      }
      Response result;
      try {
        result = await sendRequest(
          body: body,
          target: target,
        );
      } catch (e) {
        if (isLogGroup) {
          logGroupCreated = false;
        } else {
          logStreamCreated = false;
        }
        rethrow;
      }
      final int statusCode = result.statusCode;
      debugPrint(
        1,
        'CloudWatch Info: $type creation status code: $statusCode',
      );
      if (statusCode != 200) {
        final AwsResponse response = await AwsResponse.parseResponse(result);
        debugPrint(
          0,
          'CloudWatch ERROR: $response',
        );
        // Just move on if the resource already exists
        if (response.type != 'ResourceAlreadyExistsException') {
          if (isLogGroup) {
            logGroupCreated = false;
          } else {
            logStreamCreated = false;
          }
          throw CloudWatchException(
            message: response.message,
            type: response.type,
            stackTrace: StackTrace.current,
            raw: response.raw,
          );
        }
      }
      debugPrint(
        2,
        'CloudWatch INFO: created $type',
      );
    }
  }

  /// Creates a json log events string and adds the sequence token if available
  String createBody(List<Map<String, dynamic>> logsToSend) {
    debugPrint(
      2,
      'CloudWatch INFO: Generating CloudWatch request body',
    );
    final Map<String, dynamic> body = {
      'logEvents': logsToSend,
      'logGroupName': groupName,
      'logStreamName': streamName,
    };
    if (sequenceToken != null) {
      body['sequenceToken'] = sequenceToken;
      debugPrint(
        2,
        'CloudWatch INFO: Adding sequence token',
      );
    }
    final String jsonBody = jsonEncode(body);
    debugPrint(
      2,
      'CloudWatch INFO: Generated jsonBody with ${logsToSend.length} logs: $jsonBody',
    );
    return jsonBody;
  }

  /// Sets up log stream / group and then queues logs to be sent
  Future<void> log(List<String> logStrings) async {
    logStack.addLogs(logStrings);
    debugPrint(
      2,
      'CloudWatch INFO: Added messages to log stack',
    );
    dynamic error;
    await sendAllLogs().catchError((e) {
      error = e;
    });
    if (checkError(error)) {
      return;
    }
  }

  /// Checks info about [error] and returns whether execution should stop
  bool checkError(dynamic error) {
    if (error != null) {
      if (!raiseFailedLookups &&
          (error.toString().contains('XMLHttpRequest error') ||
              error.toString().contains('Failed host lookup'))) {
        print(
          'CloudWatch: Failed host lookup! This usually means internet '
          'is unavailable but could also indicate a problem with the '
          'region $region.',
        );
        return true; // stop execution
      } else {
        throw error;
      }
    }
    return false; // continue execution
  }

  /// Queues [sendLogs] until all logs are sent or error occurs
  Future<void> sendAllLogs() async {
    while (logStack.length > 0) {
      await Future.delayed(
        delay,
      );
      await lock.synchronized(sendLogs);
    }
  }

  /// Calls functions to send logs and gracefully handle errors and retries
  Future<void> sendLogs() async {
    if (logStack.length <= 0) {
      // logs already sent while this request was waiting for lock
      debugPrint(
        2,
        'CloudWatch INFO: All logs have already been sent',
      );
      return;
    }
    // capture logs that are about to be sent in case the request fails
    final CloudWatchLog _logs = logStack.pop();
    bool success = false;
    dynamic error;
    for (int i = 0; i < retries && !success; i++) {
      try {
        final String body = createBody(_logs.logs);
        final Response response = await sendRequest(
          body: body,
          target: 'Logs_20140328.PutLogEvents',
        );
        success = await handleResponse(response);
      } catch (e) {
        debugPrint(
          0,
          'CloudWatch ERROR: Failed making AwsRequest. Retrying ${i + 1}',
        );
        error = e;
      }
    }
    if (!success) {
      // prepend logs in event of failure
      logStack.prepend(_logs);
      debugPrint(
        0,
        'CloudWatch ERROR: Failed to send logs',
      );
      if (error != null) {
        throw error;
      }
    }
  }

  /// Does the actual sending of any api request and returns the result
  Future<Response> sendRequest({
    required String body,
    required String target,
  }) async {
    final Map<String, String> headers = {'x-amz-target': target};
    final Map<String, String> queryString = {};
    if (awsSessionToken != null) {
      headers['X-Amz-Security-Token'] = awsSessionToken!;
    }
    if (requestTimeout.inSeconds > 0 && requestTimeout.inSeconds < 604800) {
      queryString['X-Amz-Expires'] = requestTimeout.inSeconds.toString();
    }
    dynamic awsRequest;
    if (mockCloudWatch) {
      awsRequest = MockAwsRequest(
        awsAccessKey,
        awsSecretKey,
        region,
        service: 'logs',
        timeout: requestTimeout,
        mockFunction: mockFunction!,
      );
    } else {
      awsRequest = AwsRequest(
        awsAccessKey: awsAccessKey,
        awsSecretKey: awsSecretKey,
        region: region,
        service: 'logs',
        timeout: requestTimeout,
      );
    }
    return await awsRequest.send(
      type: AwsRequestType.post,
      jsonBody: body,
      headers: headers,
      queryString: queryString,
      signedHeaders: ['x-amz-target'],
    );
  }

  /// Handles the [response] from the cloudwatch api.
  ///
  /// Returns whether or not the call was successful
  Future<bool> handleResponse(
    Response response,
  ) async {
    final AwsResponse awsResponse = await AwsResponse.parseResponse(response);
    if (awsResponse.statusCode == 200) {
      debugPrint(
        1,
        'CloudWatch Info: $awsResponse',
      );
      sequenceToken = awsResponse.nextSequenceToken;
      return true;
    } else {
      if (awsResponse.type != null) {
        return handleError(awsResponse);
      }
      debugPrint(
        0,
        'CloudWatch ERROR: $awsResponse',
      );
      // failed for unknown reason. Throw error
      throw CloudWatchException(
        message: awsResponse.message,
        type: awsResponse.type,
        stackTrace: StackTrace.current,
        raw: awsResponse.raw,
      );
    }
  }

  /// Gracefully manage and recover from errors as best as possible
  ///
  /// returns whether the error was recovered from or not
  Future<bool> handleError(AwsResponse awsResponse) async {
    if (awsResponse.type == 'InvalidSequenceTokenException' &&
        awsResponse.expectedSequenceToken != sequenceToken) {
      // bad sequence token
      // Sometimes happen when requests are sent in quick succession
      // Attempt to recover
      sequenceToken = awsResponse.expectedSequenceToken;
      debugPrint(
        0,
        'CloudWatch Info: Found incorrect sequence token. Attempting to fix.',
      );
      return false;
    } else if (awsResponse.type == 'ResourceNotFoundException' &&
        awsResponse.message == 'The specified log stream does not exist.') {
      // LogStream not present
      // Sometimes happens with debuggers / hot reloads
      // Attempt to recover
      debugPrint(
        0,
        "CloudWatch Info: Log Stream doesn't Exist",
      );
      logStreamCreated = false;
      await createLogStream();
      return false;
    } else if (awsResponse.type == 'ResourceNotFoundException' &&
        awsResponse.message == 'The specified log group does not exist.') {
      // LogGroup not present
      // Sometimes happens with debuggers / hot reloads
      // Attempt to recover
      debugPrint(
        0,
        "CloudWatch Info: Log Group doesn't Exist",
      );
      logGroupCreated = false;
      await createLogGroup();
      return false;
    } else if (awsResponse.type == 'DataAlreadyAcceptedException') {
      // This log set has already been sent.
      // Sometimes happens with debuggers / hot reloads
      // Update the sequence token just in case.
      // A previous request was already successful => return true
      debugPrint(
        0,
        'CloudWatch Info: Data Already Sent',
      );
      sequenceToken = awsResponse.expectedSequenceToken;
      return true;
    }
    return false;
  }
}
