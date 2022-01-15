import 'dart:math';

import 'package:aws_cloudwatch/src/cloudwatch.dart';
import 'package:aws_cloudwatch/src/util.dart';
import 'package:http/http.dart';

/// A CloudWatch handler class to easily manage multiple CloudWatch instances
class AwsCloudWatchHandler {
  Map<String, AwsCloudWatch> logInstances = {};

  /// Private version of access key
  String _awsAccessKey;

  /// Your AWS access key
  void set awsAccessKey(String awsAccessKey) {
    // Updates all instances with new key. Useful for temp credentials
    for (AwsCloudWatch cw in logInstances.values) {
      cw.awsAccessKey = awsAccessKey;
    }
    _awsAccessKey = awsAccessKey;
  }

  /// Your AWS access key
  String get awsAccessKey => _awsAccessKey;

  /// Private version of secret key
  String _awsSecretKey;

  /// Your AWS secret key
  void set awsSecretKey(String awsSecretKey) {
    // Updates all instances with new key. Useful for temp credentials
    for (AwsCloudWatch cw in logInstances.values) {
      cw.awsSecretKey = awsSecretKey;
    }
    _awsSecretKey = awsSecretKey;
  }

  /// Your AWS secret key
  String get awsSecretKey => _awsSecretKey;

  /// Private version of session token
  String? _awsSessionToken;

  /// Your AWS session token
  void set awsSessionToken(String? awsSessionToken) {
    // Updates all instances with new key. Useful for temp credentials
    for (AwsCloudWatch cw in logInstances.values) {
      cw.awsSessionToken = awsSessionToken;
    }
    _awsSessionToken = awsSessionToken;
  }

  /// Your AWS session token
  String? get awsSessionToken => _awsSessionToken;

  /// Your AWS region. Instances are not updated when this value is changed
  String region;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  Duration get delay => _delay;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  void set delay(Duration val) {
    for (AwsCloudWatch cw in logInstances.values) {
      cw.delay = val;
    }
    _delay = val;
  }

  /// private version of [delay]
  Duration _delay;

  /// How long to wait for request before triggering a timeout
  Duration get requestTimeout => _requestTimeout;

  /// How long to wait for request before triggering a timeout
  void set requestTimeout(Duration val) {
    for (AwsCloudWatch cw in logInstances.values) {
      cw.requestTimeout = val;
    }
    _requestTimeout = val;
  }

  /// private version of [requestTimeout]
  Duration _requestTimeout;

  /// How many times an api request should be retired upon failure. Default is 3
  int get retries => _retries;

  /// How many times an api request should be retired upon failure. Default is 3
  void set retries(int val) {
    for (AwsCloudWatch cw in logInstances.values) {
      cw.retries = val;
    }
    _retries = val;
  }

  /// private version of [largeMessageBehavior]
  int _retries;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  CloudWatchLargeMessages get largeMessageBehavior => _largeMessageBehavior;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  void set largeMessageBehavior(CloudWatchLargeMessages val) {
    for (AwsCloudWatch cw in logInstances.values) {
      cw.largeMessageBehavior = val;
    }
    _largeMessageBehavior = val;
  }

  /// private version of [largeMessageBehavior]
  CloudWatchLargeMessages _largeMessageBehavior;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  bool get raiseFailedLookups => _raiseFailedLookups;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  void set raiseFailedLookups(bool val) {
    for (AwsCloudWatch cw in logInstances.values) {
      cw.raiseFailedLookups = val;
    }
    _raiseFailedLookups = val;
  }

  /// private version of [raiseFailedLookups]
  bool _raiseFailedLookups;

  /// Testing Variables

  /// Function used to mock requests
  Future<Response> Function(Request)? mockFunction;

  /// Whether we are mocking requests
  bool mockCloudWatch;

  /// CloudWatchHandler Constructor
  AwsCloudWatchHandler({
    required awsAccessKey,
    required awsSecretKey,
    required this.region,
    required awsSessionToken,
    required delay,
    required requestTimeout,
    required retries,
    required largeMessageBehavior,
    required raiseFailedLookups,
    this.mockCloudWatch: false,
    this.mockFunction,
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
  AwsCloudWatch? getInstance({
    required String logGroupName,
    required String logStreamName,
  }) {
    String instanceName = '$logGroupName.$logStreamName';
    return logInstances[instanceName];
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
    AwsCloudWatch instance = getInstance(
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        ) ??
        createInstance(
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        );
    await instance.log(messages);
  }

  /// Creates a CloudWatch instance.
  ///
  /// Calling any log function will call this as needed automatically
  AwsCloudWatch createInstance({
    required String logGroupName,
    required String logStreamName,
  }) {
    validateLogGroupName(logGroupName);
    validateLogStreamName(logStreamName);
    String instanceName = '$logGroupName.$logStreamName';
    AwsCloudWatch instance = AwsCloudWatch(
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      region: region,
      groupName: logGroupName,
      streamName: logStreamName,
      awsSessionToken: awsSessionToken,
      delay: delay,
      requestTimeout: requestTimeout,
      retries: retries,
      largeMessageBehavior: largeMessageBehavior,
      raiseFailedLookups: raiseFailedLookups,
      mockCloudWatch: mockCloudWatch,
      mockFunction: mockFunction,
    );
    logInstances[instanceName] = instance;
    return instance;
  }
}
