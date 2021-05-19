library aws_cloudwatch;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aws_request/aws_request.dart';

import 'SimpleLock.dart';

class CloudWatchException implements Exception {
  String cause;
  CloudWatchException(this.cause);
}

/// An AWS CloudWatch class for sending logs more easily to AWS
class CloudWatch {
  // AWS Variables
  late String _awsAccessKey;
  late String _awsSecretKey;
  late String _region;
  late int _delay;
  late int _verbosity;

  AwsRequest? _awsRequest;

  // Logging Variables
  /// The log group name for the log stream to go in
  String? logGroupName;

  /// The log stream name for log events to be filed in
  String? logStreamName;

  String? _sequenceToken;
  List<Map<String, dynamic>> _logStack = [];
  SimpleLock _loggingLock = SimpleLock(name: 'CloudWatch Logging Lock');
  bool _logStreamCreated = false;

  /// CloudWatch Constructor
  /// awsAccessKey: Public AWS access key
  /// awsSecretKey: Private AWS access key
  /// region: AWS region
  /// xAmzTarget: Deprecated and no longer used
  CloudWatch(String awsAccessKey, String awsSecretKey, String region,
      [String? xAmzTarget]) {
    _awsAccessKey = awsAccessKey;
    _awsSecretKey = awsSecretKey;
    _region = region;
    _delay = 0;
    _verbosity = 0;
    if (xAmzTarget != null) {
      print(
          'WARNING:CloudWatch - Deprecated: xAmzTarget (formerly serviceInstance) '
          'is no longer required and will be removed in a future release.');
    }
  }

  /// CloudWatch Constructor
  /// awsAccessKey: Public AWS access key
  /// awsSecretKey: Private AWS access key
  /// region: AWS region
  /// delay: Milliseconds to wait for more logs to accumulate to avoid rate limiting.
  CloudWatch.withDelay(
      String awsAccessKey, String awsSecretKey, String region, int delay) {
    _awsAccessKey = awsAccessKey;
    _awsSecretKey = awsSecretKey;
    _region = region;
    _delay = max(0, delay);
    _verbosity = 0;
  }

  /// Delays sending logs
  /// Delays sending logs to allow more logs to accumulate to avoid rate limiting
  /// delay: The amount of milliseconds to wait.
  int setDelay(int delay) {
    _delay = max(0, delay);
    if (_verbosity > 2) {
      print('CloudWatch INFO: Set delay to $_delay');
    }
    return _delay;
  }

  /// Sets console verbosity level. Default is 0.
  /// 0 - No console logging.
  /// 1 - Error console logging.
  /// 2 - API response logging.
  /// 3 - Verbose logging
  /// level: The verbosity level. Valid values are 0 through 3
  void setVerbosity(int level) {
    level = level > 3 ? 3 : level;
    level = level < 0 ? 0 : level;
    _verbosity = level;
    if (_verbosity > 2) {
      print('CloudWatch INFO: Set verbosity to $_verbosity');
    }
  }

  /// Performs a PutLogEvent to CloudWatch
  /// logString: the string you want to log in CloudWatch
  ///
  /// Throws CloudWatchException if logGroupName or logStreamName are not
  /// initialized or if aws returns an error.
  Future<void> log(String logString) async {
    if (_verbosity > 2) {
      print('CloudWatch INFO: Attempting to log $logString');
    }
    if (logGroupName == null || logStreamName == null) {
      if (_verbosity > 0) {
        print('CloudWatch ERROR: Please supply a Log Group and Stream names by '
            'calling setLoggingParameters(String logGroup, String logStreamName)');
      }
      throw new CloudWatchException(
          'CloudWatch ERROR: Please supply a Log Group and Stream names by '
          'calling setLoggingParameters(String logGroup, String logStreamName)');
    }
    await _log(logString);
  }

