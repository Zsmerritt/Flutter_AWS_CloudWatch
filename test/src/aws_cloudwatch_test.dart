import 'package:aws_cloudwatch/cloudwatch.dart';
import 'package:aws_cloudwatch/src/aws_cloudwatch.dart';
import 'package:test/test.dart';

void main() {
  group('Constructors', () {
    test('minimum', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      expect(cloudWatch.groupName, 'groupName');
      expect(cloudWatch.streamName, 'streamName');
      expect(cloudWatch.awsSessionToken, 'awsSessionToken');
      expect(cloudWatch.delay.inSeconds, 0);
      expect(cloudWatch.requestTimeout.inSeconds, 10);
      expect(cloudWatch.retries, 3);
      expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.truncate);
      expect(cloudWatch.raiseFailedLookups, false);
      expect(cloudWatch.logStack.largeMessageBehavior,
          CloudWatchLargeMessages.truncate);
    });
    test('maximum', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(seconds: 100),
        requestTimeout: Duration(seconds: 100),
        retries: 10,
        largeMessageBehavior: CloudWatchLargeMessages.split,
        raiseFailedLookups: true,
      );
      expect(cloudWatch.groupName, 'groupName');
      expect(cloudWatch.streamName, 'streamName');
      expect(cloudWatch.awsSessionToken, 'awsSessionToken');
      expect(cloudWatch.delay.inSeconds, 100);
      expect(cloudWatch.requestTimeout.inSeconds, 100);
      expect(cloudWatch.retries, 10);
      expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.split);
      expect(cloudWatch.raiseFailedLookups, true);
      expect(cloudWatch.logStack.largeMessageBehavior,
          CloudWatchLargeMessages.split);
    });
    test('negative delay', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(seconds: -10),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      expect(cloudWatch.delay.inSeconds, 0);
    });
    test('negative retries', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: -10,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      expect(cloudWatch.retries, 0);
    });
  });

  group('Getters / Setters', () {
    test('negative delay', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.delay = Duration(seconds: -1);
      expect(cloudWatch.delay.inSeconds, 0);
    });
    test('positive delay', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.delay = Duration(seconds: 15);
      expect(cloudWatch.delay.inSeconds, 15);
    });
    test('negative requestTimeout', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.requestTimeout = Duration(seconds: -1);
      expect(cloudWatch.requestTimeout.inSeconds, 0);
    });
    test('positive requestTimeout', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.requestTimeout = Duration(seconds: 15);
      expect(cloudWatch.requestTimeout.inSeconds, 15);
    });
    test('negative retries', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.retries = -1;
      expect(cloudWatch.retries, 0);
    });
    test('positive requestTimeout', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.retries = 15;
      expect(cloudWatch.retries, 15);
    });
    test('largeMessageBehavior', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.largeMessageBehavior = CloudWatchLargeMessages.split;
      expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.split);
      expect(cloudWatch.logStack.largeMessageBehavior,
          CloudWatchLargeMessages.split);
    });
    test('logGroupName', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.logGroupName = 'logGroupName';
      expect(cloudWatch.groupName, 'logGroupName');
    });
    test('logStreamName', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.logStreamName = 'logStreamName';
      expect(cloudWatch.streamName, 'logStreamName');
    });
  });

  group('Functions', () {});
}
