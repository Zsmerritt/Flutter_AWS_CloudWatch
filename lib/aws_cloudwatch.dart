library aws_cloudwatch;

import 'dart:convert';
import 'dart:io';

import 'package:aws_request/aws_request.dart';

import 'SimpleLock.dart';

class CloudWatchException implements Exception {
  String cause;
  CloudWatchException(this.cause);
}

class CloudWatch {
  // AWS Variables
  String _awsAccessKey;
  String _awsSecretKey;
  String _region;
  String _serviceInstance;

  AwsRequest _awsRequest;

  // Logging Variables
  /// The log group name for the log stream to go in
  String logGroupName;

  /// The log stream name for log events to be filed in
  String logStreamName;

  String _sequenceToken;
  List<Map<String, dynamic>> _logStack = [];
  SimpleLock _loggingLock = SimpleLock(name: 'CloudWatch Logging Lock');
  bool _logStreamCreated = false;

  CloudWatch(String awsAccessKey, String awsSecretKey, String region,
      String serviceInstance) {
    this._awsAccessKey = awsAccessKey;
    this._awsSecretKey = awsSecretKey;
    this._region = region;
    this._serviceInstance = serviceInstance;
  }

  /// Performs a PutLogEvent to CloudWatch
  /// logString: the string you want to log in CloudWatch
  ///
  /// Throws CloudWatchException if logGroupName or logStreamName are not
  /// initialized or if aws returns an error.
  Future<void> log(String logString) async {
    if (this.logGroupName == null || this.logStreamName == null) {
      throw new CloudWatchException(
          'CloudWatch ERROR: Please supply a Log Group and Stream names by '
          'calling setLoggingParameters(String logGroup, String logStreamName)');
    }
    await _log(logString);
  }

  // gets AwsRequest instance and instantiates if needed
  AwsRequest _getAwsRequest() {
    if (this._awsRequest == null) {
      this._awsRequest =
          new AwsRequest(this._awsAccessKey, this._awsSecretKey, this._region);
      this._awsRequest.service = 'logs';
    }
    return this._awsRequest;
  }

  Future<void> _createLogStream() async {
    if (!this._logStreamCreated) {
      this._logStreamCreated = true;
      AwsRequest request = _getAwsRequest();
      String body =
          '{"logGroupName": "${this.logGroupName}","logStreamName": "${this.logStreamName}"}';
      HttpClientResponse log = await request.send(
        'POST',
        jsonBody: body,
        target: '${this._serviceInstance}.CreateLogStream',
      );

      if (log.statusCode != 200) {
        String reply = await log.transform(utf8.decoder).join();
        throw new CloudWatchException('CloudWatch ERROR: $reply');
      }
    }
  }

  // turns a string into a cloudwatch event
  Future<String> _createBody() async {
    Map<String, dynamic> body = {
      'logEvents': this._logStack,
      'logGroupName': this.logGroupName,
      'logStreamName': this.logStreamName,
    };
    if (this._sequenceToken != null) {
      body['sequenceToken'] = this._sequenceToken;
    }
    String jsonBody = json.encode(body);
    this._logStack = [];
    return jsonBody;
  }

  Future<void> _log(String logString) async {
    await _createLogStream();
    int time = DateTime.now().toUtc().millisecondsSinceEpoch;
    this._logStack.add({'timestamp': time, 'message': logString});
    _loggingLock.protect(() => _sendLogs());
  }

  Future<void> _sendLogs() async {
    if (this._logStack.length < 0) {
      // logs already sent while this request was waiting for lock
      return;
    }
    AwsRequest request = _getAwsRequest();
    String body = await _createBody();
    HttpClientResponse result = await request.send(
      'POST',
      jsonBody: body,
      target: '${this._serviceInstance}.PutLogEvents',
    );
    int statusCode = result.statusCode;
    if (statusCode == 200) {
      String reply = await result.transform(utf8.decoder).join();
      String newSequenceToken = json.decode(reply)['nextSequenceToken'];
      this._sequenceToken = newSequenceToken;
    }
  }
}
