import 'package:aws_cloudwatch/aws_cloudwatch.dart';
import 'package:aws_cloudwatch/aws_cloudwatch_util.dart';
import 'package:test/test.dart';

void main() {
  test('CloudWatch - getter / setter', () {
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

  test('CloudWatch - largeMessageBehavior', () {
    CloudWatch cloudWatch = CloudWatch('', '', '');

    expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.truncate);
    expect(cloudWatch.logStack.largeMessageBehavior,
        CloudWatchLargeMessages.truncate);
    cloudWatch.largeMessageBehavior = CloudWatchLargeMessages.split;
    expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.split);
    expect(cloudWatch.logStack.largeMessageBehavior,
        CloudWatchLargeMessages.split);
  });
}
