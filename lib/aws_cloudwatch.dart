library aws_cloudwatch;

import 'dart:convert';
import 'dart:math';

import 'package:aws_request/aws_request.dart';
import 'package:synchronized/synchronized.dart';
import 'package:universal_io/io.dart';

class CloudWatchException implements Exception {
  String message;
  String cause;

  /// A custom error to identify CloudWatch errors more easily
  ///
  /// message: the cause of the error
  CloudWatchException(String message)
      : this.cause = message,
        this.message = message;
}

/// A CloudWatch handler class to easily manage multiple CloudWatch instances
class CloudWatchHandler {
  Map<String, CloudWatch> _logInstances = {};
  String awsAccessKey;
  String awsSecretKey;
  String region;
  int delay;

  /// CloudWatchHandler Constructor
  ///
  /// awsAccessKey: Your AWS Access key.
  /// awsSecretKey: Your AWS Secret key.
  /// region: Your AWS region.
  /// {delay}: Optional delay parameter to avoid rate limiting (suggested value is 200(ms))
  CloudWatchHandler({
    required this.awsAccessKey,
    required this.awsSecretKey,
    required this.region,
    this.delay: 0,
  });

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
    CloudWatch instance = getInstance(
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        ) ??
        _createInstance(
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        );
    await instance.log(msg);
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
  int delay;
  int _verbosity = 0;
  late AwsRequest _awsRequest;

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
  List<Map<String, dynamic>> _logStack = [];
  var _loggingLock = Lock();
  bool _logStreamCreated = false;
  bool _logGroupCreated = false;

  /// CloudWatch Constructor
  ///
  /// awsAccessKey: Public AWS access key
  /// awsSecretKey: Private AWS access key
  /// region: AWS region
  /// {logGroupName}: The log group the log stream will appear under
  /// {logStreamName}: The name of this logging session
  /// {delay}: Milliseconds to wait for more logs to accumulate to avoid rate limiting.
  CloudWatch(
    this.awsAccessKey,
    this.awsSecretKey,
    this.region, {
    this.groupName,
    this.streamName,
    this.delay: 0,
  }) {
    delay = max(0, delay);
    _awsRequest =
        AwsRequest(awsAccessKey, awsSecretKey, region, service: 'logs');
  }

  ///DEPRECATED
  CloudWatch.withDelay(
    this.awsAccessKey,
    this.awsSecretKey,
    this.region,
    this.delay, {
    this.groupName,
    this.streamName,
  }) {
    delay = max(0, delay);
    _awsRequest =
        AwsRequest(awsAccessKey, awsSecretKey, region, service: 'logs');
    print('CloudWatch.withDelay is deprecated. Instead call the default '
        'constructor and provide a value for the optional delay parameter');
  }

