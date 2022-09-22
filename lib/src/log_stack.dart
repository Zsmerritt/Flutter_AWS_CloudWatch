part of 'logger.dart';

/// Package Limits
// Accounts for 10 digit hash and up to 9999 split messages
const int splitMessageOverheadBytes = 21;

/// AWS Hard Limits
const int awsMaxBytesPerMessage = 262116;
const int awsMinBytesPerMessage = splitMessageOverheadBytes + 1;
const int awsMaxBytesPerRequest = 1048576;
const int awsMinBytesPerRequest = 1;
const int awsMaxMessagesPerRequest = 10000;
const int awsMinMessagesPerRequest = 1;

/// A class that automatically splits and handles logs according to AWS hard limits
class CloudWatchLogStack {
  /// An enum value that indicates how messages larger than the max size should be treated
  CloudWatchLargeMessages largeMessageBehavior;

  /// Changes how large each message can be before [largeMessageBehavior] takes
  /// effect. Min 5, Max 262116
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxBytesPerMessage => _maxBytesPerMessage;

  set maxBytesPerMessage(int val) => _maxBytesPerMessage = boundValue(
        val: val,
        maxVal: awsMaxBytesPerMessage,
        minVal: awsMinBytesPerMessage,
      );

  /// private maxBytesPerMessage
  int _maxBytesPerMessage;

  /// Changes how many bytes can be sent in each API request before a second
  /// request is made. Min 1, Max 1048576
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxBytesPerRequest => _maxBytesPerRequest;

  set maxBytesPerRequest(int val) => _maxBytesPerRequest = boundValue(
        val: val,
        maxVal: awsMaxBytesPerRequest,
        minVal: awsMinBytesPerRequest,
      );

  /// private maxBytesPerRequest
  int _maxBytesPerRequest;

  /// Changes the maximum number of messages that can be sent in each API
  /// request. Min 1, Max 10000
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxMessagesPerRequest => _maxMessagesPerRequest;

  set maxMessagesPerRequest(int val) => _maxMessagesPerRequest = boundValue(
        val: val,
        maxVal: awsMaxMessagesPerRequest,
        minVal: awsMinMessagesPerRequest,
      );

  /// private maxMessagesPerRequest
  int _maxMessagesPerRequest;

  /// CloudWatchLogStack constructor
  CloudWatchLogStack({
    this.largeMessageBehavior = CloudWatchLargeMessages.split,
    int maxBytesPerMessage = awsMaxBytesPerMessage,
    int maxBytesPerRequest = awsMaxBytesPerRequest,
    int maxMessagesPerRequest = awsMaxMessagesPerRequest,
  })  : _maxBytesPerMessage = boundValue(
          val: maxBytesPerMessage,
          maxVal: awsMaxBytesPerMessage,
          minVal: awsMinBytesPerMessage,
        ),
        _maxBytesPerRequest = boundValue(
          val: maxBytesPerRequest,
          maxVal: awsMaxBytesPerRequest,
          minVal: awsMinBytesPerRequest,
        ),
        _maxMessagesPerRequest = boundValue(
          val: maxMessagesPerRequest,
          maxVal: awsMaxMessagesPerRequest,
          minVal: awsMinMessagesPerRequest,
        );

  /// The stack of logs that holds pre-split CloudWatchLogs
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
      if (bytes.length <= maxBytesPerMessage) {
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
              '$maxBytesPerMessage. log message: $msg',
          stackTrace: StackTrace.current,
        );
    }
  }

  /// Truncates the middle of a message and replaces it with ...
  List<int> truncate(List<int> bytes) {
    // plus 3 to account for "..."
    final double toRemove = (bytes.length + 3 - maxBytesPerMessage) / 2;
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
  List<List<int>> split(List<int> bytes) {
    final int messageSize = maxBytesPerMessage - splitMessageOverheadBytes;
    final int numMessages = (bytes.length / messageSize).ceil();

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    // grab first 10 of hash. used to collate messages
    final String hash =
        sha1.convert(bytes + [timestamp]).toString().substring(0, 10);
    final List<List<int>> res = [];
    final String paddedTotal = numMessages.toString().padLeft(4, '0');
    int startIndex = 0;
    for (int x = 0; x < numMessages; x++) {
      final String paddedCurrent = (x + 1).toString().padLeft(4, '0');
      final List<int> prefix = utf8.encode(
        '$hash $paddedCurrent/$paddedTotal:',
      );
      final int newMessageSize = min(messageSize, bytes.length - startIndex);
      res.add(prefix + bytes.sublist(startIndex, startIndex + newMessageSize));
      startIndex += newMessageSize;
    }
    return res;
  }

  /// Adds logs to the last CloudWatchLog
  ///
  /// Adds a json object of [time] and decoded [bytes] to the last CloudWatchLog
  /// on the last [logStack] Creates a new CloudWatchLog as needed.
  void addToStack(int time, List<int> bytes) {
    final Map<String, dynamic> log = {
      'timestamp': time,
      'message': utf8.decode(bytes),
    };
    // each message has 26 bytes overhead as per documentation
    final int logSize = bytes.length + 26;
    // empty list / aws hard limits on batch sizes
    if (logStack.isEmpty ||
        logStack.last.logs.length >= maxMessagesPerRequest ||
        logStack.last.messageSize + logSize > maxBytesPerRequest) {
      logStack.add(CloudWatchLog(logs: [log], messageSize: logSize));
    } else {
      logStack.last.addLog(log: log, size: logSize);
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

  /// Returns an int that has been bounded between [minVal] and [maxVal]
  static int boundValue({
    required int val,
    required int minVal,
    required int maxVal,
  }) {
    return min(maxVal, max(val, minVal));
  }
}
