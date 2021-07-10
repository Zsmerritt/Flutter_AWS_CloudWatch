import 'package:aws_cloudwatch/aws_cloudwatch.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
