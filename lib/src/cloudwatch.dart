import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aws_cloudwatch/src/util.dart';
import 'package:aws_request/aws_request.dart';
import 'package:http/http.dart';
import 'package:synchronized/synchronized.dart';

import 'log.dart';
import 'log_stack.dart';

/// An AWS CloudWatch class for sending logs more easily to AWS
class AwsCloudWatch {
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
  void set delay(Duration d) {
    _delay = !d.isNegative ? d : Duration();
  }

  /// How long to wait for request before triggering a timeout
  Duration get requestTimeout => _requestTimeout;

  /// How long to wait for request before triggering a timeout
  void set requestTimeout(Duration d) {
    _requestTimeout = !d.isNegative ? d : Duration();
  }

  /// How many times an api request should be retired upon failure. Default is 3
  int get retries => _retries;

  /// How many times an api request should be retired upon failure. Default is 3
  void set retries(int d) {
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
  String? groupName;

  /// Synonym for groupName
  String? get logGroupName => groupName;

  /// Synonym for groupName
  set logGroupName(String? val) => groupName = val;

  /// The log stream name for log events to be filed in
  String? streamName;

  /// Synonym for streamName
  String? get logStreamName => streamName;

  /// Synonym for streamName
  set logStreamName(String? val) => streamName = val;

  /// Bool to skip log stream creation
  bool logStreamCreated = false;

  /// Bool to skip log group creation
  bool logGroupCreated = false;

  /// A log stack that holds queued logs ready to be sent
  CloudWatchLogStack logStack;

  /// Verbosity for debugging
  int verbosity = 0;

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

  /// CloudWatch Constructor
  AwsCloudWatch({
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
  })  : this._largeMessageBehavior = largeMessageBehavior,
        this._delay = !delay.isNegative ? delay : Duration(),
        this._requestTimeout =
            !requestTimeout.isNegative ? requestTimeout : Duration(),
        this._retries = max(0, retries),
        this.logStack =
            CloudWatchLogStack(largeMessageBehavior: largeMessageBehavior);

  /// Sets console verbosity level.
  /// Useful for debugging.
  /// Hidden by default. Get here with a debugger ;)
  ///
  /// 0 - Errors only
  /// 1 - Status Codes
  /// 2 - General Info
  void setVerbosity(int level) {
    level = min(level, 3);
    level = max(level, 0);
    verbosity = level;
    debugPrint(
      2,
      'CloudWatch INFO: Set verbosity to $verbosity',
    );
  }

  /// prints [msg] if [v] is greater than the verbosity level
  void debugPrint(int v, String msg) {
    if (verbosity > v) {
      print(msg);
    }
  }

  /// Creates a log stream and log group if needed
  ///
  /// rethrows any caught errors if ultimately unsuccessful
  Future<void> createLogStreamAndLogGroup() async {
    dynamic error;
    // retries + 1 to account for first try with 0 retries
    for (int i = 0; i < retries + 1; i++) {
      try {
        await createLogStream();
        return;
      } on CloudWatchException catch (e) {
        if (e.type == 'ResourceNotFoundException') {
          // Create a new log group and try stream creation again
          await createLogGroup();
          await createLogStream();
          return;
        }
        error = e;
      } catch (e) {
        error = e;
        debugPrint(
          0,
          'CloudWatch ERROR: Failed _createLogStreamAndLogGroup. Retrying ${i + 1}',
        );
      }
    }
    throw error;
  }

  /// Creates a log stream if one hasn't been created yet
  ///
  /// Throws [CloudWatchException] if API returns something other than 200
  Future<void> createLogStream() async {
    if (!logStreamCreated) {
      debugPrint(
        2,
        'CloudWatch INFO: Generating LogStream',
      );
      logStreamCreated = true;
      String body =
          '{"logGroupName": "$groupName","logStreamName": "$streamName"}';
      Response result;
      Map<String, String> headers = {};
      Map<String, String> queryString = {};
      if (awsSessionToken != null) {
        headers['X-Amz-Security-Token'] = awsSessionToken!;
      }
      if (requestTimeout.inSeconds > 0 && requestTimeout.inSeconds < 604800) {
        queryString['X-Amz-Expires'] = requestTimeout.inSeconds.toString();
      }
      try {
        result = await sendRequest(
          body: body,
          target: 'Logs_20140328.CreateLogStream',
        );
      } catch (e) {
        logStreamCreated = false;
        rethrow;
      }
      int statusCode = result.statusCode;
      debugPrint(
        1,
        'CloudWatch Info: LogStream creation status code: $statusCode',
      );
      if (statusCode != 200) {
        AwsResponse response = await AwsResponse.parseResponse(result);
        debugPrint(
          0,
          'CloudWatch ERROR: $response',
        );
        // Just move on if the resource already exists
        if (response.type != 'ResourceAlreadyExistsException') {
          logStreamCreated = false;
          throw CloudWatchException(
            message: response.message,
            type: response.type,
            stackTrace: StackTrace.current,
            raw: response.raw,
          );
        }
      }
    }
    debugPrint(
      2,
      'CloudWatch INFO: Got LogStream',
    );
  }

  /// Creates a log group if one hasn't been created yet
  ///
  /// Throws [CloudWatchException] if API returns something other than 200
  Future<void> createLogGroup() async {
    if (!logGroupCreated) {
      debugPrint(
        2,
        'CloudWatch INFO: creating LogGroup Exists',
      );
      logGroupCreated = true;
      String body = '{"logGroupName": "$groupName"}';
      Response result;
      Map<String, String> headers = {};
      Map<String, String> queryString = {};
      if (awsSessionToken != null) {
        headers['X-Amz-Security-Token'] = awsSessionToken!;
      }
      if (requestTimeout.inSeconds > 0 && requestTimeout.inSeconds < 604800) {
        queryString['X-Amz-Expires'] = requestTimeout.inSeconds.toString();
      }
      try {
        result = await sendRequest(
          body: body,
          target: 'Logs_20140328.CreateLogGroup',
        );
      } catch (e) {
        logGroupCreated = false;
        rethrow;
      }
      int statusCode = result.statusCode;
      debugPrint(
        1,
        'CloudWatch Info: LogGroup creation status code: $statusCode',
      );
      if (statusCode != 200) {
        AwsResponse response = await AwsResponse.parseResponse(result);
        debugPrint(
          0,
          'CloudWatch ERROR: $response',
        );
        // Just move on if the resource already exists
        if (response.type != 'ResourceAlreadyExistsException') {
          logGroupCreated = false;
          throw CloudWatchException(
            message: response.message,
            type: response.type,
            stackTrace: StackTrace.current,
            raw: response.raw,
          );
        }
      }
    }
    debugPrint(
      2,
      'CloudWatch INFO: created LogGroup',
    );
  }

  /// Creates a json log events string and adds the sequence token if available
  String createBody(List<Map<String, dynamic>> logsToSend) {
    debugPrint(
      2,
      'CloudWatch INFO: Generating CloudWatch request body',
    );
    Map<String, dynamic> body = {
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
    String jsonBody = json.encode(body);
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
    if (!logStreamCreated) {
      await lock.synchronized(createLogStreamAndLogGroup).catchError((e) {
        error = e;
      });
    }
    if (checkError(error)) return;
    await sendAllLogs().catchError((e) {
      error = e;
    });
    if (checkError(error)) return;
  }

  /// Checks info about [error] and returns whether execution should stop
  bool checkError(dynamic error) {
    if (error != null) {
      if (!raiseFailedLookups &&
              error.toString().contains('XMLHttpRequest error') ||
          error.toString().contains('Failed host lookup')) {
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
    dynamic error;
    while (logStack.length > 0 && error == null) {
      await Future.delayed(
        delay,
        () async => await lock.synchronized(sendLogs),
      ).catchError((e) {
        error = e;
      });
    }
    if (error != null) {
      throw error;
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
    CloudWatchLog _logs = logStack.pop();
    bool success = false;
    dynamic error;
    for (int i = 0; i < retries && !success; i++) {
      try {
        String body = createBody(_logs.logs);
        Response response = await sendRequest(
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
      if (error != null) throw error;
    }
  }

  /// Does the actual sending of any api request and returns the result
  Future<Response> sendRequest({
    required String body,
    required String target,
  }) async {
    Map<String, String> headers = {};
    Map<String, String> queryString = {};
    if (awsSessionToken != null) {
      headers['X-Amz-Security-Token'] = awsSessionToken!;
    }
    if (requestTimeout.inSeconds > 0 && requestTimeout.inSeconds < 604800) {
      queryString['X-Amz-Expires'] = requestTimeout.inSeconds.toString();
    }
    return await AwsRequest(
      awsAccessKey,
      awsSecretKey,
      region,
      service: 'logs',
      timeout: requestTimeout,
    ).send(
      AwsRequestType.POST,
      jsonBody: body,
      target: target,
      headers: headers,
      queryString: queryString,
    );
  }

  /// Handles the [response] from the cloudwatch api.
  ///
  /// Returns whether or not the call was successful
  Future<bool> handleResponse(
    Response response,
  ) async {
    AwsResponse awsResponse = await AwsResponse.parseResponse(response);
    if (awsResponse.statusCode == 200) {
      debugPrint(
        1,
        'CloudWatch Info: $awsResponse',
      );
      sequenceToken = awsResponse.nextSequenceToken;
      return true;
    } else {
      if (awsResponse.type != null) {
        return await handleError(awsResponse);
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
        awsResponse.message == "The specified log stream does not exist.") {
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
        awsResponse.message == "The specified log group does not exist.") {
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
