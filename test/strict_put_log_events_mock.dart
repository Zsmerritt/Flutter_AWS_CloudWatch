import 'dart:convert';

import 'package:aws_cloudwatch/src/logger.dart';
import 'package:http/http.dart';

/// PutLogEvents batch byte limit: sum of UTF-8 message lengths + 26 per event.
/// https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
int putLogEventsLogicalBatchByteLength(List<dynamic> logEvents) {
  int total = 0;
  for (final dynamic e in logEvents) {
    if (e is! Map<String, dynamic>) {
      continue;
    }
    final dynamic msg = e['message'];
    if (msg is! String) {
      continue;
    }
    total += utf8.encode(msg).length + 26;
  }
  return total;
}

/// Target header value for PutLogEvents (JSON API).
/// https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
const String kPutLogEventsTarget = 'Logs_20140328.PutLogEvents';

/// Optional strict validation of PutLogEvents HTTP requests against key service
/// limits. Lenient tests can omit this wrapper.
///
/// Constraints (same doc as [kPutLogEventsTarget]):
/// - Up to 10,000 log events per batch; minimum 1.
/// - Maximum 1,048,576 bytes per batch: sum of UTF-8 message lengths + 26 per event
///   (not raw JSON body length).
/// - [InputLogEvent](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_InputLogEvent.html):
///   non-empty message, timestamp (milliseconds since epoch).
Future<Response> Function(Request request) strictPutLogEventsMock({
  Future<Response> Function(Request request)? delegate,
}) {
  return (Request r) async {
    final String? target =
        r.headers['x-amz-target'] ?? r.headers['X-Amz-Target'];
    if (target != kPutLogEventsTarget) {
      if (delegate != null) {
        return delegate(r);
      }
      return Response('{}', 200);
    }

    final Object? decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      if (delegate != null) {
        return delegate(r);
      }
      return Response('{}', 200);
    }
    final Map<String, dynamic> map = decoded;
    final dynamic logEvents = map['logEvents'];
    if (logEvents is! List<dynamic>) {
      if (delegate != null) {
        return delegate(r);
      }
      return Response('{}', 200);
    }
    if (logEvents.isEmpty || logEvents.length > 10000) {
      return Response(
        '{"__type":"InvalidParameterException","message":"logEvents batch size"}',
        400,
        headers: {'content-type': 'application/x-amz-json-1.1'},
      );
    }
    final List<Map<String, dynamic>> batch = <Map<String, dynamic>>[];
    for (final dynamic e in logEvents) {
      if (e is Map<String, dynamic>) {
        batch.add(e);
      } else {
        return Response(
          '{"__type":"InvalidParameterException","message":"log event shape"}',
          400,
          headers: {'content-type': 'application/x-amz-json-1.1'},
        );
      }
    }
    try {
      validatePutLogEventsBatch(batch);
    } on CloudWatchException catch (e) {
      return Response(
        jsonEncode(<String, dynamic>{
          '__type': 'InvalidParameterException',
          'message': e.message ?? 'validation failed',
        }),
        400,
        headers: {'content-type': 'application/x-amz-json-1.1'},
      );
    }
    if (putLogEventsLogicalBatchByteLength(logEvents) > 1048576) {
      return Response(
        '{"__type":"InvalidParameterException","message":"batch exceeds logical 1048576 byte limit (messages UTF-8 + 26 per event)"}',
        400,
        headers: {'content-type': 'application/x-amz-json-1.1'},
      );
    }
    if (delegate != null) {
      return delegate(r);
    }
    return Response('{}', 200);
  };
}
