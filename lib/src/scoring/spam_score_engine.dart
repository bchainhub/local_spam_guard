import '../detectors/detection.dart';

double combineScores(Iterable<Detection> detections) {
  var remaining = 1.0;
  for (final detection in detections) {
    remaining *= 1 - detection.weight.clamp(0, 1);
  }
  return (1 - remaining).clamp(0, 1);
}
