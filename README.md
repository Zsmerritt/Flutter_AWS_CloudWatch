<h1 align="center">
  aws_cloudwatch
</h1>

<p align="center">
    <a href="https://pub.dev/packages/aws_cloudwatch">
        <img alt="Pub Package" src="https://img.shields.io/pub/v/aws_cloudwatch.svg?logo=dart&logoColor=00b9fc">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/issues">
        <img alt="Open Issues" src="https://img.shields.io/github/issues/Zsmerritt/Flutter_AWS_CloudWatch?logo=github&logoColor=white">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch">
        <img alt="Code size" src="https://img.shields.io/github/languages/code-size/Zsmerritt/Flutter_AWS_CloudWatch?logo=github&logoColor=white">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/Zsmerritt/Flutter_AWS_CloudWatch?logo=open-source-initiative&logoColor=white">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/actions/workflows/dart.yml">
        <img alt="CI pipeline status" src="https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/actions/workflows/dart.yml/badge.svg?branch=main">
    </a>
    <a href="https://codecov.io/gh/Zsmerritt/Flutter_AWS_CloudWatch">
      <img src="https://codecov.io/gh/Zsmerritt/Flutter_AWS_CloudWatch/branch/main/graph/badge.svg?token=IYYGJNJEA1"/>
    </a>
</p>

<p align="center">
  A easy, lightweight, turnkey solution for logging with AWS CloudWatch
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
    If you have feedback or a use case that isn't covered please open an issue.
</p>

## Getting Started

Create a CloudWatch instance, then send a log

~~~dart
import 'package:aws_cloudwatch/aws_cloudwatch.dart';

CloudWatch cloudwatch = CloudWatch(
  awsAccessKey: _awsAccessKeyId,
  awsSecretKey: _awsSecretAccessKey,
  region: _region,
  groupName: 'groupName',
  streamName: 'streamName',
);

void logHelloWorld() {
  cloudWatch.log('Hello World!');
}
~~~

### Quick Start

This is the quick start file. It is also location in `example/aws_cloudwatch.dart`

~~~dart
import 'package:aws_cloudwatch/aws_cloudwatch.dart';
import 'package:intl/intl.dart';

/// QUICK START LOGGING FILE
///
/// PLEASE FILL OUT THE FOLLOWING VARIABLES:

const String _awsAccessKeyId = 'YOUR_ACCESS_KEY';
const String _awsSecretAccessKey = 'YOUR_SECRET_ACCESS_KEY';
const String _region = 'YOUR_REGION_NAME'; // (us-west-1, us-east-2, etc)
const String _logGroup = 'DESIRED_LOG_GROUP_NAME';
const String _errorGroup = 'DESIRED_ERROR_LOG_GROUP_NAME';

/// END OF VARIABLES

CloudWatchHandler logging = CloudWatchHandler(
  awsAccessKey: _awsAccessKeyId,
  awsSecretKey: _awsSecretAccessKey,
  region: _region,
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
    logGroupName: isError ? _logGroup : _errorGroup,
    logStreamName: _getLogStreamName(),
  );
}
~~~

Then just import this file somewhere in your code and call `log('HELLO WORLD');`. `aws_cloudwatch` will 
create the log groups and log streams on its own. with this quick start file, you will have one 
log group for standard logging and another for errors. Both with have the same log stream name. To automatically send 
logs for all flutter errors see example 2 below.

## Examples

### Example 1

Here's an example of using `CloudWatch` from `aws_cloudwatch` to send a log:

~~~dart
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
~~~

The `CloudWatch` class is used when sending logs to one stream or group. If you need to send logs to multiple
streams or groups, use the `CloudWatchHandler` class and specify the log group and stream names when calling `.log()`. 
`CloudWatchHandler`will take care of the rest.

### Example 2

This example shows how to capture all errors in flutter and send them to CloudWatch. First create this file and name
it `errorLog.dart`

~~~dart
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
~~~

Then modify your `main.dart` to look like the following

~~~dart
import 'dart:async';
import 'app.dart';

