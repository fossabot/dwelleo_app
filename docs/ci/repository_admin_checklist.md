# Repository admin checklist for CI and branch protection

These items cannot be fully enforced by source changes alone and require a repository administrator.

## Branch protections / rulesets

- Protect `development` and `main`.
- Require pull requests before merging.
- Require at least one approving review; increase to two approvals for release/signing/security PRs if the team agrees.
- Require CODEOWNERS review after final owners are confirmed.
- Require resolved conversations before merge.
- Block force pushes and branch deletion.
- Require branches to be up to date before merge if the team wants linear gate behavior.

## Required status checks

After workflows have run at least once, configure required checks for:

- `quality / format-analyze-test`
- `android / dev-staging debug APKs`
- `ios / dev-staging simulator builds`
- `security / dependency review` where GitHub dependency review is available

## GitHub security settings

- Review secret-scanning alerts.
- Enable push protection where available.
- Enable Dependabot alerts and security updates if allowed for the repository.
- Review dependency review availability for private repositories/plan limits.

## Environments and secrets

- Configure GitHub environments for `development`, `staging`, and `production` before release automation.
- Store signing credentials only as GitHub environment/repository secrets or an approved external signing service.
- Never commit keystores, provisioning profiles, App Store Connect private keys, Firebase service accounts, or `.env` files.
- Add only future secret names to workflows; do not add secret values.

## Firebase and Maps

- Confirm per-flavor Firebase apps/projects.
- Review Firebase Security Rules, App Check enforcement, and API-key restrictions.
- Restrict Maps keys by package/bundle ID, SHA-1 where applicable, and allowed APIs.
