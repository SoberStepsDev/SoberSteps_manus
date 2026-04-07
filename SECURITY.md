# Security policy

SoberSteps takes the security of our users and their data seriously. This document describes how to report vulnerabilities and what you can expect from us.

**Related repository policies**

- Dependency updates and verification: [`docs/DEPENDENCIES.md`](docs/DEPENDENCIES.md)
- Android signing keys (local only, never commit secrets): [`android/KEYSTORE.md`](android/KEYSTORE.md)

SoberSteps processes **health-adjacent** user data in context of sobriety support. Reports must **not** paste real user content, recovery details, or live credentials—use redacted, synthetic examples only.

## Supported versions

We provide security updates for **currently supported production releases** of the SoberSteps mobile app (the version families distributed through official app stores). The `version` field in root [`pubspec.yaml`](pubspec.yaml) tracks the current app release line (for example **1.0.x** at time of writing).

| Version / channel | Supported |
| ----------------- | --------- |
| Latest **1.x** release on official stores | Yes |
| Older **1.x** builds (no longer offered for download) | Best effort |
| Pre-release / sideloaded builds, forks, or modified binaries | No |

If you are unsure whether your finding applies to a supported build, report it anyway; we will triage it.

## Reporting a vulnerability

**Please do not** open a public GitHub issue for security-sensitive reports (that can put users at risk before a fix is available).

### Preferred: GitHub private reporting

1. Open **[Report a vulnerability](https://github.com/SoberStepsDev/SoberSteps_manus/security/advisories/new)** for this repository (GitHub → **Security** → **Report a vulnerability**).
2. Include enough detail for us to reproduce or understand the impact (steps, affected component, app version / platform if known).
3. **Do not** include live secrets, tokens, passwords, or personal health data. Use redacted examples only.

If private reporting is unavailable in the UI, use **Security → Advisories** on the repository or contact the maintainers through a channel they publish for security contact (do not post exploit details publicly).

## What to expect

- We will acknowledge receipt as soon as practical (typically within a few business days).
- We may ask follow-up questions to assess severity and scope.
- We will coordinate a fix and release timeline where applicable, then disclose responsibly (for example via a security advisory) after mitigation is available.

## Scope (high level)

In scope for coordinated disclosure:

- This repository (client app), official release builds, and integrations that ship with them (for example Supabase client usage, auth/session handling, local storage) when the issue affects user safety or data.
- **Supply chain:** vulnerable or malicious dependencies when exploitable through a supported build path (please also follow [`docs/DEPENDENCIES.md`](docs/DEPENDENCIES.md) for maintainer response).

Out of scope (examples):

- Social engineering or physical access to a user’s device.
- Issues in third-party services **only** fixable by the vendor (report to them; we may still appreciate a heads-up).
- Theoretical problems without a plausible attack path against a supported build.

We appreciate responsible disclosure and thank reporters who help keep SoberSteps users safer.
