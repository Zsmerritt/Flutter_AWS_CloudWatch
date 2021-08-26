# aws_cloudwatch

A package that sends logs to AWS CloudWatch.

**Currently only logging is supported**

**This package is still under development**

The repository can be found [here](https://github.com/Zsmerritt/Flutter_AWS_CloudWatch)

If you have feedback or have a use case that isn't covered feel free to contact me.

## Getting Started

To get started add `aws_cloudwatch: ^[CURRENT_VERION],` to your `pubspec.yaml`

Then add `import 'package:aws_cloudwatch/aws_cloudwatch.dart';` to the top of your file.

Create a CloudWatch instance by calling

~~~
CloudWatch cloudWatch = new CloudWatch(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, REGION, 
    groupName:GROUP_NAME, streamName:STREAM NAME);
~~~

Finally, send a log by calling `cloudWatch.log('STRING TO LOG');`

## Examples

### Example - Quick Start

This is the quick start file. It is also location in example/aws_cloudwatch.dart

~~~dart
import 'package:aws_cloudwatch/aws_cloudwatch.dart';
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
    logGroupName: isError ? _LogGroup : _ErrorGroup,
    logStreamName: _getLogStreamName(),
  );
}
~~~

Then just import this file somewhere in your code and call `log('HELLO WORLD');`. The package will handle creating the
log groups and log streams on its own. The way the quick start file is setup, you will end up with one log group for
standard logging and another for errors. Both with have the same log stream name. To automatically send logs for all
flutter errors see example 3.

### Example 1

Here's an example of using aws_cloudwatch to send a CloudWatch PutLogEvent request:

~~~dart
import 'package:aws_cloudwatch/aws_cloudwatch.dart';

// AWS Variables
const String AWS_ACCESS_KEY_ID = 'ExampleKey';
const String AWS_SECRET_ACCESS_KEY = 'ExampleSecret';
const String Region = 'us-west-2';

// Logging Variables
const String logGroupName = 'LogGroupExample';
const String logStreamName = 'LogStreamExample';
CloudWatch cloudWatch = new CloudWatch(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
    Region, groupName: logGroupName, streamName: logStreamName);

void log(String logString) {
  cloudWatch.log(logString);
}
~~~

### Example 2

Here's an example of using aws_cloudwatch to send a CloudWatch PutLogEvent request with a 200-millisecond delay to avoid
rate limiting:

~~~dart
import 'package:aws_cloudwatch/aws_cloudwatch.dart';

// AWS Variables
const String AWS_ACCESS_KEY_ID = 'ExampleKey';
const String AWS_SECRET_ACCESS_KEY = 'ExampleSecret';
const String Region = 'us-west-2';

// Logging Variables
const String logGroupName = 'LogGroupExample';
const String logStreamName = 'LogStreamExample';
CloudWatch cloudWatch = new CloudWatch(AWS_ACCESS_KEY_ID,
  AWS_SECRET_ACCESS_KEY, Region, groupName: logGroupName,
  streamName: logStreamName, delay: Duration(milliseconds: 200));

void log(String logString) {
  cloudWatch.log(logString);
}
~~~

By adding a 200-millisecond delay, aws_cloudwatch will send more logs at a time and will be limited to sending api
requests at most once every 200 milliseconds. This can reduce the chance of hitting the AWS CloudWatch logging rate
limit of 5 requests per second per log stream.

### Example 3

Here is an example of how to capture all errors in flutter and send them to CloudWatch. First create this file and name
it `errorLog.dart`

~~~dart
import 'package:aws_request/aws_cloudwatch.dart';
import 'package:intl/intl.dart';

// AWS Variables
const String AWS_ACCESS_KEY_ID = 'ExampleKey';
const String AWS_SECRET_ACCESS_KEY = 'ExampleSecret';
const String Region = 'us-west-2';

// Logging Variables
const String logGroupName = 'LogGroupExample';
const String logGroupNameError = 'LogGroupExample';

CloudWatchHandler logging = CloudWatchHandler(
  awsAccessKey: AWS_ACCESS_KEY_ID,
  awsSecretKey: AWS_SECRET_ACCESS_KEY,
  region: Region,
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
    logGroupName: isError ? logGroupName : logGroupNameError,
    logStreamName: _getLogStreamName(),
  );
}

void logFlutterSystemError(dynamic logString, dynamic stackTrace) async {
  log(
    'Auto Captured Error: ${logString.toString()}\n\n'
        'Auto Captured Stack Trace:\n${stackTrace.toString()}',
    isError: true,
  );
}
~~~

Then modify your `main.dart` to look like the following

~~~dart
import 'dart:async';
import 'app.dart';

import 'errorLog.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    Function originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails errorDetails) async {
      Zone.current
          .handleUncaughtError(errorDetails.exception, errorDetails.stack);
      originalOnError(errorDetails);
    };
    runApp(MyApp());
  }, (error, stackTrace) async {
    logFlutterSystemError(error, stackTrace);
    print(error.toString());
    throw error;
  });
}
~~~

To send normal logs, import the logging file anywhere and call `log('Hello world!');`

## Important Notes:

### Avoiding AWS Cloudwatch API Rate Limiting

As of now (2021/07/09), AWS has a rate limit of 5 log requests per second per log stream. You may hit this limit rather
quickly if you have a high volume of logs. It is highly recommended to include the optional delay parameter with a value
of `Duration(milliseconds: 200)` to avoid hitting this upper limit. With a delay, logs will continue to collect, but 
the api calls will be limited to `1 / delay` per second. For example, a delay of 200 milliseconds would result in a maximum 
of 5 api requests per second. At the moment there is no way to increase this limit.

[Example 2](#Example 2) shows how to add a delay. The default delay is `Duration(milliseconds: 0)`.

### Log Groups and Log Streams

There are multiple ways to set the log group and log stream and all are roughly equivalent.

Log stream names currently (2021/07/09) have the following limits:

* Log stream names must be unique within the log group.
* Log stream names can be between 1 and 512 characters long.
* The ':' (colon) and '*' (asterisk) characters are not allowed.

This package does not enforce or check log stream names with regard to these limits in case AWS decides to add or remove
limitations. It is up to **you** to check the errors returned by the API to figure out if the problem is with the
provided log stream name.