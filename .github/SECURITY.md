# Security policy

## Supported versions

The latest published `0.x` release is the supported security branch. Older
minor releases may receive decoder compatibility but do not receive separate
security backports unless a release note explicitly says otherwise.

## Reporting a vulnerability

Use GitHub's **Report a vulnerability** form in the repository Security tab to
submit a private vulnerability report. Do not publish a proof of concept,
exploit details, secrets, or affected-user data in a public issue before a
coordinated disclosure.

The maintainer will:

- acknowledge the report within seven calendar days;
- provide a status update at least every 30 days while it remains open;
- assess impact, affected versions, and a remediation timeline based on
  severity; and
- coordinate disclosure and credit with the reporter when practical.

Security-critical fixes may shorten the normal deprecation window or the URL
wire-format compatibility window. Any such exception will be documented in the
security advisory and release notes.

Public issues are appropriate for non-sensitive hardening suggestions and bugs
that do not expose users to a security risk.
