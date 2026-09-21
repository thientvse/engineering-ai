param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ReviewBranch,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet("develop", "master", "main")]
    [string]$BaseBranch
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# UTF-8 setup
# ------------------------------------------------------------

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

[Console]::InputEncoding  = $Utf8NoBom
[Console]::OutputEncoding = $Utf8NoBom
$OutputEncoding           = $Utf8NoBom

try {
    chcp 65001 | Out-Null
}
catch {
    # Ignore if code page change is unavailable
}

function Fail {
    param([string]$Message)

    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

function Info {
    param([string]$Message)

    Write-Host $Message -ForegroundColor Cyan
}

function Success {
    param([string]$Message)

    Write-Host $Message -ForegroundColor Green
}

# ------------------------------------------------------------
# 1. Validate Engineering AI installation
# ------------------------------------------------------------

if (-not $env:ENGINEERING_AI_HOME) {
    Fail "ENGINEERING_AI_HOME is not configured."
}

if (-not (Test-Path $env:ENGINEERING_AI_HOME)) {
    Fail "ENGINEERING_AI_HOME does not exist: $env:ENGINEERING_AI_HOME"
}

$RequiredFiles = @(
    "$env:ENGINEERING_AI_HOME\config\defaults.yml",
    "$env:ENGINEERING_AI_HOME\prompts\code-review.md",
    "$env:ENGINEERING_AI_HOME\rules\common-review.md",
    "$env:ENGINEERING_AI_HOME\rules\java-spring-review.md",
    "$env:ENGINEERING_AI_HOME\rules\nextjs-react-review.md"
)

foreach ($file in $RequiredFiles) {
    if (-not (Test-Path $file)) {
        Fail "Required Engineering AI file not found: $file"
    }
}

# ------------------------------------------------------------
# 2. Validate current directory is a Git repository
# ------------------------------------------------------------

$RepoRoot = git rev-parse --show-toplevel 2>$null

if ($LASTEXITCODE -ne 0 -or -not $RepoRoot) {
    Fail "Current directory is not inside a Git repository."
}

Set-Location $RepoRoot

$RemoteUrl = git remote get-url origin 2>$null

if ($LASTEXITCODE -ne 0 -or -not $RemoteUrl) {
    Fail "Git remote 'origin' was not found."
}

# ------------------------------------------------------------
# 3. Fetch latest remote refs
# ------------------------------------------------------------

Info "Fetching latest refs from origin..."

git fetch origin --prune

if ($LASTEXITCODE -ne 0) {
    Fail "git fetch origin failed."
}

# ------------------------------------------------------------
# 4. Validate branches
# ------------------------------------------------------------

git show-ref --verify --quiet "refs/remotes/origin/$BaseBranch"

if ($LASTEXITCODE -ne 0) {
    Fail "Base branch does not exist: origin/$BaseBranch"
}

git show-ref --verify --quiet "refs/remotes/origin/$ReviewBranch"

if ($LASTEXITCODE -ne 0) {
    Fail "Review branch does not exist: origin/$ReviewBranch"
}

# ------------------------------------------------------------
# 5. Show review context
# ------------------------------------------------------------

Write-Host ""
Write-Host "==============================================" -ForegroundColor DarkGray
Write-Host " AI CODE REVIEW" -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor DarkGray

Write-Host "Repository     : $RepoRoot"
Write-Host "Remote         : $RemoteUrl"
Write-Host "Review branch  : $ReviewBranch"
Write-Host "Base branch    : $BaseBranch"
Write-Host "Engineering AI : $env:ENGINEERING_AI_HOME"

# ------------------------------------------------------------
# 6. Inspect change summary
# ------------------------------------------------------------

Write-Host ""
Info "Change summary:"

git diff --stat "origin/$BaseBranch...origin/$ReviewBranch"

$ChangedFiles = git diff --name-only "origin/$BaseBranch...origin/$ReviewBranch"

if (-not $ChangedFiles) {
    Fail "No changes found between origin/$BaseBranch and origin/$ReviewBranch."
}

Write-Host ""
Info "Changed files:"

$ChangedFiles | ForEach-Object {
    Write-Host "  $_"
}

# ------------------------------------------------------------
# 7. Prepare review prompt
# ------------------------------------------------------------

$Prompt = @"
Perform a read-only code review.

Repository:
$RepoRoot

Remote:
$RemoteUrl

Review branch:
origin/$ReviewBranch

Base branch:
origin/$BaseBranch

Review exactly the changes introduced by the review branch using:

git diff origin/$BaseBranch...origin/$ReviewBranch

Shared Engineering AI framework:

$env:ENGINEERING_AI_HOME

Before reviewing:

1. Read:
   - $env:ENGINEERING_AI_HOME/config/defaults.yml
   - $env:ENGINEERING_AI_HOME/prompts/code-review.md
   - $env:ENGINEERING_AI_HOME/rules/common-review.md

2. Detect the affected technology stack from the changed files and repository.

3. If Java or Spring Boot changes are affected, also read:
   - $env:ENGINEERING_AI_HOME/rules/java-spring-review.md

4. If Next.js or React changes are affected, also read:
   - $env:ENGINEERING_AI_HOME/rules/nextjs-react-review.md

5. If .engineering-ai.yml exists in the current repository, read it and use it as project-specific configuration overriding the shared defaults.

Review requirements:

- inspect the actual Git diff
- inspect relevant surrounding code
- inspect direct callers or dependencies when necessary
- inspect relevant tests when useful
- identify production risks
- perform impact analysis
- minimize false positives
- follow the configured output language
- keep technical identifiers unchanged

Strict read-only rules:

- do not modify files
- do not create files
- do not delete files
- do not commit
- do not push
- do not checkout branches
- do not merge
- do not rebase
- do not reset Git state
- do not approve or reject the pull request

Return only the final review report using the shared code review format.
"@

# ------------------------------------------------------------
# 8. Run Kiro reviewer
# ------------------------------------------------------------

$ReportPath = Join-Path $RepoRoot "review-report.md"
$TempOutput = Join-Path $env:TEMP "engineering-ai-review-output.txt"

if (Test-Path $TempOutput) {
    Remove-Item $TempOutput -Force
}

Write-Host ""
Info "Running Kiro code-reviewer..."

try {
    & kiro-cli --v3 chat `
        --agent code-reviewer `
        --no-interactive `
        "$Prompt" 2>&1 |
        Tee-Object -FilePath $TempOutput

    $KiroExitCode = $LASTEXITCODE

    if ($KiroExitCode -ne 0) {
        Fail "Kiro review failed with exit code $KiroExitCode."
    }

    # Read explicitly as UTF-8
    $Output = [System.IO.File]::ReadAllText(
        $TempOutput,
        [System.Text.Encoding]::UTF8
    )

    # Write final Markdown explicitly as UTF-8 without BOM
    [System.IO.File]::WriteAllText(
        $ReportPath,
        $Output,
        $Utf8NoBom
    )

    Write-Host ""
    Write-Host $Output
}
catch {
    Fail "Failed to run Kiro CLI: $($_.Exception.Message)"
}
finally {
    if (Test-Path $TempOutput) {
        Remove-Item $TempOutput -Force -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------------------------
# 9. Finish
# ------------------------------------------------------------

Write-Host ""
Write-Host "==============================================" -ForegroundColor DarkGray
Success "Review completed."
Write-Host "Report: $ReportPath"
Write-Host "==============================================" -ForegroundColor DarkGray