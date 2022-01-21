part of 'logger.dart';

/// A class to hold logs and their metadata
class CloudWatchLog {
  /// The list of logs in json form. These are ready to be sent
  List<Map<String, dynamic>> logs = [];

  /// The utf8 byte size of the logs contained within [logs]
  int messageSize = 0;

  /// Constructor for a LogObject
  CloudWatchLog({
    required this.logs,
    required this.messageSize,
  });

  /// Appends [log] to [logs] and increases [messagesSize] by [size]
  void addLog({
    required Map<String, dynamic> log,
    required int size,
  }) {
    logs.add(log);
    messageSize += size;
  }
}
