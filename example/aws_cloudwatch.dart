import 'package:aws_cloudwatch/aws_cloudwatch_handler.dart';
import 'package:intl/intl.dart';

/// QUICK START LOGGING FILE
///
/// PLEASE FILL OUT THE FOLLOWING VARIABLES:

const String _AWS_ACCESS_KEY_ID = 'YOUR_ACCESS_KEY';
const String _AWS_SECRET_ACCESS_KEY = 'YOUR_SECRET_ACCESS_KEY';
const String _Region = 'YOUR_REGION_CODE'; // (us-west-1, us-east-2, etc)
const String _LogGroup = 'DESIRED_LOG_GROUP_NAME';
const String _ErrorGroup = 'DESIRED_ERROR_LOG_GROUP_NAME';

/// END OF VARIABLES

CloudWatchHandler logging = CloudWatchHandler(
  awsAccessKey: _AWS_ACCESS_KEY_ID,
  awsSecretKey: _AWS_SECRET_ACCESS_KEY,
  region: _Region,
  delay: Duration(milliseconds: 200),
);

String logStreamName = '';

// You may want to edit this function to suit your needs
String _getLogStreamName() {
  if (logStreamName == "") {
    logStreamName = DateFormat("yyyy-MM-dd HH-mm-ss").format(
      DateTime.now().toUtc(),
    );
  }
  return logStreamName;
}

void log(String logString, {isError = false}) {
  logging.log(
    msg: logString,
    logGroupName: isError ? _ErrorGroup : _LogGroup,
    logStreamName: _getLogStreamName(),
  );
}
