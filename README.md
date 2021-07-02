# aws_cloudwatch

A package that sends logs to AWS CloudWatch. 

<span style="color:red">**Currently only logging is supported**</span>


**This package is still under development**

The repository can be found [here](https://github.com/Zsmerritt/Flutter_AWS_CloudWatch)

If you have feedback or have a use case that isn't covered feel free to contact me.

## Getting Started

To get start add `aws_cloudwatch: ^[CURRENT_VERION],` to your `pubspec.yaml`

Then import `import 'package:aws_cloudwatch/aws_cloudwatch.dart';`

Create a CloudWatch instance by calling   
~~~
CloudWatch cloudWatch = new CloudWatch(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, Region);
~~~
Finally, send a log by calling `cloudWatch.log('STRING TO LOG');`

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
const String LogGroup = 'LogGroupExample';
String logStreamName = 'LogStreamExample';
CloudWatch cloudWatch = new CloudWatch(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, Region);

void log(String logString){
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
const String LogGroup = 'LogGroupExample';
String logStreamName = 'LogStreamExample';
CloudWatch cloudWatch = new CloudWatch.withDelay(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, Region, 200);

void log(String logString){
  cloudWatch.log(logString);
}
~~~
By adding a 200-millisecond delay, aws_cloudwatch will send more logs at a time and will be limited to sending log requests
at most once every 200 milliseconds. This can reduce the chance of hitting the AWS CloudWatch logging rate limit of 5 requests 
per second per log stream.
### Example 3
Here is an example of how to capture all errors in flutter and send them to CloudWatch.
First create this file and name it `errorLog.dart`
~~~dart
import 'package:aws_request/aws_cloudwatch.dart';

// AWS Variables
const String AWS_ACCESS_KEY_ID = 'ExampleKey';
const String AWS_SECRET_ACCESS_KEY = 'ExampleSecret';
const String Region = 'us-west-2';

// Logging Variables
const String LogGroup = 'LogGroupExample';
String logStreamName = 'LogStreamExample';
CloudWatch cloudWatch = new CloudWatch(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, Region);

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