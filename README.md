<h1 align="center">
  aws_cloudwatch
</h1>

<p align="center">
    <a href="https://pub.dev/packages/aws_cloudwatch">
        <img alt="Pub Package" src="https://img.shields.io/pub/v/aws_cloudwatch.svg?logo=dart&logoColor=00b9fc">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/commits/main">
        <img alt="Last Commit" src="https://img.shields.io/github/last-commit/Zsmerritt/Flutter_AWS_CloudWatch?logo=git&logoColor=white">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/pulls">
        <img alt="Pull Requests" src="https://img.shields.io/github/issues-pr/Zsmerritt/Flutter_AWS_CloudWatch?logo=github&logoColor=white">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/issues">
        <img alt="Open Issues" src="https://img.shields.io/github/issues/Zsmerritt/Flutter_AWS_CloudWatch?logo=github&logoColor=white">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch">
        <img alt="Code size" src="https://img.shields.io/github/languages/code-size/Zsmerritt/Flutter_AWS_CloudWatch?logo=github&logoColor=white">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/Zsmerritt/Flutter_AWS_CloudWatch?logo=open-source-initiative&logoColor=blue">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/actions/workflows/dart.yml">
        <img alt="CI pipeline status" src="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/actions/workflows/dart.yml/badge.svg">
    </a>
</p>

<p align="center">
  An easy, lightweight, and convenient way to reliably send logs to AWS CloudWatch.
</p>

---

<h3 align="center">
  Resources
</h3>

<p align="center">
    <a href="https://pub.dev/documentation/aws_cloudwatch/latest/aws_cloudwatch/aws_cloudwatch-library.html">
        Documentation
    </a>
    &nbsp;
    &nbsp;
    &nbsp;
    <a href="https://pub.dev/packages/aws_cloudwatch">
        Pub Package
    </a>
    &nbsp;
    &nbsp;
    &nbsp;
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch">
        GitHub Repository
    </a>
</p>

<p align="center">
    If you have feedback or have a use case that isn't covered feel free to open an issue.
</p>

## Getting Started

Create a CloudWatch instance and then send a log

~~~dart
import 'package:aws_cloudwatch/aws_cloudwatch.dart';

CloudWatch cloudWatch = CloudWatch(
  _AWS_ACCESS_KEY_ID,
  _AWS_SECRET_ACCESS_KEY,
  _Region,
  groupName: GROUP_NAME,
  streamName: STREAM_NAME,
);

cloudWatch.log('Hello World');
~~~

### Quick Start

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
log groups and log streams on its own. The way the quick start file is set up, you will end up with one log group for
standard logging and another for errors. Both with have the same log stream name. To automatically send logs for all
flutter errors see example 3.

## Examples

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
CloudWatch cloudWatch = CloudWatch(
  AWS_ACCESS_KEY_ID,
  AWS_SECRET_ACCESS_KEY,
  Region,
  groupName: logGroupName,
  streamName: logStreamName,
);

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
    logGroupName: isError ? logGroupNameError : logGroupName,
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

As of now (2021/09/12), AWS has a rate limit of 5 log requests per second per log stream. You may hit this limit rather
quickly if you have a high volume of logs. It is highly recommended to include the optional delay parameter with a value
of `Duration(milliseconds: 200)` to avoid hitting this upper limit. With a delay, logs will continue to collect, but the
api calls will be limited to `1 / delay` per second. For example, a delay of 200 milliseconds would result in a maximum
of 5 api requests per second. At the moment there is no way to increase this limit.

Example 2 shows how to add a delay. The default delay is `Duration(milliseconds: 0)`.

### Retrying Failed Requests

Sometimes API requests can fail. This is especially true for mobile devices going in and out of cell service. Both the
CloudWatch constructor and the CloudWatchHandler constructor can take the optional parameter `retries` indicating how
many times an api request will be attempted before giving up. The default retries value is 3.

### Log Groups and Log Streams

Log stream names currently (2021/09/12) have the following limits:

* Log stream names must be unique within the log group.
* Log stream names can be between 1 and 512 characters long.
* The ':' (colon) and '*' (asterisk) characters are not allowed.

Log group names currently (2021/09/12) have the following limits:

* Log group names can be between 1 and 512 characters long and match to ^[\.\-_/#A-Za-z0-9]+$.

### Message Size and Length Limits

AWS has hard limits on the amount of messages, length of individual messages, and overall length of message data sent
per request. Currently, (2021/09/12) that limit is 10,000 messages per request, 262,118 UTF8 bytes per message, and
1,048,550 total message UTF8 bytes per request. The optional parameter `largeMessageBehavior` specifies how messages
larger than 262,118 UTF8 bytes will be handled. By default, the middle of the message will be replaced with `...` to
reduce the size to 262,118 UTF8 bytes. All other hard limits are handled automatically.

## MIT License

```
Copyright (c) Zachary Merritt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```