import 'package:local_spam_guard/local_spam_guard.dart';
import 'package:test/test.dart';

final class FakeClock implements SpamGuardClock {
  FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
  void advance(Duration duration) => current = current.add(duration);
}

void main() {
  late FakeClock clock;

  setUp(() => clock = FakeClock(DateTime.utc(2026)));

  group('normal use', () {
    test('defaults to strong and permits a conversation', () {
      final guard = LocalSpamGuard(clock: clock);
      expect(guard.strength, SpamFilterStrength.strong);
      for (final text in [
        'Hey, are you there?',
        'Yeah',
        'Where are you?',
        "I'm near the station.",
        'Okay, coming now.',
      ]) {
        expect(guard.check(senderId: 'friend', text: text).isSpam, isFalse);
        clock.advance(const Duration(seconds: 3));
      }
    });

    test('two ordinary duplicates are accepted', () {
      final guard = LocalSpamGuard(clock: clock);
      expect(guard.check(senderId: 'a', text: 'yes').isSpam, isFalse);
      clock.advance(const Duration(seconds: 2));
      expect(guard.check(senderId: 'a', text: 'yes').isSpam, isFalse);
    });

    test('supports empty and Unicode messages', () {
      final guard = LocalSpamGuard(clock: clock);
      expect(guard.check(senderId: 'a', text: '').isSpam, isFalse);
      expect(guard.check(senderId: 'a', text: 'Привет 世界 👋').isSpam, isFalse);
    });

    test('a normal single link is accepted', () {
      final result = LocalSpamGuard(clock: clock)
          .check(senderId: 'a', text: 'Docs: https://example.com/help');
      expect(result.isSpam, isFalse);
      expect(result.reasons, isNot(contains(SpamReason.excessiveLinks)));
    });
  });

  group('signals', () {
    test('detects rapid flooding', () {
      final guard = LocalSpamGuard(clock: clock);
      SpamResult result = guard.check(senderId: 'a', text: 'message 0');
      for (var i = 1; i < 7; i++) {
        result = guard.check(senderId: 'a', text: 'message $i');
      }
      expect(result.isSpam, isTrue);
      expect(result.reasons, contains(SpamReason.messageFlood));
    });

    test('detects duplicate flooding after tolerance', () {
      final guard = LocalSpamGuard(clock: clock);
      SpamResult result = guard.check(senderId: 'a', text: 'hello');
      for (var i = 0; i < 4; i++) {
        clock.advance(const Duration(seconds: 2));
        result = guard.check(senderId: 'a', text: ' HELLO ');
      }
      expect(result.reasons, contains(SpamReason.duplicateMessages));
    });

    test('detects near duplicates', () {
      final guard = LocalSpamGuard(clock: clock);
      SpamResult result = guard.check(senderId: 'a', text: 'BUY NOW!!!');
      for (final text in ['BUY NOW!!!!', 'BUY NOW!!!!!', 'BUY NOW!! 1']) {
        clock.advance(const Duration(seconds: 2));
        result = guard.check(senderId: 'a', text: text);
      }
      expect(result.reasons, contains(SpamReason.similarMessages));
    });

    test('detects repeated and excessive links', () {
      final guard = LocalSpamGuard(clock: clock);
      guard.check(senderId: 'a', text: 'See https://bad.example/x');
      clock.advance(const Duration(seconds: 2));
      final repeated =
          guard.check(senderId: 'a', text: 'https://bad.example/x again');
      expect(repeated.reasons, contains(SpamReason.repeatedLink));
      final excessive = guard.check(
        senderId: 'b',
        text: 'https://a.example https://b.example https://c.example',
      );
      expect(excessive.reasons, contains(SpamReason.excessiveLinks));
    });

    test(
        'formatting signals cover characters punctuation capitals emoji and tokens',
        () {
      final guard = LocalSpamGuard(clock: clock);
      expect(guard.check(senderId: 'a', text: 'AAAAAAAAAAAAAAAAAAAA').reasons,
          contains(SpamReason.excessiveCharacters));
      expect(
          guard.check(senderId: 'b', text: '!!!!!!!!!!!!!!!!!!!!').reasons,
          containsAll([
            SpamReason.excessiveCharacters,
            SpamReason.excessiveFormatting
          ]));
      expect(
          guard
              .check(senderId: 'c', text: 'THIS IS A VERY LOUD ADVERTISEMENT')
              .reasons,
          contains(SpamReason.excessiveFormatting));
      expect(
          guard.check(senderId: 'd', text: '🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥').reasons,
          contains(SpamReason.excessiveCharacters));
      expect(
          guard.check(senderId: 'e', text: 'buy buy buy buy buy buy').reasons,
          contains(SpamReason.repeatedTokens));
    });

    test('multiple weak signals combine above threshold', () {
      final guard = LocalSpamGuard(clock: clock);
      guard.check(senderId: 'a', text: 'GO NOW https://x.example');
      clock.advance(const Duration(seconds: 1));
      final result = guard.check(
          senderId: 'a', text: 'GO GO GO GO GO GO https://x.example!!!!!');
      expect(result.score, greaterThanOrEqualTo(.60));
      expect(result.isSpam, isTrue);
    });
  });

  group('strength', () {
    test('off always allows and does not collect state', () {
      final guard =
          LocalSpamGuard(strength: SpamFilterStrength.off, clock: clock);
      for (var i = 0; i < 20; i++) {
        expect(guard.check(senderId: 'a', text: 'SPAM!!!!').action,
            SpamAction.allow);
      }
      expect(guard.senderCount, 0);
    });

    test('intense triggers earlier than strong and medium', () {
      SpamResult run(SpamFilterStrength strength) {
        final guard = LocalSpamGuard(
            strength: strength, clock: FakeClock(DateTime.utc(2026)));
        SpamResult result = guard.check(senderId: 'a', text: 'one');
        for (var i = 0; i < 3; i++) {
          result = guard.check(senderId: 'a', text: 'item $i');
        }
        return result;
      }

      expect(run(SpamFilterStrength.intense).isSpam, isTrue);
      expect(run(SpamFilterStrength.strong).isSpam, isFalse);
      expect(run(SpamFilterStrength.medium).isSpam, isFalse);
    });
  });

  group('state lifecycle', () {
    LocalSpamGuard fastGuard() => LocalSpamGuard(
          clock: clock,
          config: const SpamGuardConfig(
            duplicateLimit: 2,
            scoreThreshold: .4,
            strikesBeforeSuspension: 2,
            baseCooldown: Duration(seconds: 10),
            strikeDecayInterval: Duration(seconds: 20),
          ),
        );

    test('strikes escalate to suspension and suspension expires', () {
      final guard = fastGuard();
      guard.check(senderId: 'a', text: 'same');
      expect(
          guard.check(senderId: 'a', text: 'same').action, SpamAction.filter);
      expect(
          guard.check(senderId: 'a', text: 'same').action, SpamAction.suspend);
      expect(guard.isSuspended('a'), isTrue);
      expect(guard.check(senderId: 'a', text: 'anything').reasons,
          [SpamReason.senderSuspended]);
      clock.advance(const Duration(seconds: 11));
      expect(guard.isSuspended('a'), isFalse);
    });

    test('clear and reset APIs work', () {
      final guard = fastGuard();
      for (var i = 0; i < 3; i++) {
        guard.check(senderId: 'a', text: 'same');
      }
      guard.clearSuspension('a');
      expect(guard.isSuspended('a'), isFalse);
      guard.resetSender('a');
      expect(guard.senderCount, 0);
      guard.check(senderId: 'b', text: 'hello');
      guard.resetAll();
      expect(guard.senderCount, 0);
    });

    test('strikes decay lazily', () {
      final guard = fastGuard();
      guard.check(senderId: 'a', text: 'same');
      guard.check(senderId: 'a', text: 'same');
      clock.advance(const Duration(seconds: 21));
      guard.check(senderId: 'a', text: 'different');
      guard.check(senderId: 'a', text: 'same');
      expect(guard.isSuspended('a'), isFalse);
    });

    test('sender histories and global state are bounded', () {
      final guard = LocalSpamGuard(
        clock: clock,
        config: const SpamGuardConfig(maxSenders: 3, maxHistoryPerSender: 4),
      );
      for (var sender = 0; sender < 5; sender++) {
        for (var message = 0; message < 10; message++) {
          guard.check(senderId: '$sender', text: 'message $message');
          clock.advance(const Duration(seconds: 2));
        }
      }
      expect(guard.senderCount, 3);
      final exported = guard.exportState();
      final senders = exported['senders']! as Map;
      expect(
          senders.values.every(
              (value) => ((value as Map)['history'] as List).length <= 4),
          isTrue);
    });

    test('different senders have independent histories', () {
      final guard = LocalSpamGuard(clock: clock);
      for (var i = 0; i < 3; i++) {
        guard.check(senderId: 'a', text: 'same');
      }
      expect(guard.check(senderId: 'b', text: 'same').isSpam, isFalse);
    });

    test('extremely long inputs are safely bounded', () {
      final guard = LocalSpamGuard(
        clock: clock,
        config:
            const SpamGuardConfig(maxMessageLength: 100, maxSenderIdLength: 10),
      );
      expect(() => guard.check(senderId: 's' * 10000, text: 'x' * 100000),
          returnsNormally);
      final state = guard.exportState();
      expect(((state['senders']! as Map).keys.single as String).length, 10);
    });
  });

  group('persistence', () {
    test('round trips state', () {
      final source = LocalSpamGuard(clock: clock);
      source.check(senderId: 'a', text: 'hello');
      final target = LocalSpamGuard(clock: clock);
      expect(target.importState(source.exportState()), isTrue);
      expect(target.senderCount, 1);
      expect(target.exportState(), source.exportState());
    });

    test('malformed or outdated input fails without replacing state', () {
      final guard = LocalSpamGuard(clock: clock)
        ..check(senderId: 'safe', text: 'hello');
      expect(guard.importState({'version': 2, 'senders': <String, Object>{}}),
          isFalse);
      expect(
          guard.importState({
            'version': 1,
            'senders': {'x': 'bad'}
          }),
          isFalse);
      expect(guard.senderCount, 1);
    });
  });
}
