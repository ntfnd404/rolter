# Rolter release runbook

Publishing to pub.dev is permanent. Run every command from a clean checkout of
the exact release commit, inspect all generated output, and never move a
published release tag.

## Versioning before 1.0

- Compatible fixes and features increment the patch version.
- Breaking Dart API or URL grammar changes increment the minor version.
- Raising the minimum Dart or Flutter SDK increments the minor version and
  requires a migration note.
- Public API stays deprecated for at least one complete minor release before
  removal, except when a security-critical fix requires faster removal.
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
- [ ] Repository, issue tracker, homepage, and package-name availability have
      been rechecked over HTTPS.
- [ ] The publishing Google Account is an administrator of verified publisher
      `ntfnd404.dev`.
- [ ] Google, GitHub, and registrar passkeys/2FA and recovery methods work;
      offline recovery codes exist in two protected locations.
- [ ] Registrar lock and automatic renewal are enabled for `ntfnd404.dev`.

Do not commit `coverage/lcov.info`, `doc/api`, build output, credentials, or a
long-lived pub.dev token.

## First release: manual upload

The first pub.dev release is `0.1.0`. Existing historical tag `v0.0.1` is not
moved or deleted.

1. Record the green release commit with `git rev-parse HEAD`.
2. Create a clean detached checkout of that commit, without creating a tag.
3. Repeat analyze, tests, docs, `pana`, archive inspection, and publish dry-run.
4. Run `dart pub publish` and complete pub.dev authentication manually.
5. Confirm that `rolter 0.1.0` is visible and healthy on pub.dev.
6. Create annotated tag `v0.1.0` on the recorded commit and push it.
7. Create GitHub Release `rolter 0.1.0` from the changelog and link pub.dev.
8. Verify README, changelog, example, API docs, screenshots, platforms, links,
   and score on pub.dev.
9. Transfer the package to `ntfnd404.dev` and verify its publisher badge.
10. Only then enable the OIDC workflow for later releases.

If upload fails before pub.dev registers the version, fix the cause and reuse
`0.1.0`; no tag exists yet. If pub.dev registered the version, never replace
its contents: publish the next SemVer version.

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
