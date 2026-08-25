import '../models/spam_reason.dart';

final class Detection {
  const Detection(this.reason, this.weight);
  final SpamReason reason;
  final double weight;
}
