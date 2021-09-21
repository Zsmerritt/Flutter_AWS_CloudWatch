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

  test('CloudWatchLogStack - Basics', () {
    CloudWatchLogStack truncateStack = CloudWatchLogStack(
        largeMessageBehavior: CloudWatchLargeMessages.truncate);
    truncateStack.addLogs(['test', 'test2']);
    expect(truncateStack.length, 1);
    expect(truncateStack.logStack[0].logs.length, 2);
    expect(truncateStack.logStack[0].logs[0]['message'], 'test');
    expect(truncateStack.logStack[0].logs[1]['message'], 'test2');
    expect(truncateStack.logStack[0].messageSize, 9);
    CloudWatchLog log = truncateStack.pop();
    expect(truncateStack.length, 0);
    truncateStack.prepend(log);
    expect(truncateStack.length, 1);
    expect(truncateStack.logStack[0].logs.length, 2);
    expect(truncateStack.logStack[0].logs[0]['message'], 'test');
    expect(truncateStack.logStack[0].logs[1]['message'], 'test2');
    expect(truncateStack.logStack[0].messageSize, 9);
  });

  test('CloudWatchLogStack - MAX_MESSAGES_PER_BATCH', () {
    CloudWatchLogStack splitStack =
        CloudWatchLogStack(largeMessageBehavior: CloudWatchLargeMessages.split);
    List<String> logStrings = List.generate(20000, (index) => 'test');
    splitStack.addLogs(logStrings);
    expect(splitStack.length, 2);
  });

  test('CloudWatchLogStack - MAX_BYTE_BATCH_SIZE', () {
    CloudWatchLogStack splitStack =
        CloudWatchLogStack(largeMessageBehavior: CloudWatchLargeMessages.split);

    splitStack.addLogs(['test' * 262118 * 2]);
    expect(splitStack.length, 2);
    expect(splitStack.logStack[0].logs.length, 4);
    expect(splitStack.logStack[0].logs[0]['message'].length, 262118);
    expect(splitStack.logStack[0].logs[1]['message'].length, 262118);
    expect(splitStack.logStack[0].logs[2]['message'].length, 262118);
    expect(splitStack.logStack[0].logs[3]['message'].length, 262118);
    expect(splitStack.logStack[0].messageSize, 1048472);
    expect(splitStack.logStack[1].logs.length, 4);
    expect(splitStack.logStack[1].logs[0]['message'].length, 262118);
    expect(splitStack.logStack[1].logs[1]['message'].length, 262118);
    expect(splitStack.logStack[1].logs[2]['message'].length, 262118);
    expect(splitStack.logStack[1].logs[3]['message'].length, 262118);
    expect(splitStack.logStack[1].messageSize, 1048472);
  });

  test('CloudWatchLogStack: split', () {
    CloudWatchLogStack splitStack =
        CloudWatchLogStack(largeMessageBehavior: CloudWatchLargeMessages.split);
    // test splitting large message into smaller chunks
    splitStack.addLogs(['test' * 262118]);
    expect(splitStack.length, 1);
    expect(splitStack.logStack[0].logs.length, 4);
    expect(splitStack.logStack[0].logs[0]['message'].length, 262118);
    expect(splitStack.logStack[0].logs[1]['message'].length, 262118);
    expect(splitStack.logStack[0].logs[2]['message'].length, 262118);
    expect(splitStack.logStack[0].logs[3]['message'].length, 262118);
    expect(splitStack.logStack[0].messageSize, 1048472);

    // these messages should not be split
    splitStack.addLogs(['test' * 65529]);
    expect(splitStack.length, 2);
    expect(splitStack.logStack[1].logs.length, 1);
    expect(splitStack.logStack[1].logs[0]['message'].length, 262116);
    expect(splitStack.logStack[1].messageSize, 262116);
  });

  test('CloudWatchLogStack: truncate', () {
    CloudWatchLogStack truncateStack = CloudWatchLogStack(
        largeMessageBehavior: CloudWatchLargeMessages.truncate);
    // test truncating large message
    List<String> logStrings = ['test' * 262118];
    truncateStack.addLogs(logStrings);
    expect(truncateStack.length, 1);
    expect(truncateStack.logStack[0].logs.length, 1);
    expect(truncateStack.logStack[0].logs[0]['message'].length, 262117);
    expect(truncateStack.logStack[0].messageSize, 262117);

    // these messages should not be truncated
    truncateStack.addLogs(['test' * 65529]);
    expect(truncateStack.length, 1);
    expect(truncateStack.logStack[0].logs.length, 2);
    expect(truncateStack.logStack[0].logs[1]['message'].length, 262116);
    expect(truncateStack.logStack[0].messageSize, 262116 + 262117);
  });

  test('CloudWatchLogStack: ignore', () {
    CloudWatchLogStack ignoreStack = CloudWatchLogStack(
        largeMessageBehavior: CloudWatchLargeMessages.ignore);
    // test ignoreing large messages
    ignoreStack.addLogs(['test' * 262118]);
    expect(ignoreStack.length, 0);

    // these messages should be added
    ignoreStack.addLogs(['test' * 65529]);
    expect(ignoreStack.length, 1);
    expect(ignoreStack.logStack[0].logs.length, 1);
    expect(ignoreStack.logStack[0].logs[0]['message'].length, 262116);
    expect(ignoreStack.logStack[0].messageSize, 262116);
  });

  test('CloudWatchLogStack: error', () {
    CloudWatchLogStack errorStack =
        CloudWatchLogStack(largeMessageBehavior: CloudWatchLargeMessages.error);
    // test throwing an error on large messages
    expect(() => errorStack.addLogs(['test' * 262118]),
        throwsA(isA<CloudWatchException>()));
    expect(errorStack.length, 0);

    // these messages should be added
    errorStack.addLogs(['test' * 65529]);
    expect(errorStack.length, 1);
    expect(errorStack.logStack[0].logs.length, 1);
    expect(errorStack.logStack[0].logs[0]['message'].length, 262116);
    expect(errorStack.logStack[0].messageSize, 262116);
  });
}
