// Live integration: real AWS CloudWatch Logs API (network required).
//
// Credentials and region are read from the process environment and from a
// project-root `.env` file (if present). Values in [Platform.environment]
// override `.env` for the same keys.
//
// Required: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY (or AWS_SECRET_KEY),
//           AWS_REGION or AWS_DEFAULT_REGION
// Optional: AWS_SESSION_TOKEN
//
// Log group and stream names are auto-generated per run; resources are removed
// in tearDownAll.
//
// Run from package root (use --concurrency=1: tests share one log group / streams):
//   dart test test/integration/live_aws_cloudwatch_logs_test.dart --concurrency=1

import 'dart:convert' show utf8;
import 'dart:io' show File, Platform;
import 'dart:math' show Random;

import 'package:aws_cloudwatch/aws_cloudwatch.dart';
import 'package:aws_cloudwatch/src/logger.dart'
    show CloudWatchLargeMessages, Logger, awsMaxBytesPerMessage;
import 'package:test/test.dart';

/// Same defaults as [CloudWatch]; used only for internal lifecycle calls in this test.
Logger _liveLogger(
  _LiveAwsConfig c, {
  required String groupName,
  required String streamName,
}) {
  return Logger(
    awsAccessKey: c.accessKeyId,
    awsSecretKey: c.secretAccessKey,
    region: c.region,
    groupName: groupName,
    streamName: streamName,
    awsSessionToken: c.sessionToken,
    delay: const Duration(milliseconds: 200),
    requestTimeout: const Duration(seconds: 10),
    retries: 3,
    largeMessageBehavior: CloudWatchLargeMessages.split,
    raiseFailedLookups: false,
    useDynamicTimeout: true,
    timeoutMultiplier: 1.2,
    dynamicTimeoutMax: const Duration(minutes: 2),
  );
}

Map<String, String> _mergedEnvironment() {
  final Map<String, String> map = <String, String>{};
  final File dotEnv = File('.env');
  if (dotEnv.existsSync()) {
    for (final String raw in dotEnv.readAsLinesSync()) {
      final String line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }
      final int eq = line.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      final String k = line.substring(0, eq).trim();
      var v = line.substring(eq + 1).trim();
      if ((v.startsWith('"') && v.endsWith('"')) ||
          (v.startsWith("'") && v.endsWith("'"))) {
        v = v.substring(1, v.length - 1);
      }
      if (k.isNotEmpty) {
        map[k] = v;
      }
    }
  }
  for (final MapEntry<String, String> e in Platform.environment.entries) {
    map[e.key] = e.value;
  }
  return map;
}

class _LiveAwsConfig {
  _LiveAwsConfig({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.region,
    this.sessionToken,
  });

  final String accessKeyId;
  final String secretAccessKey;
  final String region;
  final String? sessionToken;

  bool get isComplete =>
      accessKeyId.isNotEmpty && secretAccessKey.isNotEmpty && region.isNotEmpty;
}

_LiveAwsConfig? _readConfig(Map<String, String> env) {
  final String key = env['AWS_ACCESS_KEY_ID'] ?? '';
  final String secret =
      env['AWS_SECRET_ACCESS_KEY'] ?? env['AWS_SECRET_KEY'] ?? '';
  final String region = env['AWS_REGION'] ?? env['AWS_DEFAULT_REGION'] ?? '';
  if (key.isEmpty || secret.isEmpty || region.isEmpty) {
    return null;
  }
  final String? token = env['AWS_SESSION_TOKEN'];
  return _LiveAwsConfig(
    accessKeyId: key,
    secretAccessKey: secret,
    region: region,
    sessionToken: (token != null && token.isNotEmpty) ? token : null,
  );
}