  // gets AwsRequest instance and instantiates if needed
  AwsRequest? _getAwsRequest() {
    if (_awsRequest == null) {
      if (_verbosity > 2) {
        print('CloudWatch INFO: Generating AwsRequest');
      }
      _awsRequest = new AwsRequest(_awsAccessKey, _awsSecretKey, _region);
      _awsRequest!.service = 'logs';
    }
    if (_verbosity > 2) {
      print('CloudWatch INFO: Got AwsRequest');
    }
    return _awsRequest;
  }

  Future<void> _createLogStream() async {
    if (!_logStreamCreated) {
      if (_verbosity > 2) {
        print('CloudWatch INFO: Generating LogStream');
      }
      _logStreamCreated = true;
      AwsRequest request = _getAwsRequest()!;
      String body =
          '{"logGroupName": "$logGroupName","logStreamName": "$logStreamName"}';
      HttpClientResponse log = await request.send(
        'POST',
        jsonBody: body,
        target: 'Logs_20140328.CreateLogStream',
      );
      int statusCode = log.statusCode;

      if (_verbosity > 1) {
        print('CloudWatch Info: LogStream creation status code: $statusCode');
      }
      if (statusCode != 200) {
        Map<String, dynamic>? reply =
            jsonDecode(await log.transform(utf8.decoder).join());
        if (_verbosity > 0) {
          print(
              'CloudWatch ERROR: StatusCode: $statusCode, CloudWatchResponse: $reply');
        }
        throw new CloudWatchException('CloudWatch ERROR: $reply');
      }
    }
    if (_verbosity > 2) {
      print('CloudWatch INFO: Got LogStream');
    }
  }

  // turns a string into a cloudwatch event
  Future<String> _createBody() async {
    if (_verbosity > 2) {
      print('CloudWatch INFO: Generating CloudWatch request body');
    }
    Map<String, dynamic> body = {
      'logEvents': _logStack,
      'logGroupName': logGroupName,
      'logStreamName': logStreamName,
    };
    if (_sequenceToken != null) {
      body['sequenceToken'] = _sequenceToken;
      if (_verbosity > 2) {
        print('CloudWatch INFO: Adding sequence token');
      }
    }
    int logLength = _logStack.length;
    String jsonBody = json.encode(body);
    _logStack = [];
    if (_verbosity > 2) {
      print(
          'CloudWatch INFO: Generated jsonBody with $logLength logs: $jsonBody');
    }
    return jsonBody;
  }

  Future<void> _log(String logString) async {
    int time = DateTime.now().toUtc().millisecondsSinceEpoch;
    Map<String, dynamic> message = {'timestamp': time, 'message': logString};
    _logStack.add(message);
    if (_verbosity > 2) {
      print('CloudWatch INFO: Added message to log stack: $message');
    }
    _loggingLock
        .protect(() => _createLogStream())
        .catchError((e) => {throw new CloudWatchException(e)});
    sleep(new Duration(seconds: _delay));
    _loggingLock
        .protect(() => _sendLogs())
        .catchError((e) => {throw new CloudWatchException(e)});
  }

  Future<void> _sendLogs() async {
    if (_logStack.length <= 0) {
      // logs already sent while this request was waiting for lock
      if (_verbosity > 2) {
        print('CloudWatch INFO: All logs have already been sent');
      }
      return;
    }
    AwsRequest request = _getAwsRequest()!;
    String body = await _createBody();
    HttpClientResponse result = await request.send(
      'POST',
      jsonBody: body,
      target: 'Logs_20140328.PutLogEvents',
    );
    int statusCode = result.statusCode;
    Map<String, dynamic>? reply =
        jsonDecode(await result.transform(utf8.decoder).join());

    if (_verbosity > 1) {
      print(
          'CloudWatch Info: StatusCode: $statusCode, CloudWatchResponse: $reply');
    }
    if (statusCode == 200) {
      String? newSequenceToken = reply!['nextSequenceToken'];
      _sequenceToken = newSequenceToken;
    } else {
      if (_verbosity > 0) {
        print(
            'CloudWatch ERROR: StatusCode: $statusCode, CloudWatchResponse: $reply');
      }
      throw new CloudWatchException(
          'CloudWatch ERROR: StatusCode: $statusCode, CloudWatchResponse: $reply');
    }
  }
}
