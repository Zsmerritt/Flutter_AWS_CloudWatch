import 'dart:async';
import 'dart:io';

import 'package:aws_cloudwatch/src/logger.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('Constructors', () {
    test('minimum', () {
      final Logger cloudWatch = Logger(
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
      final Logger cloudWatch = Logger(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(seconds: 100),
        requestTimeout: const Duration(seconds: 100),
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
      final Logger cloudWatch = Logger(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
        groupName: 'groupName',
        streamName: 'streamName',
        awsSessionToken: 'awsSessionToken',
        delay: const Duration(seconds: -10),
        requestTimeout: const Duration(seconds: 10),
        retries: 3,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
      );
      expect(cloudWatch.delay.inSeconds, 0);
    });
    test('negative retries', () {
      final Logger cloudWatch = Logger(
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
        Logger(
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
        Logger(
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
    test('maxBytesPerMessage', () {
      final Logger cloudWatch = Logger(
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
      )..maxBytesPerMessage = 100;
      expect(cloudWatch.maxBytesPerMessage, 100);
    });
    test('maxBytesPerRequest', () {
      final Logger cloudWatch = Logger(
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
      )..maxBytesPerRequest = 100;
      expect(cloudWatch.maxBytesPerRequest, 100);
    });
    test('maxMessagesPerRequest', () {
      final Logger cloudWatch = Logger(
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
      )..maxMessagesPerRequest = 100;
      expect(cloudWatch.maxMessagesPerRequest, 100);
    });
    test('negative delay', () {
      final Logger cloudWatch = Logger(
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
      )..delay = const Duration(seconds: -1);
      expect(cloudWatch.delay.inSeconds, 0);
    });
    test('positive delay', () {
      final Logger cloudWatch = Logger(
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
      )..delay = const Duration(seconds: 15);
      expect(cloudWatch.delay.inSeconds, 15);
    });
    test('negative requestTimeout', () {
      final Logger cloudWatch = Logger(
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
      )..requestTimeout = const Duration(seconds: -1);
      expect(cloudWatch.requestTimeout.inSeconds, 0);
    });
    test('positive requestTimeout', () {
      final Logger cloudWatch = Logger(
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
      )..requestTimeout = const Duration(seconds: 15);
      expect(cloudWatch.requestTimeout.inSeconds, 15);
    });
    test('negative verbosity', () {
      final Logger cloudWatch = Logger(
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
      )..verbosity = -1;
      expect(cloudWatch.verbosity, 0);
    });
    test('positive verbosity - too big', () {
      final Logger cloudWatch = Logger(
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
      final Logger cloudWatch = Logger(
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
      )..verbosity = 2;
      expect(cloudWatch.verbosity, 2);
    });
    test('negative retries', () {
      final Logger cloudWatch = Logger(
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
      )..retries = -1;
      expect(cloudWatch.retries, 0);
    });
    test('positive requestTimeout', () {
      final Logger cloudWatch = Logger(
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
      )..retries = 15;
      expect(cloudWatch.retries, 15);
    });
    test('largeMessageBehavior', () {
      final Logger cloudWatch = Logger(
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
      )..largeMessageBehavior = CloudWatchLargeMessages.split;
      expect(cloudWatch.largeMessageBehavior, CloudWatchLargeMessages.split);
      expect(cloudWatch.logStack.largeMessageBehavior,
          CloudWatchLargeMessages.split);
    });
    test('logGroupName', () {
      final Logger cloudWatch = Logger(
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
      )..logGroupName = 'logGroupName';
      expect(cloudWatch.groupName, 'logGroupName');
    });
    test('logStreamName', () {
      final Logger cloudWatch = Logger(
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
      )..logStreamName = 'logStreamName';
      expect(cloudWatch.streamName, 'logStreamName');
    });
  });

  group('Functions', () {
    group('debugPrint', () {
      test('verbosity 0', () {
        final Logger cloudWatch = Logger(
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
        final bool res =
            cloudWatch.debugPrint(1, 'this message wont be printed');
        expect(res, false);
      });
      test('verbosity 1', () {
        final Logger cloudWatch = Logger(
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
        )..verbosity = 1;
        bool res = cloudWatch.debugPrint(0, 'this message will be printed');
        expect(res, true);
        res = cloudWatch.debugPrint(1, 'this message wont be printed');
        expect(res, false);
      });
      test('verbosity 2', () {
        final Logger cloudWatch = Logger(
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
        )..verbosity = 2;
        bool res = cloudWatch.debugPrint(1, 'this message will be printed');
        expect(res, true);
        res = cloudWatch.debugPrint(2, 'this message wont be printed');
        expect(res, false);
      });
      test('verbosity 3', () {
        final Logger cloudWatch = Logger(
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
        )..verbosity = 3;
        bool res = cloudWatch.debugPrint(2, 'this message will be printed');
        expect(res, true);
        res = cloudWatch.debugPrint(3, 'this message wont be printed');
        expect(res, false);
      });
    });
    group('createLogStream', () {
      late Logger cloudWatch;
      setUpAll(() {
        cloudWatch = Logger(
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
        cloudWatch
          ..logStreamCreated = true
          ..mockFunction = (Request request) async {
            throw Exception('Big bad exception');
          };
        await cloudWatch.createLogStream();
        expect(cloudWatch.logStreamCreated, true);
      });
      test('create log stream', () async {
        cloudWatch
          ..logStreamCreated = false
          ..mockFunction = (Request request) async {
            return Response('', 200);
          };
        await cloudWatch.createLogStream();
        expect(cloudWatch.logStreamCreated, true);
      });
      test('ResourceAlreadyExistsException', () async {
        cloudWatch
          ..logStreamCreated = false
          ..mockFunction = (Request request) async {
            return Response('{"__type":"ResourceAlreadyExistsException"}', 400);
          };
        await cloudWatch.createLogStream();
        expect(cloudWatch.logStreamCreated, true);
      });
      test('Other Error', () async {
        cloudWatch
          ..logStreamCreated = false
          ..mockFunction = (Request request) async {
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
      late Logger cloudWatch;
      setUpAll(() {
        cloudWatch = Logger(
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
        cloudWatch
          ..logGroupCreated = true
          ..mockFunction = (Request request) async {
            throw Exception('Big bad exception');
          };
        await cloudWatch.createLogGroup();
        expect(cloudWatch.logGroupCreated, true);
      });
      test('create log stream', () async {
        cloudWatch
          ..logGroupCreated = false
          ..mockFunction = (Request request) async {
            return Response('', 200);
          };
        await cloudWatch.createLogGroup();
        expect(cloudWatch.logGroupCreated, true);
      });
      test('ResourceAlreadyExistsException', () async {
        cloudWatch
          ..logGroupCreated = false
          ..mockFunction = (Request request) async {
            return Response('{"__type":"ResourceAlreadyExistsException"}', 400);
          };
        await cloudWatch.createLogGroup();
        expect(cloudWatch.logGroupCreated, true);
      });
      test('Other Error', () async {
        cloudWatch
          ..logGroupCreated = false
          ..mockFunction = (Request request) async {
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
      late Logger cloudWatch;
      setUpAll(() {
        cloudWatch = Logger(
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
        final String res = cloudWatch.createBody([]);
        expect(
          res,
          '{"logEvents":[],"logGroupName":"groupName",'
          '"logStreamName":"streamName"}',
        );
      });
      test('logs', () {
        final String res = cloudWatch.createBody([
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
        final String res = cloudWatch.createBody([]);
        expect(
          res,
          '{"logEvents":[],"logGroupName":"groupName",'
          '"logStreamName":"streamName","sequenceToken":"abc"}',
        );
      });
    });
    group('checkError', () {
      late Logger cloudWatch;
      setUpAll(() {
        cloudWatch = Logger(
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
      test('error XMLHttpRequest error', () {
        cloudWatch.checkError(Exception('XMLHttpRequest error'));
        expect(cloudWatch.shouldPrintFailedLookup, false);
      });
      test('error Failed host lookup', () {
        cloudWatch.checkError(Exception('Failed host lookup'));
        expect(cloudWatch.shouldPrintFailedLookup, false);
      });
      test('error Failed host lookup then null', () {
        cloudWatch.checkError(Exception('Failed host lookup'));
        expect(cloudWatch.shouldPrintFailedLookup, false);
        cloudWatch.checkError(null);
        expect(cloudWatch.shouldPrintFailedLookup, true);
      });
      test('error timeout', () {
        cloudWatch.shouldPrintFailedLookup = true;
        try {
          cloudWatch.checkError(TimeoutException(''));
        } on CloudWatchException catch (e) {
          expect(
              e.message,
              'A timeout occurred while trying to upload logs. '
              'Consider increasing requestTimeout.');
          expect(cloudWatch.shouldPrintFailedLookup, true);
          return;
        } catch (e) {
          fail('Wrong exception was thrown');
        }
        fail('Exception was not thrown');
      });
      test('error general exception', () {
        cloudWatch.shouldPrintFailedLookup = true;
        try {
          cloudWatch.checkError(Exception('General Exception'));
        } on CloudWatchException {
          fail('Wrong exception was thrown');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(e.toString(), 'Exception: General Exception');
          expect(cloudWatch.shouldPrintFailedLookup, true);
          return;
        }
        fail('Exception was not thrown');
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
      late Logger cloudWatch;
      setUpAll(() {
        cloudWatch = Logger(
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
        cloudWatch
          ..mockCloudWatch = false
          ..raiseFailedLookups = true;
        cloudWatch.logStack.addLogs(['test']);
        try {
          await cloudWatch.sendLogs();
        } catch (e) {
          expect(e, isA<SocketException>());
        }
      });
    });
    group('handleResponse', () {
      late Logger cloudWatch;
      setUpAll(() {
        cloudWatch = Logger(
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
        final bool res = await cloudWatch.handleResponse(
          Response('{"__type": "InvalidSequenceTokenException"}', 400),
        );
        expect(res, false);
      });
    });
    group('handleError', () {
      late Logger cloudWatch;
      setUpAll(() {
        cloudWatch = Logger(
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
        final AwsResponse awsResponse =
            await AwsResponse.parseResponse(Response(
          '{"__type": "InvalidSequenceTokenException", '
          '"expectedSequenceToken":"abc"}',
          400,
        ));
        final bool res = await cloudWatch.handleError(awsResponse);
        expect(res, false);
        expect(cloudWatch.sequenceToken, 'abc');
      });
      test('ResourceNotFoundException', () async {
        final AwsResponse awsResponse =
            await AwsResponse.parseResponse(Response(
          '{"__type": "ResourceNotFoundException", '
          '"message":"The specified log stream does not exist."}',
          400,
        ));
        final bool res = await cloudWatch.handleError(awsResponse);
        expect(res, false);
      });
      test('ResourceNotFoundException', () async {
        final AwsResponse awsResponse =
            await AwsResponse.parseResponse(Response(
          '{"__type": "ResourceNotFoundException", '
          '"message":"The specified log group does not exist."}',
          400,
        ));
        final bool res = await cloudWatch.handleError(awsResponse);
        expect(res, false);
      });
      test('DataAlreadyAcceptedException', () async {
        final AwsResponse awsResponse =
            await AwsResponse.parseResponse(Response(
          '{"__type": "DataAlreadyAcceptedException", '
          '"expectedSequenceToken":"def"}',
          400,
        ));
        final bool res = await cloudWatch.handleError(awsResponse);
        expect(res, true);
        expect(cloudWatch.sequenceToken, 'def');
      });
      test('InvalidParameterException', () async {
        final AwsResponse awsResponse =
            await AwsResponse.parseResponse(Response(
          '{"__type": "InvalidParameterException", "message": "this is a test"}',
          400,
        ));
        try {
          final bool res = await cloudWatch.handleError(awsResponse);
          expect(res, true);
          expect(cloudWatch.sequenceToken, 'def');
        } on CloudWatchException catch (e) {
          expect(
              e.message,
              'An InvalidParameterException occurred! This is probably a bug! '
              'Please report it at\n'
              'https://github.com/Zsmerritt/Flutter_AWS_CloudWatch/issues/new \n'
              'and it will be addressed promptly. \n'
              'Message: this is a test Raw: {__type: InvalidParameterException, message: this is a test}');
          expect(awsResponse.raw,
              '{__type: InvalidParameterException, message: this is a test}');
          expect(e.type, 'InvalidParameterException');
          return;
        } catch (e) {
          fail('Wrong exception thrown!');
        }
        fail('Exception not thrown!');
      });
      test('unknown type', () async {
        final AwsResponse awsResponse =
            await AwsResponse.parseResponse(Response(
          '{"__type": "unknown"}',
          400,
        ));
        final bool res = await cloudWatch.handleError(awsResponse);
        expect(res, false);
      });
    });
  });
}
