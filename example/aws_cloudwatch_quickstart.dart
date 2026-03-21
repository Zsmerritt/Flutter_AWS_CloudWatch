import 'package:aws_cloudwatch/aws_cloudwatch.dart';

/// QUICK START LOGGING FILE
///
/// PLEASE FILL OUT THE FOLLOWING VARIABLES:

const String _awsAccessKeyId = 'YOUR_ACCESS_KEY';
const String _awsSecretAccessKey = 'YOUR_SECRET_ACCESS_KEY';
const String _region = 'YOUR_REGION_CODE'; // (us-west-1, us-east-2, etc)
const String _logGroup = 'DESIRED_LOG_GROUP_NAME';
const String _errorGroup = 'DESIRED_ERROR_LOG_GROUP_NAME';

/// END OF VARIABLES

CloudWatchHandler logging = CloudWatchHandler(
  awsAccessKey: _awsAccessKeyId,
  awsSecretKey: _awsSecretAccessKey,
  region: _region,
  delay: const Duration(milliseconds: 200),
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
    logGroupName: isError ? _errorGroup : _logGroup,
    logStreamName: _getLogStreamName(),
  );
}
