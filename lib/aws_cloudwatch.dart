// Copyright (c) 2021, Zachary Merritt.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

library aws_cloudwatch;

import 'package:aws_cloudwatch/src/logger.dart'
    show
        CloudWatchLargeMessages,
        Logger,
        LoggerHandler,
        awsMaxBytesPerMessage,
        awsMaxBytesPerRequest,
        awsMaxMessagesPerRequest;

export 'package:aws_cloudwatch/aws_cloudwatch.dart'
    show CloudWatch, CloudWatchHandler;
export 'package:aws_cloudwatch/src/logger.dart'
    show CloudWatchLargeMessages, CloudWatchException;

part 'aws_cloudwatch_handler.dart';

/// An AWS CloudWatch interface to easily send logs to CloudWatch
class CloudWatch {
  // AWS Variables

  /// Public AWS access key
  String get awsAccessKey => _cloudWatch.awsAccessKey;

  set awsAccessKey(String key) => _cloudWatch.awsAccessKey = key;

  /// Private AWS access key
  String get awsSecretKey => _cloudWatch.awsSecretKey;

  set awsSecretKey(String key) => _cloudWatch.awsSecretKey = key;

  /// AWS region
  String get region => _cloudWatch.region;

  set region(String r) => _cloudWatch.region = r;

  /// AWS session token (temporary credentials)
  String? get awsSessionToken => _cloudWatch.awsSessionToken;

  set awsSessionToken(String? token) => _cloudWatch.awsSessionToken = token;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  Duration get delay => _cloudWatch.delay;

  set delay(Duration d) => _cloudWatch.delay = d;

  /// How long to wait for request before triggering a timeout
  Duration get requestTimeout => _cloudWatch.requestTimeout;

  set requestTimeout(Duration d) => _cloudWatch.requestTimeout = d;

  /// How many times an api request should be retired upon failure. Default is 3
  int get retries => _cloudWatch.retries;

  set retries(int r) => _cloudWatch.retries = r;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  CloudWatchLargeMessages get largeMessageBehavior =>
      _cloudWatch.largeMessageBehavior;

  set largeMessageBehavior(CloudWatchLargeMessages val) =>
      _cloudWatch.largeMessageBehavior = val;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  bool get raiseFailedLookups => _cloudWatch.raiseFailedLookups;

  set raiseFailedLookups(bool rfl) => _cloudWatch.raiseFailedLookups = rfl;

  // Logging Variables
  /// The log group the log stream will appear under
  String get groupName => _cloudWatch.groupName;

  set groupName(String group) => _cloudWatch.groupName = group;

  /// Synonym for groupName
  String get logGroupName => groupName;

  set logGroupName(String val) => groupName = val;

  /// The log stream name for log events to be filed in
  String get streamName => _cloudWatch.streamName;

  set streamName(String stream) => _cloudWatch.streamName = stream;

  /// Synonym for streamName
  String get logStreamName => streamName;

  /// Synonym for streamName
  set logStreamName(String val) => streamName = val;

  /// Changes how large each message can be before [largeMessageBehavior] takes
  /// effect. Min 5, Max 262116
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxBytesPerMessage => _cloudWatch.maxBytesPerMessage;

  set maxBytesPerMessage(int val) => _cloudWatch.maxBytesPerMessage = val;

  /// Changes how many bytes can be sent in each API request before a second
  /// request is made. Min 1, Max 1048576
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxBytesPerRequest => _cloudWatch.maxBytesPerRequest;

  set maxBytesPerRequest(int val) => _cloudWatch.maxBytesPerRequest = val;

  /// Changes the maximum number of messages that can be sent in each API
  /// request. Min 1, Max 10000
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxMessagesPerRequest => _cloudWatch.maxMessagesPerRequest;

  set maxMessagesPerRequest(int val) => _cloudWatch.maxMessagesPerRequest = val;

  /// Hidden instance of AwsCloudWatch that does behind the scenes work
  final Logger _cloudWatch;

  /// CloudWatch Constructor
  CloudWatch({
    required String awsAccessKey,
    required String awsSecretKey,
    required String region,
    required String groupName,
    required String streamName,
    String? awsSessionToken,
    Duration delay = const Duration(),
    Duration requestTimeout = const Duration(seconds: 10),
    int retries = 3,
    CloudWatchLargeMessages largeMessageBehavior =
        CloudWatchLargeMessages.truncate,
    bool raiseFailedLookups = false,
    int maxBytesPerMessage = awsMaxBytesPerMessage,
    int maxBytesPerRequest = awsMaxBytesPerRequest,
    int maxMessagesPerRequest = awsMaxMessagesPerRequest,
  }) : _cloudWatch = Logger(
          awsAccessKey: awsAccessKey,
          awsSecretKey: awsSecretKey,
          region: region,
          groupName: groupName,
          streamName: streamName,
          awsSessionToken: awsSessionToken,
          delay: delay,
          requestTimeout: requestTimeout,
          retries: retries,
          largeMessageBehavior: largeMessageBehavior,
          raiseFailedLookups: raiseFailedLookups,
          maxBytesPerMessage: maxBytesPerMessage,
          maxBytesPerRequest: maxBytesPerRequest,
          maxMessagesPerRequest: maxMessagesPerRequest,
        );

  /// Private constructor used with CloudWatchHandler
  CloudWatch._(this._cloudWatch);

  /// Sends a log to AWS
  ///
  /// Sends the [logString] to AWS to be added to the CloudWatch logs
  ///
  /// Throws a [CloudWatchException] if [groupName] or [streamName] are not
  /// initialized or if aws returns an error.
  Future<void> log(String logString) async {
    await _cloudWatch.log([logString]);
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
    await _cloudWatch.log(logStrings);
  }
}
