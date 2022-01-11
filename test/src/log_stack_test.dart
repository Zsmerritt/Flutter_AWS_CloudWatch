import 'package:aws_cloudwatch/src/log.dart';
import 'package:aws_cloudwatch/src/log_stack.dart';
import 'package:aws_cloudwatch/src/util.dart';
import 'package:test/test.dart';

void main() {
  test('consts', () {
    expect(AWS_MAX_BYTE_MESSAGE_SIZE, 262118);
    expect(AWS_MAX_BYTE_BATCH_SIZE, 1048550);
    expect(AWS_MAX_MESSAGES_PER_BATCH, 10000);
  });

  test('constructor', () {
    CloudWatchLogStack logStack = CloudWatchLogStack();
    expect(logStack.largeMessageBehavior, CloudWatchLargeMessages.truncate);
    expect(logStack.length, 0);
    expect(logStack.logStack.length, 0);
  });

  test('length getter', () {
    CloudWatchLogStack logStack = CloudWatchLogStack(
      largeMessageBehavior: CloudWatchLargeMessages.split,
    );
    logStack.addLogs(['test']);
    expect(logStack.length, 1);
    expect(logStack.logStack.length, 1);
  });

  group('Functions', () {
    test('pop - 1 message', () {
      CloudWatchLogStack truncateStack = CloudWatchLogStack();
      truncateStack.addLogs(['test', 'test2']);
      CloudWatchLog log = truncateStack.pop();
      expect(truncateStack.length, 0);
      expect(log.logs.length, 2);
      expect(log.logs[0]['message'], 'test');
      expect(log.logs[1]['message'], 'test2');
      expect(log.messageSize, 9);
    });

    test('pop - 2 message', () {
      CloudWatchLogStack splitStack = CloudWatchLogStack(
        largeMessageBehavior: CloudWatchLargeMessages.split,
      );
      List<String> logStrings = List.generate(20000, (index) => 'test');
      splitStack.addLogs(logStrings);
      expect(splitStack.length, 2);
      CloudWatchLog log = splitStack.pop();
      expect(splitStack.length, 1);
      expect(log.logs.length, 10000);
    });

    test('prepend', () {
      CloudWatchLogStack truncateStack = CloudWatchLogStack();
      CloudWatchLog log = CloudWatchLog(logs: [
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
        CloudWatchLogStack truncateStack = CloudWatchLogStack();
        truncateStack.addLogs(['test', 'test2']);
        expect(truncateStack.length, 1);
        expect(truncateStack.logStack[0].logs.length, 2);
        expect(truncateStack.logStack[0].logs[0]['message'], 'test');
        expect(truncateStack.logStack[0].logs[1]['message'], 'test2');
        expect(truncateStack.logStack[0].messageSize, 9);
      });

      test('empty', () {
        CloudWatchLogStack truncateStack = CloudWatchLogStack();
        truncateStack.addLogs([]);
        expect(truncateStack.length, 0);
      });

      test('MAX_MESSAGES_PER_BATCH', () {
        CloudWatchLogStack splitStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.split,
        );
        List<String> logStrings = List.generate(20000, (index) => 'test');
        splitStack.addLogs(logStrings);
        expect(splitStack.length, 2);
      });

      test('MAX_BYTE_BATCH_SIZE', () {
        CloudWatchLogStack splitStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.split,
        );

        splitStack.addLogs(['test' * 262118 * 2]);
        expect(splitStack.length, 2);
        expect(splitStack.logStack[0].logs.length, 4);
        expect(splitStack.logStack[0].logs[0]['message'].length, 262118);
        expect(splitStack.logStack[0].logs[1]['message'].length, 262118);
        expect(splitStack.logStack[0].logs[2]['message'].length, 262118);
        expect(splitStack.logStack[0].logs[3]['message'].length, 262118);
        expect(splitStack.logStack[0].messageSize, 1048472);
        expect(splitStack.logStack[1].logs.length, 4);
        expect(splitStack.logStack[1].logs[0]['message'].length, 262118);
        expect(splitStack.logStack[1].logs[1]['message'].length, 262118);
        expect(splitStack.logStack[1].logs[2]['message'].length, 262118);
        expect(splitStack.logStack[1].logs[3]['message'].length, 262118);
        expect(splitStack.logStack[1].messageSize, 1048472);
      });

      test('split', () {
        CloudWatchLogStack splitStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.split,
        );
        // test splitting large message into smaller chunks
        splitStack.addLogs(['test' * 262118]);
        expect(splitStack.length, 1);
        expect(splitStack.logStack[0].logs.length, 4);
        expect(splitStack.logStack[0].logs[0]['message'].length, 262118);
        expect(splitStack.logStack[0].logs[1]['message'].length, 262118);
        expect(splitStack.logStack[0].logs[2]['message'].length, 262118);
        expect(splitStack.logStack[0].logs[3]['message'].length, 262118);
        expect(splitStack.logStack[0].messageSize, 1048472);

        // these messages should not be split
        splitStack.addLogs(['test' * 65529]);
        expect(splitStack.length, 2);
        expect(splitStack.logStack[1].logs.length, 1);
        expect(splitStack.logStack[1].logs[0]['message'].length, 262116);
        expect(splitStack.logStack[1].messageSize, 262116);
      });

      test('truncate', () {
        CloudWatchLogStack truncateStack = CloudWatchLogStack();
        // test truncating large message
        List<String> logStrings = ['test' * 262118];
        truncateStack.addLogs(logStrings);
        expect(truncateStack.length, 1);
        expect(truncateStack.logStack[0].logs.length, 1);
        expect(truncateStack.logStack[0].logs[0]['message'].length, 262117);
        expect(truncateStack.logStack[0].messageSize, 262117);

        // these messages should not be truncated
        truncateStack.addLogs(['test' * 65529]);
        expect(truncateStack.length, 1);
        expect(truncateStack.logStack[0].logs.length, 2);
        expect(truncateStack.logStack[0].logs[1]['message'].length, 262116);
        expect(truncateStack.logStack[0].messageSize, 262116 + 262117);
      });

      test('ignore', () {
        CloudWatchLogStack ignoreStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.ignore,
        );
        // test ignoreing large messages
        ignoreStack.addLogs(['test' * 262118]);
        expect(ignoreStack.length, 0);

        // these messages should be added
        ignoreStack.addLogs(['test' * 65529]);
        expect(ignoreStack.length, 1);
        expect(ignoreStack.logStack[0].logs.length, 1);
        expect(ignoreStack.logStack[0].logs[0]['message'].length, 262116);
        expect(ignoreStack.logStack[0].messageSize, 262116);
      });

      test('error', () {
        CloudWatchLogStack errorStack = CloudWatchLogStack(
          largeMessageBehavior: CloudWatchLargeMessages.error,
        );
        // test throwing an error on large messages
        try {
          errorStack.addLogs(['test' * 262118]);
        } catch (e) {
          expect(e, isA<CloudWatchException>());
        }
        expect(errorStack.length, 0);

        // these messages should be added
        errorStack.addLogs(['test' * 65529]);
        expect(errorStack.length, 1);
        expect(errorStack.logStack[0].logs.length, 1);
        expect(errorStack.logStack[0].logs[0]['message'].length, 262116);
        expect(errorStack.logStack[0].messageSize, 262116);
      });
    });

    group('addToStack', () {
      test('logStack.length = 0', () {
        CloudWatchLogStack stack = CloudWatchLogStack();
        expect(stack.logStack.length, 0);
        stack.addToStack(0, [46, 46, 46]);
        expect(stack.logStack.length, 1);
        expect(stack.logStack[0].logs[0]['message'], '...');
        expect(stack.logStack[0].logs[0]['timestamp'], 0);
        expect(stack.logStack[0].messageSize, 3);
      });

      test('logStack.length = 1', () {
        CloudWatchLogStack stack = CloudWatchLogStack();
        stack.addToStack(0, [46]);
        stack.addToStack(1, [46, 46, 46]);
        expect(stack.logStack.length, 1);
        expect(stack.logStack[0].logs.length, 2);
        expect(stack.logStack[0].logs[1]['message'], '...');
        expect(stack.logStack[0].logs[1]['timestamp'], 1);
        expect(stack.logStack[0].messageSize, 4);
      });

      test('logStack.last.logs.length = AWS_MAX_MESSAGES_PER_BATCH', () {
        CloudWatchLogStack stack = CloudWatchLogStack();
        stack.logStack.add(CloudWatchLog(logs: [], messageSize: 0));
        for (int x = 0; x < AWS_MAX_MESSAGES_PER_BATCH; x++) {
          stack.logStack.last.addLog(
            log: {'timestamp': 0, 'message': '.'},
            size: 1,
          );
        }
        expect(stack.logStack.length, 1);
        expect(stack.logStack[0].logs.length, AWS_MAX_MESSAGES_PER_BATCH);
        stack.addToStack(1, [46, 46, 46]);
        expect(stack.logStack.length, 2);
        expect(stack.logStack[1].logs.length, 1);
        expect(stack.logStack[1].logs[0]['message'], '...');
        expect(stack.logStack[1].logs[0]['timestamp'], 1);
        expect(stack.logStack[1].messageSize, 3);
      });

      test('logStack.last.logs.length = AWS_MAX_MESSAGES_PER_BATCH', () {
        CloudWatchLogStack stack = CloudWatchLogStack();
        stack.logStack.add(CloudWatchLog(
          logs: [],
          messageSize: AWS_MAX_BYTE_BATCH_SIZE,
        ));
        stack.addToStack(1, [46, 46, 46]);
        expect(stack.logStack.length, 2);
        expect(stack.logStack[1].logs.length, 1);
        expect(stack.logStack[1].logs[0]['message'], '...');
        expect(stack.logStack[1].logs[0]['timestamp'], 1);
        expect(stack.logStack[1].messageSize, 3);
      });
    });
  });
}
