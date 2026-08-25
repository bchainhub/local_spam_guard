import 'message_record.dart';

final class SenderSpamState {
  SenderSpamState({required this.lastSeen});

  final List<MessageRecord> history = [];
  int strikes = 0;
  DateTime? lastStrikeAt;
  DateTime? suspendedUntil;
  DateTime lastSeen;
}
