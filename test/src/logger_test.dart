import 'dart:async';
import 'dart:convert';
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
      )..logStreamName = 'logStreamName';
      expect(cloudWatch.streamName, 'logStreamName');
    });
    test('negative timeoutMultiplier', () {
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
      )..timeoutMultiplier = -1;
      expect(cloudWatch.timeoutMultiplier, 1);
    });
    test('negative dynamicTimeoutMax', () {
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
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
      )..dynamicTimeoutMax = const Duration(seconds: -1);
      expect(cloudWatch.dynamicTimeoutMax.inSeconds, 0);
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
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
    group('deleteLogStream', () {
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
        );
      });
      test('request error', () async {
        cloudWatch.mockFunction = (Request request) async {
          throw Exception('Big bad exception');
        };
        try {
          await cloudWatch.deleteLogStream();
        } catch (e) {
          return;
        }
        fail('Exception did not propagate');
      });
      test('HTTP 200 clears logStreamCreated', () async {
        cloudWatch
          ..logStreamCreated = true
          ..mockFunction = (Request request) async {
            return Response('', 200);
          };
        await cloudWatch.deleteLogStream();
        expect(cloudWatch.logStreamCreated, false);
      });
      test('ResourceNotFoundException ignored when ignoreNotFound is true',
          () async {
        cloudWatch.mockFunction = (Request request) async {
          return Response(
            '{"__type":"ResourceNotFoundException","message":"gone"}',
            400,
          );
        };
        await cloudWatch.deleteLogStream(ignoreNotFound: true);
        expect(cloudWatch.logStreamCreated, false);
      });
      test('ResourceNotFoundException throws when ignoreNotFound is false',
          () async {
        cloudWatch.mockFunction = (Request request) async {
          return Response(
            '{"__type":"ResourceNotFoundException","message":"gone"}',
            400,
          );
        };
        try {
          await cloudWatch.deleteLogStream(ignoreNotFound: false);
        } catch (e) {
          expect(e, isA<CloudWatchException>());
          return;
        }
        fail('Expected CloudWatchException');
      });
      test('Other error throws', () async {
        cloudWatch.mockFunction = (Request request) async {
          return Response('{"__type":"AccessDeniedException"}', 403);
        };
        try {
          await cloudWatch.deleteLogStream();
        } catch (e) {
          expect(e, isA<CloudWatchException>());
          return;
        }
        fail('Expected CloudWatchException');
      });
    });
    group('deleteLogGroup', () {
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
        );
      });
      test('request error', () async {
        cloudWatch.mockFunction = (Request request) async {
          throw Exception('Big bad exception');
        };
        try {
          await cloudWatch.deleteLogGroup();
        } catch (e) {
          return;
        }
        fail('Exception did not propagate');
      });
      test('HTTP 200 clears logGroupCreated and logStreamCreated', () async {
        cloudWatch
          ..logGroupCreated = true
          ..logStreamCreated = true
          ..mockFunction = (Request request) async {
            return Response('', 200);
          };
        await cloudWatch.deleteLogGroup();
        expect(cloudWatch.logGroupCreated, false);
        expect(cloudWatch.logStreamCreated, false);
      });
      test('ResourceNotFoundException ignored when ignoreNotFound is true',
          () async {
        cloudWatch.mockFunction = (Request request) async {
          return Response(
            '{"__type":"ResourceNotFoundException","message":"gone"}',
            400,
          );
        };
        await cloudWatch.deleteLogGroup(ignoreNotFound: true);
        expect(cloudWatch.logGroupCreated, false);
        expect(cloudWatch.logStreamCreated, false);
      });
      test('ResourceNotFoundException throws when ignoreNotFound is false',
          () async {
        cloudWatch.mockFunction = (Request request) async {
          return Response(
            '{"__type":"ResourceNotFoundException","message":"gone"}',
            400,
          );
        };
        try {
          await cloudWatch.deleteLogGroup(ignoreNotFound: false);
        } catch (e) {
          expect(e, isA<CloudWatchException>());
          return;
        }
        fail('Expected CloudWatchException');
      });
      test('Other error throws', () async {
        cloudWatch.mockFunction = (Request request) async {
          return Response('{"__type":"AccessDeniedException"}', 403);
        };
        try {
          await cloudWatch.deleteLogGroup();
        } catch (e) {
          expect(e, isA<CloudWatchException>());
          return;
        }
        fail('Expected CloudWatchException');
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
        );
      });
      test('empty logEvents list throws (PutLogEvents min 1 event)', () {
        expect(
          () => cloudWatch.createBody([]),
          throwsA(
            predicate(
              (Object e) =>
                  e is CloudWatchException &&
                  e.message!.contains('at least one log event'),
            ),
          ),
        );
      });
      // InputLogEvent: timestamp (Number, ms since epoch), message (String, min 1).
      // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_InputLogEvent.html
      test(
          'createBody logEvents match InputLogEvent timestamp and message shape',
          () {
        const int ts1 = 1396035378988;
        const int ts2 = 1396035378990;
        final String res = cloudWatch.createBody(
          [
            {'timestamp': ts2, 'message': 'second'},
            {'timestamp': ts1, 'message': 'first'},
          ],
          nowUtc: DateTime.fromMillisecondsSinceEpoch(
            ts2 + const Duration(hours: 1).inMilliseconds,
            isUtc: true,
          ),
        );
        final Map<String, dynamic> decoded =
            jsonDecode(res) as Map<String, dynamic>;
        final List<dynamic> events = decoded['logEvents']! as List<dynamic>;
        expect(events.length, 2);
        for (final dynamic ev in events) {
          final Map<String, dynamic> m = ev as Map<String, dynamic>;
          expect(m['timestamp'], isA<int>());
          expect(m['timestamp'], greaterThan(0));
          expect(m['message'], isA<String>());
          expect((m['message'] as String).isNotEmpty, isTrue);
        }
        // PutLogEvents: log events must be in chronological order by timestamp.
        // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
        expect(events[0]['timestamp'], ts1);
        expect(events[0]['message'], 'first');
        expect(events[1]['timestamp'], ts2);
        expect(events[1]['message'], 'second');
        expect(decoded['logGroupName'], 'groupName');
        expect(decoded['logStreamName'], 'streamName');
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
        );
      });
      test('error XMLHttpRequest error', () {
        cloudWatch.checkError(Exception('XMLHttpRequest error'));
        expect(cloudWatch.errorsSeen.contains('Failed host lookup'), true);
      });
      test('error Failed host lookup', () {
        cloudWatch.checkError(Exception('Failed host lookup'));
        expect(cloudWatch.errorsSeen.contains('Failed host lookup'), true);
      });
      test('error Failed host lookup then null', () {
        cloudWatch.checkError(Exception('Failed host lookup'));
        expect(cloudWatch.errorsSeen.contains('Failed host lookup'), true);
        cloudWatch.checkError(null);
        expect(cloudWatch.errorsSeen.length, 0);
      });
      test('error timeout', () {
        cloudWatch.checkError(TimeoutException(''));
        expect(cloudWatch.errorsSeen.contains('TimeoutException'), true);
      });
      test('error general exception', () {
        cloudWatch.errorsSeen = {};
        try {
          cloudWatch.checkError(Exception('General Exception'));
        } on CloudWatchException {
          fail('Wrong exception was thrown');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(e.toString(), 'Exception: General Exception');
          expect(cloudWatch.errorsSeen.length, 0);
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
      test('requestTimeout > dynamicTimeoutMax', () {
        cloudWatch
          ..timeoutMultiplier = 10000
          ..checkError(TimeoutException(''));
        expect(cloudWatch.requestTimeout.inMinutes, 2);
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
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
      test(
        '200 with rejectedLogEventsInfo prepends batch and rethrows',
        () async {
          cloudWatch.mockFunction = (Request request) async {
            return Response(
              '{"nextSequenceToken":"t","rejectedLogEventsInfo":'
              '{"tooNewLogEventStartIndex":0}}',
              200,
            );
          };
          cloudWatch.logStack.addLogs(['test']);
          expect(cloudWatch.logStack.length, 1);
          try {
            await cloudWatch.sendLogs();
          } catch (e) {
            expect(e, isA<CloudWatchException>());
            final CloudWatchException ex = e as CloudWatchException;
            expect(ex.type, 'RejectedLogEventsInfo');
            expect(cloudWatch.logStack.length, 1);
            return;
          }
          fail('Expected CloudWatchException');
        },
      );
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
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
          Response('{"__type": "UnknownType"}', 400),
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
          useDynamicTimeout: true,
          dynamicTimeoutMax: const Duration(minutes: 2),
          timeoutMultiplier: 1.2,
          mockCloudWatch: true,
          mockFunction: (Request request) async {
            return Response('', 200);
          },
        );
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
      test(
        'ResourceNotFoundException log stream: message wording variant still recovers',
        () async {
          final AwsResponse awsResponse =
              await AwsResponse.parseResponse(Response(
            '{"__type": "ResourceNotFoundException", '
            '"message":"The specified LOG STREAM does not exist."}',
            400,
          ));
          final bool res = await cloudWatch.handleError(awsResponse);
          expect(res, false);
        },
      );
      test('InvalidParameterException', () async {
        final AwsResponse awsResponse =
            await AwsResponse.parseResponse(Response(
          '{"__type": "InvalidParameterException", "message": "this is a test"}',
          400,
        ));
        try {
          await cloudWatch.handleError(awsResponse);
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

  group('LoggerHandler', () {
    LoggerHandler newMockHandler() {
      return LoggerHandler(
        awsAccessKey: 'a',
        awsSecretKey: 's',
        region: 'us-east-1',
        awsSessionToken: null,
        delay: const Duration(),
        requestTimeout: const Duration(seconds: 10),
        retries: 1,
        largeMessageBehavior: CloudWatchLargeMessages.truncate,
        raiseFailedLookups: false,
        useDynamicTimeout: true,
        dynamicTimeoutMax: const Duration(minutes: 2),
        timeoutMultiplier: 1.2,
        mockCloudWatch: true,
        mockFunction: (Request r) async => Response('', 200),
      );
    }

    test('deleteLogStream removes cached instance', () async {
      final LoggerHandler h = newMockHandler()
        ..createInstance(logGroupName: 'g', logStreamName: 'st');
      expect(h.logInstances.length, 1);
      await h.deleteLogStream(logGroupName: 'g', logStreamName: 'st');
      expect(h.logInstances.length, 0);
    });

    test('deleteLogStream without cached instance', () async {
      final LoggerHandler h = newMockHandler();
      await h.deleteLogStream(logGroupName: 'g', logStreamName: 'st');
      expect(h.logInstances.length, 0);
    });

    test('deleteLogGroup removes all instances in group', () async {
      final LoggerHandler h = newMockHandler()
        ..createInstance(logGroupName: 'g', logStreamName: 's1')
        ..createInstance(logGroupName: 'g', logStreamName: 's2');
      expect(h.logInstances.length, 2);
      await h.deleteLogGroup(logGroupName: 'g');
      expect(h.logInstances.length, 0);
    });

    test('deleteLogGroup leaves other groups intact', () async {
      final LoggerHandler h = newMockHandler()
        ..createInstance(logGroupName: 'g1', logStreamName: 's')
        ..createInstance(logGroupName: 'g2', logStreamName: 's');
      await h.deleteLogGroup(logGroupName: 'g1');
      expect(h.logInstances.length, 1);
      expect(h.logInstances.values.first.groupName, 'g2');
    });
  });
}
