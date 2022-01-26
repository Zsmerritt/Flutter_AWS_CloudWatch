part of 'logger.dart';

/// A CloudWatch handler class to easily manage multiple CloudWatch instances
class LoggerHandler {
  Map<String, Logger> logInstances = {};

  /// Private version of access key
  String _awsAccessKey;

  /// Your AWS access key
  set awsAccessKey(String awsAccessKey) {
    // Updates all instances with new key. Useful for temp credentials
    for (final Logger cw in logInstances.values) {
      cw.awsAccessKey = awsAccessKey;
    }
    _awsAccessKey = awsAccessKey;
  }

  /// Your AWS access key
  String get awsAccessKey => _awsAccessKey;

  /// Private version of secret key
  String _awsSecretKey;

  /// Your AWS secret key
  set awsSecretKey(String awsSecretKey) {
    // Updates all instances with new key. Useful for temp credentials
    for (final Logger cw in logInstances.values) {
      cw.awsSecretKey = awsSecretKey;
    }
    _awsSecretKey = awsSecretKey;
  }

  /// Your AWS secret key
  String get awsSecretKey => _awsSecretKey;

  /// Private version of session token
  String? _awsSessionToken;

  /// Your AWS session token
  set awsSessionToken(String? awsSessionToken) {
    // Updates all instances with new key. Useful for temp credentials
    for (final Logger cw in logInstances.values) {
      cw.awsSessionToken = awsSessionToken;
    }
    _awsSessionToken = awsSessionToken;
  }

  /// Your AWS session token
  String? get awsSessionToken => _awsSessionToken;

  /// Your AWS region. Instances are not updated when this value is changed
  String region;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  Duration get delay => _delay;

  /// How long to wait between requests to avoid rate limiting (suggested value is Duration(milliseconds: 200))
  set delay(Duration val) {
    for (final Logger cw in logInstances.values) {
      cw.delay = val;
    }
    _delay = val;
  }

  /// private version of [delay]
  Duration _delay;

  /// How long to wait for request before triggering a timeout
  Duration get requestTimeout => _requestTimeout;

  /// How long to wait for request before triggering a timeout
  set requestTimeout(Duration val) {
    for (final Logger cw in logInstances.values) {
      cw.requestTimeout = val;
    }
    _requestTimeout = val;
  }

  /// private version of [requestTimeout]
  Duration _requestTimeout;

  /// How many times an api request should be retired upon failure. Default is 3
  int get retries => _retries;

  /// How many times an api request should be retired upon failure. Default is 3
  set retries(int val) {
    for (final Logger cw in logInstances.values) {
      cw.retries = val;
    }
    _retries = val;
  }

  /// private version of [largeMessageBehavior]
  int _retries;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  CloudWatchLargeMessages get largeMessageBehavior => _largeMessageBehavior;

  /// How messages larger than AWS limit should be handled. Default is truncate.
  set largeMessageBehavior(CloudWatchLargeMessages val) {
    for (final Logger cw in logInstances.values) {
      cw.largeMessageBehavior = val;
    }
    _largeMessageBehavior = val;
  }

  /// private version of [largeMessageBehavior]
  CloudWatchLargeMessages _largeMessageBehavior;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  bool get raiseFailedLookups => _raiseFailedLookups;

  /// Whether exceptions should be raised on failed lookups (usually no internet)
  set raiseFailedLookups(bool val) {
    for (final Logger cw in logInstances.values) {
      cw.raiseFailedLookups = val;
    }
    _raiseFailedLookups = val;
  }

  /// private version of [raiseFailedLookups]
  bool _raiseFailedLookups;

  /// Changes how large each message can be before [largeMessageBehavior] takes
  /// effect. Min 5, Max 262116
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxBytesPerMessage => _maxBytesPerMessage;

  set maxBytesPerMessage(int val) {
    for (final Logger cw in logInstances.values) {
      cw.maxBytesPerMessage = val;
    }
    _maxBytesPerMessage = val;
  }

  /// private maxBytesPerMessage
  int _maxBytesPerMessage;

  /// Changes how many bytes can be sent in each API request before a second
  /// request is made. Min 1, Max 1048576
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxBytesPerRequest => _maxBytesPerRequest;

  set maxBytesPerRequest(int val) {
    for (final Logger cw in logInstances.values) {
      cw.maxBytesPerRequest = val;
    }
    _maxBytesPerRequest = val;
  }

