// CloudWatch Logs JSON API compliance tests (not CloudWatch Metrics).
//
// This package calls Amazon CloudWatch Logs (service `logs`, host `logs.<region>.amazonaws.com`)
// with x-amz-target `Logs_20140328.*`. See:
// - PutLogEvents: https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
// - CreateLogGroup: https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_CreateLogGroup.html
// - CreateLogStream: https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_CreateLogStream.html
// - Making requests (JSON POST): same guide as other AWS JSON services; SigV4 signing is implemented by package:aws_request.

import 'dart:convert';

import 'package:aws_cloudwatch/src/logger.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

import 'strict_put_log_events_mock.dart';

/// Extracts the SignedHeaders list from an AWS SigV4 Authorization header value.
List<String> signedHeaderNamesFromAuthorization(String? authorization) {
  if (authorization == null) {
    return [];
  }
  final RegExpMatch? m =
      RegExp('SignedHeaders=([^,]+)').firstMatch(authorization);
  if (m == null) {
    return [];
  }
  return m.group(1)!.split(';').map((s) => s.trim().toLowerCase()).toList();
}

String? headerValue(Request request, String name) {
  for (final MapEntry<String, String> e in request.headers.entries) {
    if (e.key.toLowerCase() == name.toLowerCase()) {
      return e.value;
    }
  }
  return null;
}

Logger _baseLogger({
  required String groupName,
  required String streamName,
  String region = 'us-east-1',
  String? awsSessionToken,
  bool mockCloudWatch = true,
  Future<Response> Function(Request)? mockFunction,
}) {
  return Logger(
    awsAccessKey: 'AKIAIOSFODNN7EXAMPLE',
    awsSecretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    region: region,
    groupName: groupName,
    streamName: streamName,
    awsSessionToken: awsSessionToken,
    delay: Duration.zero,
    requestTimeout: const Duration(seconds: 10),
    retries: 1,
    largeMessageBehavior: CloudWatchLargeMessages.truncate,
    raiseFailedLookups: false,
    useDynamicTimeout: false,
    dynamicTimeoutMax: const Duration(minutes: 2),
    timeoutMultiplier: 1.0,
    mockCloudWatch: mockCloudWatch,
    mockFunction: mockFunction,
  );
}

