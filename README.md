*[Tiếng Việt](README.vi.md)*

# Engineering AI — Shared Code Review Framework

Shared config/prompts/rules for running **read-only, advisory AI code review** against other repositories. This repository holds no code to review itself — it's the framework other repos point to when running a review.

## 1. Prerequisites

- Windows + PowerShell.
- [Kiro CLI](https://kiro.dev) installed and logged in (`kiro-cli`), since the script currently runs the review through Kiro's `code-reviewer` agent.
- The repository being reviewed must be a **Git repo with an `origin` remote** (the script fetches and diffs on `origin/<branch>`, not local branches).
- Both branches (the one under review and the base branch) must already be pushed to the remote.

## 2. Setup

1. Clone this repository, e.g. to `D:\skill\engineering-ai`.
2. Point the `ENGINEERING_AI_HOME` environment variable at that path.

   For the current session only:
   ```powershell
   $env:ENGINEERING_AI_HOME = "D:\skill\engineering-ai"
   ```

   Persisted (recommended, so you don't have to set it every new terminal):
   ```powershell
   [System.Environment]::SetEnvironmentVariable("ENGINEERING_AI_HOME", "D:\skill\engineering-ai", "User")
   ```
   Open a new terminal afterward for it to take effect.

## 3. Running a review against any repo

```powershell
cd <path-to-the-repo-being-reviewed>
D:\skill\engineering-ai\scripts\review.ps1 <review-branch> <base-branch>
```

Example:
```powershell
cd C:\projects\my-service
D:\skill\engineering-ai\scripts\review.ps1 feature/add-payment develop
```

- `review-branch`: the branch containing the changes to review (typically a PR branch).
- `base-branch`: the branch to diff against. Only `develop`, `master`, or `main` are accepted.

The script will:
1. Validate `ENGINEERING_AI_HOME` and that all required framework files exist.
2. Verify the current directory is a Git repo with an `origin` remote.
3. Run `git fetch origin --prune` and confirm both branches exist on the remote.
4. Print the changed-files summary (`git diff --stat origin/<base>...origin/<review>`).
5. Build the review prompt and invoke `kiro-cli` (agent `code-reviewer`, read-only mode — **no edits, commits, pushes, merges, or approvals**).
6. Write the result to `review-report.md` at the root of the reviewed repo, and print it to the terminal.

## 4. What the review is based on

When run, the AI reads, in order:

1. [config/defaults.yml](config/defaults.yml) — output language (defaults to `vi`), severity levels, read-only behavior.
2. [prompts/code-review.md](prompts/code-review.md) — the standard review process: scope determination, stack detection, evidence requirements, false-positive control, severity, test gaps, impact analysis, output format.
3. [rules/common-review.md](rules/common-review.md) — general rules applied to every stack.
4. Stack-specific rules, detected from the changed files:
   - [rules/java-spring-review.md](rules/java-spring-review.md) — if `pom.xml`, `build.gradle`, `src/main/java`, Spring Boot dependencies, etc. are present.
   - [rules/nextjs-react-review.md](rules/nextjs-react-review.md) — if `next.config.*`, `app/`, `pages/`, Next.js/React dependencies, etc. are present.
   - Full-stack repos (both backend and frontend changed) load both rule sets.

The result follows a fixed structure: Summary → Risk Level → Findings (CRITICAL/MAJOR/MINOR/SUGGESTION, with evidence + confidence) → Test Gaps → Impact Analysis → Positive Observations → Final Review Result (`READY FOR HUMAN REVIEW` / `CHANGES RECOMMENDED` / `CHANGES REQUIRED`).

**Note:** the result is advisory only. The human reviewer still makes the final merge decision.

## 5. Per-repo overrides (optional)

If a reviewed repo needs different settings (e.g. a different output language, enabling/disabling a section), add a `.engineering-ai.yml` file at its root — it overrides `config/defaults.yml`.

## 6. Current limitations

- Only **Kiro CLI** is supported for now. The `adapters/claude` and `adapters/codex` directories are empty — there's no equivalent adapter yet for Claude Code or Codex CLI.
- `base-branch` only accepts `develop` / `master` / `main`. If your team uses a different branch convention (e.g. `release/*`), you'll need to edit `scripts/review.ps1` first.
- **PowerShell only** — there's no bash/macOS/Linux equivalent yet.
- `workflows/github` is currently empty — no CI/GitHub Action integration to auto-run reviews on PR open yet.

## 7. Common errors

| Error message | Cause | Fix |
|---|---|---|
| `ENGINEERING_AI_HOME is not configured.` | Environment variable not set | Set it as described in section 2 |
| `Current directory is not inside a Git repository.` | Not inside a git repo | `cd` into the correct repo directory |
| `Git remote 'origin' was not found.` | No remote configured | `git remote add origin <url>` |
| `Base branch does not exist: origin/<x>` / `Review branch does not exist: origin/<x>` | Branch not pushed to remote | `git push origin <branch>` then retry |
| `No changes found between origin/<base> and origin/<review>` | No diff between the two branches | Double-check you're comparing the right branches |
| `Failed to run Kiro CLI` | `kiro-cli` not installed or not logged in | Install and log in to Kiro CLI first |
