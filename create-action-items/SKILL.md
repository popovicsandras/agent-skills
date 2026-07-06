---
name: create-action-items
description: Create a structured action plan from documents by extracting actionable items, categorizing them, and formatting as Markdown with verbose descriptions and priorities
disable-model-invocation: true
---

Digest documents and meeting transcripts to create structured, categorized action plans.

# Process

1. **Read all source documents.** If binary format (DOCX, PDF), convert first:
   - DOCX: `textutil -convert txt document.docx -output -`
   - PDF: Use Read tool with page ranges

2. **Extract actionable items.** For each, capture: problem, context, proposed solutions, impact, technical details, constraints, open questions.

3. **Categorize.** Ask if user has existing categories. If not, propose logical groupings and get confirmation. In most cases, the user will have already created Jira epics that they want you to use as categories.
Present your proposed categories and get user confirmation before proceeding.

## 4. Structure Each Item

This plan should be a task list written in Markdown format using the Markdown checklist syntax.

Format each item with:
- A clear, descriptive title (not just "Fix bug" but "Fix workspace name with spaces causing command failures")
- **Priority:** Low | Medium | High
- **Description:** **Incisive and reasonably short** markdown with sections like:
  - # Problem (always present)
  - # Context (always present)
  - # Proposed Solution (only present if it were discussed)
  - # Impact (only present if it were discussed)
  - # Open Questions (only present if it were discussed)

**Critical:** Keep verbatim quotes from feedback where valuable, but make attributions anonymous ("user feedback indicated", "from testing notes", "developers reported").

**Critical:** Give explicit technical details only when they help, but the main goal of this action plan is to record the feature or change request, not the implementation details!

**Critical:** Restrain the description to a minimum. Don't write long descriptions. Avoid entering proposals or unnecessary technical details.

**Critical:** Only record in the description what was in the provided context. Do not try to complete the description with what you think.

## 5. Create Output File

Generate a Markdown file in the repository root (or user-specified location) with:

```markdown
# [Title] - Action Plan from [Source]

**Date:** [Date]
**Source:** [Description]

---

## Category: [Category Name]

### [ID]: [Item Title]

- **Priority:** [Low|Medium|High]
- **Description:**
  
  ## Problem
  [Description]
  
  ## Context
  [Details]
  
  ## Proposed Solution
  [Approach]

---
```

# Critical Requirements

- **Be comprehensive:** Don't lose details from source documents
- **Be anonymous:** Remove personal names unless explicitly tracking individual contributions
- **Be structured:** Use consistent markdown formatting with clear sections
- **Be honest:** Include uncertainties, open questions, and tradeoffs

# Output

A single Markdown file containing all categorized action items, ready to be used for planning, ticket creation, or project tracking.
