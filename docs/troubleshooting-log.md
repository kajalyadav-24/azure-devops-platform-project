# Troubleshooting Log

This log captures issues encountered during the build, the reasoning used to isolate them, and the reusable lesson from each one.

## 1. AKS node VM family quota unavailable

**Symptom:** AKS creation could not proceed with the originally selected VM size/family.

**Root cause:** The region had no usable quota for the requested VM family even though other regional vCPU quota existed.

**Diagnostics:**

```powershell
az vm list-usage --location centralindia --output table
```

**Fix:** Switched the node pool to a VM family with available quota and used two `Standard_D4s_v4` nodes.

**Lesson:** Azure VM quota is enforced by family as well as regional total. Check the exact family before assuming a regional vCPU total is sufficient.

---

## 2. Terraform showed AKS upgrade-setting drift

**Symptom:** Terraform wanted to update AKS upgrade settings even though no functional application change was intended.

**Root cause:** Provider/API defaults were being represented explicitly after refresh.

**Fix:** Added explicit upgrade settings to Terraform so configuration matched the intended state.

**Lesson:** Normalize important provider defaults in code when repeated drift makes plans noisy or ambiguous.

---

## 3. `az aks check-acr` problem on Windows

**Symptom:** The helper check hit a local/temp-file related issue and did not provide a reliable validation path.

**Fix:** Proved registry integration directly by running a temporary pod that pulled an image from ACR.

**Lesson:** When a convenience diagnostic fails, test the actual dependency path. A real image pull is stronger evidence than a helper command.

---

## 4. Helm adoption / existing Kubernetes resources

**Symptom:** Helm could not cleanly take control of resources that had originally been created with raw `kubectl apply` manifests.

**Root cause:** The same objects already existed without Helm release ownership metadata and later field-manager ownership also conflicted.

**Fix:** Adopted the resources into the Helm release and resolved field conflicts during the transition.

**Lesson:** Avoid managing the same Kubernetes Deployment long-term with both raw `kubectl apply` and Helm. Choose one release owner after migration.

---

## 5. PowerShell vs Bash continuation syntax

