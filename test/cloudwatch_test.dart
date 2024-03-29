import 'package:aws_cloudwatch/aws_cloudwatch.dart';
import 'package:aws_cloudwatch/src/logger.dart';
import 'package:test/test.dart';

void main() {
  group('Constructors', () {
    test('min constructor', () {
      final CloudWatch cw = CloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
      );
      expect(cw.awsAccessKey, 'awsAccessKey');
      expect(cw.awsSecretKey, 'awsSecretKey');
      expect(cw.region, 'region');
      expect(cw.groupName, 'groupName');
      expect(cw.streamName, 'streamName');
      expect(cw.awsSessionToken == null, true);
      expect(cw.delay.inSeconds, 0);
      expect(cw.requestTimeout.inSeconds, 10);
      expect(cw.retries, 3);
      expect(cw.largeMessageBehavior, CloudWatchLargeMessages.split);
      expect(cw.raiseFailedLookups, false);
    });
    test('max constructor', () {
      final CloudWatch cw = CloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(seconds: 100),
        requestTimeout: const Duration(seconds: 100),
        retries: 10,
        largeMessageBehavior: CloudWatchLargeMessages.error,
        raiseFailedLookups: true,
      );
      expect(cw.awsAccessKey, 'awsAccessKey');
      expect(cw.awsSecretKey, 'awsSecretKey');
      expect(cw.region, 'region');
      expect(cw.groupName, 'groupName');
      expect(cw.streamName, 'streamName');
      expect(cw.awsSessionToken, 'awsSessionToken');
      expect(cw.delay.inSeconds, 100);
      expect(cw.requestTimeout.inSeconds, 100);
      expect(cw.retries, 10);
      expect(cw.largeMessageBehavior, CloudWatchLargeMessages.error);
      expect(cw.raiseFailedLookups, true);
    });
  });
  group('Getters & Setters', () {
    final CloudWatch cw = CloudWatch(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
      groupName: 'groupName',
      streamName: 'streamName',
      awsSessionToken: 'awsSessionToken',
      delay: const Duration(seconds: 100),
      requestTimeout: const Duration(seconds: 100),
      retries: 10,
      largeMessageBehavior: CloudWatchLargeMessages.error,
      raiseFailedLookups: true,
    );
    test('awsAccessKey', () {
      expect(cw.awsAccessKey, 'awsAccessKey');
      cw.awsAccessKey = 'accessKey';
      expect(cw.awsAccessKey, 'accessKey');
    });
    test('awsSecretKey', () {
      expect(cw.awsSecretKey, 'awsSecretKey');
      cw.awsSecretKey = 'secretKey';
      expect(cw.awsSecretKey, 'secretKey');
    });
    test('region', () {
      expect(cw.region, 'region');
      cw.region = 'r';
      expect(cw.region, 'r');
    });
    test('logGroupName', () {
      expect(cw.logGroupName, 'groupName');
      cw.logGroupName = 'group';
      expect(cw.logGroupName, 'group');
    });
    test('groupName', () {
      expect(cw.groupName, 'group');
      cw.groupName = 'groupName';
      expect(cw.groupName, 'groupName');
    });
    test('logStreamName', () {
      expect(cw.logStreamName, 'streamName');
      cw.logStreamName = 'stream';
      expect(cw.logStreamName, 'stream');
    });
    test('streamName', () {
      expect(cw.streamName, 'stream');
      cw.streamName = 'streamName';
      expect(cw.streamName, 'streamName');
    });
    test('awsSessionToken', () {
      expect(cw.awsSessionToken, 'awsSessionToken');
      cw.awsSessionToken = 'sessionToken';
      expect(cw.awsSessionToken, 'sessionToken');
    });
    test('delay', () {
      expect(cw.delay.inSeconds, 100);
      cw.delay = const Duration();
      expect(cw.delay.inSeconds, 0);
    });
    test('requestTimeout', () {
      expect(cw.requestTimeout.inSeconds, 100);
      cw.requestTimeout = const Duration();
      expect(cw.requestTimeout.inSeconds, 0);
    });
    test('useDynamicTimeout', () {
      expect(cw.useDynamicTimeout, true);
      cw.useDynamicTimeout = false;
      expect(cw.useDynamicTimeout, false);
    });
    test('timeoutMultiplier', () {
      expect(cw.timeoutMultiplier, 1.2);
      cw.timeoutMultiplier = 2;
      expect(cw.timeoutMultiplier, 2);
    });
    test('dynamicTimeoutMax', () {
      expect(cw.dynamicTimeoutMax.inMinutes, 2);
      cw.dynamicTimeoutMax = const Duration();
      expect(cw.dynamicTimeoutMax.inSeconds, 0);
    });
    test('retries', () {
      expect(cw.retries, 10);
      cw.retries = 0;
      expect(cw.retries, 0);
    });
    test('largeMessageBehavior', () {
      expect(cw.largeMessageBehavior, CloudWatchLargeMessages.error);
      cw.largeMessageBehavior = CloudWatchLargeMessages.split;
      expect(cw.largeMessageBehavior, CloudWatchLargeMessages.split);
    });
    test('raiseFailedLookups', () {
      expect(cw.raiseFailedLookups, true);
      cw.raiseFailedLookups = false;
      expect(cw.raiseFailedLookups, false);
    });
    test('maxBytesPerMessage', () {
      expect(cw.maxBytesPerMessage, awsMaxBytesPerMessage);
      cw.maxBytesPerMessage = 100;
      expect(cw.maxBytesPerMessage, 100);
    });
    test('maxBytesPerRequest', () {
      expect(cw.maxBytesPerRequest, awsMaxBytesPerRequest);
      cw.maxBytesPerRequest = 100;
      expect(cw.maxBytesPerRequest, 100);
    });
    test('maxMessagesPerRequest', () {
      expect(cw.maxMessagesPerRequest, awsMaxMessagesPerRequest);
      cw.maxMessagesPerRequest = 100;
      expect(cw.maxMessagesPerRequest, 100);
    });
  });
  group('functions', () {
    final CloudWatch cw = CloudWatch(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
      groupName: 'groupName',
      streamName: 'streamName',
      awsSessionToken: 'awsSessionToken',
      delay: const Duration(),
      requestTimeout: const Duration(seconds: 10),
      retries: 10,
      largeMessageBehavior: CloudWatchLargeMessages.error,
      raiseFailedLookups: true,
    );
    test('log', () async {
      try {
        await cw.log('test');
      } catch (e) {
        expect(e.toString().contains('Failed host lookup'), true);
        return;
      }
      fail('raiseFailedLookups: true didnt catch failed lookup');
    });
    test('logMany', () async {
      try {
        await cw.logMany(['test']);
      } catch (e) {
        expect(e.toString().contains('Failed host lookup'), true);
        return;
      }
      fail('raiseFailedLookups: true didnt catch failed lookup');
    });
  });
}
