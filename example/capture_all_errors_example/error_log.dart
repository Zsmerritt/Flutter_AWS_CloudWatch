import 'package:aws_cloudwatch/aws_cloudwatch.dart';

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

String _utcLogStreamTimestamp() {
  final DateTime t = DateTime.now().toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} '
      '${two(t.hour)}-${two(t.minute)}-${two(t.second)}';
}

// You may want to edit this function to suit your needs
String _getLogStreamName() {
  if (logStreamName.isEmpty) {
    logStreamName = _utcLogStreamTimestamp();
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
