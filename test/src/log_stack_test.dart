import 'dart:convert';

import 'package:aws_cloudwatch/src/logger.dart';
import 'package:test/test.dart';

void main() {
  test('consts', () {
    expect(awsMaxBytesPerMessage, 262116);
    expect(awsMaxBytesPerRequest, 1048576);
    expect(awsMaxMessagesPerRequest, 10000);
    expect(splitMessageOverheadBytes, 21);
    expect(awsMinBytesPerMessage, splitMessageOverheadBytes + 1);
    expect(awsMinBytesPerRequest, 1);
    expect(awsMinMessagesPerRequest, 1);
  });

  test('constructor', () {
    final CloudWatchLogStack logStack = CloudWatchLogStack();
    expect(logStack.largeMessageBehavior, CloudWatchLargeMessages.truncate);
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
        expect(splitStack.logStack.last.logs.length, 3);
      });

      test('MAX_BYTE_BATCH_SIZE', () {
        final CloudWatchLogStack splitStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.split,
        )..addLogs(['test' * awsMaxBytesPerMessage * 2]);
        expect(splitStack.length, 3);
        expect(splitStack.logStack[0].logs.length, 4);
        expect(
          splitStack.logStack[0].logs[0]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(
          splitStack.logStack[0].logs[1]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(
          splitStack.logStack[0].logs[2]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(
          splitStack.logStack[0].logs[3]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(splitStack.logStack[0].messageSize, 1048568);
        expect(splitStack.logStack[1].logs.length, 4);
        expect(
          splitStack.logStack[1].logs[0]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(
          splitStack.logStack[1].logs[1]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(
          splitStack.logStack[1].logs[2]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(
          splitStack.logStack[1].logs[3]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(splitStack.logStack[1].messageSize, 1048568);
        expect(splitStack.logStack[2].logs.length, 1);
        expect(
          splitStack.logStack[2].logs[0]['message'].length,
          189,
        );
        expect(splitStack.logStack[2].messageSize, 215);
      });

      test('split', () {
        final CloudWatchLogStack splitStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.split,
        )
          // test splitting large message into smaller chunks
          ..addLogs(
              ['test' * (awsMaxBytesPerMessage - splitMessageOverheadBytes)]);
        expect(splitStack.length, 1);
        expect(splitStack.logStack[0].logs.length, 4);
        expect(
          splitStack.logStack[0].logs[0]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(
          splitStack.logStack[0].logs[1]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(
          splitStack.logStack[0].logs[2]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(
          splitStack.logStack[0].logs[3]['message'].length,
          awsMaxBytesPerMessage,
        );
        expect(splitStack.logStack[0].messageSize, 1048568);

        // these messages should not be split
        splitStack.addLogs(['test' * 65529]);
        expect(splitStack.length, 2);
        expect(splitStack.logStack[1].logs.length, 1);
        expect(splitStack.logStack[1].logs[0]['message'].length, 262116);
        expect(splitStack.logStack[1].messageSize, awsMaxBytesPerMessage + 26);
      });

      test('truncate', () {
        final CloudWatchLogStack truncateStack = CloudWatchLogStack();
        // test truncating large message
        final List<String> logStrings = ['test' * awsMaxBytesPerMessage];
        truncateStack.addLogs(logStrings);
        expect(truncateStack.length, 1);
        expect(truncateStack.logStack[0].logs.length, 1);
        expect(truncateStack.logStack[0].logs[0]['message'].length,
            awsMaxBytesPerMessage);
        expect(
            truncateStack.logStack[0].messageSize, awsMaxBytesPerMessage + 26);

        // these messages should not be truncated
        truncateStack.addLogs(['test' * 65529]);
        expect(truncateStack.length, 1);
        expect(truncateStack.logStack[0].logs.length, 2);
        expect(truncateStack.logStack[0].logs[1]['message'].length, 262116);
        expect(truncateStack.logStack[0].messageSize,
            262116 + awsMaxBytesPerMessage + 26 * 2);
      });

      test('ignore', () {
        final CloudWatchLogStack ignoreStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.ignore,
        )
          // test ignoreing large messages
          ..addLogs(['test' * awsMaxBytesPerMessage]);
        expect(ignoreStack.length, 0);

        // these messages should be added
        ignoreStack.addLogs(['test' * 65529]);
        expect(ignoreStack.length, 1);
        expect(ignoreStack.logStack[0].logs.length, 1);
        expect(ignoreStack.logStack[0].logs[0]['message'].length, 262116);
        expect(ignoreStack.logStack[0].messageSize, awsMaxBytesPerMessage + 26);
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

        // these messages should be added
        errorStack.addLogs(['test' * 65529]);
        expect(errorStack.length, 1);
        expect(errorStack.logStack[0].logs.length, 1);
        expect(errorStack.logStack[0].logs[0]['message'].length, 262116);
        expect(errorStack.logStack[0].messageSize, awsMaxBytesPerMessage + 26);
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