import 'errorLog.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    final Function originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails errorDetails) async {
      Zone.current
          .handleUncaughtError(errorDetails.exception, errorDetails.stack);
      originalOnError(errorDetails);
    };
    runApp(MyApp());
  }, (dynamic error, stackTrace) async {
    logFlutterSystemError(error, stackTrace);
    print(error.toString());
    throw error;
  });
}
~~~

To send normal logs, import the logging file anywhere and call `log('Hello world!');`. Any uncaught exceptions will 
automatically be uploaded to AWS CloudWatch in a separate log group for errors with the exception and stacktrace.

## Important Notes:

### Android
If running on android, make sure you have

`<uses-permission android:name="android.permission.INTERNET" />`

in your app's `android/app/src/main/AndroidManifest.xml`

### Using Temporary Credentials

Temporary credentials are supported. Use the optional parameter `sessionToken` to specify your session
token. Expired credentials can be updated by setting the CloudWatch instance `sessionToken` variable. Setting the 
sessionToken on a CloudWatchHandler will update the `sessionToken` on all CloudWatch instances it manages.

### Avoiding AWS Cloudwatch API Rate Limiting

AWS has a rate limit of 5 log requests per second per log stream. To prevent hitting this rate limit, a delay is added between API requests.
By default, this delay is set to 200 millisecond. With a delay, logs will continue to be collected, but the
api calls will be limited to `1 / delay` per second. For example, a delay of 200 milliseconds would result in a maximum
of 5 API requests per second.

### Retrying Failed Requests

Sometimes API requests fail. This is especially true for mobile devices going in and out of cell service. Both the
`CloudWatch` constructor and the `CloudWatchHandler` constructor can take the optional parameter `retries` indicating how
many times an api request will be attempted before giving up. The default retries value is 3.

### Failed DNS Lookups

By default, failed DNS lookups are silenced. Generally it can be assumed that if the DNS lookup fails, internet is
unavailable. This behaviour is controlled by the `raiseFailedLookups` flag and set to `false` by default. If internet
is available and this case is getting hit, its possible there is an issue on the server level, but it is far more likely
that the provided region has a typo.

### Log Groups and Log Streams

Log stream names have the following limits:

* Log stream names must be unique within the log group.
* Log stream names can be between 1 and 512 characters long.
* The ':' (colon) and '*' (asterisk) characters are not allowed.

Log group names have the following limits:

* Log group names can be between 1 and 512 characters long and match to `^[\.\-_/#A-Za-z0-9]+$`.

### Message Size Limits

AWS has hard limits on the length of individual messages. The optional parameter `largeMessageBehavior` specifies how messages
larger than the limit will be handled. By default, the message will be broken up and paginated over several
log entries with a timestamped message hash to collate them, and a message number like so: `JKNA9ANF23 0001/0045:[LOG_MESSAGE]`

### Requests Timing Out
Sometimes, if the connection is poor or the payload is very large, requests can timeout. Logs from requests that time 
out aren't lost, and the request will be retried the next time a log is added to the queue. Here are some debugging 
steps to take if you are running into this issue frequently:

1)  Increase the timeout -
The first thing to try is increasing the duration of the `requestTimeout` parameter. This increases the amount of time 
requests have before timing out.
    

2)  Adjust the dynamic timeout -
If increasing the request timeout doesn't work, you can try adjusting the dynamic timeout. With the dynamic timeout, as
requests timeout, the timeout is slowly increased. The aim of this feature is to tune the timeout to the situation the 
user is in. 

    `useDynamicTimeout`: whether this feature is enabled. Default: true
    
    `timeoutMultiplier`: the factor by which the timeout increases after a timeout. Default: 1.2  
    
    `dynamicTimeoutMax`: the upper bound for the `requestTimeout`. Default: 2 minutes


3) Adjust log limits -
If that still doesn't solve the issue, there are several other options that are aimed at decreasing the size of the 
payload. 
   
    `maxBytesPerMessage`: how many bytes each message can be before `largeMessageBehavior` takes effect. Min 22, Max 262116
    
    `maxBytesPerRequest`: how many bytes can be sent in each API request before messages are paginated. Min 1, Max 1048576
    
    `maxMessagesPerRequest`: the maximum number of messages that can be sent in each API request. Min 1, Max 10000

    By default, these parameters are set to their maximum. Decreasing any of them will decrease the payload size and 
    increase pagination.


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