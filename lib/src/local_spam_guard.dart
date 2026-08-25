import 'detectors/detection.dart';
import 'detectors/duplicate_detector.dart';
import 'detectors/flood_detector.dart';
import 'detectors/formatting_detector.dart';
import 'detectors/link_detector.dart';
import 'detectors/similarity_detector.dart';
import 'models/spam_action.dart';
import 'models/spam_filter_strength.dart';
import 'models/spam_guard_config.dart';
import 'models/spam_reason.dart';
import 'models/spam_result.dart';
import 'models/suspension.dart';
import 'scoring/spam_score_engine.dart';
import 'state/message_record.dart';
import 'state/sender_spam_state.dart';
import 'utils/clock.dart';
import 'utils/normalization.dart';
import 'utils/url_parser.dart';

/// A synchronous, fully offline spam guard for incoming chat messages.
///
/// State, reputation, and cooldowns are local to this instance. The class does
/// not make network requests, manage identities, or prevent remote packets.
final class LocalSpamGuard {
  /// Creates a guard with [SpamFilterStrength.strong] protection by default.
  ///
  /// [config] selectively overrides the selected strength's preset. [clock]
  /// is intended for deterministic tests and specialized host applications.
  LocalSpamGuard({
    SpamFilterStrength strength = SpamFilterStrength.strong,
    SpamGuardConfig config = const SpamGuardConfig(),
    SpamGuardClock? clock,
  })  : _strength = strength,
        _overrides = config,
        _clock = clock ?? const SystemSpamGuardClock(),
        _resolved = config.resolve(strength);

  SpamFilterStrength _strength;
  final SpamGuardConfig _overrides;
  final SpamGuardClock _clock;
  ResolvedSpamGuardConfig _resolved;
  final Map<String, SenderSpamState> _senders = {};

  /// The active filtering strength.
  SpamFilterStrength get strength => _strength;

  /// Changes filtering strength while retaining sender history.
  ///
  /// Existing advanced overrides are applied to the new preset. Switching to
  /// [SpamFilterStrength.off] allows messages and collects no new state.
  set strength(SpamFilterStrength value) {
    _strength = value;
    _resolved = _overrides.resolve(value);
    _trimToLimits();
  }

  /// The fully resolved active limits, useful for diagnostics.
  ResolvedSpamGuardConfig get effectiveConfig => _resolved;

  /// Number of sender records currently retained.
  int get senderCount => _senders.length;

  /// Checks an incoming [text] associated with the application's [senderId].
  ///
  /// Empty input is allowed. Very large inputs and sender IDs are inspected
  /// only up to configured bounds, keeping work and memory predictable.
  SpamResult check({required String senderId, required String text}) {
    if (_strength == SpamFilterStrength.off) return _allowed;
    final now = _clock.now().toUtc();
    final key = boundedSenderId(senderId, _resolved.maxSenderIdLength);
    final state = _stateFor(key, now);
    _decayAndExpire(state, now);
    final until = state.suspendedUntil;
    if (until != null && now.isBefore(until)) {
      state.lastSeen = now;
      return const SpamResult(
        isSpam: true,
        score: 1,
        action: SpamAction.suspend,
        reasons: [SpamReason.senderSuspended],
      );
    }

    _pruneHistory(state, now);
    final normalized = normalizeMessage(text, _resolved.maxMessageLength);
    final similarityText = normalizeForSimilarity(normalized);
    final urls = extractUrls(normalized, _resolved.maxUrlsPerMessage);
    final boundedText = text.length <= _resolved.maxMessageLength
        ? text
        : text.substring(0, _resolved.maxMessageLength);
    final detections = <Detection>[
      ...detectFormatting(boundedText),
      ...detectLinks(normalized, urls, state.history, _resolved),
      if (detectFlood(state.history, now, _resolved) case final signal?) signal,
      if (detectDuplicates(normalized, state.history, _resolved)
          case final signal?)
        signal,
      if (detectSimilarity(similarityText, state.history, _resolved)
          case final signal?)
        signal,
    ];
    final score = combineScores(detections);
    final isSpam = score >= _resolved.scoreThreshold;
    var action = isSpam ? SpamAction.filter : SpamAction.allow;
    if (isSpam) {
      _addStrike(state, now);
      if (state.strikes >= _resolved.strikesBeforeSuspension) {
        final multiplier = 1 <<
            (state.strikes - _resolved.strikesBeforeSuspension).clamp(0, 5);
        state.suspendedUntil = now.add(_resolved.baseCooldown * multiplier);
        action = SpamAction.suspend;
      }
    }
    state.history.add(MessageRecord(
      at: now,
      normalized: normalized,
      similarityText: similarityText,
      urls: urls,
    ));
    if (state.history.length > _resolved.maxHistoryPerSender) {
      state.history
          .removeRange(0, state.history.length - _resolved.maxHistoryPerSender);
    }
    state.lastSeen = now;
    return SpamResult(
      isSpam: isSpam,
      score: score,
      action: action,
      reasons: List.unmodifiable(detections.map((item) => item.reason).toSet()),
    );
  }

  /// Whether [senderId] is currently in a local temporary cooldown.
  bool isSuspended(String senderId) => getSuspension(senderId) != null;

  /// Returns active local cooldown details for [senderId], or null.
  SpamSuspension? getSuspension(String senderId) {
    final key = boundedSenderId(senderId, _resolved.maxSenderIdLength);
    final state = _senders[key];
    if (state == null) return null;
    final now = _clock.now().toUtc();
    _decayAndExpire(state, now);
    final until = state.suspendedUntil;
    if (until == null) return null;
    return SpamSuspension(until: until, remaining: until.difference(now));
  }

