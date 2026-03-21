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
  An easy, lightweight, turnkey solution for logging with AWS CloudWatch
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

## Table of Contents

- [Getting Started](#getting-started)
- [Quick Start](#quick-start)
- [Logging to Multiple Groups / Streams](#logging-to-multiple-groups--streams)
- [Capturing All Flutter Errors](#capturing-all-flutter-errors)
- [API Reference](#api-reference)
- [Important Notes](#important-notes)
  - [Android](#android)
  - [Using Temporary Credentials](#using-temporary-credentials)
  - [Rate Limiting](#avoiding-aws-cloudwatch-api-rate-limiting)
  - [Retrying Failed Requests](#retrying-failed-requests)
  - [Failed DNS Lookups](#failed-dns-lookups)
  - [Log Groups and Log Streams](#log-groups-and-log-streams)
  - [Message Size Limits](#message-size-limits)
  - [Requests Timing Out](#requests-timing-out)

## Getting Started

Create a `CloudWatch` instance, then send a log:

~~~dart
import 'package:aws_cloudwatch/aws_cloudwatch.dart';

CloudWatch cloudWatch = CloudWatch(
  awsAccessKey: 'YOUR_ACCESS_KEY',
  awsSecretKey: 'YOUR_SECRET_KEY',
  region: 'us-west-2',
  groupName: 'MyLogGroup',
  streamName: 'MyLogStream',
);

void logHelloWorld() {
  cloudWatch.log('Hello World!');
}
~~~

Log groups and log streams are created automatically if they don't already exist. No additional AWS setup is
needed beyond having credentials with the appropriate CloudWatch Logs permissions.

## Quick Start

This is a ready-to-use logging file. It is also located in `example/aws_cloudwatch.dart`.

> **Note:** This example uses the `intl` package for date formatting. Add `intl` to your `pubspec.yaml`
> dependencies if you want to use this pattern.

~~~dart
import 'package:aws_cloudwatch/aws_cloudwatch.dart';
import 'package:intl/intl.dart';

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
);

String logStreamName = '';

// You may want to edit this function to suit your needs
String _getLogStreamName() {
  if (logStreamName.isEmpty) {
    logStreamName = DateFormat('yyyy-MM-dd HH-mm-ss').format(
      DateTime.now().toUtc(),
    );
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
~~~

Then just import this file somewhere in your code and call `log('HELLO WORLD');`. `aws_cloudwatch` will
create the log groups and log streams on its own. With this quick start file, you will have one
log group for standard logging and another for errors. Both will have the same log stream name. To automatically send
logs for all Flutter errors see [Capturing All Flutter Errors](#capturing-all-flutter-errors) below.

## Logging to Multiple Groups / Streams

The `CloudWatch` class is used when sending logs to a single stream and group. If you need to send logs to multiple
streams or groups, use the `CloudWatchHandler` class and specify the log group and stream names when calling `.log()`.
`CloudWatchHandler` will take care of the rest.

~~~dart
import 'package:aws_cloudwatch/aws_cloudwatch.dart';

CloudWatchHandler handler = CloudWatchHandler(
  awsAccessKey: 'ExampleKey',
  awsSecretKey: 'ExampleSecret',
  region: 'us-west-2',
);

// Logs are routed to different groups/streams automatically
handler.log(
  message: 'User signed in',
  logGroupName: 'AuthLogs',
  logStreamName: 'production',
);

handler.log(
  message: 'Something went wrong',
  logGroupName: 'ErrorLogs',
  logStreamName: 'production',
);
~~~

### Sending Multiple Logs at Once

Both `CloudWatch` and `CloudWatchHandler` support sending multiple log messages in a single call using `logMany`.
All messages sent via `logMany` will share the same timestamp.

~~~dart
// With CloudWatch
cloudWatch.logMany(['First message', 'Second message', 'Third message']);

// With CloudWatchHandler
handler.logMany(
  messages: ['First message', 'Second message', 'Third message'],
  logGroupName: 'MyLogGroup',
  logStreamName: 'MyLogStream',
);
~~~

## Capturing All Flutter Errors

This example shows how to capture all errors in Flutter and send them to CloudWatch. First create a file named
`error_log.dart`:

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
  if (logStreamName.isEmpty) {
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

Then modify your `main.dart` to look like the following:

~~~dart
import 'dart:async';
import 'app.dart';

import 'error_log.dart';

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

## API Reference

### CloudWatch Constructor

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `awsAccessKey` | `String` | **required** | Your AWS access key |
| `awsSecretKey` | `String` | **required** | Your AWS secret key |
| `region` | `String` | **required** | AWS region (e.g. `us-west-2`) |
| `groupName` | `String` | **required** | CloudWatch log group name |
| `streamName` | `String` | **required** | CloudWatch log stream name |
| `awsSessionToken` | `String?` | `null` | Session token for temporary credentials |
| `delay` | `Duration` | 200ms | Delay between API requests |
| `requestTimeout` | `Duration` | 10s | HTTP request timeout |
| `retries` | `int` | 3 | Number of retry attempts on failure |
| `largeMessageBehavior` | `CloudWatchLargeMessages` | `split` | How to handle oversized messages |
| `raiseFailedLookups` | `bool` | `false` | Throw on DNS lookup failures |
| `useDynamicTimeout` | `bool` | `true` | Dynamically increase timeout after failures |
| `timeoutMultiplier` | `double` | 1.2 | Factor to increase timeout by |
| `dynamicTimeoutMax` | `Duration` | 2 min | Upper bound for dynamic timeout |
| `maxBytesPerMessage` | `int` | 1048550 | Max bytes per message (min 22, max ~1 MB) |
| `maxBytesPerRequest` | `int` | 1048576 | Max bytes per API request (min 1) |
| `maxMessagesPerRequest` | `int` | 10000 | Max messages per API request (min 1) |

### CloudWatchHandler Constructor

Same parameters as `CloudWatch` except `groupName` and `streamName` are not required. Instead, the group and stream
are specified per-call when using `log()` or `logMany()`.

### CloudWatchLargeMessages

Controls what happens when a log message exceeds the maximum size:

| Value | Description |
|-------|-------------|
| `split` | **Default.** Split the message into multiple smaller messages with a hash prefix for reassembly |
| `truncate` | Replace the middle of the message with `...` to fit within the limit |
| `ignore` | Silently discard the message |
| `error` | Throw a `CloudWatchException` |

### CloudWatchException

All errors thrown by the library use `CloudWatchException`, which includes:

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String?` | Description of the error |
| `stackTrace` | `StackTrace?` | Stack trace at the point of the error |
| `type` | `String?` | AWS error type (e.g. `InvalidParameterException`) |
| `statusCode` | `int?` | HTTP status code from AWS |
| `raw` | `String?` | Raw response body from AWS |

## Important Notes

### Android
If running on Android, make sure you have

`<uses-permission android:name="android.permission.INTERNET" />`

in your app's `android/app/src/main/AndroidManifest.xml`

### Using Temporary Credentials

Temporary credentials (such as those from AWS STS, IAM Roles, or Amazon Cognito) are fully supported. Pass the
optional `awsSessionToken` parameter when creating your `CloudWatch` or `CloudWatchHandler` instance.

#### Basic Usage

~~~dart
CloudWatch cloudWatch = CloudWatch(
  awsAccessKey: temporaryAccessKey,
  awsSecretKey: temporarySecretKey,
  awsSessionToken: sessionToken,
  region: 'us-west-2',
  groupName: 'MyApp',
  streamName: 'production',
);
~~~

#### Refreshing Expired Credentials

Temporary credentials expire. When you obtain new credentials, update them on the instance directly — no need to
create a new `CloudWatch` or `CloudWatchHandler`. All three values (access key, secret key, and session token) should
be updated together since they are issued as a set.

~~~dart
// Update all credentials when they are refreshed
cloudWatch.awsAccessKey = newAccessKey;
cloudWatch.awsSecretKey = newSecretKey;
cloudWatch.awsSessionToken = newSessionToken;
~~~

#### With CloudWatchHandler

When using `CloudWatchHandler`, setting the credentials on the handler automatically propagates the update to all
`CloudWatch` instances it manages. This means you only need to update credentials in one place.

~~~dart
CloudWatchHandler handler = CloudWatchHandler(
  awsAccessKey: temporaryAccessKey,
  awsSecretKey: temporarySecretKey,
  awsSessionToken: sessionToken,
  region: 'us-west-2',
);

// Later, when credentials expire:
handler.awsAccessKey = newAccessKey;
handler.awsSecretKey = newSecretKey;
handler.awsSessionToken = newSessionToken;
// All managed instances are now updated
~~~

#### Periodic Credential Refresh Example

~~~dart
import 'dart:async';

// Set up a timer to refresh credentials before they expire
Timer.periodic(Duration(minutes: 50), (_) async {
  final newCredentials = await fetchTemporaryCredentials();
  handler.awsAccessKey = newCredentials.accessKeyId;
  handler.awsSecretKey = newCredentials.secretAccessKey;
  handler.awsSessionToken = newCredentials.sessionToken;
});
~~~

**Note:** If you are using long-lived IAM credentials (not recommended for client-side apps), you can omit
`awsSessionToken` entirely — it is optional and defaults to `null`.

### Avoiding AWS Cloudwatch API Rate Limiting

AWS throttles `PutLogEvents` based on a per-account quota (default 5,000 TPS per account per region). The old
per-stream limit of 5 requests per second has been removed. However, a delay between API requests is still recommended
to avoid hitting the account-level quota, especially if you have many log streams active at once.

By default, this delay is set to 200 milliseconds. With a delay, logs will continue to be collected, but the
API calls will be limited to `1 / delay` per second. For example, a delay of 200 milliseconds would result in a maximum
of 5 API requests per second per stream.

### Retrying Failed Requests

Sometimes API requests fail. This is especially true for mobile devices going in and out of cell service. Both the
`CloudWatch` constructor and the `CloudWatchHandler` constructor can take the optional parameter `retries` indicating how
many times an API request will be attempted before giving up. The default retries value is 3.

### Failed DNS Lookups

By default, failed DNS lookups are silenced. Generally it can be assumed that if the DNS lookup fails, internet is
unavailable. This behaviour is controlled by the `raiseFailedLookups` flag and set to `false` by default. If internet
is available and this case is getting hit, it's possible there is an issue on the server level, but it is far more likely
that the provided region has a typo.

### Log Groups and Log Streams

Log stream names have the following limits:

* Log stream names must be unique within the log group.
* Log stream names can be between 1 and 512 characters long.
* The ':' (colon) and '*' (asterisk) characters are not allowed.

Log group names have the following limits:

* Log group names can be between 1 and 512 characters long and match to `^[\.\-_/#A-Za-z0-9]+$`.

### Message Size Limits

AWS allows individual log events up to 1 MB in size (increased from 256 KB in April 2025). This package supports the
full 1 MB limit by default. Messages exceeding the limit are handled according to the `largeMessageBehavior` parameter.
By default, the message will be broken up and paginated over several log entries with a hash to collate them, and a
message number like so: `JKNA9ANF23 0001/0045:[LOG_MESSAGE]`

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

    `maxBytesPerMessage`: how many bytes each message can be before `largeMessageBehavior` takes effect. Min 22, Max 1048550

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
