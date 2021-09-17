import 'package:aws_cloudwatch/aws_cloudwatch.dart';
import 'package:test/test.dart';

void main() {
  test('tests getter / setter', () {
    final cloudWatch = CloudWatch('', '', '');
    expect(cloudWatch.logStreamName == null, true);
    expect(cloudWatch.logGroupName == null, true);
    cloudWatch.logGroupName = 'LogGroupName';
    cloudWatch.logStreamName = 'LogStreamName';
    expect(cloudWatch.logStreamName == 'LogStreamName', true);
    expect(cloudWatch.logGroupName == 'LogGroupName', true);
    cloudWatch.setLoggingParameters(null, null);
    expect(cloudWatch.logStreamName == null, true);
    expect(cloudWatch.logGroupName == null, true);
    cloudWatch.setLoggingParameters('LogGroupName', 'LogStreamName');
    expect(cloudWatch.logStreamName == 'LogStreamName', true);
    expect(cloudWatch.logGroupName == 'LogGroupName', true);
  });

  test('CloudWatchHandler', () {
    final CloudWatchHandler cloudWatchHandler = CloudWatchHandler(
      awsAccessKey: 'awsAccessKey',
      awsSecretKey: 'awsSecretKey',
      region: 'region',
    );
    CloudWatch? nullCloudWatch = cloudWatchHandler.getInstance(
      logGroupName: 'logGroupName',
      logStreamName: 'logStreamName',
    );
    expect(nullCloudWatch == null, true);

    expect(
        () async => await cloudWatchHandler.log(
              msg: 'Hello World!',
              logGroupName: 'logGroupName',
              logStreamName: 'logGroupName',
            ),
        throwsA(isA<CloudWatchException>()));
  });
}
