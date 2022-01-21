import 'package:aws_cloudwatch/aws_cloudwatch.dart';
import 'package:intl/intl.dart';

// AWS Variables
const String awsAccessKeyId = 'ExampleKey';
const String awsSecretAccessKey = 'ExampleSecret';
const String region = 'us-west-2';

// Logging Variables
const String logGroupName = 'LogGroupExample';
const String logGroupNameError = 'ErrorLogGroupExample';

CloudWatchHandler logging = CloudWatchHandler(
  awsAccessKey: awsAccessKeyId,
  awsSecretKey: awsSecretAccessKey,
  region: region,
);

String logStreamName = '';

// You may want to edit this function to suit your needs
String _getLogStreamName() {
  if (logStreamName == '') {
    logStreamName = DateFormat('yyyy-MM-dd HH-mm-ss').format(
      DateTime.now().toUtc(),
    );
  }
  return logStreamName;
}

void log(String logString, {bool isError = false}) {
  logging.log(
    message: logString,
    logGroupName: isError ? logGroupNameError : logGroupName,
    logStreamName: _getLogStreamName(),
  );
}

void logFlutterSystemError(dynamic logString, dynamic stackTrace) {
  log(
    'Auto Captured Error: ${logString.toString()}\n\n'
    'Auto Captured Stack Trace:\n${stackTrace.toString()}',
    isError: true,
  );
}
