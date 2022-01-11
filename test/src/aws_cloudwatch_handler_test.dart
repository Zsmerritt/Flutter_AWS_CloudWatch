import 'package:aws_cloudwatch/cloudwatch.dart';
import 'package:aws_cloudwatch/src/aws_cloudwatch_handler.dart';
import 'package:test/test.dart';

void main() {
  test('CloudWatchHandler - creation', () {
    final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
      awsSessionToken: 'awsSessionToken',
      delay: Duration(),
      requestTimeout: Duration(seconds: 10),
      retries: 3,
      largeMessageBehavior: CloudWatchLargeMessages.truncate,
      raiseFailedLookups: false,
    );
    try {
      cloudWatchHandler.createInstance(
        logGroupName: '',
        logStreamName: '',
      );
    } catch (e) {
      expect(e, isA<CloudWatchException>());
    }
    try {
      cloudWatchHandler.createInstance(
        logGroupName: 'logGroupName',
        logStreamName: '',
      );
    } catch (e) {
      expect(e, isA<CloudWatchException>());
    }
    try {
      cloudWatchHandler.createInstance(
        logGroupName: '',
        logStreamName: 'logStreamName',
      );
    } catch (e) {
      expect(e, isA<CloudWatchException>());
    }
    CloudWatch? nullCloudWatch = cloudWatchHandler.getInstance(
      logGroupName: 'logGroupName',
      logStreamName: 'logStreamName',
    );
    expect(nullCloudWatch == null, true);
    cloudWatchHandler.createInstance(
      logGroupName: 'logGroupName',
      logStreamName: 'logStreamName',
    );
    CloudWatch? cloudWatch = cloudWatchHandler.getInstance(
      logGroupName: 'logGroupName',
      logStreamName: 'logStreamName',
    );
    expect(cloudWatch == null, false);
  });

  test('CloudWatchHandler - delay', () {
    final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
      awsSessionToken: 'awsSessionToken',
      delay: Duration(),
      requestTimeout: Duration(seconds: 10),
      retries: 3,
      largeMessageBehavior: CloudWatchLargeMessages.truncate,
      raiseFailedLookups: false,
    );
    CloudWatch cloudWatch = cloudWatchHandler.createInstance(
      logGroupName: 'logGroupName',
      logStreamName: 'logStreamName',
    );
    expect(cloudWatchHandler.delay, Duration());
    expect(cloudWatch.delay, Duration());
    cloudWatchHandler.delay = Duration(days: 1);
    expect(cloudWatchHandler.delay, Duration(days: 1));
    expect(cloudWatch.delay, Duration(days: 1));
  });

  test('CloudWatchHandler - requestTimeout', () {
    final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
      awsSessionToken: 'awsSessionToken',
      delay: Duration(),
      requestTimeout: Duration(seconds: 10),
      retries: 3,
      largeMessageBehavior: CloudWatchLargeMessages.truncate,
      raiseFailedLookups: false,
    );
    CloudWatch cloudWatch = cloudWatchHandler.createInstance(
      logGroupName: 'logGroupName',
      logStreamName: 'logStreamName',
    );
    expect(cloudWatchHandler.requestTimeout, Duration(seconds: 10));
    expect(cloudWatch.requestTimeout, Duration(seconds: 10));
    cloudWatchHandler.requestTimeout = Duration(days: 1);
    expect(cloudWatchHandler.requestTimeout, Duration(days: 1));
    expect(cloudWatch.requestTimeout, Duration(days: 1));
  });

  test('CloudWatchHandler - retries', () {
    final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
      awsSessionToken: 'awsSessionToken',
      delay: Duration(),
      requestTimeout: Duration(seconds: 10),
      retries: 3,
      largeMessageBehavior: CloudWatchLargeMessages.truncate,
      raiseFailedLookups: false,
    );
    CloudWatch cloudWatch = cloudWatchHandler.createInstance(
      logGroupName: 'logGroupName',
      logStreamName: 'logStreamName',
    );
    expect(cloudWatchHandler.retries, 3);
    expect(cloudWatch.retries, 3);
    cloudWatchHandler.retries = 1;
    expect(cloudWatchHandler.retries, 1);
    expect(cloudWatch.retries, 1);
  });

  test('CloudWatchHandler - largeMessageBehavior', () {
    final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
      awsSessionToken: 'awsSessionToken',
      delay: Duration(),
      requestTimeout: Duration(seconds: 10),
      retries: 3,
      largeMessageBehavior: CloudWatchLargeMessages.truncate,
      raiseFailedLookups: false,
    );
    CloudWatch cloudWatch = cloudWatchHandler.createInstance(
      logGroupName: 'logGroupName',
      logStreamName: 'logStreamName',
    );
    expect(cloudWatchHandler.largeMessageBehavior,
        CloudWatchLargeMessages.truncate);
    expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.truncate);
    cloudWatchHandler.largeMessageBehavior = CloudWatchLargeMessages.split;
    expect(
        cloudWatchHandler.largeMessageBehavior, CloudWatchLargeMessages.split);
    expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.split);
  });

  test('CloudWatchHandler - raiseFailedLookups', () {
    final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
      awsSessionToken: 'awsSessionToken',
      delay: Duration(),
      requestTimeout: Duration(seconds: 10),
      retries: 3,
      largeMessageBehavior: CloudWatchLargeMessages.truncate,
      raiseFailedLookups: false,
    );
    CloudWatch cloudWatch = cloudWatchHandler.createInstance(
      logGroupName: 'logGroupName',
      logStreamName: 'logStreamName',
    );
    expect(cloudWatchHandler.raiseFailedLookups, false);
    expect(cloudWatch.raiseFailedLookups, false);
    cloudWatchHandler.raiseFailedLookups = true;
    expect(cloudWatchHandler.raiseFailedLookups, true);
    expect(cloudWatch.raiseFailedLookups, true);
  });
}
