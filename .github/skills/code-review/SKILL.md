---
name: code-review
description: Review pull requests in the Mobile Token SDK for Flutter. Use when reviewing Dart APIs, native bridges, operations, OIDC, push, security, or release changes.
---

# mToken Flutter SDK review

## Review contract

Review only PR and repository content already available. Do not run or suggest
commands, scripts, builds, tests, linters, formatters, validation tasks, or Git
operations. Determine the pull request target and head from available content
only. This repository normally merges to `develop`; releases use
`release/a.b.x`. Default to approval. Raise only a demonstrated defect
introduced by the PR, with path/line, concrete impact, and exact corrective
direction. Do not provide formatting, style, CI, speculative, or generic
testing advice. Do not post any GitHub review/comment without user approval;
begin all postable content with `🤖`. Grammar is reviewable only in public
documentation/Dartdoc and only if the PR base is not a release branch.

Public user-visible API/flow changes require associated docs and changelog
updates. `pubspec.yaml` declares the package version: release-to-`develop`
changes must leave every declared version as `0.0.1-dev`.

## Code and API map

The public export is `lib/mtoken_sdk_flutter.dart`. The SDK is pure Dart over
`flutter_powerauth_mobile_sdk_plugin`, with these API groups:

* `lib/src/wultra_mobile_token.dart` coordinates the SDK;
* `operations/` covers online/user/QR operations, polling, proximity checks,
  PAC utilities, pre-approval, rejection, and operation listener contracts;
* `oidc/` handles configuration, authorization request, activation attributes,
  PKCE codes, and OIDC errors;
* `inbox/`, `push/`, and `networking/` hold inbox, notification, REST response
  and known-error behavior;
* `core/` contains version, exception, and logging behavior; `utils/` contains
  JSON decoding and response processing.

Treat `README.md`, `docs/`, `CHANGELOG.md`, and `pubspec.yaml` as public
release surfaces. Tests under `test/` include deserialization, operations
polling, QR parsing, proximity/PAC, pre-approval, mobile-token data, and logs;
`example/integration_test/` is the platform integration host. Tests and tracked
analysis/test/integration workflow definitions may be inspected as evidence,
but never executed or suggested as validation.

## Security and protocol review

Review all HTTP/protocol code in `networking/`, OIDC/PKCE code in `oidc/`,
operation authorization in `operations/`, and push payload handling in `push/`
as security-sensitive. Preserve the dependency plugin's PowerAuth signing,
authentication and encrypted transport semantics; a request must not silently
drop authorization context, alter a signed body after signature creation, or
treat a transport/protocol error as success.

Never expose operation authorization data, activation attributes, access or
refresh tokens, PKCE verifier, PAC, authentication factors, request headers,
or decrypted response details in logs or exceptions. `core/logger.dart` must
respect redaction. Treat backend fields as untrusted: reject malformed,
unexpectedly nullable, or wrong-type JSON at the decoding boundary rather than
using unsafe casts or defaulting a security decision.

Maintain wire compatibility for operation IDs, timestamps, enum/string values,
JSON key names, OIDC redirects and query parameters. A change to
`json_utils.dart`, `response_processor.dart`, response-error mapping, QR
parsing, or model `fromJson`/`toJson` merits paired valid and invalid payload
coverage when existing test fixtures cover that contract.

## Async and behavioral checks

Futures, operation polling, and listeners must complete exactly once, stop
polling after cancellation/disposal, propagate cancellation/network failures,
and avoid callbacks after a listener is removed. Preserve ordering between a
received push, refreshed operation, user authorization/rejection, and listener
notification. Do not turn a failing `Future` into a nullable/success result.

For a public API change, confirm export from
`lib/mtoken_sdk_flutter.dart`, docs, and source compatibility. For changed
operations/OIDC/network decoding behavior, look for focused coverage in the
corresponding test (`operations_polling_test.dart`, `deserialization_test.dart`,
`qr_parser_test.dart`, `pac_utils_test.dart`, or `pre_approval_test.dart`).
Assess that coverage by reading it only; do not report lack of unrelated CI
work.
