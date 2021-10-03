import 'dart:convert';

import 'aws_cloudwatch.dart';
import 'aws_cloudwatch_cloudwatch_log.dart';
import 'aws_cloudwatch_util.dart';

/// AWS Hard Limits
const int _AWS_MAX_BYTE_MESSAGE_SIZE = 262118;
const int _AWS_MAX_BYTE_BATCH_SIZE = 1048550;
const int _AWS_MAX_MESSAGES_PER_BATCH = 10000;

/// A class that automatically splits and handles logs according to AWS hard limits
class CloudWatchLogStack {
  /// An enum value that indicates how messages larger than the max size should be treated
  CloudWatchLargeMessages largeMessageBehavior;

  /// CloudWatchLogStack constructor
  CloudWatchLogStack({
    required this.largeMessageBehavior,
  });

  /// The stack of logs that holds presplt CloudWatchLogs
  List<CloudWatchLog> logStack = [];

  /// The length of the stack
  int get length => logStack.length;

  /// Splits up [logStrings] and processes them in prep to add them to the [logStack]
  ///
  /// Prepares [logStrings] using selected [largeMessageBehavior] as needed
  /// taking care to mind aws hard limits.
  void addLogs(List<String> logStrings) {
    int time = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (String msg in logStrings) {
      List<int> bytes = utf8.encode(msg);
      // AWS hard limit on message size
      if (bytes.length <= _AWS_MAX_BYTE_MESSAGE_SIZE) {
        addToStack(time, bytes);
      } else {
        switch (largeMessageBehavior) {

          /// Truncate message by replacing middle with "..."
          case CloudWatchLargeMessages.truncate:
            // plus 3 to account for "..."
            int toRemove =
                ((bytes.length - _AWS_MAX_BYTE_MESSAGE_SIZE + 3) / 2).ceil();
            int midPoint = (bytes.length / 2).floor();
            List<int> newMessage = bytes.sublist(0, midPoint - toRemove) +
                // "..." in bytes (2e)
                [46, 46, 46] +
                bytes.sublist(midPoint + toRemove);
            addToStack(time, newMessage);
            break;

          /// Split up large message into multiple smaller ones
          case CloudWatchLargeMessages.split:
            while (bytes.length > _AWS_MAX_BYTE_MESSAGE_SIZE) {
              addToStack(
                time,
                bytes.sublist(0, _AWS_MAX_BYTE_MESSAGE_SIZE),
              );
              bytes = bytes.sublist(_AWS_MAX_BYTE_MESSAGE_SIZE);
            }
            addToStack(time, bytes);
            break;

          /// Ignore the message
          case CloudWatchLargeMessages.ignore:
            continue;

          /// Throw an error
          case CloudWatchLargeMessages.error:
            throw CloudWatchException(
              message:
                  'Provided log message is too long. Individual message size limit is '
                  '$_AWS_MAX_BYTE_MESSAGE_SIZE. log message: $msg',
              stackTrace: StackTrace.current,
            );
        }
      }
    }
  }

  /// Adds logs to the last CloudWatchLog
  ///
  /// Adds a json object of [time] and decoded [bytes] to the last CloudWatchLog
  /// on the last [logStack] Creates a new CloudWatchLog as needed.
  void addToStack(int time, List<int> bytes) {
    // empty list / aws hard limits on batch sizes
    if (logStack.length == 0 ||
        logStack.last.logs.length >= _AWS_MAX_MESSAGES_PER_BATCH ||
        logStack.last.messageSize + bytes.length > _AWS_MAX_BYTE_BATCH_SIZE) {
      logStack.add(
        CloudWatchLog(
          logs: [
            {
              'timestamp': time,
              'message': utf8.decode(bytes),
            },
          ],
          messageSize: bytes.length,
        ),
      );
    } else {
      logStack.last.addLog(
        log: {'timestamp': time, 'message': utf8.decode(bytes)},
        size: bytes.length,
      );
    }
  }

  /// Pops off first CloudWatchLog from the [logStack] and returns it
  CloudWatchLog pop() {
    CloudWatchLog result = logStack.first;
    if (logStack.length > 1) {
      logStack = logStack.sublist(1);
    } else {
      logStack.clear();
    }
    return result;
  }

  /// Prepends a CloudWatchLog to the [logStack]
  void prepend(CloudWatchLog messages) {
    // this is the fastest prepend until ~1700 items
    logStack = [messages, ...logStack];
  }
}