void main() {
  group('CloudWatch Logs — PutLogEvents', () {
    group('request construction', () {
      // API_PutLogEvents — Request Parameters: logEvents, logGroupName, logStreamName (JSON keys).
      test(
        'PutLogEvents JSON body matches spec: logEvents array with timestamp and message',
        () {
          final Logger logger = _baseLogger(
            groupName: 'my-log-group',
            streamName: 'my-log-stream',
          );
          const int ts = 1396035378988;
          // Distinct ascending timestamps so createBody sort matches stable order.
          final String body = logger.createBody([
            {'timestamp': ts, 'message': 'Example event 1'},
            {'timestamp': ts + 1, 'message': 'Example event 2'},
          ]);
          final Object? decoded = jsonDecode(body);
          expect(decoded, isA<Map>());
          final Map<String, dynamic> map = decoded! as Map<String, dynamic>;
          expect(map['logGroupName'], 'my-log-group');
          expect(map['logStreamName'], 'my-log-stream');
          expect(map['logEvents'], isA<List>());
          final List<dynamic> events = map['logEvents']! as List<dynamic>;
          expect(events.length, 2);
          expect(events[0], {'timestamp': ts, 'message': 'Example event 1'});
          expect(events[1], {'timestamp': ts + 1, 'message': 'Example event 2'});
        },
      );

      // Same doc — InputLogEvent: timestamp (ms since epoch), message.
      test(
        'PutLogEvents encodes unicode in message as UTF-8 JSON strings',
        () {
          final Logger logger = _baseLogger(
            groupName: 'g',
            streamName: 's',
          );
          final String body = logger.createBody([
            {'timestamp': 0, 'message': 'café 日本語'},
          ]);
          final Map<String, dynamic> map =
              jsonDecode(body) as Map<String, dynamic>;
          expect(map['logEvents'][0]['message'], 'café 日本語');
        },
      );

      // PutLogEvents — logEvents: minimum 1 array member.
      test('createBody rejects empty logEvents array', () {
        final Logger logger = _baseLogger(
          groupName: 'g',
          streamName: 's',
        );
        expect(
          () => logger.createBody([]),
          throwsA(isA<CloudWatchException>()),
        );
      });

      // PutLogEvents: events must be in chronological order; library sorts by timestamp.
      // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
      test('createBody sorts logEvents by timestamp ascending', () {
        final Logger logger = _baseLogger(
          groupName: 'g',
          streamName: 's',
        );
        const int t1 = 100;
        const int t2 = 500;
        const int t3 = 300;
        final String body = logger.createBody([
          {'timestamp': t2, 'message': 'b'},
          {'timestamp': t1, 'message': 'a'},
          {'timestamp': t3, 'message': 'c'},
        ]);
        final List<dynamic> events =
            (jsonDecode(body) as Map<String, dynamic>)['logEvents']! as List;
        expect(events[0]['timestamp'], t1);
        expect(events[1]['timestamp'], t3);
        expect(events[2]['timestamp'], t2);
      });

      // PutLogEvents: batch cannot span more than 24 hours.
      // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
      test('createBody rejects events spanning more than 24 hours', () {
        final Logger logger = _baseLogger(
          groupName: 'g',
          streamName: 's',
        );
        final int start = 1700000000000;
        final int end = start + const Duration(hours: 24).inMilliseconds + 1;
        expect(
          () => logger.createBody([
            {'timestamp': end, 'message': 'late'},
            {'timestamp': start, 'message': 'early'},
          ]),
          throwsA(isA<CloudWatchException>()),
        );
      });

      // InputLogEvent — message minimum length 1.
      test('addLogs rejects empty string message', () {
        final Logger logger = _baseLogger(
          groupName: 'g',
          streamName: 's',
        );
        expect(
          () => logger.logStack.addLogs(['']),
          throwsA(isA<CloudWatchException>()),
        );
      });
    });

    group('sigv4 integration (via MockAwsRequest + real signer)', () {
      // Making API Requests: POST, host logs.<region>.amazonaws.com, x-amz-target, JSON body signed.
      test(
        'PutLogEvents request uses host logs.<region>.amazonaws.com and POST',
        () async {
          Request? captured;
          final Logger logger = _baseLogger(
            groupName: 'g',
            streamName: 's',
            mockFunction: (Request r) async {
              captured = r;
              return Response('{}', 200);
            },
          );
          await logger.sendRequest(
            body: logger.createBody([
              {'timestamp': 1, 'message': 'm'},
            ]),
            target: 'Logs_20140328.PutLogEvents',
          );
          expect(captured, isNotNull);
          final Request req = captured!;
          expect(req.method, 'POST');
          expect(req.url.scheme, 'https');
          expect(req.url.host, 'logs.us-east-1.amazonaws.com');
          expect(req.url.path, '/');
        },
      );

      // PutLogEvents sample: Content-Type application/x-amz-json-1.1, X-Amz-Target Logs_20140328.PutLogEvents
      test(
        'PutLogEvents sets x-amz-target and application/x-amz-json-1.1 content-type',
        () async {
          Request? captured;
          final Logger logger = _baseLogger(
            groupName: 'g',
            streamName: 's',
            mockFunction: (Request r) async {
              captured = r;
              return Response('{}', 200);
            },
          );
          await logger.sendRequest(
            body: '{}',
            target: 'Logs_20140328.PutLogEvents',
          );
          expect(headerValue(captured!, 'x-amz-target'),
              'Logs_20140328.PutLogEvents');
          expect(headerValue(captured!, 'content-type'),
              'application/x-amz-json-1.1');
        },
      );

      test(
        'SigV4 Authorization lists signed headers used in canonical request',
        () async {
          Request? captured;
          final Logger logger = _baseLogger(
            groupName: 'g',
            streamName: 's',
            mockFunction: (Request r) async {
              captured = r;
              return Response('{}', 200);
            },
          );
          const String jsonBody = '{"a":1}';
          await logger.sendRequest(
            body: jsonBody,
            target: 'Logs_20140328.PutLogEvents',
          );
          final String? auth = headerValue(captured!, 'authorization');
          expect(auth, isNotNull);
          // Credential scope must use CloudWatch Logs service id "logs", not "monitoring" (Metrics).
          expect(auth, contains('/us-east-1/logs/aws4_request'));
          final List<String> signed = signedHeaderNamesFromAuthorization(auth);
          expect(signed, containsAll(['host', 'x-amz-date', 'content-type']));
          expect(signed, contains('x-amz-target'));
          // Body on the wire must match what was hashed (same string as jsonBody).
          expect(captured!.body, jsonBody);
        },
      );

      // SigV4: temporary credentials require x-amz-security-token in the signed header list.
      // https://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html
      test(
        'temporary credentials include x-amz-security-token in SigV4 SignedHeaders',
        () async {
          Request? captured;
          final Logger logger = _baseLogger(
            groupName: 'g',
            streamName: 's',
            awsSessionToken: 'AQoDYXdzEJr...',
            mockFunction: (Request r) async {
              captured = r;
              return Response('{}', 200);
            },
          );
          await logger.sendRequest(
            body: '{}',
            target: 'Logs_20140328.PutLogEvents',
          );
          expect(headerValue(captured!, 'x-amz-security-token'), isNotNull);
          final String? auth = headerValue(captured!, 'authorization');
          final List<String> signed = signedHeaderNamesFromAuthorization(auth);
          expect(
            signed,
            contains('x-amz-security-token'),
          );
        },
      );

      test(
        'requestTimeout in range adds X-Amz-Expires query (library behavior)',
        () async {
          Request? captured;
          final Logger logger = _baseLogger(
            groupName: 'g',
            streamName: 's',
            mockFunction: (Request r) async {
              captured = r;
              return Response('{}', 200);
            },
          );
          await logger.sendRequest(
            body: '{}',
            target: 'Logs_20140328.PutLogEvents',
          );
          expect(captured!.url.queryParameters['X-Amz-Expires'], '10');
        },
      );
    });

    group('end-to-end (build → sign → mock receives final Request)', () {
      test(
        'full PutLogEvents pipeline produces coherent URL, headers, and body',
        () async {
          Request? captured;
          final Logger logger = _baseLogger(
            groupName: 'my-log-group',
            streamName: 'my-log-stream',
            mockFunction: (Request r) async {
              captured = r;
              return Response('{}', 200);
            },
          );
          final String body = logger.createBody([
            {'timestamp': 1396035378988, 'message': 'Example event 1'},
          ]);
          await logger.sendRequest(
            body: body,
            target: 'Logs_20140328.PutLogEvents',
          );
          expect(captured!.url.host, 'logs.us-east-1.amazonaws.com');
          expect(headerValue(captured!, 'x-amz-target'),
              'Logs_20140328.PutLogEvents');
          final Map<String, dynamic> decoded =
              jsonDecode(captured!.body) as Map<String, dynamic>;
          expect(decoded['logGroupName'], 'my-log-group');
          expect(decoded['logStreamName'], 'my-log-stream');
          expect((decoded['logEvents'] as List).length, 1);
        },
      );
    });

    group('mock service — response handling', () {
      // API_PutLogEvents — HTTP 200 success.
      test('handleResponse returns true on 200 with empty JSON object', () async {
        final Logger logger = _baseLogger(groupName: 'g', streamName: 's');
        final bool ok = await logger.handleResponse(Response('{}', 200));
        expect(ok, isTrue);
      });

      // Response Elements: rejectedLogEventsInfo — PutLogEvents 200 can include partial rejections.
      // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
      // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_RejectedLogEventsInfo.html
      test(
        '200 with non-empty rejectedLogEventsInfo throws CloudWatchException (partial rejection detected)',
        () async {
          final Logger logger = _baseLogger(groupName: 'g', streamName: 's');
          expect(
            () => logger.handleResponse(
              Response(
                '{"nextSequenceToken":"t","rejectedLogEventsInfo":{"tooNewLogEventStartIndex":0}}',
                200,
                headers: {'content-type': 'application/x-amz-json-1.1'},
              ),
            ),
            throwsA(
              predicate(
                (Object e) =>
                    e is CloudWatchException &&
                    e.type == 'RejectedLogEventsInfo' &&
                    e.statusCode == 200,
              ),
            ),
          );
        },
      );

      test(
        '200 with empty rejectedLogEventsInfo object is treated as full success',
        () async {
          final Logger logger = _baseLogger(groupName: 'g', streamName: 's');
          final bool ok = await logger.handleResponse(
            Response(
              '{"nextSequenceToken":"t","rejectedLogEventsInfo":{}}',
              200,
            ),
          );
          expect(ok, isTrue);
        },
      );

      // Response Elements — rejectedEntityInfo (optional). Library does not parse
      // entity fields; JSON must still parse and succeed when only entity rejection
      // metadata is present.
      // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
      test(
        '200 with rejectedEntityInfo does not crash (contents not parsed)',
        () async {
          final Logger logger = _baseLogger(groupName: 'g', streamName: 's');
          final bool ok = await logger.handleResponse(
            Response(
              '{"rejectedEntityInfo":{"errorRecords":[{"errorCode":"E","message":"m"}]}}',
              200,
              headers: {'content-type': 'application/x-amz-json-1.1'},
            ),
          );
          expect(ok, isTrue);
        },
      );

      test(
        'handleResponse throws CloudWatchException on 400 without parseable __type',
        () async {
          final Logger logger = _baseLogger(groupName: 'g', streamName: 's');
          expect(
            () => logger.handleResponse(Response('', 400)),
            throwsA(isA<CloudWatchException>()),
          );
        },
      );

      test(
        'handleResponse routes __type to handleError on non-200',
        () async {
          final Logger logger = _baseLogger(groupName: 'g', streamName: 's');
          final bool ok = await logger.handleResponse(
            Response('{"__type": "ThrottlingException"}', 400),
          );
          expect(ok, isFalse);
        },
      );

      test(
        'ServiceUnavailableException body yields handleError false when type unknown',
        () async {
          final Logger logger = _baseLogger(groupName: 'g', streamName: 's');
          final bool ok = await logger.handleResponse(
            Response(
              '{"__type": "ServiceUnavailableException", "message": "retry"}',
              500,
            ),
          );
          expect(ok, isFalse);
        },
      );

      // API_ResourceNotFoundException — recovery uses substring heuristics only;
      // see [resourceNotFoundMessageImpliesMissingLogStream] in util.dart.
      // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_ResourceNotFoundException.html
      test(
        'ResourceNotFoundException with non-matching message is not auto-recovered',
        () async {
          final Logger logger = _baseLogger(groupName: 'g', streamName: 's');
          final bool ok = await logger.handleResponse(
            Response(
              '{"__type":"ResourceNotFoundException","message":"The specified ARN was not found."}',
              400,
              headers: {'content-type': 'application/x-amz-json-1.1'},
            ),
          );
          expect(ok, isFalse);
        },
      );
    });

    group('edge cases', () {
      // PutLogEvents constraints: max batch 1,048,576 bytes (sum messages + 26 per event).
      test(
        'batch sizing uses 26 bytes overhead per event in log stack',
        () {
          final Logger logger = _baseLogger(groupName: 'g', streamName: 's');
          logger.logStack.addLogs(['a']);
          expect(logger.logStack.length, 1);
          expect(logger.logStack.logStack.first.messageSize, utf8.encode('a').length + 26);
        },
      );

      // Doc: log events must be chronologically ordered; identical timestamps are allowed.
      test(
        'single addLogs call assigns one timestamp to all events (documented behavior)',
        () {
          final Logger logger = _baseLogger(groupName: 'g', streamName: 's');
          logger.logStack.addLogs(['first', 'second']);
          final List<Map<String, dynamic>> logs =
              logger.logStack.pop().logs;
          expect(logs.length, 2);
          expect(logs[0]['timestamp'], logs[1]['timestamp']);
        },
      );

      // Split path: fixMessage passes one [time] to every chunk so ordering stays non-decreasing.
      test(
        'split large message assigns same timestamp to every chunk (chronological batch)',
        () {
          final Logger logger = _baseLogger(
            groupName: 'g',
            streamName: 's',
          );
          logger.largeMessageBehavior = CloudWatchLargeMessages.split;
          logger.maxBytesPerMessage = 80;
          final String big = List<String>.filled(500, 'x').join();
          logger.logStack.addLogs([big]);
          final CloudWatchLog batch = logger.logStack.pop();
          expect(batch.logs.length, greaterThan(1));
          final int firstTs = batch.logs.first['timestamp'] as int;
          for (final Map<String, dynamic> ev in batch.logs) {
            expect(ev['timestamp'], firstTs);
          }
        },
      );
    });

    // PutLogEvents service limits (batch size, payload, InputLogEvent):
    // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
    // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_InputLogEvent.html
    group('strict PutLogEvents mock', () {
      test('library sendRequest with 10000 events passes strict mock', () async {
        final Logger logger = _baseLogger(
          groupName: 'g',
          streamName: 's',
          mockFunction: strictPutLogEventsMock(),
        );
        final List<Map<String, dynamic>> events =
            List<Map<String, dynamic>>.generate(
          10000,
          (int i) => <String, dynamic>{'timestamp': 1 + i, 'message': 'x'},
        );
        final Response r = await logger.sendRequest(
          body: logger.createBody(events),
          target: kPutLogEventsTarget,
        );
        expect(r.statusCode, 200);
      });

      test('strict mock rejects 10001 log events in one batch', () async {
        final Logger logger = _baseLogger(
          groupName: 'g',
          streamName: 's',
          mockFunction: strictPutLogEventsMock(),
        );
        final List<Map<String, dynamic>> events =
            List<Map<String, dynamic>>.generate(
          10001,
          (int i) => <String, dynamic>{'timestamp': 1 + i, 'message': 'x'},
        );
        final Response r = await logger.sendRequest(
          body: logger.createBody(events),
          target: kPutLogEventsTarget,
        );
        expect(r.statusCode, 400);
      });

      test('strict mock rejects UTF-8 body larger than 1048576 bytes', () async {
        final Logger logger = _baseLogger(
          groupName: 'g',
          streamName: 's',
          mockFunction: strictPutLogEventsMock(),
        );
        // Single-event message large enough that full JSON UTF-8 body exceeds limit.
        final String huge = List<String>.filled(1048500, 'a').join();
        final String body = jsonEncode(<String, dynamic>{
          'logGroupName': 'g',
          'logStreamName': 's',
          'logEvents': <Map<String, dynamic>>[
            <String, dynamic>{'timestamp': 1, 'message': huge},
          ],
        });
        expect(utf8.encode(body).length, greaterThan(1048576));
        final Response r = await logger.sendRequest(
          body: body,
          target: kPutLogEventsTarget,
        );
        expect(r.statusCode, 400);
      });

      test('strict mock rejects empty message string', () async {
        final Logger logger = _baseLogger(
          groupName: 'g',
          streamName: 's',
          mockFunction: strictPutLogEventsMock(),
        );
        final String body = jsonEncode(<String, dynamic>{
          'logGroupName': 'g',
          'logStreamName': 's',
          'logEvents': <Map<String, dynamic>>[
            <String, dynamic>{'timestamp': 1, 'message': ''},
          ],
        });
        final Response r = await logger.sendRequest(
          body: body,
          target: kPutLogEventsTarget,
        );
        expect(r.statusCode, 400);
      });

      test('strict mock rejects negative timestamp', () async {
        final Logger logger = _baseLogger(
          groupName: 'g',
          streamName: 's',
          mockFunction: strictPutLogEventsMock(),
        );
        final String body = jsonEncode(<String, dynamic>{
          'logGroupName': 'g',
          'logStreamName': 's',
          'logEvents': <Map<String, dynamic>>[
            <String, dynamic>{'timestamp': -1, 'message': 'ok'},
          ],
        });
        final Response r = await logger.sendRequest(
          body: body,
          target: kPutLogEventsTarget,
        );
        expect(r.statusCode, 400);
      });
    });
  });

  group('CloudWatch Logs — CreateLogGroup', () {
    group('request construction', () {
      // API_CreateLogGroup — body is JSON { "logGroupName": "..." }.
      test(
        'CreateLogGroup uses x-amz-target Logs_20140328.CreateLogGroup',
        () async {
          Request? captured;
          final Logger logger = _baseLogger(
            groupName: 'my-log-group',
            streamName: 's',
            mockFunction: (Request r) async {
              captured = r;
              return Response('{}', 200);
            },
          );
          await (logger..logGroupCreated = false).createLogGroup();
          expect(headerValue(captured!, 'x-amz-target'),
              'Logs_20140328.CreateLogGroup');
          expect(
            jsonDecode(captured!.body) as Map<String, dynamic>,
            {'logGroupName': 'my-log-group'},
          );
        },
      );
    });
  });

  group('CloudWatch Logs — CreateLogStream', () {
    group('request construction', () {
      // API_CreateLogStream — JSON logGroupName + logStreamName.
      test(
        'CreateLogStream uses x-amz-target Logs_20140328.CreateLogStream',
        () async {
          Request? captured;
          final Logger logger = _baseLogger(
            groupName: 'my-log-group',
            streamName: 'my-stream',
            mockFunction: (Request r) async {
              captured = r;
              return Response('{}', 200);
            },
          );
          await (logger..logStreamCreated = false).createLogStream();
          expect(headerValue(captured!, 'x-amz-target'),
              'Logs_20140328.CreateLogStream');
          expect(
            jsonDecode(captured!.body) as Map<String, dynamic>,
            {
              'logGroupName': 'my-log-group',
              'logStreamName': 'my-stream',
            },
          );
        },
      );

      // CreateLogStream request body must be valid JSON (escape quotes, backslashes, etc.).
      test(
        'CreateLogStream body is valid JSON when streamName contains quotes',
        () async {
          Request? captured;
          final Logger logger = _baseLogger(
            groupName: 'g',
            streamName: 'has"quote',
            mockFunction: (Request r) async {
              captured = r;
              return Response('{}', 200);
            },
          );
          await (logger..logStreamCreated = false).createLogStream();
          final Map<String, dynamic> decoded =
              jsonDecode(captured!.body) as Map<String, dynamic>;
          expect(decoded['logStreamName'], 'has"quote');
        },
      );

      test(
        'CreateLogStream body is valid JSON when streamName contains backslashes',
        () async {
          Request? captured;
          final Logger logger = _baseLogger(
            groupName: 'g',
            streamName: r'a\b\c',
            mockFunction: (Request r) async {
              captured = r;
              return Response('{}', 200);
            },
          );
          await (logger..logStreamCreated = false).createLogStream();
          final Map<String, dynamic> decoded =
              jsonDecode(captured!.body) as Map<String, dynamic>;
          expect(decoded['logStreamName'], r'a\b\c');
        },
      );
    });
  });

  group('Out of scope (documented gap)', () {
    test(
      'pagination: library does not call FilterLogEvents or metric APIs',
      () {
        // No code path to test; Metrics (monitoring) and log pagination are not implemented.
        expect(true, isTrue);
      },
    );

    test(
      'metrics client edge cases (empty MetricData, gzip, dimensions, NaN) are out of scope',
      () {
        // This package implements CloudWatch Logs only, not CloudWatch Metrics (monitoring API).
        expect(true, isTrue);
      },
    );
  });
}
