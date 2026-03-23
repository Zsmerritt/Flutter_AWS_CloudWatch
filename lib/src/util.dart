part of 'logger.dart';

/// AWS Hard Limits
const String groupNameRegexPattern = r'^[\.\-_/#A-Za-z0-9]+$';
const String streamNameRegexPattern = r'^[^:*]*$';

/// Enum representing what should happen to messages that are too big
/// to be sent as a single message. This limit is 1048550 utf8 bytes
///
/// truncate: Replace the middle of the message with "...", making it fit within
///           the max message size. This is the default value.
///
/// ignore: Ignore large messages. They will not be sent
///
/// split: Split large messages into multiple smaller messages and send them
///
/// error: Throw an error when a large message is encountered
enum CloudWatchLargeMessages {
  /// Replace the middle of the message with "...", making it fit within
  /// the max message size.
  truncate,

  /// Ignore large messages. They will not be sent
  ignore,

  /// Split large messages into multiple smaller messages and send them
  split,

  /// Throw an error when a large message is encountered
  error,
}

/// Special exception class to identify exceptions from CloudWatch
class CloudWatchException implements Exception {
  String? message;
  StackTrace? stackTrace;
  String? type;
  int? statusCode;
  String? raw;

  /// A custom error to identify CloudWatch errors more easily
  ///
  /// message: the cause of the error
  /// stackTrace: the stack trace of the error
  CloudWatchException({
    required this.message,
    required this.stackTrace,
    this.type,
    this.statusCode,
    this.raw,
  });

  /// CloudWatchException toString
  @override
  String toString() {
    final StringBuffer buffer = StringBuffer('CloudWatchException - ');
    if (statusCode != null) {
      buffer.write('statusCode: $statusCode, ');
    }
    if (type != null) {
      buffer.write('type: $type, ');
    }
    buffer.write('message: $message');
    return buffer.toString();
  }
}

bool _resourceNotFoundImpliesMissing(String? message, String resourceLower) {
  final String? m = message?.toLowerCase();
  if (m == null || m.isEmpty) {
    return false;
  }
  if (!m.contains(resourceLower)) {
    return false;
  }
  return m.contains('does not exist') ||
      m.contains('not exist') ||
      m.contains('not found');
}

/// Heuristic match for [ResourceNotFoundException](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_ResourceNotFoundException.html) when the log stream is missing.
///
/// Matches common AWS English messages (e.g. "The specified log stream does not exist.").
/// Non-English or unusual phrasing may not trigger auto-recovery.
bool resourceNotFoundMessageImpliesMissingLogStream(String? message) {
  return _resourceNotFoundImpliesMissing(message, 'log stream');
}

/// Heuristic match for ResourceNotFoundException when the log group is missing.
bool resourceNotFoundMessageImpliesMissingLogGroup(String? message) {
  return _resourceNotFoundImpliesMissing(message, 'log group');
}

/// Validates [streamName] based on aws restrictions
///
/// Throws [CloudWatchException] if bad name is found
void validateLogStreamName(String streamName) {
  validateName(
    streamName,
    'streamName',
    streamNameRegexPattern,
  );
}

/// Validates [groupName] based on aws restrictions
///
/// Throws [CloudWatchException] if bad name is found
void validateLogGroupName(String groupName) {
  validateName(
    groupName,
    'groupName',
    groupNameRegexPattern,
  );
}

/// Validates [name] to have a regex match with [pattern] and checks length requirements
void validateName(String name, String type, String pattern) {
  if (name.length > 512 || name.isEmpty) {
    throw CloudWatchException(
      message:
          'Provided $type "$name" is invalid. $type must be between 1 and 512 characters.',
      stackTrace: StackTrace.current,
    );
  }
  if (!RegExp(pattern).hasMatch(name)) {
    throw CloudWatchException(
      message:
          'Provided $type "$name" doesnt match pattern $pattern required of $type',
      stackTrace: StackTrace.current,
    );
  }
}

