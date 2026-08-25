# Local Spam Guard

`local_spam_guard` is an offline-first spam detection and rate-limiting library
for Dart and Flutter chat applications. It detects flooding, repeated messages,
link spam, and other abusive messaging patterns entirely on-device.

It is designed for peer-to-peer, mesh, Bluetooth, Wi-Fi Direct, LAN, off-grid,
and conventional chat applications where privacy matters or no moderation server
exists.

## Privacy guarantee

The package makes no network requests, requires no API key or Internet
permission, and contains no analytics or telemetry. Messages and sender IDs never
leave the process through this library. State is held in memory unless your
application explicitly exports and persists it.

## Installation

```sh
dart pub add local_spam_guard
```

The implementation is pure Dart and works in Dart applications and Flutter on
Android, iOS, desktop, and web.

## Basic usage

```dart
import 'package:local_spam_guard/local_spam_guard.dart';

final guard = LocalSpamGuard(); // Strong protection by default.

final result = guard.check(
  senderId: senderPublicKey,
  text: message.text,
);

switch (result.action) {
  case SpamAction.allow:
    display(message);
  case SpamAction.filter:
    hide(message);
  case SpamAction.suspend:
    rejectLocally(senderPublicKey);
}
```

`senderId` is a stable public key, peer ID, account ID, or device identity
supplied by your application. The library does not create or authenticate
identities.

## How detection works

Independent signals inspect sliding message-rate windows, exact normalized
duplicates, near-duplicates (using bounded bigram similarity), URLs, repeated
URLs, repeated characters/tokens, punctuation, and capitalization. Their weights
combine probabilistically into a normalized score from 0 to 1. A result exposes
the score, `SpamReason` values, and recommended action.

One weak signal normally does not trigger filtering. Several weak signals become
meaningful together. All heuristics are deterministic; there is no ML model.

## Filter strengths

- `off` allows everything and collects no new state.
- `medium` tolerates larger bursts and more repetition to minimize false positives.
- `strong` is the balanced default.
- `intense` uses tighter rate, repetition, similarity, URL, score, strike, and cooldown settings.

Strength can be changed at runtime while retaining history:

```dart
guard.strength = SpamFilterStrength.intense;
```

All preset thresholds are centralized in `ResolvedSpamGuardConfig.preset`.
Advanced applications can override individual values:

```dart
final guard = LocalSpamGuard(
  config: const SpamGuardConfig(
    maxSenders: 500,
    maxHistoryPerSender: 30,
    scoreThreshold: 0.65,
  ),
);
```

Invalid configurations throw `ArgumentError` during construction or a strength
change.

## Local cooldowns and strike decay

A filtered result adds one sender-local strike. Repeated violations trigger a
temporary cooldown, with later cooldowns increasing up to a bounded multiplier.
Strikes decay lazily at the configured interval when sender state is accessed;
no timer or background process runs.

```dart
if (guard.isSuspended(peerId)) {
  final suspension = guard.getSuspension(peerId)!;
  print(suspension.remaining);
}

guard.clearSuspension(peerId); // Keep strikes/history.
guard.resetSender(peerId);     // Remove all state for one sender.
```

A local suspension does **not** stop a malicious peer from transmitting packets.
It tells the receiving application to reject or filter messages associated with
that sender ID on this device.

## Optional persistence

The core has no storage dependency. Export a JSON-compatible map and persist it
with any storage your application chooses:

```dart
final jsonCompatibleState = guard.exportState();
final accepted = guard.importState(savedState);
```

Import validates version, types, dates, and configured bounds. Malformed or
outdated state returns `false` without replacing current state. Exported state
contains sender IDs and bounded normalized message history; protect it according
to your application's privacy requirements.

## Resource limits

Defaults retain at most 1,000 sender records and 40 recent messages per sender.
Messages are inspected/stored up to 8,192 UTF-16 code units, sender IDs to 512,
URLs to 20, and similarity to 16 recent records. History expires after the long
rate window. Regexes are simple and bounded input prevents pathological work.

## Limitations

This package answers whether this receiving application should locally treat a
message/sender as spam based on recent local behavior. It does not establish a
universal reputation, inspect packet-level abuse, understand language semantics,
authenticate sender IDs, or synchronize moderation decisions between devices.
Applications should still bound inbound packets before decoding and apply their
own identity and transport controls.

See the runnable [example](example/local_spam_guard_example.dart).

## License

[CORE License](LICENSE). Source distributions, modifications, and contributions
must be disclosed and publicly available as described in the license.
