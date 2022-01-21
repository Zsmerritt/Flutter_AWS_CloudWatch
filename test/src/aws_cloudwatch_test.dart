import 'dart:io';

import 'package:aws_cloudwatch/src/cloudwatch.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('Constructors', () {
    test('minimum', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      expect(cloudWatch.groupName, 'groupName');
      expect(cloudWatch.streamName, 'streamName');
      expect(cloudWatch.awsSessionToken, 'awsSessionToken');
      expect(cloudWatch.delay.inSeconds, 0);
      expect(cloudWatch.requestTimeout.inSeconds, 10);
      expect(cloudWatch.retries, 3);
      expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.truncate);
      expect(cloudWatch.raiseFailedLookups, false);
      expect(cloudWatch.logStack.largeMessageBehavior,
          CloudWatchLargeMessages.truncate);
    });
    test('maximum', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(seconds: 100),
        requestTimeout: Duration(seconds: 100),
        retries: 10,
        largeMessageBehavior: CloudWatchLargeMessages.split,
        raiseFailedLookups: true,
      );
      expect(cloudWatch.groupName, 'groupName');
      expect(cloudWatch.streamName, 'streamName');
      expect(cloudWatch.awsSessionToken, 'awsSessionToken');
      expect(cloudWatch.delay.inSeconds, 100);
      expect(cloudWatch.requestTimeout.inSeconds, 100);
      expect(cloudWatch.retries, 10);
      expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.split);
      expect(cloudWatch.raiseFailedLookups, true);
      expect(cloudWatch.logStack.largeMessageBehavior,
          CloudWatchLargeMessages.split);
    });
    test('negative delay', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: Duration(seconds: -10),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      expect(cloudWatch.delay.inSeconds, 0);
    });
    test('negative retries', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: -10,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      expect(cloudWatch.retries, 0);
    });
    test('bad groupName', () {
      try {
        AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: '',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: -10,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
        );
      } catch (e) {
        expect(e, isA<CloudWatchException>());
        return;
      }
      fail('Bad group name not caught!');
    });
    test('bad streamName', () {
      try {
        AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: '',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: -10,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
        );
      } catch (e) {
        expect(e, isA<CloudWatchException>());
        return;
      }
      fail('Bad stream name not caught!');
    });
  });

  group('Getters / Setters', () {
    test('negative delay', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.delay = Duration(seconds: -1);
      expect(cloudWatch.delay.inSeconds, 0);
    });
    test('positive delay', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.delay = Duration(seconds: 15);
      expect(cloudWatch.delay.inSeconds, 15);
    });
    test('negative requestTimeout', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.requestTimeout = Duration(seconds: -1);
      expect(cloudWatch.requestTimeout.inSeconds, 0);
    });
    test('positive requestTimeout', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.requestTimeout = Duration(seconds: 15);
      expect(cloudWatch.requestTimeout.inSeconds, 15);
    });
    test('negative verbosity', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.verbosity = -1;
      expect(cloudWatch.verbosity, 0);
    });
    test('positive verbosity - too big', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      )..verbosity = 15;
      expect(cloudWatch.verbosity, 3);
    });
    test('positive verbosity - ok', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.verbosity = 2;
      expect(cloudWatch.verbosity, 2);
    });
    test('negative retries', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.retries = -1;
      expect(cloudWatch.retries, 0);
    });
    test('positive requestTimeout', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.retries = 15;
      expect(cloudWatch.retries, 15);
    });
    test('largeMessageBehavior', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.largeMessageBehavior = CloudWatchLargeMessages.split;
      expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.split);
      expect(cloudWatch.logStack.largeMessageBehavior,
          CloudWatchLargeMessages.split);
    });
    test('logGroupName', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.logGroupName = 'logGroupName';
      expect(cloudWatch.groupName, 'logGroupName');
    });
    test('logStreamName', () {
      final AwsCloudWatch cloudWatch = AwsCloudWatch(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      cloudWatch.logStreamName = 'logStreamName';
      expect(cloudWatch.streamName, 'logStreamName');
    });
  });

  group('Functions', () {
    Future<Response> mockFunction(Request request) async {
      String body = request.body;
      if (body.contains('"logGroupName": "ok"')) {
        return Response('', 200);
      } else if (body.contains('"logStreamName": "ok"')) {
        return Response('', 200);
      } else if (body.contains('"logGroupName": "ResourceNotFoundException"')) {
        return Response(
            '{"__type":"ResourceNotFoundException", "message": "The specified log group does not exist."}',
            400);
      } else if (body
          .contains('"logStreamName": "DataAlreadyAcceptedException"')) {
        return Response('{"__type":"DataAlreadyAcceptedException"}', 400);
      } else if (body
          .contains('"logStreamName": "ResourceNotFoundException"')) {
        return Response(
            '{"__type":"ResourceNotFoundException", "message":"The specified log stream does not exist."}',
            400);
      } else if (body
          .contains('"logStreamName": "InvalidSequenceTokenException"')) {
        return Response(
            '{"__type":"InvalidSequenceTokenException", "expectedSequenceToken":"abc"}',
            400);
      } else {
        return Response('', 200);
      }
    }

    group('debugPrint', () {
      test('verbosity 0', () {
        final AwsCloudWatch cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
        );
        bool res = cloudWatch.debugPrint(1, 'this message wont be printed');
        expect(res, false);
      });
      test('verbosity 1', () {
        final AwsCloudWatch cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
        );
        cloudWatch.verbosity = 1;
        bool res = cloudWatch.debugPrint(0, 'this message will be printed');
        expect(res, true);
        res = cloudWatch.debugPrint(1, 'this message wont be printed');
        expect(res, false);
      });
      test('verbosity 2', () {
        final AwsCloudWatch cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
        );
        cloudWatch.verbosity = 2;
        bool res = cloudWatch.debugPrint(1, 'this message will be printed');
        expect(res, true);
        res = cloudWatch.debugPrint(2, 'this message wont be printed');
        expect(res, false);
      });
      test('verbosity 3', () {
        final AwsCloudWatch cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
        );
        cloudWatch.verbosity = 3;
        bool res = cloudWatch.debugPrint(2, 'this message will be printed');
        expect(res, true);
        res = cloudWatch.debugPrint(3, 'this message wont be printed');
        expect(res, false);
      });
    });
    group('createLogStream', () {
      late AwsCloudWatch cloudWatch;
      setUpAll(() {
        cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
          mockCloudWatch: true,
        );
      });
      test('request error', () async {
        cloudWatch.mockFunction = (Request request) async {
          throw Exception('Big bad exception');
        };
        try {
          await cloudWatch.createLogStream();
        } catch (e) {
          expect(cloudWatch.logStreamCreated, false);
          return;
        }
        fail('Exception did not stop log stream creation!');
      });
      test('log stream already created', () async {
        cloudWatch.logStreamCreated = true;
        cloudWatch.mockFunction = (Request request) async {
          throw Exception('Big bad exception');
        };
        await cloudWatch.createLogStream();
        expect(cloudWatch.logStreamCreated, true);
      });
      test('create log stream', () async {
        cloudWatch.logStreamCreated = false;
        cloudWatch.mockFunction = (Request request) async {
          return Response('', 200);
        };
        await cloudWatch.createLogStream();
        expect(cloudWatch.logStreamCreated, true);
      });
      test('ResourceAlreadyExistsException', () async {
        cloudWatch.logStreamCreated = false;
        cloudWatch.mockFunction = (Request request) async {
          return Response('{"__type":"ResourceAlreadyExistsException"}', 400);
        };
        await cloudWatch.createLogStream();
        expect(cloudWatch.logStreamCreated, true);
      });
      test('Other Error', () async {
        cloudWatch.logStreamCreated = false;
        cloudWatch.mockFunction = (Request request) async {
          return Response('', 400);
        };
        try {
          await cloudWatch.createLogStream();
        } catch (e) {
          expect(e, isA<CloudWatchException>());
          expect(cloudWatch.logStreamCreated, false);
          return;
        }
        fail('Log stream creation recovered from unrecoverable error');
      });
    });
    group('createLogGroup', () {
      late AwsCloudWatch cloudWatch;
      setUpAll(() {
        cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
          mockCloudWatch: true,
        );
      });
      test('request error', () async {
        cloudWatch.mockFunction = (Request request) async {
          throw Exception('Big bad exception');
        };
        try {
          await cloudWatch.createLogGroup();
        } catch (e) {
          expect(cloudWatch.logGroupCreated, false);
          return;
        }
        fail('Exception did not stop log stream creation!');
      });
      test('log stream already created', () async {
        cloudWatch.logGroupCreated = true;
        cloudWatch.mockFunction = (Request request) async {
          throw Exception('Big bad exception');
        };
        await cloudWatch.createLogGroup();
        expect(cloudWatch.logGroupCreated, true);
      });
      test('create log stream', () async {
        cloudWatch.logGroupCreated = false;
        cloudWatch.mockFunction = (Request request) async {
          return Response('', 200);
        };
        await cloudWatch.createLogGroup();
        expect(cloudWatch.logGroupCreated, true);
      });
      test('ResourceAlreadyExistsException', () async {
        cloudWatch.logGroupCreated = false;
        cloudWatch.mockFunction = (Request request) async {
          return Response('{"__type":"ResourceAlreadyExistsException"}', 400);
        };
        await cloudWatch.createLogGroup();
        expect(cloudWatch.logGroupCreated, true);
      });
      test('Other Error', () async {
        cloudWatch.logGroupCreated = false;
        cloudWatch.mockFunction = (Request request) async {
          return Response('', 400);
        };
        try {
          await cloudWatch.createLogGroup();
        } catch (e) {
          expect(e, isA<CloudWatchException>());
          expect(cloudWatch.logGroupCreated, false);
          return;
        }
        fail('Log stream creation recovered from unrecoverable error');
      });
    });
    group('createBody', () {
      late AwsCloudWatch cloudWatch;
      setUpAll(() {
        cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
          mockCloudWatch: true,
        );
      });
      test('empty logs', () {
        String res = cloudWatch.createBody([]);
        expect(
          res,
          '{"logEvents":[],"logGroupName":"groupName",'
          '"logStreamName":"streamName"}',
        );
      });
      test('logs', () {
        String res = cloudWatch.createBody([
          {'key': 'value'}
        ]);
        expect(
          res,
          '{"logEvents":[{"key":"value"}],"logGroupName":"groupName",'
          '"logStreamName":"streamName"}',
        );
      });
      test('sequenceToken', () {
        cloudWatch.sequenceToken = 'abc';
        String res = cloudWatch.createBody([]);
        expect(
          res,
          '{"logEvents":[],"logGroupName":"groupName",'
          '"logStreamName":"streamName","sequenceToken":"abc"}',
        );
      });
    });
    group('checkError', () {
      late AwsCloudWatch cloudWatch;
      setUpAll(() {
        cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
          mockCloudWatch: true,
        );
      });
      test('error null', () {
        bool res = cloudWatch.checkError(null);
        expect(res, false);
      });
      test('error null', () {
        bool res = cloudWatch.checkError(Exception('XMLHttpRequest error'));
        expect(res, true);
      });
      test('error null', () {
        bool res = cloudWatch.checkError(Exception('Failed host lookup'));
        expect(res, true);
      });
      test('raiseFailedLookups', () {
        cloudWatch.raiseFailedLookups = true;
        try {
          cloudWatch.checkError(Exception());
        } catch (e) {
          return;
        }
        fail('raiseFailedLookups = true did not trigger an exception!');
      });
    });
    group('sendLogs', () {
      late AwsCloudWatch cloudWatch;
      setUpAll(() {
        cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
          mockCloudWatch: true,
        );
      });
      test('logStack empty', () {
        expect(cloudWatch.logStack.length, 0);
        cloudWatch.sendLogs();
      });
      test('error request', () async {
        cloudWatch.mockFunction = (Request request) async {
          throw Exception('Big bad exception');
        };
        cloudWatch.logStack.addLogs(['test']);
        expect(cloudWatch.logStack.length, 1);
        try {
          await cloudWatch.sendLogs();
        } catch (e) {
          // make sure log got prepended after failed request
          expect(cloudWatch.logStack.length, 1);
          return;
        }
        fail('Exception was not thrown!');
      });
      test('Send Not Mocked Logs', () async {
        cloudWatch.mockCloudWatch = false;
        cloudWatch.raiseFailedLookups = true;
        cloudWatch.logStack.addLogs(['test']);
        try {
          await cloudWatch.sendLogs();
        } catch (e) {
          expect(e, isA<SocketException>());
        }
      });
    });
    group('handleResponse', () {
      late AwsCloudWatch cloudWatch;
      setUpAll(() {
        cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
          mockCloudWatch: true,
        );
      });
      test('status 400 - no type', () async {
        try {
          await cloudWatch.handleResponse(Response('', 400));
        } catch (e) {
          expect(e, isA<CloudWatchException>());
          return;
        }
        fail('Error not thrown');
      });
      test('status 400 - type', () async {
        bool res = await cloudWatch.handleResponse(
          Response('{"__type": "InvalidSequenceTokenException"}', 400),
        );
        expect(res, false);
      });
    });
    group('handleError', () {
      late AwsCloudWatch cloudWatch;
      setUpAll(() {
        cloudWatch = AwsCloudWatch(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          groupName: 'groupName',
          streamName: 'streamName',
          awsSessionToken: 'awsSessionToken',
          delay: const Duration(),
          requestTimeout: const Duration(seconds: 10),
          retries: 3,
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
          raiseFailedLookups: false,
          mockCloudWatch: true,
          mockFunction: (Request request) async {
            return Response('', 200);
          },
        );
      });
      test('InvalidSequenceTokenException', () async {
        AwsResponse awsResponse = await AwsResponse.parseResponse(Response(
          '{"__type": "InvalidSequenceTokenException", '
          '"expectedSequenceToken":"abc"}',
          400,
        ));
        bool res = await cloudWatch.handleError(awsResponse);
        expect(res, false);
        expect(cloudWatch.sequenceToken, 'abc');
      });
      test('ResourceNotFoundException', () async {
        AwsResponse awsResponse = await AwsResponse.parseResponse(Response(
          '{"__type": "ResourceNotFoundException", '
          '"message":"The specified log stream does not exist."}',
          400,
        ));
        bool res = await cloudWatch.handleError(awsResponse);
        expect(res, false);
      });
      test('ResourceNotFoundException', () async {
        AwsResponse awsResponse = await AwsResponse.parseResponse(Response(
          '{"__type": "ResourceNotFoundException", '
          '"message":"The specified log group does not exist."}',
          400,
        ));
        bool res = await cloudWatch.handleError(awsResponse);
        expect(res, false);
      });
      test('DataAlreadyAcceptedException', () async {
        AwsResponse awsResponse = await AwsResponse.parseResponse(Response(
          '{"__type": "DataAlreadyAcceptedException", '
          '"expectedSequenceToken":"def"}',
          400,
        ));
        bool res = await cloudWatch.handleError(awsResponse);
        expect(res, true);
        expect(cloudWatch.sequenceToken, 'def');
      });
      test('unknown type', () async {
        AwsResponse awsResponse = await AwsResponse.parseResponse(Response(
          '{"__type": "unknown"}',
          400,
        ));
        bool res = await cloudWatch.handleError(awsResponse);
        expect(res, false);
      });
    });
  });
}
