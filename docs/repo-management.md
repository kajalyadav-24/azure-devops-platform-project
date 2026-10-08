# Repository Management and Hygiene

## Goal

Keep the repository reviewable, reproducible, and safe for a public portfolio.

## Source files that belong in Git

Commit application source, Dockerfile, dependency manifests, GitHub Actions workflows, Terraform `.tf` files, Terraform lock files, Kubernetes YAML, Helm chart files, documentation, and operational scripts.

## Generated/local files that should not be tracked

Typical exclusions:

```gitignore
# Python
.venv/
venv/
__pycache__/
*.py[cod]
.pytest_cache/

# Terraform
**/.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log
crash.*.log

# Local environment / secrets
.env
.env.*
!.env.example
*.pem
*.key

# Editors / OS
.vscode/
.idea/
.DS_Store
Thumbs.db
```

Terraform `.terraform.lock.hcl` files are intentionally **not** ignored; they pin provider selections and should normally be version controlled.

## Forbidden-file audit

Run:

```powershell
git ls-files | Select-String "\.venv|\.terraform/|terraform\.tfstate|tfplan|drift\.tfplan|__pycache__"
```

Expected result: no output.

If a generated file was accidentally committed, add it to `.gitignore` and remove it only from Git tracking:

```powershell
git rm -r --cached <path>
```

Do not run `git rm` blindly against infrastructure source directories.

## Secret audit

Do not commit:

- Azure client secrets.
- Key Vault secret values.
- Personal email addresses used for alert receivers unless intentionally public.
- access tokens / PATs.
- kubeconfig files.
- service-account tokens.
- `.env` files containing credentials.

IDs such as subscription, tenant, or managed identity client IDs are not passwords, but public documentation should still prefer placeholders unless the identifier is necessary for reproducibility.

## Pre-commit quality checks

```powershell
git status
git diff --check
terraform fmt -recursive -check .\terraform
helm lint .\helm\incident-app
```

If Terraform is being changed, also run `terraform validate` from the relevant initialized working directory.

## Commit strategy

Use focused commits that explain intent. Examples:

```text
feat: add AKS workload identity and Key Vault integration
feat: add container insights and application error alert
fix: correct Helm deployment template indentation
fix: preserve workload identity values in CD deployment
chore: finalize project documentation and runbooks
```

Avoid commits such as `changes`, `update`, or `final final` because they do not help reviewers understand history.

## Recommended branch workflow

For a portfolio repo, `main` can remain the deployable branch. For future changes:

```text
main
  <- feature/<short-description>
  <- fix/<short-description>
  <- docs/<short-description>
```

Use a pull request before merge when you want to demonstrate review discipline.

## GitHub Actions hygiene

- Pin deployments to an exact source SHA.
- Keep Azure authentication on OIDC federation.
- Do not echo tokens or secrets.
- Prefer repository variables for non-sensitive configuration and secrets only for truly secret values.
- Fail deployment if the target image tag is missing.
- Keep CI responsible for artifact creation and CD responsible for release.

## Release traceability

The preferred chain is:

```text
Git commit SHA
  -> Docker image tag
  -> ACR image
  -> Helm release values
  -> AKS deployment image
```

This allows an interviewer/operator to trace a running pod back to source.

## Documentation ownership

Update these files when behavior changes:

- `README.md` for the public project story.
- `docs/architecture.md` for design changes.
- `docs/runbook.md` for operational commands.
- `docs/incident-response.md` for incidents/RCA.
- `docs/troubleshooting-log.md` for recurring troubleshooting lessons.
- `docs/interview-guide.md` for claims that must match the implemented project.

Documentation should describe what is actually implemented, not aspirational tooling.
