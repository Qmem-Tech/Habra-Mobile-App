# App Development General Rules

Rules we must always follow when developing this app.

---

## Command execution and feedback

- **The user runs all commands.** As a rule, the user will always run the commands (e.g. Flutter, Dart, terminal) and give back the results.
- **Commands are not run on the user’s behalf.** When working with an AI or assistant, it should provide the exact commands, steps, or scripts for the user to run locally.
- **Workflow:** When something requires running a command (e.g. `flutter pub get`, `flutter analyze`, `dart run build_runner build`):
  1. Provide the command(s) to run and the order to run them.
  2. The user runs them and pastes the full output (or relevant part) back.
  3. Use that output to diagnose issues, suggest fixes, or confirm success.

This keeps execution on the developer’s machine and ensures decisions are based on real command results.

---

## Common Flutter/Dart issues to avoid

Follow these so `flutter analyze` stays clean and we avoid recurring errors and warnings.

### 1. BuildContext after async (`use_build_context_synchronously`)

- After any `await` or `.then()`, do not use `BuildContext` until you have checked that the widget is still mounted.
- Use an early return, then use context on the next line(s). Do **not** guard with `if (context.mounted) doSomething(context);` — the analyzer may treat that as an "unrelated" check.
- **Correct:** After async, do `if (!context.mounted) return;` then use `context` on the following line(s).

### 2. Nullable type when value is never null (`unnecessary_nullable_for_final_variable_declarations`)

- If a `final` variable is initialized with a non-null value, declare it as non-nullable (e.g. `final String _x = '...'` not `final String? _x = '...'`).

### 3. Deprecated APIs

- **Color:** Use `color.withValues(alpha: x)` instead of `color.withOpacity(x)`.
- **Form fields:** Use `initialValue` where the form API requires it; add `// ignore` only when migration is not yet possible.
- **Radio:** Prefer `RadioGroup` when stable; otherwise use a short `// ignore` with a comment.

### 4. Dead code

- Remove or refactor code that is never executed. Do not leave dead branches for “future use”; use a single path or a TODO comment.

### 5. Unused imports

- Remove imports that are not used. Fix every `unused_import` reported by the analyzer.

### 6. Final fields (`prefer_final_fields`)

- If a field is only assigned once (at declaration or in `initState`), make it `final`.

### 7. String composition (`prefer_interpolation_to_compose_strings`)

- Prefer string interpolation: use `'$a - $b'` or `'${expr} - ${expr2}'` instead of `a + ' - ' + b`.
