import 'dart:convert';

import 'package:aws_cloudwatch/src/logger.dart';
import 'package:test/test.dart';

void main() {
  test('consts', () {
    expect(awsMaxBytesPerMessage, 1048550);
    expect(awsMaxBytesPerRequest, 1048576);
    expect(awsMaxMessagesPerRequest, 10000);
    expect(splitMessageOverheadBytes, 21);
    expect(awsMinBytesPerMessage, splitMessageOverheadBytes + 1);
    expect(awsMinBytesPerRequest, 1);
    expect(awsMinMessagesPerRequest, 1);
  });

  test('constructor', () {
    final CloudWatchLogStack logStack = CloudWatchLogStack();
    expect(logStack.largeMessageBehavior, CloudWatchLargeMessages.split);
    expect(logStack.length, 0);
    expect(logStack.logStack.length, 0);
  });

  group('getters & setters', () {
    test('length getter', () {
      final CloudWatchLogStack logStack = CloudWatchLogStack(
        largeMessageBehavior: CloudWatchLargeMessages.split,
      )..addLogs(['test']);
      expect(logStack.length, 1);
      expect(logStack.logStack.length, 1);
    });
    test('maxBytesPerMessage too large', () {
      final CloudWatchLogStack logStack = CloudWatchLogStack()
        ..maxBytesPerMessage = awsMaxBytesPerMessage + 10;
      expect(logStack.maxBytesPerMessage, awsMaxBytesPerMessage);
    });
    test('maxBytesPerMessage too small', () {
      final CloudWatchLogStack logStack = CloudWatchLogStack()
        ..maxBytesPerMessage = -1;
      expect(logStack.maxBytesPerMessage, awsMinBytesPerMessage);
    });
    test('maxBytesPerRequest too large', () {
      final CloudWatchLogStack logStack = CloudWatchLogStack()
        ..maxBytesPerRequest = awsMaxBytesPerRequest + 10;
      expect(logStack.maxBytesPerRequest, awsMaxBytesPerRequest);
    });
    test('maxBytesPerRequest too small', () {
      final CloudWatchLogStack logStack = CloudWatchLogStack()
        ..maxBytesPerRequest = -1;
      expect(logStack.maxBytesPerRequest, awsMinBytesPerRequest);
    });
    test('maxMessagesPerRequest too large', () {
      final CloudWatchLogStack logStack = CloudWatchLogStack()
        ..maxMessagesPerRequest = awsMaxMessagesPerRequest + 10;
      expect(logStack.maxMessagesPerRequest, awsMaxMessagesPerRequest);
    });
    test('maxMessagesPerRequest too small', () {
      final CloudWatchLogStack logStack = CloudWatchLogStack()
        ..maxMessagesPerRequest = -1;
      expect(logStack.maxMessagesPerRequest, awsMinMessagesPerRequest);
    });
  });

  group('Functions', () {
    test('pop - 1 message', () {
      final CloudWatchLogStack truncateStack = CloudWatchLogStack()
        ..addLogs(['test', 'test2']);
      final CloudWatchLog log = truncateStack.pop();
      expect(truncateStack.length, 0);
      expect(log.logs.length, 2);
      expect(log.logs[0]['message'], 'test');
      expect(log.logs[1]['message'], 'test2');
      expect(log.messageSize, 61);
    });

    test('pop - 2 message', () {
      final CloudWatchLogStack splitStack = CloudWatchLogStack(
        largeMessageBehavior: CloudWatchLargeMessages.split,
      );
      final List<String> logStrings = List.generate(20000, (index) => 'test');
      splitStack.addLogs(logStrings);
      expect(splitStack.length, 2);
      final CloudWatchLog log = splitStack.pop();
      expect(splitStack.length, 1);
      expect(log.logs.length, awsMaxMessagesPerRequest);
    });

    test('prepend', () {
      final CloudWatchLogStack truncateStack = CloudWatchLogStack();
      final CloudWatchLog log = CloudWatchLog(logs: [
        {'message': 'testMessage'}
      ], messageSize: 10);
      truncateStack.prepend(log);
      expect(truncateStack.length, 1);
      expect(truncateStack.logStack[0].logs.length, 1);
      expect(truncateStack.logStack[0].logs[0]['message'], 'testMessage');
      expect(truncateStack.logStack[0].messageSize, 10);
    });
    group('addLogs', () {
      test('standard', () {
        final CloudWatchLogStack truncateStack = CloudWatchLogStack()
          ..addLogs(['test', 'test2']);
        expect(truncateStack.length, 1);
        expect(truncateStack.logStack[0].logs.length, 2);
        expect(truncateStack.logStack[0].logs[0]['message'], 'test');
        expect(truncateStack.logStack[0].logs[1]['message'], 'test2');
        expect(truncateStack.logStack[0].messageSize, 61);
      });

      test('empty', () {
        final CloudWatchLogStack truncateStack = CloudWatchLogStack()
          ..addLogs([]);
        expect(truncateStack.length, 0);
      });

      test('MAX_MESSAGES_PER_BATCH', () {
        final CloudWatchLogStack splitStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.split,
        );
        final List<String> logStrings = List.generate(20000, (index) => 'test');
        splitStack.addLogs(logStrings);
        expect(splitStack.length, 2);
      });

      test('MAX_BYTES_PER_MESSAGE', () {
        final CloudWatchLogStack splitStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.split,
          maxBytesPerMessage: 5,
        );
        final List<String> logStrings = ['111112222233333'];
        splitStack.addLogs(logStrings);
        expect(splitStack.logStack.last.logs.length, 1);
      });

      test('MAX_BYTE_BATCH_SIZE', () {
        // With 1MB max message size, each max-size split message fills an
        // entire batch (1048550 + 26 overhead = 1048576 = maxBytesPerRequest).
        final CloudWatchLogStack splitStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.split,
        )..addLogs(['test' * awsMaxBytesPerMessage * 2]);
        // 'test' * 2097100 = 8388400 bytes
        // split into chunks of 1048529 bytes (1048550 - 21 overhead)
        // = 9 chunks (8 full + 1 remainder of 168 bytes)
        // each full chunk = 1048550 bytes = fills one batch
        expect(splitStack.length, 9);
        // First 8 batches: 1 message each, max size
        for (int i = 0; i < 8; i++) {
          expect(splitStack.logStack[i].logs.length, 1);
          expect(
            splitStack.logStack[i].logs[0]['message'].length,
            awsMaxBytesPerMessage,
          );
          expect(splitStack.logStack[i].messageSize, awsMaxBytesPerMessage + 26);
        }
        // Last batch: 1 smaller message (21 byte prefix + 168 byte remainder)
        expect(splitStack.logStack[8].logs.length, 1);
        expect(
          splitStack.logStack[8].logs[0]['message'].length,
          189,
        );
        expect(splitStack.logStack[8].messageSize, 215);
      });

      test('split', () {
        final CloudWatchLogStack splitStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.split,
        )
          // test splitting large message into smaller chunks
          // 'test' * 1048529 = 4194116 bytes, splits into exactly 4 messages
          ..addLogs(
              ['test' * (awsMaxBytesPerMessage - splitMessageOverheadBytes)]);
        // Each split message is max size (1048550 bytes) and fills one batch
        expect(splitStack.length, 4);
        for (int i = 0; i < 4; i++) {
          expect(splitStack.logStack[i].logs.length, 1);
          expect(
            splitStack.logStack[i].logs[0]['message'].length,
            awsMaxBytesPerMessage,
          );
          expect(
              splitStack.logStack[i].messageSize, awsMaxBytesPerMessage + 26);
        }

        // these messages should not be split (262136 bytes < 1048550 limit)
        splitStack.addLogs(['test' * 65534]);
        expect(splitStack.length, 5);
        expect(splitStack.logStack[4].logs.length, 1);
        expect(splitStack.logStack[4].logs[0]['message'].length, 262136);
        expect(splitStack.logStack[4].messageSize, 262136 + 26);
      });

      test('truncate', () {
        final CloudWatchLogStack truncateStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.truncate,
        );
        // test truncating large message
        final List<String> logStrings = ['test' * awsMaxBytesPerMessage];
        truncateStack.addLogs(logStrings);
        expect(truncateStack.length, 1);
        expect(truncateStack.logStack[0].logs.length, 1);
        expect(truncateStack.logStack[0].logs[0]['message'].length,
            awsMaxBytesPerMessage);
        expect(
            truncateStack.logStack[0].messageSize, awsMaxBytesPerMessage + 26);

        // these messages should not be truncated (262136 < 1048550)
        // but the batch is full so they go to a new batch
        truncateStack.addLogs(['test' * 65534]);
        expect(truncateStack.length, 2);
        expect(truncateStack.logStack[1].logs.length, 1);
        expect(truncateStack.logStack[1].logs[0]['message'].length, 262136);
        expect(truncateStack.logStack[1].messageSize, 262136 + 26);
      });

      test('ignore', () {
        final CloudWatchLogStack ignoreStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.ignore,
        )
          // test ignoring large messages
          ..addLogs(['test' * awsMaxBytesPerMessage]);
        expect(ignoreStack.length, 0);

        // these messages should be added (262136 < 1048550)
        ignoreStack.addLogs(['test' * 65534]);
        expect(ignoreStack.length, 1);
        expect(ignoreStack.logStack[0].logs.length, 1);
        expect(ignoreStack.logStack[0].logs[0]['message'].length, 262136);
        expect(ignoreStack.logStack[0].messageSize, 262136 + 26);
      });

      test('error', () {
        final CloudWatchLogStack errorStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.error,
        );
        // test throwing an error on large messages
        try {
          errorStack.addLogs(['test' * awsMaxBytesPerMessage]);
        } catch (e) {
          expect(e, isA<CloudWatchException>());
        }
        expect(errorStack.length, 0);

        // these messages should be added (262136 < 1048550)
        errorStack.addLogs(['test' * 65534]);
        expect(errorStack.length, 1);
        expect(errorStack.logStack[0].logs.length, 1);
        expect(errorStack.logStack[0].logs[0]['message'].length, 262136);
        expect(errorStack.logStack[0].messageSize, 262136 + 26);
      });
    });

    group('addToStack', () {
      test('logStack.length = 0', () {
        final CloudWatchLogStack stack = CloudWatchLogStack();
        expect(stack.logStack.length, 0);
        stack.addToStack(0, [46, 46, 46]);
        expect(stack.logStack.length, 1);
        expect(stack.logStack[0].logs[0]['message'], '...');
        expect(stack.logStack[0].logs[0]['timestamp'], 0);
        expect(stack.logStack[0].messageSize, 3 + 26);
      });

      test('logStack.length = 1', () {
        final CloudWatchLogStack stack = CloudWatchLogStack()
          ..addToStack(0, [46])
          ..addToStack(1, [46, 46, 46]);
        expect(stack.logStack.length, 1);
        expect(stack.logStack[0].logs.length, 2);
        expect(stack.logStack[0].logs[1]['message'], '...');
        expect(stack.logStack[0].logs[1]['timestamp'], 1);
        expect(stack.logStack[0].messageSize, 4 + 26 * 2);
      });

      test('logStack.last.logs.length = AWS_MAX_MESSAGES_PER_BATCH', () {
        final CloudWatchLogStack stack = CloudWatchLogStack();
        stack.logStack.add(CloudWatchLog(logs: [], messageSize: 0));
        for (int x = 0; x < awsMaxMessagesPerRequest; x++) {
          stack.logStack.last.addLog(
            log: {'timestamp': 0, 'message': '.'},
            size: 1,
          );
        }
        expect(stack.logStack.length, 1);
        expect(stack.logStack[0].logs.length, awsMaxMessagesPerRequest);
        stack.addToStack(1, [46, 46, 46]);
        expect(stack.logStack.length, 2);
        expect(stack.logStack[1].logs.length, 1);
        expect(stack.logStack[1].logs[0]['message'], '...');
        expect(stack.logStack[1].logs[0]['timestamp'], 1);
        expect(stack.logStack[1].messageSize, 3 + 26);
      });

      test('logStack.last.logs.length = AWS_MAX_MESSAGES_PER_BATCH', () {
        final CloudWatchLogStack stack = CloudWatchLogStack();
        stack.logStack.add(CloudWatchLog(
          logs: [],
          messageSize: awsMaxBytesPerRequest,
        ));
        stack.addToStack(1, [46, 46, 46]);
        expect(stack.logStack.length, 2);
        expect(stack.logStack[1].logs.length, 1);
        expect(stack.logStack[1].logs[0]['message'], '...');
        expect(stack.logStack[1].logs[0]['timestamp'], 1);
        expect(stack.logStack[1].messageSize, 3 + 26);
      });
    });

    group('truncate', () {
      test('limit + 1', () {
        final String msg = '1' * (awsMaxBytesPerMessage + 1);
        final List<int> bytes = utf8.encode(msg);
        final List<int> result = CloudWatchLogStack().truncate(bytes);
        expect(result.length, awsMaxBytesPerMessage);
      });
      test('limit + 2', () {
        final String msg = '1' * (awsMaxBytesPerMessage + 2);
        final List<int> bytes = utf8.encode(msg);
        final List<int> result = CloudWatchLogStack().truncate(bytes);
        expect(result.length, awsMaxBytesPerMessage);
      });
    });
    group('calculateMidpoint', () {
      test('no split', () {
        final String msg =
            '1' * (awsMaxBytesPerMessage - 1 - splitMessageOverheadBytes);
        final List<int> bytes = utf8.encode(msg);
        final List<List<int>> result = CloudWatchLogStack().split(bytes);
        expect(result.length, 1);
      });
      test('Limit + 1', () {
        final String msg = '1' * (awsMaxBytesPerMessage + 1);
        final List<int> bytes = utf8.encode(msg);
        final List<List<int>> result = CloudWatchLogStack().split(bytes);
        expect(result.length, 2);
      });
      test('Limit + 2', () {
        final String msg = '1' * (awsMaxBytesPerMessage + 2);
        final List<int> bytes = utf8.encode(msg);
        final List<List<int>> result = CloudWatchLogStack().split(bytes);
        expect(result.length, 2);
      });
    });
  });
}
