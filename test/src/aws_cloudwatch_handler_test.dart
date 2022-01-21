import 'package:aws_cloudwatch/src/cloudwatch.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('constructor', () {
    test('main constructor', () {
      LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
    });
    test('mock constructor', () {
      LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
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
      final LoggerHandler cloudWatchHandler = LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
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
        final LoggerHandler cloudWatchHandler = LoggerHandler(
          awsAccessKey: '1',
          awsSecretKey: '2',
          region: '3',
          awsSessionToken: '4',
          delay: const Duration(seconds: 100),
          requestTimeout: const Duration(seconds: 100),
          retries: 10,
          largeMessageBehavior: CloudWatchLargeMessages.split,
          raiseFailedLookups: true,
          mockFunction: (Request request) async {
            return Response('body', 200);
          },
          mockCloudWatch: true,
        );
        final Logger cw = cloudWatchHandler.createInstance(
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
      final LoggerHandler cloudWatchHandler = LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('no instances', () {
        final Logger? nullCloudWatch = cloudWatchHandler.getInstance(
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
        final Logger? cloudWatch = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        );
        expect(cloudWatch != null, true);
        expect(cloudWatch, isA<Logger>());
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
        final Logger? cloudWatch = cloudWatchHandler.getInstance(
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
        final LoggerHandler handler = LoggerHandler(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
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
        final Logger cw = handler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.sequenceToken, '123412341234');
      });
      test('logMany', () async {
        final LoggerHandler handler = LoggerHandler(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
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
        final Logger cw = handler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw.sequenceToken, '123412341234');
      });
    });
  });
  group('Getters & Setters', () {
    group('awsAccessKey', () {
      final LoggerHandler cloudWatchHandler = LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.awsAccessKey = '';
        expect(cloudWatchHandler.awsAccessKey, '');
      });
      test('set - instances', () {
        cloudWatchHandler
          ..createInstance(
            logGroupName: 'logGroupName',
            logStreamName: 'logStreamName',
          )
          ..awsAccessKey = '';
        expect(cloudWatchHandler.awsAccessKey, '');
        final Logger? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw!.awsAccessKey, '');
      });
    });
    group('awsSecretKey', () {
      final LoggerHandler cloudWatchHandler = LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.awsSecretKey = '';
        expect(cloudWatchHandler.awsSecretKey, '');
      });
      test('set - instances', () {
        cloudWatchHandler
          ..createInstance(
            logGroupName: 'logGroupName',
            logStreamName: 'logStreamName',
          )
          ..awsSecretKey = '';
        expect(cloudWatchHandler.awsSecretKey, '');
        final Logger? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw!.awsSecretKey, '');
      });
    });
    group('awsSessionToken', () {
      final LoggerHandler cloudWatchHandler = LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.awsSessionToken = '';
        expect(cloudWatchHandler.awsSessionToken, '');
      });
      test('set - instances', () {
        cloudWatchHandler
          ..createInstance(
            logGroupName: 'logGroupName',
            logStreamName: 'logStreamName',
          )
          ..awsSessionToken = '';
        expect(cloudWatchHandler.awsSessionToken, '');
        final Logger? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw!.awsSessionToken, '');
      });
    });
    group('delay', () {
      final LoggerHandler cloudWatchHandler = LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.delay = const Duration(seconds: 100);
        expect(cloudWatchHandler.delay.inSeconds, 100);
      });
      test('set - instances', () {
        cloudWatchHandler
          ..createInstance(
            logGroupName: 'logGroupName',
            logStreamName: 'logStreamName',
          )
          ..delay = const Duration(seconds: 100);
        expect(cloudWatchHandler.delay.inSeconds, 100);
        final Logger? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw!.delay.inSeconds, 100);
      });
    });
    group('requestTimeout', () {
      final LoggerHandler cloudWatchHandler = LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.requestTimeout = const Duration(seconds: 100);
        expect(cloudWatchHandler.requestTimeout.inSeconds, 100);
      });
      test('set - instances', () {
        cloudWatchHandler
          ..createInstance(
            logGroupName: 'logGroupName',
            logStreamName: 'logStreamName',
          )
          ..requestTimeout = const Duration(seconds: 100);
        expect(cloudWatchHandler.requestTimeout.inSeconds, 100);
        final Logger? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw!.requestTimeout.inSeconds, 100);
      });
    });
    group('largeMessageBehavior', () {
      final LoggerHandler cloudWatchHandler = LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
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
        cloudWatchHandler
          ..createInstance(
            logGroupName: 'logGroupName',
            logStreamName: 'logStreamName',
          )
          ..largeMessageBehavior = CloudWatchLargeMessages.split;
        expect(cloudWatchHandler.largeMessageBehavior,
            CloudWatchLargeMessages.split);
        final Logger? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw!.largeMessageBehavior, CloudWatchLargeMessages.split);
      });
    });
    group('raiseFailedLookups', () {
      final LoggerHandler cloudWatchHandler = LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.raiseFailedLookups = true;
        expect(cloudWatchHandler.raiseFailedLookups, true);
      });
      test('set - instances', () {
        cloudWatchHandler
          ..createInstance(
            logGroupName: 'logGroupName',
            logStreamName: 'logStreamName',
          )
          ..raiseFailedLookups = true;
        expect(cloudWatchHandler.raiseFailedLookups, true);
        final Logger? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw!.raiseFailedLookups, true);
      });
    });
    group('retries', () {
      final LoggerHandler cloudWatchHandler = LoggerHandler(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      test('set - no instances', () {
        cloudWatchHandler.retries = 0;
        expect(cloudWatchHandler.retries, 0);
      });
      test('set - instances', () {
        cloudWatchHandler
          ..createInstance(
            logGroupName: 'logGroupName',
            logStreamName: 'logStreamName',
          )
          ..retries = 0;
        expect(cloudWatchHandler.retries, 0);
        final Logger? cw = cloudWatchHandler.getInstance(
          logGroupName: 'logGroupName',
          logStreamName: 'logStreamName',
        )!;
        expect(cw!.retries, 0);
      });
    });
  });
}