  /// Clears only the active local cooldown, retaining history and strikes.
  void clearSuspension(String senderId) {
    final key = boundedSenderId(senderId, _resolved.maxSenderIdLength);
    _senders[key]?.suspendedUntil = null;
  }

  /// Removes all locally retained state for [senderId].
  void resetSender(String senderId) {
    final key = boundedSenderId(senderId, _resolved.maxSenderIdLength);
    _senders.remove(key);
  }

  /// Removes all locally retained spam state.
  void resetAll() => _senders.clear();

  /// Exports bounded state as a JSON-compatible map.
  ///
  /// Message text and sender IDs are included because behavioral detection
  /// needs them. Applications are responsible for protecting persisted data.
  Map<String, Object> exportState() {
    final now = _clock.now().toUtc();
    for (final state in _senders.values) {
      _decayAndExpire(state, now);
    }
    return {
      'version': 1,
      'senders': _senders.map((key, state) => MapEntry(key, {
            'strikes': state.strikes,
            'lastStrikeAt': state.lastStrikeAt?.toUtc().toIso8601String(),
            'suspendedUntil': state.suspendedUntil?.toUtc().toIso8601String(),
            'lastSeen': state.lastSeen.toUtc().toIso8601String(),
            'history': state.history.map((record) => record.toJson()).toList(),
          })),
    };
  }

  /// Safely replaces state from an [exportState] map.
  ///
  /// Returns false and leaves existing state unchanged if the input is
  /// malformed or uses an unsupported version.
  bool importState(Map<String, Object?> data) {
    try {
      if (data['version'] != 1 || data['senders'] is! Map) return false;
      final imported = <String, SenderSpamState>{};
      final rawSenders = data['senders']! as Map;
      for (final entry in rawSenders.entries.take(_resolved.maxSenders)) {
        if (entry.key is! String || entry.value is! Map) return false;
        final key =
            boundedSenderId(entry.key as String, _resolved.maxSenderIdLength);
        final raw = entry.value as Map;
        final lastSeen = DateTime.tryParse(raw['lastSeen'] as String? ?? '');
        final strikes = raw['strikes'];
        final history = raw['history'];
        if (lastSeen == null ||
            strikes is! int ||
            strikes < 0 ||
            history is! List) {
          return false;
        }
        final state = SenderSpamState(lastSeen: lastSeen.toUtc())
          ..strikes = strikes;
        state.lastStrikeAt = _dateOrNull(raw['lastStrikeAt']);
        state.suspendedUntil = _dateOrNull(raw['suspendedUntil']);
        for (final item in history.take(_resolved.maxHistoryPerSender)) {
          if (item is! Map) return false;
          final at = DateTime.tryParse(item['at'] as String? ?? '');
          final text = item['text'];
          final similarityText = item['similarityText'];
          final rawUrls = item['urls'];
          if (at == null ||
              text is! String ||
              similarityText is! String ||
              rawUrls is! List ||
              rawUrls.any((url) => url is! String)) {
            return false;
          }
          state.history.add(MessageRecord(
            at: at.toUtc(),
            normalized: normalizeMessage(text, _resolved.maxMessageLength),
            similarityText:
                normalizeMessage(similarityText, _resolved.maxMessageLength),
            urls: rawUrls
                .cast<String>()
                .take(_resolved.maxUrlsPerMessage)
                .toList(),
          ));
        }
        imported[key] = state;
      }
      _senders
        ..clear()
        ..addAll(imported);
      _trimToLimits();
      return true;
    } on Object {
      return false;
    }
  }

  static const _allowed = SpamResult(
    isSpam: false,
    score: 0,
    action: SpamAction.allow,
    reasons: [],
  );

  SenderSpamState _stateFor(String key, DateTime now) {
    final existing = _senders.remove(key);
    if (existing != null) {
      _senders[key] = existing;
      return existing;
    }
    if (_senders.length >= _resolved.maxSenders) {
      _senders.remove(_senders.keys.first);
    }
    return _senders[key] = SenderSpamState(lastSeen: now);
  }

  void _pruneHistory(SenderSpamState state, DateTime now) {
    final cutoff = now.subtract(_resolved.longWindow);
    state.history.removeWhere((record) => record.at.isBefore(cutoff));
  }

  void _decayAndExpire(SenderSpamState state, DateTime now) {
    final lastStrike = state.lastStrikeAt;
    if (lastStrike != null && state.strikes > 0 && now.isAfter(lastStrike)) {
      final elapsed = now.difference(lastStrike).inMicroseconds;
      final interval = _resolved.strikeDecayInterval.inMicroseconds;
      final decay = elapsed ~/ interval;
      if (decay > 0) {
        state.strikes = (state.strikes - decay).clamp(0, state.strikes);
        state.lastStrikeAt =
            lastStrike.add(_resolved.strikeDecayInterval * decay);
      }
    }
    final until = state.suspendedUntil;
    if (until != null && !now.isBefore(until)) state.suspendedUntil = null;
  }

  void _addStrike(SenderSpamState state, DateTime now) {
    _decayAndExpire(state, now);
    state.strikes++;
    state.lastStrikeAt = now;
  }

  void _trimToLimits() {
    while (_senders.length > _resolved.maxSenders) {
      _senders.remove(_senders.keys.first);
    }
    for (final state in _senders.values) {
      if (state.history.length > _resolved.maxHistoryPerSender) {
        state.history.removeRange(
            0, state.history.length - _resolved.maxHistoryPerSender);
      }
    }
  }

  static DateTime? _dateOrNull(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException();
    return DateTime.parse(value).toUtc();
  }
}
