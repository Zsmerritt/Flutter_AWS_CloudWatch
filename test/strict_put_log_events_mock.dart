import 'dart:convert';

import 'package:http/http.dart';

/// Target header value for PutLogEvents (JSON API).
/// https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
const String kPutLogEventsTarget = 'Logs_20140328.PutLogEvents';

/// Optional strict validation of PutLogEvents HTTP requests against key service
/// limits. Lenient tests can omit this wrapper.
///
/// Constraints (same doc as [kPutLogEventsTarget]):
/// - Up to 10,000 log events per batch; minimum 1.
/// - Maximum 1,048,576 bytes per batch (UTF-8 body).
/// - [InputLogEvent](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_InputLogEvent.html):
///   non-empty message, timestamp (milliseconds since epoch).
Future<Response> Function(Request request) strictPutLogEventsMock({
  Future<Response> Function(Request request)? delegate,
}) {
  return (Request r) async {
    final String? target = r.headers['x-amz-target'] ?? r.headers['X-Amz-Target'];
    if (target != kPutLogEventsTarget) {
      if (delegate != null) {
        return delegate(r);
      }
      return Response('{}', 200);
    }

    final List<int> bodyBytes = utf8.encode(r.body);
    if (bodyBytes.length > 1048576) {
      return Response(
        '{"__type":"InvalidParameterException","message":"batch exceeds 1048576 bytes"}',
        400,
        headers: {'content-type': 'application/x-amz-json-1.1'},
      );
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
    for (final dynamic e in logEvents) {
      if (e is! Map<String, dynamic>) {
        return Response(
          '{"__type":"InvalidParameterException","message":"log event shape"}',
          400,
          headers: {'content-type': 'application/x-amz-json-1.1'},
        );
      }
      final dynamic msg = e['message'];
      if (msg is! String || msg.isEmpty) {
        return Response(
          '{"__type":"InvalidParameterException","message":"message min length 1"}',
          400,
          headers: {'content-type': 'application/x-amz-json-1.1'},
        );
      }
      final dynamic ts = e['timestamp'];
      if (ts is! int || ts < 0) {
        return Response(
          '{"__type":"InvalidParameterException","message":"timestamp"}',
          400,
          headers: {'content-type': 'application/x-amz-json-1.1'},
        );
      }
    }
    if (delegate != null) {
      return delegate(r);
    }
    return Response('{}', 200);
  };
}
