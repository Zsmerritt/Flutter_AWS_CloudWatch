part of 'cloudwatch.dart';

/// AWS Hard Limits
const int awsMaxByteMessageSize = 262118;
const int awsMaxByteBatchSize = 1048550;
const int awsMaxMessagePerByte = 10000;

/// A class that automatically splits and handles logs according to AWS hard limits
class CloudWatchLogStack {
  /// An enum value that indicates how messages larger than the max size should be treated
  CloudWatchLargeMessages largeMessageBehavior;

  /// CloudWatchLogStack constructor
  CloudWatchLogStack({
    this.largeMessageBehavior = CloudWatchLargeMessages.truncate,
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
    final int time = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final String msg in logStrings) {
      final List<int> bytes = utf8.encode(msg);
      // AWS hard limit on message size
      if (bytes.length <= awsMaxByteMessageSize) {
        addToStack(time, bytes);
      } else {
        fixMessage(bytes, time, msg);
      }
    }
  }

  /// Implements chosen largeMessageBehaviour
  void fixMessage(List<int> bytes, int time, String msg) {
    switch (largeMessageBehavior) {

      /// Truncate message by replacing middle with "..."
      case CloudWatchLargeMessages.truncate:
        addToStack(time, truncate(bytes));
        return;

      /// Split up large message into multiple smaller ones
      case CloudWatchLargeMessages.split:
        split(bytes).forEach((splitMessage) {
          addToStack(time, splitMessage);
        });
        return;

      /// Ignore the message
      case CloudWatchLargeMessages.ignore:
        return;

      /// Throw an error
      case CloudWatchLargeMessages.error:
        throw CloudWatchException(
          message:
              'Provided log message is too long. Individual message size limit is '
              '$awsMaxByteMessageSize. log message: $msg',
          stackTrace: StackTrace.current,
        );
    }
  }

  /// Truncates the middle of a message and replaces it with ...
  static List<int> truncate(List<int> bytes) {
    // plus 3 to account for "..."
    final double toRemove = (bytes.length + 3 - awsMaxByteMessageSize) / 2;
    final int toRemoveFront = toRemove.ceil();
    final int toRemoveBack =
        toRemove % 1 == 0 ? toRemove.ceil() : toRemove.floor();
    final int midPoint = (bytes.length / 2).floor();
    return bytes.sublist(0, midPoint - toRemoveFront) +
        // "..." in bytes (2e)
        [46, 46, 46] +
        bytes.sublist(midPoint + toRemoveBack);
  }

  /// Splits message into smaller chunks
  static List<List<int>> split(List<int> bytes) {
    List<int> newBytes = bytes;
    final List<List<int>> res = [];
    while (newBytes.length > awsMaxByteMessageSize) {
      res.add(newBytes.sublist(0, awsMaxByteMessageSize));
      newBytes = newBytes.sublist(awsMaxByteMessageSize);
    }
    if (newBytes.isNotEmpty) {
      res.add(newBytes);
    }
    return res;
  }

  /// Adds logs to the last CloudWatchLog
  ///
  /// Adds a json object of [time] and decoded [bytes] to the last CloudWatchLog
  /// on the last [logStack] Creates a new CloudWatchLog as needed.
  void addToStack(int time, List<int> bytes) {
    // empty list / aws hard limits on batch sizes
    if (logStack.isEmpty ||
        logStack.last.logs.length >= awsMaxMessagePerByte ||
        logStack.last.messageSize + bytes.length > awsMaxByteBatchSize) {
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
    final CloudWatchLog result = logStack.first;
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
