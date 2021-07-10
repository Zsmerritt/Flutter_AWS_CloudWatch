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

## Important Notes:

### Avoiding AWS Cloudwatch API Rate Limiting

As of now (2021/07/09), AWS has a rate limit of 5 log requests per second per log stream. You may hit this limit rather
quickly if you have a high volume of logs. It is highly recommended to include the optional delay parameter with a value
of 200 (milliseconds) to avoid hitting this upper limit. With a delay, logs will continue to collect, but the api calls
will be limited to 5 per second. At the moment there is no way around this limit.

Example 2 below shows how to add a delay. The default delay is 0 milliseconds.

### Log Groups and Log Streams

Creating streams and uploading logs is the primary reason this package exists. Log groups must still be created
manually. If you would like this feature let me know, and I will work on implementing it. With my use cases, I haven't
felt the need for it.

There are multiple ways to set the log group and log stream and all are roughly equivalent.

Log stream names currently (2021/07/09) have the following limits:

* Log stream names must be unique within the log group.
* Log stream names can be between 1 and 512 characters long.
* The ':' (colon) and '*' (asterisk) characters are not allowed.

This package does not enforce or check log stream names with regard to these limits in case AWS decides to add or remove
limitations. It is up to **you** to check the errors returned by the API to figure out if the problem is with the
provided log stream name.

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
    streamName: logStreamName, delay: 200);

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

// AWS Variables
const String AWS_ACCESS_KEY_ID = 'ExampleKey';
const String AWS_SECRET_ACCESS_KEY = 'ExampleSecret';
const String Region = 'us-west-2';

// Logging Variables
const String logGroupName = 'LogGroupExample';
const String logStreamName = 'LogStreamExample';
CloudWatch cloudWatch = new CloudWatch(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
    Region);
cloudWatch.setLoggingParameters(logGroupName, logStreamName);

void logFlutterSystemError(dynamic logString, dynamic stackTrace) async {
  cloudWatch.log('Auto Captured Error: ${logString.toString()}\n\n'
      'Auto Captured Stack Trace:\n${stackTrace.toString()}');
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