/// Validates [InputLogEvent](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_InputLogEvent.html)
/// shape and [PutLogEvents](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html)
/// batch rules: at least one event, each `timestamp` / `message` valid, max 24h
/// span between earliest and latest timestamp, and timestamps not more than
/// 2 hours in the future or older than 14 days relative to [nowUtc] (AWS may
/// also reject events that exceed the log group's retention; that is not
/// checked here).
///
/// Does not reorder events. Throws [CloudWatchException] when validation fails.
void validatePutLogEventsBatch(
  List<Map<String, dynamic>> logsToSend, {
  DateTime? nowUtc,
}) {
  if (logsToSend.isEmpty) {
    throw CloudWatchException(
      message:
          'PutLogEvents requires at least one log event; logEvents array '
          'cannot be empty.',
      stackTrace: StackTrace.current,
    );
  }
  int minTs = 0;
  int maxTs = 0;
  bool first = true;
  for (final Map<String, dynamic> log in logsToSend) {
    final Object? tsRaw = log['timestamp'];
    if (tsRaw is! int) {
      throw CloudWatchException(
        message:
            'PutLogEvents InputLogEvent.timestamp must be an int (milliseconds '
            'since Unix epoch). '
            'https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_InputLogEvent.html',
        stackTrace: StackTrace.current,
      );
    }
    final int ts = tsRaw;
    // InputLogEvent.timestamp — valid range minimum 0 (milliseconds since epoch).
    // https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_InputLogEvent.html
    if (ts < 0) {
      throw CloudWatchException(
        message:
            'PutLogEvents InputLogEvent.timestamp must be >= 0 (milliseconds '
            'since Unix epoch).',
        stackTrace: StackTrace.current,
      );
    }
    final DateTime now = (nowUtc ?? DateTime.now()).toUtc();
    final int maxFutureMs =
        now.millisecondsSinceEpoch + const Duration(hours: 2).inMilliseconds;
    final int minPastMs =
        now.millisecondsSinceEpoch - const Duration(days: 14).inMilliseconds;
    if (ts > maxFutureMs) {
      throw CloudWatchException(
        message:
            'PutLogEvents rejects events more than 2 hours in the future '
            '(relative to client clock). '
            'https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html',
        stackTrace: StackTrace.current,
      );
    }
    if (ts < minPastMs) {
      throw CloudWatchException(
        message:
            'PutLogEvents rejects events older than 14 days (relative to client '
            'clock) or beyond log group retention. '
            'https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html',
        stackTrace: StackTrace.current,
      );
    }
    if (first) {
      minTs = ts;
      maxTs = ts;
      first = false;
    } else {
      if (ts < minTs) {
        minTs = ts;
      }
      if (ts > maxTs) {
        maxTs = ts;
      }
    }
    final Object? msg = log['message'];
    if (msg is! String || msg.isEmpty) {
      throw CloudWatchException(
        message:
            'PutLogEvents InputLogEvent.message must be a non-empty string. '
            'https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_InputLogEvent.html',
        stackTrace: StackTrace.current,
      );
    }
  }
  if (maxTs - minTs > const Duration(hours: 24).inMilliseconds) {
    throw CloudWatchException(
      message:
          'PutLogEvents rejects batches spanning more than 24 hours between '
          'the earliest and latest event timestamp. '
          'https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html',
      stackTrace: StackTrace.current,
    );
  }
}

/// Returns a new list of the same maps sorted by `timestamp` ascending.
///
/// Call [validatePutLogEventsBatch] first so every `timestamp` is an [int].
List<Map<String, dynamic>> orderPutLogEventsBatch(
  List<Map<String, dynamic>> logsToSend,
) {
  return List<Map<String, dynamic>>.from(logsToSend)
    ..sort(
      (Map<String, dynamic> a, Map<String, dynamic> b) =>
          (a['timestamp'] as int).compareTo(b['timestamp'] as int),
    );
}

/// An aws response object class that holds common response elements
class AwsResponse {
  int statusCode;
  String? type;
  String? message;
  String? raw;

  /// Present on PutLogEvents 200 when the response includes rejection metadata.
  Map<String, dynamic>? rejectedLogEventsInfo;

  AwsResponse._(this.statusCode);

  /// True when the service reported at least one rejected log event index.
  ///
  /// See [RejectedLogEventsInfo](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_RejectedLogEventsInfo.html).
  bool get hasRejectedLogEvents {
    if (rejectedLogEventsInfo == null || rejectedLogEventsInfo!.isEmpty) {
      return false;
    }
    const List<String> keys = <String>[
      'expiredLogEventEndIndex',
      'tooNewLogEventStartIndex',
      'tooOldLogEventEndIndex',
    ];
    for (final String k in keys) {
      final dynamic v = rejectedLogEventsInfo![k];
      // RejectedLogEventsInfo indices are numbers; null/absent means no rejection.
      if (v is num) {
        return true;
      }
    }
    return false;
  }

  /// Attempts to parse aws response into its type and message parts
  static Future<AwsResponse> parseResponse(Response response) async {
    final AwsResponse result = AwsResponse._(response.statusCode);
    if (response.body.isEmpty) {
      return result;
    }
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return result;
      }
      final Map<String, dynamic> reply = decoded;
      result.raw = reply.toString();
      if (reply.containsKey('__type')) {
        result.type = reply['__type'] as String?;
      }
      if (reply.containsKey('message')) {
        result.message = reply['message'] as String?;
      }
      if (reply.containsKey('rejectedLogEventsInfo')) {
        final dynamic info = reply['rejectedLogEventsInfo'];
        if (info is Map<String, dynamic>) {
          result.rejectedLogEventsInfo = info;
        }
      }
    } catch (_) {
      // Malformed JSON; leave minimal AwsResponse.
    }
    return result;
  }

  /// AwsResponse toString
  @override
  String toString() {
    final StringBuffer sb =
        StringBuffer('AwsResponse - statusCode: $statusCode');
    if (type != null) {
      sb.write(', type: $type');
    }
    if (message != null) {
      sb.write(', message: $message');
    }
    return sb.toString();
  }
}
