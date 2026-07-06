---
name: hyland-address-gh-reviews
description: Address GitHub PR review comments (filtered by reactions). Use when asked to address PR comments, review feedback, fix issues from GitHub reviews, or work on thumbs-up reactions from pull requests.
argument-hint: <pr-url>
disable-model-invocation: true
---

# Address GitHub PR Review Comments

This skill helps you systematically address review comments on a pull request. Comments are filtered by 👍 reactions, allowing you to selectively address feedback from any reviewer (including GitHub Copilot, human reviewers, or other bots). When a thumbed-up comment has replies in its thread, all replies are included to provide complete context about what needs to be done.

## Available Scripts

This skill bundles four scripts in the `scripts/` directory:

### `scripts/verify-token.sh` (Token Validation)

Validates `GITHUB_PERSONAL_ACCESS_TOKEN` before any GitHub API calls.

**Usage:**
```bash
scripts/verify-token.sh [owner] [repo] [pr_number]
```

**What it does:**
- Fails fast if `GITHUB_PERSONAL_ACCESS_TOKEN` is not set
- Calls `GET /user` to detect invalid or expired tokens
- When owner/repo/pr are provided, tests repository and pull request comment access using the same API endpoints as the fetch scripts
- Returns actionable guidance for fine-grained and classic token scopes

**Invoked by:** `fetch-pr-comments.sh` (always runs first)

### `scripts/fetch-pr-comments-from-url.sh` (Main Entry Point)

Accepts a full GitHub PR URL and orchestrates the entire fetch and process pipeline.

**Usage:**
```bash
scripts/fetch-pr-comments-from-url.sh <pr_url>
```

**Example:**
```bash
scripts/fetch-pr-comments-from-url.sh https://github.com/HylandSoftware/satori/pull/1086
```

**What it does:**
- Extracts owner, repo, and PR number from URL
- Delegates to `fetch-pr-comments.sh` for actual fetching

### `scripts/fetch-pr-comments.sh` (Core Fetcher)

Fetches PR comments from GitHub API and processes them.

**Usage:**
```bash
scripts/fetch-pr-comments.sh <pr_number> [owner] [repo]
```

**Defaults:**
- Owner: `HylandSoftware`
- Repo: `satori`

**What it does:**
- Calls GitHub API to fetch all PR review comments with reactions
- Saves raw JSON to `.tmp/ai/pr-comments/<pr-number>-raw.json`
- Invokes TypeScript processor to filter and format
- Outputs processed results

### `scripts/process-comments.ts` (TypeScript Processor)

Filters comments by reactions, fetches reply threads, and formats for LLM consumption.

**Invoked by:** `fetch-pr-comments.sh` (not typically called directly)

**What it does:**
- Filters comments to only those with 👍 reactions (`reactions["+1"] > 0`)
- For each thumbed-up comment, fetches all replies in the thread
- Extracts code suggestions from comment bodies
- Formats output as human-readable text with file grouping
- Saves to `.tmp/ai/pr-comments/<pr-number>-processed.json` and `.txt`

## Prerequisites

