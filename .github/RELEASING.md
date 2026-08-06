# Rolter release runbook

Publishing to pub.dev is permanent. Run every command from a clean checkout of
the exact release commit, inspect all generated output, and never move a
published release tag.

## Versioning before 1.0

- Compatible fixes and features increment the patch version.
- Breaking Dart API or URL grammar changes increment the minor version.
- Raising the minimum Dart or Flutter SDK increments the minor version and
  requires a migration note.
- Before 1.0, deprecation is required only when a compatibility path is both
  inexpensive and architecturally correct. A clean removal in `0.x.0` requires
  explicit owner approval, a `Breaking changes` changelog section, and a
  migration guide; do not create a temporary compatibility hierarchy solely to
  avoid a minor-version breaking change.
- From 1.0 onward, deprecated public API remains available for at least one
  complete minor release and is removed only in a subsequent major release,
  except when a security-critical fix requires faster removal.
- The encoder writes the current URL wire format. The decoder accepts the
  previous minor's format for at least one complete minor release cycle.

## Preflight checklist

- [ ] The release commit is on protected `main` and `git status` is clean.
- [ ] `pubspec.yaml`, the first `CHANGELOG.md` section, the README dependency,
      and the intended `vX.Y.Z` tag all contain the same version.
- [ ] Latest-stable quality, coverage, docs, archive, `pana`, platform, and
      WebAssembly checks pass.
- [ ] Flutter 3.32.0 declared-minimum and downgraded-dependency checks pass.
- [ ] `dart pub publish --dry-run` reports no warnings and its file list has
      been reviewed for secrets, local paths, generated output, and excess
      files.
- [ ] Both screenshots and the package archive are within pub.dev limits.
- [ ] `screenshots/architecture.svg` was reviewed at original size and zoom;
      `architecture.webp` was manually derived from that SVG rather than
      edited independently, and both render the same diagram.
- [ ] Repository, issue tracker, homepage, and package-name availability have
      been rechecked over HTTPS.
- [ ] The publishing Google Account is an administrator of verified publisher
      `ntfnd404.dev`.
- [ ] Google, GitHub, and registrar passkeys/2FA and recovery methods work;
      offline recovery codes exist in two protected locations.
- [ ] Registrar lock and automatic renewal are enabled for `ntfnd404.dev`.

Do not commit `coverage/lcov.info`, `doc/api`, build output, credentials, or a
long-lived pub.dev token.

## Package page and breaking-change notes

Pub.dev has no separate breaking-change form. It renders the package's root
`CHANGELOG.md` in the **Changelog** tab, so every breaking release must make its
top version section self-contained: mark the breaking change explicitly,
describe removed and required APIs, include a minimal before/after migration,
and link the complete guide. Keep version headings consistent so tools can
parse them. See Dart's
[package layout conventions](https://dart.dev/tools/pub/package-layout).

The root `README.md` is the package landing page. Follow the official
[package-page guidance](https://dart.dev/tools/pub/writing-package-pages): keep
the description and constraints near the top, place useful visuals early, use
lists and Dart-formatted copyable examples, mention searchable terms such as
dependency injection, centralized routing, feature-first routing, nested
navigation, and deep linking, and tell readers where to continue. Use absolute
URLs for images so they render consistently outside GitHub.

Pub.dev selects a conventional file under `example/` for its **Example** tab.
Rolter uses `example/example.md` to index the runnable feature-first,
centralized, narrow-scope, and adapter entrypoints. Before release, verify every
command and link in that file and inspect all four package tabs: README,
Changelog, Example, and API reference.

For a pre-1.0 breaking release, Dart convention shifts semantic versioning down
one position: `0.1.x` to `0.2.0` communicates a breaking change. See
[package versioning](https://dart.dev/tools/pub/versioning). Before any upload,
run `dart pub publish --dry-run`, inspect the complete archive file list, and
resolve every warning; the command performs publication validation without
uploading. See the official
[`dart pub publish` reference](https://dart.dev/tools/pub/cmd/pub-lish).

## Historical first release

The first pub.dev release, `0.1.0`, has already been published manually.
Existing historical tags are immutable. Do not repeat the first-release flow or
attempt to replace its archive.

Rolter `0.2.0` is a later release and follows the OIDC flow below after owner
approval. Preparing `pubspec.yaml`, changelog, docs, and dry-run metadata does
not authorize a commit, tag, release, or upload.

## Later releases: GitHub OIDC

1. Update `pubspec.yaml`, `CHANGELOG.md`, and the README constraint.
2. Merge only after all required checks pass on the protected `main` branch.
3. Create a new annotated strict SemVer tag `vX.Y.Z`; never move it.
4. Before requesting Environment approval, the tag workflow fetches a fresh
   `origin/main`, peels the annotated tag to its commit, and fails closed unless
   that commit exactly equals `origin/main`.
5. The tag workflow verifies the tag against package metadata and changelog.
6. Approve the `pub-dev` Environment deployment as GitHub user `ntfnd404`.
7. OIDC publishes without a persistent token.
8. A transient infrastructure failure may rerun the unchanged job. A code or
   metadata defect requires a new version.

The `pub-dev` Environment is restricted to `v*.*.*` tags, has `ntfnd404` as its
only required reviewer, leaves **Prevent self-review** disabled, and grants no
administrator bypass when that can be configured without losing recovery
access. The single-owner bus-factor risk is accepted intentionally; do not add
a second publisher administrator or reviewer without changing this policy.

## Retraction and discontinuation

Published versions are immutable. Use pub.dev's retraction mechanism only when
the version qualifies and directing users away from it is necessary. Publish a
fixed version first whenever possible and document the reason without exposing
sensitive exploit detail. If maintenance ends, mark the package discontinued
on pub.dev, update the README with the successor or migration path, and archive
the repository only after users have a clear notice.

## Access recovery

If normal access is lost, use the stored Google/GitHub recovery methods and
offline codes, then validate the domain through the locked registrar account.
Rotate any credentials implicated in the event and audit GitHub deployments,
publisher members, releases, tags, and domain DNS. Because there is no second
administrator, recovery depends entirely on these owner-controlled methods.
