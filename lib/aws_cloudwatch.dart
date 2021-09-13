library aws_cloudwatch;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aws_request/aws_request.dart';
import 'package:synchronized/synchronized.dart';
import 'package:universal_io/io.dart';

// AWS Hard Limits
const _AWS_LOG_GROUP_NAME_REGEX_PATTERN = r'^[\.\-_/#A-Za-z0-9]+$';
const _AWS_LOG_STREAM_NAME_REGEX_PATTERN = r'^[^:*]*$';
const int AWS_MAX_BYTE_MESSAGE_SIZE = 262118;
const int AWS_MAX_BYTE_BATCH_SIZE = 1048550;
const int AWS_MAX_MESSAGES_PER_BATCH = 10000;

class CloudWatchException implements Exception {
  late String message;
  late String cause;
  StackTrace stackTrace;

  /// A custom error to identify CloudWatch errors more easily
  ///
  /// message: the cause of the error
  /// stackTrace: the stack trace of the error
  CloudWatchException(String message, this.stackTrace) {
    this.cause = message;
    this.message = message;
  }
}

/// A CloudWatch handler class to easily manage multiple CloudWatch instances
class CloudWatchHandler {
  Map<String, CloudWatch> _logInstances = {};
  String awsAccessKey;
  String awsSecretKey;
  String region;
  Duration delay;
  Duration requestTimeout;
  int retries;
  bool splitLargeMessages;

  /// CloudWatchHandler Constructor
  ///
  /// awsAccessKey: Your AWS Access key.
  ///
  /// awsSecretKey: Your AWS Secret key.
  ///
  /// region: Your AWS region.
  ///
  /// {delay}: Optional delay parameter to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  ///
  /// {requestTimeout}: Duration to wait for request before triggering a timeout
  ///
  /// {retries}: Optional parameter specifying number of times to retry api request on failure. Default is 3
  ///
  /// {splitLargeMessages}: Optional parameter specifying whether messages too large to send should be split up into multiple messages. Default is false
  CloudWatchHandler({
    required this.awsAccessKey,
    required this.awsSecretKey,
    required this.region,
    this.delay: const Duration(milliseconds: 0),
    this.requestTimeout: const Duration(seconds: 10),
    this.retries: 3,
    this.splitLargeMessages: false,
  }) {
    this.retries = max(1, this.retries);
  }

  /// Returns a specific instance of a CloudWatch class (or null if it doesnt
  /// exist) based on group name and stream name
  ///
  /// logGroupName: the log group name of the instance you would like
  /// logStreamName: the stream name of the instance you would like
  CloudWatch? getInstance({
    required String logGroupName,
    required String logStreamName,
  }) {
    String instanceName = '$logGroupName.$logStreamName';
    return _logInstances[instanceName];
  }

  /// Logs the provided message to the provided log group and log stream
  /// Creates a new CloudWatch instance if needed
  ///
  /// msg: the message you would like to log
  /// logGroupName: the log group the log stream will appear under
  /// logStreamName: the name of the logging session
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
  /// Creates a new CloudWatch instance if needed
  ///
  /// msg: the message you would like to log
  /// logGroupName: the log group the log stream will appear under
  /// logStreamName: the name of the logging session
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
      splitLargeMessages: splitLargeMessages,
    );
    _logInstances[instanceName] = instance;
    return instance;
  }
}

/// An AWS CloudWatch class for sending logs more easily to AWS
class CloudWatch {
  // AWS Variables
  String awsAccessKey;
  String awsSecretKey;
  String region;
  Duration delay;
  Duration requestTimeout;
  int retries;
  bool splitLargeMessages;

  int _verbosity = 0;

  // Logging Variables
  /// The log group name for the log stream to go in
  String? groupName;

  /// Synonym for groupName
  String? get logGroupName => groupName;

  set logGroupName(String? val) => groupName = val;

  /// The log stream name for log events to be filed in
  String? streamName;

  /// Synonym for streamName
  String? get logStreamName => streamName;

  set logStreamName(String? val) => streamName = val;

  String? _sequenceToken;
  late _LogStack _logStack;
  var _loggingLock = Lock();
  bool _logStreamCreated = false;
  bool _logGroupCreated = false;

