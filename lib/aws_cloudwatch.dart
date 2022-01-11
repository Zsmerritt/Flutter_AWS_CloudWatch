library aws_cloudwatch;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aws_request/aws_request.dart';
import 'package:synchronized/synchronized.dart';

import 'aws_cloudwatch_cloudwatch_log.dart';
import 'aws_cloudwatch_log_stack.dart';
import 'aws_cloudwatch_util.dart';
import 'package:http/http.dart' as http;

/// Enum representing what should happen to messages that are too big
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

  /// Private version of access key
  String _awsAccessKey;

  /// Your AWS access key
  set awsAccessKey(String awsAccessKey) {
    // Updates all instances with new key. Useful for temp credentials
    for (CloudWatch cw in _logInstances.values) {
      cw.awsAccessKey = awsAccessKey;
      _awsAccessKey = awsAccessKey;
    }
  }

  /// Your AWS access key
  String get awsAccessKey => _awsAccessKey;

  /// Private version of secret key
  String _awsSecretKey;

  /// Your AWS secret key
  set awsSecretKey(String awsSecretKey) {
    // Updates all instances with new key. Useful for temp credentials
    for (CloudWatch cw in _logInstances.values) {
      cw.awsSecretKey = awsSecretKey;
      _awsSecretKey = awsSecretKey;
    }
  }

  /// Your AWS secret key
  String get awsSecretKey => _awsSecretKey;

  /// Private version of session token
  String? _awsSessionToken;

  /// Your AWS session token
  set awsSessionToken(String? awsSessionToken) {
    // Updates all instances with new key. Useful for temp credentials
    for (CloudWatch cw in _logInstances.values) {
      cw.awsSessionToken = awsSessionToken;
      _awsSessionToken = awsSessionToken;
    }
  }

  /// Your AWS session token
  String? get awsSessionToken => _awsSessionToken;

  /// Your AWS region. Instances are not updated when this value is changed
  String region;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  Duration get delay => _delay;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  set delay(Duration val) {
    for (CloudWatch cw in _logInstances.values) {
      cw.delay = val;
      _delay = val;
    }
  }

  /// private version of [delay]
  Duration _delay;

  /// How long to wait for request before triggering a timeout
  Duration get requestTimeout => _requestTimeout;

  /// How long to wait for request before triggering a timeout
  set requestTimeout(Duration val) {
    for (CloudWatch cw in _logInstances.values) {
      cw.requestTimeout = val;
      _requestTimeout = val;
    }
  }

  /// private version of [requestTimeout]
  Duration _requestTimeout;

  /// How many times an api request should be retired upon failure. Default is 3
  int get retries => _retries;

  /// How many times an api request should be retired upon failure. Default is 3
  set retries(int val) {
    for (CloudWatch cw in _logInstances.values) {
      cw.retries = val;
      _retries = val;
    }
  }

  /// private version of [largeMessageBehavior]
  int _retries;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  CloudWatchLargeMessages get largeMessageBehavior => _largeMessageBehavior;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  set largeMessageBehavior(CloudWatchLargeMessages val) {
    for (CloudWatch cw in _logInstances.values) {
      cw.largeMessageBehavior = val;
    }
    _largeMessageBehavior = val;
  }

  /// private version of [largeMessageBehavior]
  CloudWatchLargeMessages _largeMessageBehavior;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  bool get raiseFailedLookups => _raiseFailedLookups;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  set raiseFailedLookups(bool val) {
    for (CloudWatch cw in _logInstances.values) {
      cw.raiseFailedLookups = val;
    }
    _raiseFailedLookups = val;
  }

  /// private version of [raiseFailedLookups]
  bool _raiseFailedLookups;

  /// CloudWatchHandler Constructor
  CloudWatchHandler({
    required awsAccessKey,
    required awsSecretKey,
    required this.region,
    awsSessionToken: null,
    delay: const Duration(),
    requestTimeout: const Duration(seconds: 10),
    retries: 3,
    largeMessageBehavior: CloudWatchLargeMessages.truncate,
    raiseFailedLookups: false,
  })  : this._awsAccessKey = awsAccessKey,
        this._awsSecretKey = awsSecretKey,
        this._awsSessionToken = awsSessionToken,
        this._delay = delay,
        this._requestTimeout = requestTimeout,
        this._retries = max(0, retries),
        this._largeMessageBehavior = largeMessageBehavior,
        this._raiseFailedLookups = raiseFailedLookups;

  /// Returns a specific instance of a CloudWatch class (or null if it doesn't
  /// exist) based on group name and stream name
  ///
  /// Uses the [logGroupName] and the [logStreamName] to find the correct
  /// CloudWatch instance. Returns null if it doesn't exist
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
        createInstance(
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        );
    await instance.logMany(messages);
  }

  /// Creates a CloudWatch instance.
  ///
  /// Calling any log function will call this as needed automatically
  CloudWatch createInstance({
    required String logGroupName,
    required String logStreamName,
  }) {
    validateLogGroupName(logGroupName);
    validateLogStreamName(logStreamName);
    String instanceName = '$logGroupName.$logStreamName';
    CloudWatch instance = CloudWatch(
      awsAccessKey,
      awsSecretKey,
      region,
      groupName: logGroupName,
      streamName: logStreamName,
      awsSessionToken: awsSessionToken,
      delay: delay,
      requestTimeout: requestTimeout,
      retries: retries,
      largeMessageBehavior: largeMessageBehavior,
      raiseFailedLookups: raiseFailedLookups,
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
  int _verbosity = 0;

  /// Token provided by aws to ensure logs are received in the correct order
  String? _sequenceToken;

  /// Synchronous lock to enforce synchronous request order
  Lock _loggingLock = Lock();

  /// Private version of delay
  Duration _delay;

  /// Private version of requestTimeout
  Duration _requestTimeout;

  /// Private version of retries
  int _retries;

  /// CloudWatch Constructor
  CloudWatch(
    this.awsAccessKey,
    this.awsSecretKey,
    this.region, {
    this.groupName,
    this.streamName,
    this.awsSessionToken,
    delay: const Duration(),
    requestTimeout: const Duration(seconds: 10),
    retries: 3,
    largeMessageBehavior: CloudWatchLargeMessages.truncate,
    this.raiseFailedLookups: false,
  })  : this._largeMessageBehavior = largeMessageBehavior,
        this._delay = !delay.isNegative ? delay : Duration(),
        this._requestTimeout =
            !requestTimeout.isNegative ? requestTimeout : Duration(),
        this._retries = max(0, retries),
        this.logStack =
            CloudWatchLogStack(largeMessageBehavior: largeMessageBehavior);

  /// Sets how long to wait between requests to avoid rate limiting
  ///
  /// Sets the delay to be [delay]
  @Deprecated('Set the delay property')
  Duration setDelay(Duration delay) {
    this.delay = delay;
    _debugPrint(
      2,
      'CloudWatch INFO: Set delay to $delay',
    );
    return delay;
  }

  /// Sets log group name and log stream name
  ///
  /// Sets the [logGroupName] and [logStreamName]
  @Deprecated('Set the logGroupName and logStreamName properties')
  void setLoggingParameters(String? logGroupName, String? logStreamName) {
    groupName = logGroupName;
    streamName = logStreamName;
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
    validateLogGroupName(groupName);
    validateLogStreamName(streamName);
    await _log(logStrings);
  }

  /// Sets console verbosity level.
  /// Useful for debugging.
  /// Hidden by default. Get here with a debugger ;)
  ///
  /// 0 - Errors only
  /// 1 - Status Codes
  /// 2 - General Info
  void _setVerbosity(int level) {
    level = min(level, 3);
    level = max(level, 0);
    _verbosity = level;
    _debugPrint(
      2,
      'CloudWatch INFO: Set verbosity to $_verbosity',
    );
  }

  /// prints [msg] if [v] is greater than the verbosity level
  void _debugPrint(int v, String msg) {
    if (_verbosity > v) {
      print(msg);
    }
  }

  /// Creates a log stream and log group if needed
  ///
  /// rethrows any caught errors if ultimately unsuccessful
  Future<void> _createLogStreamAndLogGroup() async {
    dynamic error;
    // retries + 1 to account for first try with 0 retries
    for (int i = 0; i < retries + 1; i++) {
      try {
        await _createLogStream();
        return;
      } on CloudWatchException catch (e) {
        if (e.type == 'ResourceNotFoundException') {
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
    throw error;
  }

  /// Creates a log stream if one hasn't been created yet
  ///
  /// Throws [CloudWatchException] if API returns something other than 200
  Future<void> _createLogStream() async {
    if (!logStreamCreated) {
      _debugPrint(
        2,
        'CloudWatch INFO: Generating LogStream',
      );
      logStreamCreated = true;
      String body =
          '{"logGroupName": "$groupName","logStreamName": "$streamName"}';
      http.Response log;
      Map<String, String> headers = {};
      Map<String, String> queryString = {};
      if (awsSessionToken != null) {
        headers['X-Amz-Security-Token'] = awsSessionToken!;
      }
      if (requestTimeout.inSeconds > 0 && requestTimeout.inSeconds < 604800) {
        queryString['X-Amz-Expires'] = requestTimeout.inSeconds.toString();
      }
      try {
        log = await AwsRequest(
          awsAccessKey,
          awsSecretKey,
          region,
          service: 'logs',
          timeout: requestTimeout,
        ).send(
          AwsRequestType.POST,
          jsonBody: body,
          target: 'Logs_20140328.CreateLogStream',
          headers: headers,
          queryString: queryString,
        );
      } catch (e) {
        logStreamCreated = false;
        rethrow;
      }
      int statusCode = log.statusCode;
      _debugPrint(
        1,
        'CloudWatch Info: LogStream creation status code: $statusCode',
      );
      if (statusCode != 200) {
        AwsResponse response = await AwsResponse.parseResponse(log);
        _debugPrint(
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
    _debugPrint(
      2,
      'CloudWatch INFO: Got LogStream',
    );
  }

  /// Creates a log group if one hasn't been created yet
  ///
  /// Throws [CloudWatchException] if API returns something other than 200
  Future<void> _createLogGroup() async {
    if (!logGroupCreated) {
      _debugPrint(
        2,
        'CloudWatch INFO: creating LogGroup Exists',
      );
      logGroupCreated = true;
      String body = '{"logGroupName": "$groupName"}';
      http.Response log;
      Map<String, String> headers = {};
      Map<String, String> queryString = {};
      if (awsSessionToken != null) {
        headers['X-Amz-Security-Token'] = awsSessionToken!;
      }
      if (requestTimeout.inSeconds > 0 && requestTimeout.inSeconds < 604800) {
        queryString['X-Amz-Expires'] = requestTimeout.inSeconds.toString();
      }
      try {
        log = await AwsRequest(
          awsAccessKey,
          awsSecretKey,
          region,
          service: 'logs',
          timeout: requestTimeout,
        ).send(
          AwsRequestType.POST,
          jsonBody: body,
          target: 'Logs_20140328.CreateLogGroup',
          headers: headers,
          queryString: queryString,
        );
      } catch (e) {
        logGroupCreated = false;
        rethrow;
      }
      int statusCode = log.statusCode;
      _debugPrint(
        1,
        'CloudWatch Info: LogGroup creation status code: $statusCode',
      );
      if (statusCode != 200) {
        AwsResponse response = await AwsResponse.parseResponse(log);
        _debugPrint(
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
    _debugPrint(
      2,
      'CloudWatch INFO: created LogGroup',
    );
  }

  /// Creates a json log events string and adds the sequence token if available
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

  /// Sets up log stream / group and then queues logs to be sent
  Future<void> _log(List<String> logStrings) async {
    logStack.addLogs(logStrings);
    _debugPrint(
      2,
      'CloudWatch INFO: Added messages to log stack',
    );
    dynamic error;
    if (!logStreamCreated) {
      await _loggingLock
          .synchronized(_createLogStreamAndLogGroup)
          .catchError((e) {
        error = e;
      });
    }
    if (_checkError(error)) return;
    await _sendAllLogs().catchError((e) {
      error = e;
    });
    if (_checkError(error)) return;
  }

  /// Checks info about [error] and returns whether execution should stop
  bool _checkError(dynamic error) {
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

  /// Queues [_sendLogs] until all logs are sent or error occurs
  Future<void> _sendAllLogs() async {
    dynamic error;
    while (logStack.length > 0 && error == null) {
      await Future.delayed(
        delay,
        () async => await _loggingLock.synchronized(_sendLogs),
      ).catchError((e) {
        error = e;
      });
    }
    if (error != null) {
      throw error;
    }
  }

  /// Calls functions to send logs and gracefully handle errors and retries
  Future<void> _sendLogs() async {
    if (logStack.length <= 0) {
      // logs already sent while this request was waiting for lock
      _debugPrint(
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
        http.Response? response = await _sendRequest(_logs);
        success = await _handleResponse(response);
      } catch (e) {
        _debugPrint(
          0,
          'CloudWatch ERROR: Failed making AwsRequest. Retrying ${i + 1}',
        );
        error = e;
      }
    }
    if (!success) {
      // prepend logs in event of failure
      logStack.prepend(_logs);
      _debugPrint(
        0,
        'CloudWatch ERROR: Failed to send logs',
      );
      if (error != null) throw error;
    }
  }

  /// Creates an AwsRequest and sends request
  Future<http.Response?> _sendRequest(CloudWatchLog _logs) async {
    String body = _createBody(_logs.logs);
    http.Response? result;
    Map<String, String> headers = {};
    Map<String, String> queryString = {};
    if (awsSessionToken != null) {
      headers['X-Amz-Security-Token'] = awsSessionToken!;
    }
    if (requestTimeout.inSeconds > 0 && requestTimeout.inSeconds < 604800) {
      queryString['X-Amz-Expires'] = requestTimeout.inSeconds.toString();
    }
    result = await AwsRequest(
      awsAccessKey,
      awsSecretKey,
      region,
      service: 'logs',
      timeout: requestTimeout,
    ).send(
      AwsRequestType.POST,
      jsonBody: body,
      target: 'Logs_20140328.PutLogEvents',
      headers: headers,
      queryString: queryString,
    );
    return result;
  }

  /// Handles the [response] from the cloudwatch api.
  ///
  /// Returns whether or not the call was successful
  Future<bool> _handleResponse(
    http.Response? response,
  ) async {
    if (response == null) {
      _debugPrint(
        0,
        'CloudWatch ERROR: Null response received from AWS',
      );
      throw CloudWatchException(
        message: 'CloudWatch ERROR: Null response received from AWS',
        stackTrace: StackTrace.current,
      );
    }
    AwsResponse awsResponse = await AwsResponse.parseResponse(response);
    if (awsResponse.statusCode == 200) {
      _debugPrint(
        1,
        'CloudWatch Info: $awsResponse',
      );
      _sequenceToken = awsResponse.nextSequenceToken;
      return true;
    } else {
      if (awsResponse.type != null) {
        return await _handleError(awsResponse);
      }
      _debugPrint(
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
  Future<bool> _handleError(AwsResponse awsResponse) async {
    if (awsResponse.type == 'InvalidSequenceTokenException' &&
        awsResponse.expectedSequenceToken != _sequenceToken) {
      // bad sequence token
      // Sometimes happen when requests are sent in quick succession
      // Attempt to recover
      _sequenceToken = awsResponse.expectedSequenceToken;
      _debugPrint(
        0,
        'CloudWatch Info: Found incorrect sequence token. Attempting to fix.',
      );
      return false;
    } else if (awsResponse.type == 'ResourceNotFoundException' &&
        awsResponse.message == "The specified log stream does not exist.") {
      // LogStream not present
      // Sometimes happens with debuggers / hot reloads
      // Attempt to recover
      _debugPrint(
        0,
        "CloudWatch Info: Log Stream doesn't Exist",
      );
      logStreamCreated = false;
      await _createLogStream();
      return false;
    } else if (awsResponse.type == 'ResourceNotFoundException' &&
        awsResponse.message == "The specified log group does not exist.") {
      // LogGroup not present
      // Sometimes happens with debuggers / hot reloads
      // Attempt to recover
      _debugPrint(
        0,
        "CloudWatch Info: Log Group doesn't Exist",
      );
      logGroupCreated = false;
      await _createLogGroup();
      return false;
    } else if (awsResponse.type == 'DataAlreadyAcceptedException') {
      // This log set has already been sent.
      // Sometimes happens with debuggers / hot reloads
      // Update the sequence token just in case.
      // A previous request was already successful => return true
      _debugPrint(
        0,
        'CloudWatch Info: Data Already Sent',
      );
      _sequenceToken = awsResponse.expectedSequenceToken;
      return true;
    }
    return false;
  }
}