  /// private maxBytesPerRequest
  int _maxBytesPerRequest;

  /// Changes the maximum number of messages that can be sent in each API
  /// request. Min 1, Max 10000
  ///
  /// These overrides change when messages are sent. No need to mess with them
  /// unless you're running into issues
  int get maxMessagesPerRequest => _maxMessagesPerRequest;

  set maxMessagesPerRequest(int val) {
    for (final Logger cw in logInstances.values) {
      cw.maxMessagesPerRequest = val;
    }
    _maxMessagesPerRequest = val;
  }

  /// private maxMessagesPerRequest
  int _maxMessagesPerRequest;

  /// Testing Variables

  /// Function used to mock requests
  Future<Response> Function(Request)? mockFunction;

  /// Whether we are mocking requests
  bool mockCloudWatch;

  /// CloudWatchHandler Constructor
  LoggerHandler({
    required awsAccessKey,
    required awsSecretKey,
    required this.region,
    required awsSessionToken,
    required delay,
    required requestTimeout,
    required retries,
    required largeMessageBehavior,
    required raiseFailedLookups,
    this.mockCloudWatch = false,
    this.mockFunction,
    int maxBytesPerMessage = awsMaxBytesPerMessage,
    int maxBytesPerRequest = awsMaxBytesPerRequest,
    int maxMessagesPerRequest = awsMaxMessagesPerRequest,
  })  : _awsAccessKey = awsAccessKey,
        _awsSecretKey = awsSecretKey,
        _awsSessionToken = awsSessionToken,
        _delay = delay,
        _requestTimeout = requestTimeout,
        _retries = max(0, retries),
        _largeMessageBehavior = largeMessageBehavior,
        _raiseFailedLookups = raiseFailedLookups,
        _maxBytesPerMessage = maxBytesPerMessage,
        _maxBytesPerRequest = maxBytesPerRequest,
        _maxMessagesPerRequest = maxMessagesPerRequest;

  /// Returns a specific instance of a CloudWatch class (or null if it doesn't
  /// exist) based on group name and stream name
  ///
  /// Uses the [logGroupName] and the [logStreamName] to find the correct
  /// CloudWatch instance. Returns null if it doesn't exist
  Logger? getInstance({
    required String logGroupName,
    required String logStreamName,
  }) {
    final String instanceName = '$logGroupName.$logStreamName';
    return logInstances[instanceName];
  }

  /// Logs the provided message to the provided log group and log stream
  ///
  /// Logs a single [message] to [logStreamName] under the group [logGroupName]
  Future<void> log({
    required String message,
    required String logGroupName,
    required String logStreamName,
  }) async {
    await logMany(
      messages: [message],
      logGroupName: logGroupName,
      logStreamName: logStreamName,
    );
  }

  /// Logs the provided message to the provided log group and log stream
  ///
  /// Logs a list of string [messages] to [logStreamName] under the group [logGroupName]
  ///
  /// Note: using logMany will result in all logs having the same timestamp
  Future<void> logMany({
    required List<String> messages,
    required String logGroupName,
    required String logStreamName,
  }) async {
    final Logger instance = getInstance(
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        ) ??
        createInstance(
          logGroupName: logGroupName,
          logStreamName: logStreamName,
        );
    await instance.log(messages);
  }

  /// Creates a CloudWatch instance.
  ///
  /// Calling any log function will call this as needed automatically
  Logger createInstance({
    required String logGroupName,
    required String logStreamName,
  }) {
    validateLogGroupName(logGroupName);
    validateLogStreamName(logStreamName);
    final String instanceName = '$logGroupName.$logStreamName';
    final Logger instance = Logger(
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      region: region,
      groupName: logGroupName,
      streamName: logStreamName,
      awsSessionToken: awsSessionToken,
      delay: delay,
      requestTimeout: requestTimeout,
      retries: retries,
      largeMessageBehavior: largeMessageBehavior,
      raiseFailedLookups: raiseFailedLookups,
      maxBytesPerMessage: maxBytesPerMessage,
      maxBytesPerRequest: maxBytesPerRequest,
      maxMessagesPerRequest: maxMessagesPerRequest,
      mockCloudWatch: mockCloudWatch,
      mockFunction: mockFunction,
    );
    logInstances[instanceName] = instance;
    return instance;
  }
}
