# Contributing

Thanks for helping improve `local_spam_guard`.

Open an issue before substantial changes. Keep detection deterministic, offline,
explainable, and conservative about false positives. New signals need focused
tests and normal-conversation counterexamples.

Before submitting a pull request, run:

```sh
dart format .
dart analyze
dart test
dart pub publish --dry-run
```

Contributions are accepted under the repository's CORE License.
