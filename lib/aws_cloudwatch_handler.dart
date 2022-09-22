// Copyright (c) 2021, Zachary Merritt.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

part of 'aws_cloudwatch.dart';

/// A CloudWatch handler class to easily manage multiple CloudWatch instances
class CloudWatchHandler {
  /// Your AWS access key
  String get awsAccessKey => _handler.awsAccessKey;

  set awsAccessKey(String key) => _handler.awsAccessKey = key;

  /// Your AWS secret key
  String get awsSecretKey => _handler.awsSecretKey;

  set awsSecretKey(String key) => _handler.awsSecretKey = key;

  /// Your AWS session token
  String? get awsSessionToken => _handler.awsSessionToken;

  set awsSessionToken(String? token) => _handler.awsSessionToken = token;

  /// Your AWS region. Instances are not updated when this value is changed
  String get region => _handler.region;

  set region(String region) => _handler.region = region;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  Duration get delay => _handler.delay;

  set delay(Duration val) => _handler.delay = val;

  /// How long to wait for request before triggering a timeout
  Duration get requestTimeout => _handler.requestTimeout;

  set requestTimeout(Duration val) => _handler.requestTimeout = val;

  /// How many times an api request should be retired upon failure. Default is 3
  int get retries => _handler.retries;

  set retries(int val) => _handler.retries = val;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  CloudWatchLargeMessages get largeMessageBehavior =>
      _handler.largeMessageBehavior;

  set largeMessageBehavior(CloudWatchLargeMessages val) =>
      _handler.largeMessageBehavior = val;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  bool get raiseFailedLookups => _handler.raiseFailedLookups;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  set raiseFailedLookups(bool val) => _handler.raiseFailedLookups = val;

  /// Whether to dynamically adjust the timeout or not
  bool get useDynamicTimeout => _handler.useDynamicTimeout;

  set useDynamicTimeout(bool val) => _handler.useDynamicTimeout = val;

  /// How much to increase the timeout after a timeout occurs
  double get timeoutMultiplier => _handler.timeoutMultiplier;

  set timeoutMultiplier(double val) => _handler.timeoutMultiplier = val;

  /// The maximum length dynamic timeouts can be
  Duration get dynamicTimeoutMax => _handler.dynamicTimeoutMax;

  set dynamicTimeoutMax(Duration val) => _handler.dynamicTimeoutMax = val;

  /// Changes how large each message can be before [largeMessageBehavior] takes
  /// effect. Min 5, Max 262116
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxBytesPerMessage => _handler.maxBytesPerMessage;

  set maxBytesPerMessage(int val) => _handler.maxBytesPerMessage = val;

  /// Changes how many bytes can be sent in each API request before a second
  /// request is made. Min 1, Max 1048576
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxBytesPerRequest => _handler.maxBytesPerRequest;

  set maxBytesPerRequest(int val) => _handler.maxBytesPerRequest = val;

  /// Changes the maximum number of messages that can be sent in each API
  /// request. Min 1, Max 10000
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxMessagesPerRequest => _handler.maxMessagesPerRequest;

  set maxMessagesPerRequest(int val) => _handler.maxMessagesPerRequest = val;

  final LoggerHandler _handler;

  /// CloudWatchHandler Constructor
  CloudWatchHandler({
    required awsAccessKey,
    required awsSecretKey,
    required region,
    String? awsSessionToken,
    Duration delay = const Duration(milliseconds: 200),
    Duration requestTimeout = const Duration(seconds: 10),
    bool useDynamicTimeout = true,
    double timeoutMultiplier = 1.2,
    Duration dynamicTimeoutMax = const Duration(minutes: 2),
    retries = 3,
    CloudWatchLargeMessages largeMessageBehavior =
        CloudWatchLargeMessages.truncate,
    bool raiseFailedLookups = false,
    int maxBytesPerMessage = awsMaxBytesPerMessage,
    int maxBytesPerRequest = awsMaxBytesPerRequest,
    int maxMessagesPerRequest = awsMaxMessagesPerRequest,
  }) : _handler = LoggerHandler(
          awsAccessKey: awsAccessKey,
          awsSecretKey: awsSecretKey,
          region: region,
          awsSessionToken: awsSessionToken,
          delay: delay,
          requestTimeout: requestTimeout,
          useDynamicTimeout: useDynamicTimeout,
          timeoutMultiplier: timeoutMultiplier,
          dynamicTimeoutMax: dynamicTimeoutMax,
          retries: retries,
          largeMessageBehavior: largeMessageBehavior,
          raiseFailedLookups: raiseFailedLookups,
          maxBytesPerMessage: maxBytesPerMessage,
          maxBytesPerRequest: maxBytesPerRequest,
          maxMessagesPerRequest: maxMessagesPerRequest,
        );

  /// Returns a specific instance of a CloudWatch class (or null if it doesn't
  /// exist) based on group name and stream name
  ///
  /// Uses the [logGroupName] and the [logStreamName] to find the correct
  /// CloudWatch instance. Returns null if it doesn't exist
  CloudWatch? getInstance({
    required String logGroupName,
    required String logStreamName,
  }) {
    final Logger? cw = _handler.getInstance(
      logGroupName: logGroupName,
      logStreamName: logStreamName,
    );
    if (cw != null) {
      return CloudWatch._(cw);
    }
    return null;
  }

  /// Creates a CloudWatch instance.
  ///
  /// Calling any log function will call this as needed automatically
  CloudWatch createInstance({
    required String logGroupName,
    required String logStreamName,
  }) {
    return CloudWatch._(
      _handler.createInstance(
        logGroupName: logGroupName,
        logStreamName: logStreamName,
      ),
    );
  }

  /// Logs the provided message to the provided log group and log stream
  ///
  /// Logs a single [message] to [logStreamName] under the group [logGroupName]
  Future<void> log({
    required String message,
    required String logGroupName,
    required String logStreamName,
  }) async {
    await _handler.log(
      message: message,
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
    await _handler.logMany(
      messages: messages,
      logGroupName: logGroupName,
      logStreamName: logStreamName,
    );
  }
}