  /// CloudWatch Constructor
  ///
  /// awsAccessKey: Public AWS access key
  ///
  /// awsSecretKey: Private AWS access key
  ///
  /// region: AWS region
  ///
  /// {logGroupName}: The log group the log stream will appear under
  ///
  /// {logStreamName}: The name of this logging session
  ///
  /// {delay}: Duration to wait for more logs to accumulate to avoid rate limiting.
  ///
  /// {requestTimeout}: Duration to wait for request before triggering a timeout
  ///
  /// {retries}: Optional parameter specifying number of times to retry api request on failure. Default is 3
  ///
  /// {splitLargeMessages}: Optional parameter specifying whether messages too large to send should be split up into multiple messages. Default is false
  CloudWatch(
    this.awsAccessKey,
    this.awsSecretKey,
    this.region, {
    this.groupName,
    this.streamName,
    this.delay: const Duration(milliseconds: 0),
    this.requestTimeout: const Duration(seconds: 10),
    this.retries: 3,
    this.splitLargeMessages: false,
  }) {
    delay = !delay.isNegative ? delay : Duration(milliseconds: 0);
    this.retries = max(1, this.retries);
    this._logStack = _LogStack(splitLargeMessages: splitLargeMessages);
  }

  ///DEPRECATED
  CloudWatch.withDelay(
    this.awsAccessKey,
    this.awsSecretKey,
    this.region,
    this.delay, {
    this.groupName,
    this.streamName,
    this.requestTimeout: const Duration(seconds: 10),
    this.retries: 3,
    this.splitLargeMessages: false,
  }) {
    delay = !delay.isNegative ? delay : Duration(milliseconds: 0);
    this.retries = max(1, this.retries);
    this._logStack = _LogStack(splitLargeMessages: splitLargeMessages);
    print(
      'CloudWatch.withDelay is deprecated. Instead call the default '
      'constructor and provide a value for the optional delay parameter',
    );
  }

  /// Delays sending logs to allow more logs to accumulate to avoid rate limiting
  ///
  /// delay: the Duration to delay
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
  /// groupName: The log group you wish the log to appear under
  /// streamName: The name for this logging session
  void setLoggingParameters(String? groupName, String? streamName) {
    logGroupName = groupName;
    logStreamName = streamName;
  }

  /// Performs a PutLogEvent to CloudWatch
  ///
  /// logString: the string you want to log in CloudWatch
  ///
  /// Throws CloudWatchException if logGroupName or logStreamName are not
  /// initialized or if aws returns an error.
  Future<void> log(String logString) async {
    await logMany([logString]);
  }

  /// Performs a PutLogEvent to CloudWatch
  ///
  /// logStrings: a list of strings you want to log in CloudWatch
  ///
  /// Note: using logMany will result in all logs having the same timestamp
  ///
  /// Throws CloudWatchException if logGroupName or logStreamName are not
  /// initialized or if aws returns an error.
  Future<void> logMany(List<String> logStrings) async {
    _debugPrint(
      2,
      'CloudWatch INFO: Attempting to log many',
    );
    if ([logGroupName, logStreamName].contains(null)) {
      _debugPrint(
        0,
        'CloudWatch ERROR: Please supply a Log Group and Stream names by '
        'calling setLoggingParameters(String? logGroupName, String? logStreamName)',
      );
      throw new CloudWatchException(
          'CloudWatch ERROR: Please supply a Log Group and Stream names by '
          'calling setLoggingParameters(String logGroupName, String logStreamName)',
          StackTrace.current);
    }
    _validateName(
      logGroupName!,
      'logGroupName',
      _AWS_LOG_GROUP_NAME_REGEX_PATTERN,
    );
    _validateName(
      logStreamName!,
      'logStreamName',
      _AWS_LOG_STREAM_NAME_REGEX_PATTERN,
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
          '{"logGroupName": "$logGroupName","logStreamName": "$logStreamName"}';
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
      String body = '{"logGroupName": "$logGroupName"}';
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
      'logGroupName': logGroupName,
      'logStreamName': logStreamName,
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
      ).catchError((e){
        error = e;
      });
    }
    if (error != null){
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
    required this.splitLargeMessages,
  });

  bool splitLargeMessages;

  List<__LogStack> _logStack = [];

  int get length => _logStack.length;

  void _addLogs(List<String> logStrings) {
    int time = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (String msg in logStrings) {
      List<int> bytes = utf8.encode(msg);
      // AWS hard limit on message size
      if (bytes.length > AWS_MAX_BYTE_MESSAGE_SIZE) {
        if (!splitLargeMessages) {
          throw CloudWatchException(
            'Provided log message is too long. Please enable splitLargeMessages'
            ' or split the message yourself. Individual message size limit is '
            '$AWS_MAX_BYTE_MESSAGE_SIZE. log message: $msg',
            StackTrace.current,
          );
        }
        while (bytes.length > AWS_MAX_BYTE_MESSAGE_SIZE) {
          _addToStack(
            time,
            bytes.sublist(0, AWS_MAX_BYTE_MESSAGE_SIZE),
          );
          bytes = bytes.sublist(AWS_MAX_BYTE_MESSAGE_SIZE);
        }
      }
      _addToStack(time, bytes);
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
