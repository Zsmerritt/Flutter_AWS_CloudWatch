import 'package:aws_cloudwatch/aws_cloudwatch.dart';
import 'package:test/test.dart';

void main() {
  group('Constructors', () {
    test('min constructor', () {
      final CloudWatchHandler cw = CloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
      );
      expect(cw.awsAccessKey, 'awsAccessKey');
      expect(cw.awsSecretKey, 'awsSecretKey');
      expect(cw.region, 'region');
      expect(cw.awsSessionToken == null, true);
      expect(cw.delay.inSeconds, 0);
      expect(cw.requestTimeout.inSeconds, 10);
      expect(cw.retries, 3);
      expect(cw.largeMessageBehavior, CloudWatchLargeMessages.truncate);
      expect(cw.raiseFailedLookups, false);
    });
    test('max constructor', () {
      final CloudWatchHandler cw = CloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
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
      expect(cw.awsSessionToken, 'awsSessionToken');
      expect(cw.delay.inSeconds, 100);
      expect(cw.requestTimeout.inSeconds, 100);
      expect(cw.retries, 10);
      expect(cw.largeMessageBehavior, CloudWatchLargeMessages.error);
      expect(cw.raiseFailedLookups, true);
    });
  });
  group('Getters & Setters', () {
    final CloudWatchHandler cw = CloudWatchHandler(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
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
  });
  group('functions', () {
    final CloudWatchHandler cw = CloudWatchHandler(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
      awsSessionToken: 'awsSessionToken',
      delay: const Duration(),
      requestTimeout: const Duration(seconds: 10),
      retries: 10,
      largeMessageBehavior: CloudWatchLargeMessages.error,
      raiseFailedLookups: true,
    );
    test('getInstance - null', () {
      final CloudWatch? cloudwatch = cw.getInstance(
        logGroupName: 'logGroupName',
        logStreamName: 'logStreamName',
      );
      expect(cloudwatch == null, true);
    });
    test('createInstance & getInstance', () {
      final CloudWatch cloudwatch1 = cw.createInstance(
        logGroupName: 'logGroupName',
        logStreamName: 'logStreamName',
      );
      final CloudWatch cloudwatch2 = cw.getInstance(
        logGroupName: 'logGroupName',
        logStreamName: 'logStreamName',
      )!;
      expect(
        cloudwatch1.awsAccessKey,
        cloudwatch2.awsAccessKey,
      );
      expect(
        cloudwatch1.awsSecretKey,
        cloudwatch2.awsSecretKey,
      );
      expect(
        cloudwatch1.region,
        cloudwatch2.region,
      );
      expect(
        cloudwatch1.awsSessionToken,
        cloudwatch2.awsSessionToken,
      );
      expect(
        cloudwatch1.delay.inSeconds,
        cloudwatch2.delay.inSeconds,
      );
      expect(
        cloudwatch1.requestTimeout.inSeconds,
        cloudwatch2.requestTimeout.inSeconds,
      );
      expect(
        cloudwatch1.retries,
        cloudwatch2.retries,
      );
      expect(
        cloudwatch1.largeMessageBehavior,
        cloudwatch2.largeMessageBehavior,
      );
      expect(
        cloudwatch1.raiseFailedLookups,
        cloudwatch2.raiseFailedLookups,
      );
    });
    test('log', () async {
      try {
        await cw.log(
          message: 'test',
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
      } catch (e) {
        expect(e.toString().contains('SocketException'), true);
        return;
      }
      fail('raiseFailedLookups: true didnt catch failed lookup');
    });
    test('logMany', () async {
      try {
        await cw.logMany(
          messages: ['test'],
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
      } catch (e) {
        expect(e.toString().contains('SocketException'), true);
        return;
      }
      fail('raiseFailedLookups: true didnt catch failed lookup');
    });
  });
}
