import 'package:aws_cloudwatch/aws_cloudwatch.dart';

// AWS Variables
const String AWS_ACCESS_KEY_ID = 'ExampleKey';
const String AWS_SECRET_ACCESS_KEY = 'ExampleSecret';
const String Region = 'us-west-2';

// Logging Variables
const String groupName = 'LogGroupExample';
const String streamName = 'LogStreamExample';
CloudWatch cloudWatch = CloudWatch(
  AWS_ACCESS_KEY_ID,
  AWS_SECRET_ACCESS_KEY,
  Region,
  groupName: groupName,
  streamName: streamName,
);

void log(String logString) {
  cloudWatch.log(logString);
}
