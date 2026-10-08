[CmdletBinding()]
param(
    [string]$RepoPath = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Command-Exists {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

Set-Location $RepoPath

Write-Step "Repository status"
git status --short
if ($LASTEXITCODE -ne 0) { throw "git status failed" }

Write-Step "Whitespace / patch sanity"
git diff --check
if ($LASTEXITCODE -ne 0) { throw "git diff --check found errors" }

Write-Step "Checking for generated or sensitive local artifacts tracked by Git"
$tracked = git ls-files
$badPatterns = @(
    '(^|/)\.venv/',
    '(^|/)venv/',
    '(^|/)\.terraform/',
    'terraform\.tfstate($|\.)',
    '(^|/)(tfplan|drift\.tfplan)$',
    '(^|/)__pycache__/',
    '(^|/)\.env($|\.)',
    '\.pem$',
    '\.key$'
)

$bad = @()
foreach ($file in $tracked) {
    foreach ($pattern in $badPatterns) {
        if ($file -match $pattern) {
            $bad += $file
            break
        }
    }
}

if ($bad.Count -gt 0) {
    Write-Host "Tracked files that should be reviewed:" -ForegroundColor Yellow
    $bad | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" }
    throw "Repository hygiene check failed. Remove generated/secret files from Git tracking before publishing."
}
else {
    Write-Host "No forbidden generated files detected in Git tracking." -ForegroundColor Green
}

if (Command-Exists terraform) {
    Write-Step "Terraform formatting check"
    terraform fmt -recursive -check .\terraform
    if ($LASTEXITCODE -ne 0) { throw "terraform fmt check failed" }
}
else {
    Write-Host "Terraform not installed; skipping terraform fmt check." -ForegroundColor Yellow
}

if (Command-Exists helm) {
    Write-Step "Helm lint"
    helm lint .\helm\incident-app
    if ($LASTEXITCODE -ne 0) { throw "helm lint failed" }
}
else {
    Write-Host "Helm not installed; skipping helm lint." -ForegroundColor Yellow
}

if (Command-Exists python) {
    Write-Step "Python syntax check"
    python -m py_compile .\app\app.py
    if ($LASTEXITCODE -ne 0) { throw "Python syntax check failed" }
}
else {
    Write-Host "Python not installed; skipping Python syntax check." -ForegroundColor Yellow
}

Write-Step "Documentation presence"
$requiredDocs = @(
    ".\README.md",
    ".\docs\architecture.md",
    ".\docs\runbook.md",
    ".\docs\incident-response.md",
    ".\docs\project-handbook.md",
    ".\docs\troubleshooting-log.md",
    ".\docs\kql-cheatsheet.md",
    ".\docs\interview-guide.md",
    ".\docs\repo-management.md"
)

$missing = $requiredDocs | Where-Object { -not (Test-Path $_) }
if ($missing) {
    $missing | ForEach-Object { Write-Host "Missing: $_" -ForegroundColor Red }
    throw "Documentation set is incomplete."
}

Write-Host "`nRepository health checks passed." -ForegroundColor Green