  /// Delays sending logs to allow more logs to accumulate to avoid rate limiting
  ///
  /// delay: The amount of milliseconds to wait.
  int setDelay(int delay) {
    delay = max(0, delay);
    _debugPrint(2, 'CloudWatch INFO: Set delay to $delay');
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

  /// Sets console verbosity level. Default is 0.
  ///
  /// 0 - No console logging.
  /// 1 - Error console logging.
  /// 2 - API response logging.
  /// 3 - Verbose logging
  ///
  /// level: The verbosity level. Valid values are 0 through 3
  void setVerbosity(int level) {
    level = min(level, 3);
    level = max(level, 0);
    _verbosity = level;
    _debugPrint(2, 'CloudWatch INFO: Set verbosity to $_verbosity');
  }

  /// Performs a PutLogEvent to CloudWatch
  ///
  /// logString: the string you want to log in CloudWatch
  ///
  /// Throws CloudWatchException if logGroupName or logStreamName are not
  /// initialized or if aws returns an error.
  Future<void> log(String logString) async {
    _debugPrint(2, 'CloudWatch INFO: Attempting to log $logString');
    if ([logGroupName, logStreamName].contains(null)) {
      _debugPrint(
          0,
          'CloudWatch ERROR: Please supply a Log Group and Stream names by '
          'calling setLoggingParameters(String? logGroupName, String? logStreamName)');
      throw new CloudWatchException(
          'CloudWatch ERROR: Please supply a Log Group and Stream names by '
          'calling setLoggingParameters(String logGroupName, String logStreamName)');
    }
    await _log(logString);
  }

  void _debugPrint(int v, String msg) {
    if (_verbosity > v) {
      print(msg);
    }
  }

  Future<void> _createLogStreamAndLogGroup() async {
    try {
      await _createLogStream();
    } on CloudWatchException catch (e) {
      if (e.message == 'CloudWatch ERROR: ResourceNotFoundException') {
        // Create a new log group and try stream creation again
        await _createLogGroup();
        await _createLogStream();
      }
    }
  }

  Future<void> _createLogStream() async {
    if (!_logStreamCreated) {
      _debugPrint(2, 'CloudWatch INFO: Generating LogStream');
      _logStreamCreated = true;
      String body =
          '{"logGroupName": "$logGroupName","logStreamName": "$logStreamName"}';
      HttpClientResponse log = await _awsRequest.send(
        'POST',
        jsonBody: body,
        target: 'Logs_20140328.CreateLogStream',
      );
      int statusCode = log.statusCode;
      _debugPrint(
          1, 'CloudWatch Info: LogStream creation status code: $statusCode');
      if (statusCode != 200) {
        Map<String, dynamic>? reply =
            jsonDecode(await log.transform(utf8.decoder).join());
        if (reply?['__type'] == 'ResourceNotFoundException') {
          _logStreamCreated = false;
          throw new CloudWatchException(
              'CloudWatch ERROR: ResourceNotFoundException');
        } else {
          _debugPrint(0,
              'CloudWatch ERROR: StatusCode: $statusCode, CloudWatchResponse: $reply');
          _logStreamCreated = false;
          throw new CloudWatchException('CloudWatch ERROR: $reply');
        }
      }
    }
    _debugPrint(2, 'CloudWatch INFO: Got LogStream');
  }

  Future<void> _createLogGroup() async {
    if (!_logGroupCreated) {
      _debugPrint(2, 'CloudWatch INFO: creating LogGroup Exists');
      _logGroupCreated = true;
      String body = '{"logGroupName": "$logGroupName"}';
      HttpClientResponse log = await _awsRequest.send(
        'POST',
        jsonBody: body,
        target: 'Logs_20140328.CreateLogGroup',
      );
      int statusCode = log.statusCode;
      _debugPrint(
          1, 'CloudWatch Info: LogGroup creation status code: $statusCode');
      if (statusCode != 200) {
        Map<String, dynamic>? reply =
            jsonDecode(await log.transform(utf8.decoder).join());
        _debugPrint(0,
            'CloudWatch ERROR: StatusCode: $statusCode, CloudWatchResponse: $reply');
        _logGroupCreated = false;
        throw new CloudWatchException('CloudWatch ERROR: $reply');
      }
    }
    _debugPrint(2, 'CloudWatch INFO: created LogGroup');
  }

  // turns a string into a cloudwatch event
  Future<String> _createBody() async {
    _debugPrint(2, 'CloudWatch INFO: Generating CloudWatch request body');
    Map<String, dynamic> body = {
      'logEvents': _logStack,
      'logGroupName': logGroupName,
      'logStreamName': logStreamName,
    };
    if (_sequenceToken != null) {
      body['sequenceToken'] = _sequenceToken;
      _debugPrint(2, 'CloudWatch INFO: Adding sequence token');
    }
    int logLength = _logStack.length;
    String jsonBody = json.encode(body);
    _logStack = [];
    _debugPrint(2,
        'CloudWatch INFO: Generated jsonBody with $logLength logs: $jsonBody');
    return jsonBody;
  }

  Future<void> _log(String logString) async {
    int time = DateTime.now().toUtc().millisecondsSinceEpoch;
    Map<String, dynamic> message = {'timestamp': time, 'message': logString};
    _logStack.add(message);
    _debugPrint(2, 'CloudWatch INFO: Added message to log stack: $message');
    await _loggingLock
        .synchronized(_createLogStreamAndLogGroup)
        .catchError((e) {
      return Future.error(CloudWatchException(e.message));
    });
    sleep(new Duration(seconds: delay));
    await _loggingLock.synchronized(_sendLogs).catchError((e) {
      return Future.error(CloudWatchException(e.message));
    });
  }

  Future<void> _sendLogs() async {
    if (_logStack.length <= 0) {
      // logs already sent while this request was waiting for lock
      _debugPrint(2, 'CloudWatch INFO: All logs have already been sent');
      return;
    }
    String body = await _createBody();
    HttpClientResponse result = await _awsRequest.send(
      'POST',
      jsonBody: body,
      target: 'Logs_20140328.PutLogEvents',
    );
    int statusCode = result.statusCode;
    Map<String, dynamic>? reply =
        jsonDecode(await result.transform(utf8.decoder).join());
    if (statusCode == 200) {
      _debugPrint(1,
          'CloudWatch Info: StatusCode: $statusCode, CloudWatchResponse: $reply');
      String? newSequenceToken = reply!['nextSequenceToken'];
      _sequenceToken = newSequenceToken;
    } else {
      _debugPrint(0,
          'CloudWatch ERROR: StatusCode: $statusCode, CloudWatchResponse: $reply');
      throw new CloudWatchException(
          'CloudWatch ERROR: StatusCode: $statusCode, CloudWatchResponse: $reply');
    }
  }
}
