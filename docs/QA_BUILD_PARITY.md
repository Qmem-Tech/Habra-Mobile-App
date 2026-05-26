# QA build parity

When verifying Habra–Mol tickets, record:

| Field | How |
|--------|-----|
| Git commit | `git rev-parse HEAD` |
| App version | `version` in `pubspec.yaml` |
| Dart defines | Values from `dart_defines.json` (no secrets in tickets; use placeholders in notes) |

Compare behavior on the **same defines** and **release vs debug** as production when possible.
