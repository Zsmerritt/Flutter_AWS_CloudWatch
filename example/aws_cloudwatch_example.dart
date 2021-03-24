import 'package:aws_cloudwatch/aws_cloudwatch.dart';

// AWS Variables
const String AWS_ACCESS_KEY_ID = 'ExampleKey';
const String AWS_SECRET_ACCESS_KEY = 'ExampleSecret';
const String Region = 'us-west-2';
const String ServiceInstance = 'Logs_XXXXXXXX';

// Logging Variables
const String LogGroup = 'LogGroupExample';
String logStreamName = 'LogStreamExample';
CloudWatch cloudWatch =
    new CloudWatch(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, Region);

void log(String logString) {
  cloudWatch.log(logString);
}
