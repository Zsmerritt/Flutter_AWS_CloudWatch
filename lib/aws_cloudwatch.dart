// Copyright (c) 2021, Zachary Merritt.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

library CloudWatch;

import 'src/cloudwatch.dart' show AwsCloudWatch;
import 'src/cloudwatch_handler.dart' show AwsCloudWatchHandler;
import 'src/util.dart' show CloudWatchLargeMessages, CloudWatchException;

export 'src/util.dart' show CloudWatchLargeMessages, CloudWatchException;

class CloudWatch {
  // AWS Variables

  /// Public AWS access key
  String get awsAccessKey => _cloudWatch.awsAccessKey;

  void set awsAccessKey(String key) => _cloudWatch.awsAccessKey = key;

  /// Private AWS access key
  String get awsSecretKey => _cloudWatch.awsSecretKey;

  void set awsSecretKey(String key) => _cloudWatch.awsSecretKey = key;

  /// AWS region
  String get region => _cloudWatch.region;

  void set region(String r) => _cloudWatch.region = r;

  /// AWS session token (temporary credentials)
  String? get awsSessionToken => _cloudWatch.awsSessionToken;

  void set awsSessionToken(String? token) => _cloudWatch.awsSessionToken;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  Duration get delay => _cloudWatch.delay;

  void set delay(Duration d) => _cloudWatch.delay = d;

  /// How long to wait for request before triggering a timeout
  Duration get requestTimeout => _cloudWatch.requestTimeout;

  void set requestTimeout(Duration d) => _cloudWatch.requestTimeout = d;

  /// How many times an api request should be retired upon failure. Default is 3
  int get retries => _cloudWatch.retries;

  void set retries(int r) => _cloudWatch.retries = r;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  CloudWatchLargeMessages get largeMessageBehavior =>
      _cloudWatch.largeMessageBehavior;

  void set largeMessageBehavior(CloudWatchLargeMessages val) =>
      _cloudWatch.largeMessageBehavior = val;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  bool get raiseFailedLookups => _cloudWatch.raiseFailedLookups;

  void set raiseFailedLookups(bool rfl) => _cloudWatch.raiseFailedLookups = rfl;

  // Logging Variables
  /// The log group the log stream will appear under
  String? get groupName => _cloudWatch.groupName;

  void set groupName(String? group) => _cloudWatch.groupName = group;

  /// Synonym for groupName
  String? get logGroupName => groupName;

  void set logGroupName(String? val) => groupName = val;

  /// The log stream name for log events to be filed in
  String? get streamName => _cloudWatch.streamName;

  void set streamName(String? stream) => _cloudWatch.streamName = stream;

  /// Synonym for streamName
  String? get logStreamName => streamName;

  /// Synonym for streamName
  void set logStreamName(String? val) => streamName = val;

  /// Hidden instance of AwsCloudWatch that does behind the scenes work
  AwsCloudWatch _cloudWatch;

  /// CloudWatch Constructor
  CloudWatch(
    String awsAccessKey,
    String awsSecretKey,
    String region, {
    groupName,
    streamName,
    awsSessionToken,
    delay: const Duration(),
    requestTimeout: const Duration(seconds: 10),
    retries: 3,
    largeMessageBehavior: CloudWatchLargeMessages.truncate,
    raiseFailedLookups: false,
  }) : this._cloudWatch = AwsCloudWatch(
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

  AwsCloudWatchHandler _handler;

  /// CloudWatchHandler Constructor
  CloudWatchHandler({
    required awsAccessKey,
    required awsSecretKey,
    required region,
    awsSessionToken: null,
    delay: const Duration(),
    requestTimeout: const Duration(seconds: 10),
    retries: 3,
    largeMessageBehavior: CloudWatchLargeMessages.truncate,
    raiseFailedLookups: false,
  }) : _handler = AwsCloudWatchHandler(
          awsAccessKey: awsAccessKey,
          awsSecretKey: awsSecretKey,
          region: region,
          awsSessionToken: awsSessionToken,
          delay: delay,
          requestTimeout: requestTimeout,
          retries: retries,
          largeMessageBehavior: largeMessageBehavior,
          raiseFailedLookups: raiseFailedLookups,
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
    AwsCloudWatch? cw = _handler.getInstance(
      logGroupName: logGroupName,
      logStreamName: logStreamName,
    );
    if (cw != null) return CloudWatch._(cw);
  }

  /// Logs the provided message to the provided log group and log stream
  ///
  /// Logs a single [msg] to [logStreamName] under the group [logGroupName]
  void log({
    required String msg,
    required String logGroupName,
    required String logStreamName,
  }) {
    _handler.log(
      msg: msg,
      logGroupName: logGroupName,
      logStreamName: logStreamName,
    );
  }

  /// Logs the provided message to the provided log group and log stream
  ///
  /// Logs a list of string [messages] to [logStreamName] under the group [logGroupName]
  ///
  /// Note: using logMany will result in all logs having the same timestamp
  void logMany({
    required List<String> messages,
    required String logGroupName,
    required String logStreamName,
  }) {
    _handler.logMany(
      messages: messages,
      logGroupName: logGroupName,
      logStreamName: logStreamName,
    );
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
}
