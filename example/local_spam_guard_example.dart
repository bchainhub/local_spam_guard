import 'package:local_spam_guard/local_spam_guard.dart';

void main() {
  final guard = LocalSpamGuard();
  final result = guard.check(senderId: 'peer-public-key', text: 'Hello!');

  switch (result.action) {
    case SpamAction.allow:
      print('Display message');
    case SpamAction.filter:
      print('Message filtered: ${result.reasons}');
    case SpamAction.suspend:
      print('Peer temporarily suspended locally');
  }

  guard.strength = SpamFilterStrength.intense;
}