void main() {
  final Map<String, String> env = _mergedEnvironment();
  final _LiveAwsConfig? cfg = _readConfig(env);
  final bool skip = cfg == null;

  final int runId = DateTime.now().millisecondsSinceEpoch;
  final int nonce = Random().nextInt(1 << 20);
  final String logGroupName = '/aws/flutter-aws-cloudwatch/it-$runId-$nonce';
  final String logStreamPrimary = 'it-stream-$runId-$nonce';
  final String logStreamSecondary = 'it-stream-b-$runId-$nonce';

  late final CloudWatch primary;
  late final Logger primaryLifecycle;
  late final Logger secondaryLifecycle;
  late final CloudWatchHandler handler;

  group('Live AWS CloudWatch Logs', () {
    setUpAll(() async {
      if (skip) {
        return;
      }
      final _LiveAwsConfig c = cfg;
      primary = CloudWatch(
        awsAccessKey: c.accessKeyId,
        awsSecretKey: c.secretAccessKey,
        region: c.region,
        groupName: logGroupName,
        streamName: logStreamPrimary,
        awsSessionToken: c.sessionToken,
      );
      primaryLifecycle = _liveLogger(
        c,
        groupName: logGroupName,
        streamName: logStreamPrimary,
      );
      await primaryLifecycle.createLogGroup();
      await primaryLifecycle.createLogStream();

      secondaryLifecycle = _liveLogger(
        c,
        groupName: logGroupName,
        streamName: logStreamSecondary,
      );
      await secondaryLifecycle.createLogStream();

      handler = CloudWatchHandler(
        awsAccessKey: c.accessKeyId,
        awsSecretKey: c.secretAccessKey,
        region: c.region,
        awsSessionToken: c.sessionToken,
      );
    });

    tearDownAll(() async {
      if (skip) {
        return;
      }
      try {
        await handler.deleteLogStream(
          logGroupName: logGroupName,
          logStreamName: logStreamSecondary,
        );
      } catch (_) {
        // Best-effort cleanup
      }
      try {
        await primary.deleteLogStream();
      } catch (_) {
        // Best-effort cleanup
      }
      try {
        await primary.deleteLogGroup();
      } catch (_) {
        // Best-effort cleanup
      }
    });

    test(
      'CloudWatch: log one line (PutLogEvents)',
      () async {
        await primary.log(
          'aws_cloudwatch integration ${DateTime.now().toUtc().toIso8601String()}',
        );
      },
      skip: skip
          ? 'Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, '
              'AWS_REGION (or AWS_DEFAULT_REGION); optional .env in package root'
          : false,
    );

    test(
      'CloudWatch: logMany',
      () async {
        await primary.logMany(<String>[
          'live-it many-0 ${DateTime.now().toUtc().toIso8601String()}',
          'live-it many-1 ${DateTime.now().toUtc().toIso8601String()}',
        ]);
      },
      skip: skip
          ? 'Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, '
              'AWS_REGION (or AWS_DEFAULT_REGION); optional .env in package root'
          : false,
    );

    test(
      'CloudWatch: single event at max message size (UTF-8 bytes)',
      () async {
        primary.requestTimeout = const Duration(minutes: 3);
        final String maxMsg = ''.padRight(awsMaxBytesPerMessage, 'x');
        expect(utf8.encode(maxMsg).length, awsMaxBytesPerMessage);
        await primary.log(maxMsg);
      },
      skip: skip
          ? 'Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, '
              'AWS_REGION (or AWS_DEFAULT_REGION); optional .env in package root'
          : false,
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'CloudWatchHandler: log and logMany to two streams in same group',
      () async {
        await handler.log(
          message: 'handler single ${DateTime.now().toUtc().toIso8601String()}',
          logGroupName: logGroupName,
          logStreamName: logStreamPrimary,
        );
        await handler.logMany(
          messages: <String>[
            'handler many-0 ${DateTime.now().toUtc().toIso8601String()}',
            'handler many-1 ${DateTime.now().toUtc().toIso8601String()}',
          ],
          logGroupName: logGroupName,
          logStreamName: logStreamSecondary,
        );
      },
      skip: skip
          ? 'Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, '
              'AWS_REGION (or AWS_DEFAULT_REGION); optional .env in package root'
          : false,
    );

    test(
      'Logger deleteLogStream: second delete is ignored (ResourceNotFound)',
      () async {
        final _LiveAwsConfig c = cfg!;
        final String extraStream = 'it-stream-del-$runId-$nonce';
        final Logger extra = _liveLogger(
          c,
          groupName: logGroupName,
          streamName: extraStream,
        );
        await extra.createLogStream();
        await extra.deleteLogStream();
        await extra.deleteLogStream();
      },
      skip: skip
          ? 'Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, '
              'AWS_REGION (or AWS_DEFAULT_REGION); optional .env in package root'
          : false,
    );

    test(
      'Logger deleteLogGroup: second delete is ignored (ResourceNotFound)',
      () async {
        final _LiveAwsConfig c = cfg!;
        final String soloGroup =
            '/aws/flutter-aws-cloudwatch/it-delgrp-$runId-$nonce';
        final String soloStream = 'it-s-$runId-$nonce';
        final Logger solo = _liveLogger(
          c,
          groupName: soloGroup,
          streamName: soloStream,
        );
        await solo.createLogGroup();
        await solo.createLogStream();
        await solo.deleteLogStream();
        await solo.deleteLogGroup();
        await solo.deleteLogGroup();
      },
      skip: skip
          ? 'Set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, '
              'AWS_REGION (or AWS_DEFAULT_REGION); optional .env in package root'
          : false,
    );
  });
}
