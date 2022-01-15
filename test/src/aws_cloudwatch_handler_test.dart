import 'package:aws_cloudwatch/src/cloudwatch.dart';
import 'package:aws_cloudwatch/src/cloudwatch_handler.dart';
import 'package:aws_cloudwatch/src/util.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('constructor', () {
    test('main constructor', () {
      AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
    });
    test('mock constructor', () {
      AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
        mockFunction: (Request request) async {
          return Response('body', 200);
        },
        mockCloudWatch: true,
      );
    });
  });
  group('functions', () {
    group('createInstance', () {
      final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('empty strings', () {
        try {
          cloudWatchHandler.createInstance(
            logGroupName: '',
            logStreamName: '',
          );
        } catch (e) {
          expect(e, isA<CloudWatchException>());
        }
      });
      test('empty streamName', () {
        try {
          cloudWatchHandler.createInstance(
            logGroupName: 'logGroupName',
            logStreamName: '',
          );
        } catch (e) {
          expect(e, isA<CloudWatchException>());
        }
      });
      test('empty groupName', () {
        try {
          cloudWatchHandler.createInstance(
            logGroupName: '',
            logStreamName: 'logStreamName',
          );
        } catch (e) {
          expect(e, isA<CloudWatchException>());
        }
      });
      test('neither null', () {
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
      });
      test('variables', () {
        final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
          awsAccessKey: '1',
          awsSecretKey: '2',
          region: '3',
          awsSessionToken: '4',
          delay: Duration(seconds: 100),
          requestTimeout: Duration(seconds: 100),
          retries: 10,
          largeMessageBehavior: CloudWatchLargeMessages.split,
          raiseFailedLookups: true,
          mockFunction: (Request request) async {
            return Response('body', 200);
          },
          mockCloudWatch: true,
        );
        AwsCloudWatch cw = cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        expect(cloudWatchHandler.awsAccessKey, cw.awsAccessKey);
        expect(cloudWatchHandler.awsSecretKey, cw.awsSecretKey);
        expect(cloudWatchHandler.region, cw.region);
        expect(cloudWatchHandler.awsSessionToken, cw.awsSessionToken);
        expect(cloudWatchHandler.delay, cw.delay);
        expect(cloudWatchHandler.requestTimeout, cw.requestTimeout);
        expect(cloudWatchHandler.retries, cw.retries);
        expect(cloudWatchHandler.largeMessageBehavior, cw.largeMessageBehavior);
        expect(cloudWatchHandler.raiseFailedLookups, cw.raiseFailedLookups);
        expect(cloudWatchHandler.mockFunction, cw.mockFunction);
        expect(cloudWatchHandler.mockCloudWatch, cw.mockCloudWatch);
      });
    });
    group('getInstance', () {
      final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('no instances', () {
        AwsCloudWatch? nullCloudWatch = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        expect(cloudWatchHandler.logInstances.length, 0);
        expect(nullCloudWatch == null, true);
      });
      test('create and get', () {
        expect(cloudWatchHandler.logInstances.length, 0);
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        expect(cloudWatchHandler.logInstances.length, 1);
        AwsCloudWatch? cloudWatch = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        expect(cloudWatch != null, true);
        expect(cloudWatch, isA<AwsCloudWatch>());
        expect(cloudWatch!.logGroupName, 'logGroupName');
        expect(cloudWatch.logStreamName, 'logStreamName');
      });
      test('create and get - null', () {
        expect(cloudWatchHandler.logInstances.length, 1);
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        expect(cloudWatchHandler.logInstances.length, 1);
        AwsCloudWatch? cloudWatch = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName1',
          logStreamName: 'logStreamName1',
        );
        expect(cloudWatch == null, true);
      });
      test('overwrite', () {
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        expect(cloudWatchHandler.logInstances.length, 1);
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        expect(cloudWatchHandler.logInstances.length, 1);
      });
    });
    group('logging functions', () {
      Future<Response> mockFunction(Request request) async {
        if (request.body.contains('CreateLogStream')) {
          return Response('', 200);
        } else {
          return Response('{"nextSequenceToken":"123412341234"}', 200);
        }
      }

      test('log', () async {
        AwsCloudWatchHandler handler = AwsCloudWatchHandler(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          awsSessionToken: 'awsSessionToken',
          delay: Duration(),
          requestTimeout: Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
          mockFunction: mockFunction,
          mockCloudWatch: true,
        );
        await handler.log(
          msg: 'msg',
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        AwsCloudWatch cw = handler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.sequenceToken, '123412341234');
      });
      test('logMany', () async {
        AwsCloudWatchHandler handler = AwsCloudWatchHandler(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          awsSessionToken: 'awsSessionToken',
          delay: Duration(),
          requestTimeout: Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
          mockFunction: mockFunction,
          mockCloudWatch: true,
        );
        await handler.logMany(
          messages: ['msg'],
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        AwsCloudWatch cw = handler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.sequenceToken, '123412341234');
      });
    });
  });
  group('Getters & Setters', () {
    group('awsAccessKey', () {
      final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.awsAccessKey = '';
        expect(cloudWatchHandler.awsAccessKey, '');
      });
      test('set - instances', () {
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        cloudWatchHandler.awsAccessKey = '';
        expect(cloudWatchHandler.awsAccessKey, '');
        AwsCloudWatch? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.awsAccessKey, '');
      });
    });
    group('awsSecretKey', () {
      final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.awsSecretKey = '';
        expect(cloudWatchHandler.awsSecretKey, '');
      });
      test('set - instances', () {
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        cloudWatchHandler.awsSecretKey = '';
        expect(cloudWatchHandler.awsSecretKey, '');
        AwsCloudWatch? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.awsSecretKey, '');
      });
    });
    group('awsSessionToken', () {
      final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.awsSessionToken = '';
        expect(cloudWatchHandler.awsSessionToken, '');
      });
      test('set - instances', () {
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        cloudWatchHandler.awsSessionToken = '';
        expect(cloudWatchHandler.awsSessionToken, '');
        AwsCloudWatch? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.awsSessionToken, '');
      });
    });
    group('delay', () {
      final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.delay = Duration(seconds: 100);
        expect(cloudWatchHandler.delay.inSeconds, 100);
      });
      test('set - instances', () {
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        cloudWatchHandler.delay = Duration(seconds: 100);
        expect(cloudWatchHandler.delay.inSeconds, 100);
        AwsCloudWatch? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.delay.inSeconds, 100);
      });
    });
    group('requestTimeout', () {
      final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.requestTimeout = Duration(seconds: 100);
        expect(cloudWatchHandler.requestTimeout.inSeconds, 100);
      });
      test('set - instances', () {
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        cloudWatchHandler.requestTimeout = Duration(seconds: 100);
        expect(cloudWatchHandler.requestTimeout.inSeconds, 100);
        AwsCloudWatch? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.requestTimeout.inSeconds, 100);
      });
    });
    group('largeMessageBehavior', () {
      final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.largeMessageBehavior = CloudWatchLargeMessages.split;
        expect(cloudWatchHandler.largeMessageBehavior,
            CloudWatchLargeMessages.split);
      });
      test('set - instances', () {
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        cloudWatchHandler.largeMessageBehavior = CloudWatchLargeMessages.split;
        expect(cloudWatchHandler.largeMessageBehavior,
            CloudWatchLargeMessages.split);
        AwsCloudWatch? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.largeMessageBehavior, CloudWatchLargeMessages.split);
      });
    });
    group('raiseFailedLookups', () {
      final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.raiseFailedLookups = true;
        expect(cloudWatchHandler.raiseFailedLookups, true);
      });
      test('set - instances', () {
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        cloudWatchHandler.raiseFailedLookups = true;
        expect(cloudWatchHandler.raiseFailedLookups, true);
        AwsCloudWatch? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.raiseFailedLookups, true);
      });
    });
    group('retries', () {
      final AwsCloudWatchHandler cloudWatchHandler = AwsCloudWatchHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(),
        requestTimeout: Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.retries = 0;
        expect(cloudWatchHandler.retries, 0);
      });
      test('set - instances', () {
        cloudWatchHandler.createInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        cloudWatchHandler.retries = 0;
        expect(cloudWatchHandler.retries, 0);
        AwsCloudWatch? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.retries, 0);
      });
    });
  });
}
