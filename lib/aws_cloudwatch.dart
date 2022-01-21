// Copyright (c) 2021, Zachary Merritt.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

library aws_cloudwatch;

import 'package:aws_cloudwatch/src/cloudwatch.dart'
    show AwsCloudWatch, CloudWatchLargeMessages, AwsCloudWatchHandler;

export 'package:aws_cloudwatch/aws_cloudwatch.dart'
    show CloudWatch, CloudWatchHandler;
export 'package:aws_cloudwatch/src/cloudwatch.dart'
    show CloudWatchLargeMessages, CloudWatchException;

part 'aws_cloudwatch_handler.dart';

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

  set awsSessionToken(String? token) => _cloudWatch.awsSessionToken;

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
  String? get groupName => _cloudWatch.groupName;

  set groupName(String? group) => _cloudWatch.groupName = group;

  /// Synonym for groupName
  String? get logGroupName => groupName;

  set logGroupName(String? val) => groupName = val;

  /// The log stream name for log events to be filed in
  String? get streamName => _cloudWatch.streamName;

  set streamName(String? stream) => _cloudWatch.streamName = stream;

  /// Synonym for streamName
  String? get logStreamName => streamName;

  /// Synonym for streamName
  set logStreamName(String? val) => streamName = val;

  /// Hidden instance of AwsCloudWatch that does behind the scenes work
  final AwsCloudWatch _cloudWatch;

  /// CloudWatch Constructor
  CloudWatch(
    String awsAccessKey,
    String awsSecretKey,
    String region, {
    groupName,
    streamName,
    awsSessionToken,
    delay = const Duration(),
    requestTimeout = const Duration(seconds: 10),
    retries = 3,
    largeMessageBehavior = CloudWatchLargeMessages.truncate,
    raiseFailedLookups = false,
  }) : _cloudWatch = AwsCloudWatch(
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
        );

  /// Private constructor used with CloudWatchHandler
  CloudWatch._(this._cloudWatch);

  /// Sends a log to AWS
  ///
  /// Sends the [logString] to AWS to be added to the CloudWatch logs
  ///
  /// Throws a [CloudWatchException] if [groupName] or [streamName] are not
  /// initialized or if aws returns an error.
  void log(String logString) {
    _cloudWatch.log([logString]);
  }

  /// Sends a log to AWS
  ///
  /// Sends a list of strings [logStrings] to AWS to be added to the CloudWatch logs
  ///
  /// Note: using logMany will result in all logs having the same timestamp
  ///
  /// Throws a [CloudWatchException] if [groupName] or [streamName] are not
  /// initialized or if aws returns an error.
  void logMany(List<String> logStrings) {
    _cloudWatch.log(logStrings);
  }
}
