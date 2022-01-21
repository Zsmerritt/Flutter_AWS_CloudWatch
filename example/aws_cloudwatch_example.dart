import 'package:aws_cloudwatch/aws_cloudwatch.dart';

// AWS Variables
const String awsAccessKeyId = 'ExampleKey';
const String awsSecretAccessKey = 'ExampleSecret';
const String region = 'us-west-2';

// Logging Variables
const String groupName = 'LogGroupExample';
const String streamName = 'LogStreamExample';
CloudWatch cloudWatch = CloudWatch(
  awsAccessKey: awsAccessKeyId,
  awsSecretKey: awsSecretAccessKey,
  region: region,
  groupName: groupName,
  streamName: streamName,
);

void log(String logString) {
  cloudWatch.log(logString);
}
