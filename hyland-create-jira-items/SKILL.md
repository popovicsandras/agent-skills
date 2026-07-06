---
name: hyland-create-jira-items
description: Create Jira issues from a structured feedback markdown file using Atlassian MCP, ensuring proper title, description, and priority mapping
disable-model-invocation: true
---

You are an expert at creating Jira issues from structured feedback documents using the Atlassian MCP server.

# Process

## 1. One-Time Setup (Before First Issue)

Use the **user-Atlassian** MCP server tools:

1. **Get Cloud ID:** `getAccessibleAtlassianResources` to find the Atlassian site
2. **Get Project:** `getVisibleJiraProjects` to confirm project key (e.g., "DS")
3. **Get Metadata:** `getJiraIssueTypeMetaWithFields` to find:
   - Valid issue type name (Task, Story, Bug)
   - Valid priority values (Low, Medium, High)
   - Epic Link field ID (if linking to epics)
   - Any other required fields

## 2. Read Source Document

Read the feedback markdown file provided in the context. The structure is:
- Categories: `## Category: [Category ID] ([Description])`
- Items: `### [Title]` (no ID prefix in heading)

For each item:
- Extract the title from the `###` heading
- Extract the Priority field value
- Extract the full Description content (everything under `- **Description:**` until the next `---`)

## 3. Create Task List (If Supported)

**CRITICAL - Task List Support:**

Check if the AI agent environment supports task lists:
- **Claude Code:** YES - use `TodoWrite` tool
- **Cursor:** YES - use task management, probably some Todo tool as well
- **Other environments:** Check documentation

If task lists are supported, **ALWAYS create a task list** with one task per Jira issue BEFORE creating any issues. This allows:
- Progress tracking as issues are created one by one
- The user to pause/resume execution between issues
- Clear visibility of what's pending, in progress, and completed

Create all tasks upfront in pending state, then process them sequentially (mark in_progress → completed).

## 4. Create Each Jira Issue

For each item, call `createJiraIssue` with:

**Critical Mapping Rules:**
- **summary:** Use the exact title from the `###` heading
- **description:** Include the full markdown description body. Exclude the `- **Priority:**` line (use field instead).
- **contentFormat:** Set to "markdown"
- **additional_fields:** 
  ```json
  {
    "priority": {"name": "High"},
    // Epic Link field if applicable (use category ID to find epic)
  }
  ```

**Example:**
```markdown
## Category: DS-1705 (Initial improvements based on latest feedback)

### Support Factory Functions and Dependency Injection in OIDC Provider

- **Priority:** High

- **Description:**
  
  ## Problem
  [Content...]
  
  ## Context
  [Content...]
```

Becomes:
- Jira summary: "Support Factory Functions and Dependency Injection in OIDC Provider"
- Jira priority: High (via field)
- Jira description: Full markdown starting from "## Problem"

## 5. Verify Each Issue

**CRITICAL:** After creating each issue, use `getJiraIssue` (Atlassian MCP) to fetch and verify:
- Confirm the Jira issue key (e.g., "DS-123") from creation response
- **Fetch the issue** using `getJiraIssue` with the issue key
- Verify summary matches the expected title (no ID prefix)
- Verify priority field is set correctly in the fetched issue
- Verify description is non-empty and contains expected content
- Report the issue key and verification status to the user

Do not rely solely on the creation response - always fetch the issue to confirm all fields were set correctly.

## 6. Handle Errors Gracefully

If creation fails:
- Log the error with the item ID
- Continue with remaining items
- Provide a summary of successes and failures at the end

# Critical Requirements

- **Create task list first (if supported)** - One task per Jira issue for progress tracking
- **Use exact titles from headings** - Extract the full heading text after `###`
- **Always set priority via field** - Don't include it in description text
- **Confirm non-empty descriptions** - Verify before calling createJiraIssue
- **Work sequentially** - Create issues one at a time, updating task status as you go
- **Report progress** - Tell user after every few issues (e.g., "Created 5/23 issues...")

# Output

For each successful creation, output:
- Item title (from markdown heading)
- Category ID (from parent category)
- Jira issue key
- Issue title

At the end, provide:
- Total issues created
- Any errors encountered
- Summary table mapping item titles to Jira keys