- `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable must be set (see Error Handling section for setup)
- `npx tsx` available for running TypeScript
- Scripts have execute permissions (run `chmod +x scripts/*.sh` if needed)

## Process

### Step 1: Fetch and Analyze PR Comments

1. Accept the PR URL from the user as `$ARGUMENTS`

2. **Run the convenience script with the full PR URL:**

   ```bash
   ./scripts/fetch-pr-comments-from-url.sh $ARGUMENTS
   ```

   This automatically runs `verify-token.sh` first. If token validation fails, stop and share the script's error message with the user — do not attempt to fetch comments.
   
   These scripts will:
   - Verify the GitHub token is set, valid, and scoped for pull request comment access
   - Fetch comments from GitHub API with reactions data
   - Save raw response to `.tmp/ai/pr-comments/<pr-number>-raw.json`
   - Filter comments by user reactions (only `reactions["+1"] > 0` - thumbs up 👍)
   - Include comments from **all authors** (not just bots)
   - **Follow comment threads** - for thumbed-up comments, include all reply comments in the thread to capture your specific instructions
   - Process and format comments for LLM consumption
   - Save processed data to `.tmp/ai/pr-comments/<pr-number>-processed.json`
   - Save formatted output to `.tmp/ai/pr-comments/<pr-number>.txt`
   
3. **Read the formatted output:**
   - The script outputs a preview, or read `.tmp/ai/pr-comments/<pr-number>.txt`
   - This file contains all necessary information: file paths, line numbers, comment bodies, code context, and suggestions

### Step 2: Create Issue Checklist

Create a TODO list with all comments that have thumbs up reactions:

- The formatted output file already contains a summary with file grouping
- Display file path, line number, and the comment body
- Only include comments with 👍 reactions
- Group by file for better organization

Example output:

```
Found 5 review comments with 👍 reactions to address:

📁 score-calculation.service.ts
  [👍 1] Line 97: Use inject() instead of constructor injection
  [👍 1] [2 replies] Line 177: Missing return type annotation on updateWeight
  [👍 1] Line 193: Missing return type annotation on updateWeightToPercentage

📁 weights-management.service.ts
  [👍 1] [1 reply] Line 35: Unused batchMode property

📁 theme.service.ts
  [👍 1] Line 51: Browser API access without SSR safety checks

(3 comments without reactions were skipped)
```

### Step 3: Ask User for Approach

Present options to the user:

```
How would you like to address these issues?

1. **One by one** - I'll fix each issue and give you control to review before moving to the next
2. **All at once** - I'll fix all issues together and then run tests
3. **Custom** - You tell me which specific issues to address

Please respond with 1, 2, or 3 (or specify custom requirements).
```

### Step 4: Implement Fixes

Based on user's choice:

**Option 1 (One by one):**

- Fix the first issue
- Show the changes made
- Ask: "Ready to proceed to the next issue? (yes/no/modify)" AND STOP, GIVING BACK THE CONTROL TO THE USER
- Repeat for each issue

**Option 2 (All at once):**

- Create a TODO list with all issues
- Fix all issues systematically
- Mark each as completed in the TODO

**Option 3 (Custom):**

- Follow user's specific instructions

### Step 5: Validate Changes

After all fixes are applied, run Nx affected commands to validate only the impacted projects:

1. **Run linting on affected projects:**

   ```bash
   NX_TUI=false npx nx affected -t lint
   ```

   Ensure everything passes. If not, fix the issues.

2. **Run build on affected projects:**

   ```bash
   NX_TUI=false npx nx affected -t build
   ```

   Ensure everything passes. If not, fix the issues.

3. **Run tests on affected projects (if available):**

   ```bash
   NX_TUI=false npx nx affected -t test
   ```

   Ensure everything passes. If not, fix the issues.

### Step 6: Summary

Provide a very concise final summary:

- ✅ Issues addressed
- ✅ Files modified

## Error Handling

- If `verify-token.sh` fails, stop immediately and relay its message — it covers missing tokens, expired tokens, and insufficient scopes
- Fine-grained token requirements: **Pull requests: Read-only** on the target repository (Metadata: Read-only is included automatically)
- Classic token requirements: **repo** (private repos) or **public_repo** (public repos)
- Organization repositories may require SSO authorization on the token
- If PR is not found or inaccessible after token verification passes, verify the PR URL and permissions/SSO authorization
- If no comments found, inform user
- If no comments have 👍 reactions, inform user that they need to add reactions on GitHub first
- If tests/linting fail, offer to fix issues before proceeding
- If the script fails to run, check:
  - Script has execute permissions: `chmod +x scripts/fetch-pr-comments.sh`
  - TypeScript execution is available: `npx tsx --version`
  - Output directory can be created: `.tmp/ai/pr-comments/`

## Technical Notes

- **Why not use GitHub MCP server for comments?** The MCP server's `mcp_github_get_pull_request_comments` tool doesn't return the `reactions` field, so we need to use the raw GitHub API via curl to access reaction data
- **Script Architecture:** The solution uses a shell script for orchestration and a TypeScript processor for JSON parsing and formatting
- **Output Files:** All data is saved to `.tmp/ai/pr-comments/` for persistence and debugging
- **Author Filtering:** Unlike previous versions, comments from **all authors** are included (not just bots), allowing for comprehensive review feedback
- Reactions filtering is essential for giving users fine-grained control over which feedback to address
- The formatted text output is optimized for LLM consumption with clear sections and extracted code suggestions