**Symptom:** Multiline commands copied with Bash-style `\` continuation did not work in Windows PowerShell.

**Fix:** Used PowerShell backticks for line continuation or single-line commands.

**Lesson:** Shell syntax matters in operational documentation. Commands in this project are documented for PowerShell.

---

## 6. Placeholder image tag used literally

**Symptom:** A command referenced a placeholder instead of the actual SHA/tag.

**Root cause:** Example text was copied without replacing the placeholder.

**Fix:** Queried/used the real build SHA.

**Lesson:** Prefer scripts that derive artifact identifiers automatically rather than requiring manual placeholder replacement.

---

## 7. GitHub Actions Azure login: `No subscriptions found`

**Symptom:** OIDC authentication reached Azure but the service principal could not operate against the target subscription/resources.

**Root cause:** Federated identity authentication existed, but required Azure RBAC permissions were incomplete.

**Fix:** Added the appropriate Azure roles for the CI/CD service principal, including ACR and AKS access needed by the workflows.

**Lesson:** Authentication and authorization are separate. Successful federation proves identity; Azure RBAC determines what that identity can do.

---

## 8. Invalid placeholder workflow in `.github/workflows`

**Symptom:** GitHub reported that a workflow had no event triggers defined in `on`.

**Root cause:** A placeholder `terraform.yml` file existed in the workflows directory.

**Fix:** Removed the unused invalid workflow rather than keeping a nonfunctional template under `.github/workflows`.

**Lesson:** Every YAML file in the workflow directory is parsed as a workflow. Keep incomplete examples elsewhere.

---

## 9. New Terraform module required reinitialization

**Symptom:** Terraform did not immediately recognize a newly introduced module/provider dependency.

**Fix:** Re-ran `terraform init` after adding/changing modules.

**Lesson:** Reinitialize after backend/module/provider changes; `terraform init` is not only a first-time command.

---

## 10. Helm Deployment template indentation failure

**Symptom:** Helm revision failed with Kubernetes validation errors including selector/template-label mismatch and missing containers.

**Root cause:** YAML indentation placed fields at incorrect levels while adding Workload Identity-related template content.

**Fix:** Corrected the complete Deployment template structure and redeployed/rolled back as required.

**Lesson:** YAML can be syntactically parseable yet structurally wrong for the Kubernetes API. Use `helm lint` and rendered manifest inspection before release.

---

## 11. Key Vault seed operation returned `ForbiddenByRbac`

**Symptom:** The application identity design was valid, but the operator could not initially create the demo secret.

**Root cause:** The signed-in user lacked a Key Vault data-plane RBAC role for setting secrets.

**Fix:** Granted the user an appropriate secrets-management role to seed the value while retaining the workload identity's narrower read-only role.

**Lesson:** Key Vault control-plane access and secret data-plane permissions are distinct. Use least privilege for runtime identities.

---

## 12. Federated token command quoting issue

**Symptom:** A nested shell/token expression did not behave correctly when testing workload identity from PowerShell.

**Root cause:** Command substitution/quoting patterns differed between shells.

**Fix:** Read the client ID, tenant ID and federated token into PowerShell variables first, then passed those values explicitly to the login command.

**Lesson:** Break complex cross-shell authentication tests into observable variables; it improves reliability and troubleshooting.

---

## 13. CD workflow accidentally contained duplicate deployment block

**Symptom:** While editing the workflow, a deployment step was unintentionally duplicated/replaced.

**Fix:** Reviewed the YAML and restored one clear deployment block followed by validation steps.

**Lesson:** CI/CD YAML should be reviewed as code. Small editing mistakes can alter deployment behavior significantly.

---

## 14. Whitespace / diff quality issues

**Symptom:** Git checks surfaced formatting noise during edits.

**Fix:** Used `git diff --check` and corrected whitespace before committing.

**Lesson:** Run lightweight quality checks before every commit; they prevent avoidable repository noise.

---

## 15. PowerShell variables lost between sessions

**Symptom:** Previously set variables such as workspace IDs or pod names were empty in a new terminal.

**Root cause:** PowerShell session variables are process-local and not persistent.

**Fix:** Re-query values from Terraform/Azure/Kubernetes instead of assuming they still exist.

**Lesson:** Operational scripts should derive current state rather than rely on interactive-session memory.

---

## 16. Container Insights agent running but no telemetry tables populated

**Symptom:** `ama-logs` pods were healthy, but expected Kubernetes telemetry was not appearing in Log Analytics.

**Root cause:** The telemetry collection path was incomplete: the cluster needed an explicit Data Collection Rule and association.

**Fix:** Added a dedicated Terraform `container-insights` module containing the DCR and DCRA, enabled `ContainerLogV2`, and associated it with AKS.

**Lesson:** A running agent does not prove end-to-end observability. Validate agent, collection rule, association, destination, and actual table ingestion.

---

## 17. Scheduled query alert Terraform plan showed no changes

**Symptom:** Terraform reported no change even though an alert resource had supposedly been added.

**Root cause:** The new alert resource had not actually been saved into `main.tf`.

**Diagnostics:** Used `Select-String` / `Get-Content` to confirm the expected resource was absent.

**Fix:** Saved the resource definition, re-ran plan, and then applied the action group / scheduled query rule.

**Lesson:** When IaC says no change, first verify the source file contains the intended code before assuming Terraform state is wrong.

---

## 18. Helm history PowerShell JSON extraction failed

**Symptom:** The expression used to extract a deployed revision from JSON did not expose the expected `revision` property in the pipeline shape.

**Fix:** Parsed the plain Helm history output with `Select-String` and selected the last deployed entry.

**Lesson:** For one-off shell diagnostics, the simplest robust parser can be better than a complex object pipeline when tool output shape differs by version.

---

## 19. Controlled bad image deployment entered `ImagePullBackOff`

**Symptom:** New pod was `0/1 ImagePullBackOff`; Helm timed out waiting for the Deployment.

**Root cause:** Helm was intentionally given `incident-app:broken-image-test`, a tag that did not exist in ACR.

**Diagnostics:**

```powershell
kubectl get pods -n cloudops-dev -o wide
kubectl get pod <bad-pod> -n cloudops-dev -o jsonpath="{.spec.containers[0].image}"
kubectl describe pod <bad-pod> -n cloudops-dev
az acr repository show --name acrcloudopsdevw9yni0 --image "incident-app:broken-image-test" --output table
helm history incident-app -n cloudops-dev
```

**Fix:** Rolled back to the known-good Helm revision and verified the restored SHA, `/health`, and `/api/keyvault-check`.

**Why no outage occurred:** The Deployment used `maxUnavailable: 0` and `maxSurge: 1`, so the failed replacement did not remove the previous healthy replicas.

**Lesson:** Diagnose from workload state to artifact registry, then recover using a known-good immutable release. The normal CD pipeline should verify the image before deployment and use rollback protection.
