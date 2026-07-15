# Auto mode

Applies English corrections directly — scan the document, build a fix list, then work through each item without user handoff.

## Core rules

1. **Apply fixes** — edit the file (or return corrected inline text) without waiting for approval.
2. **Preserve content** — keep meaning and structure. No big rewording; only small, necessary fixes.
3. **Target audience** — non-native speakers between intermediate and advanced. Fix mistakes and phrasing this level would miss; do not over-correct acceptable prose.
4. **Apply both tiers** — apply **recommended** fixes (grammar, spelling, meaning) and **optional** fixes (minor polish) unless a change would alter technical terms, acronyms (l10n, RTL, i18n), or domain wording the user chose.

## Workflow

1. **Read** the full source from top to bottom.
2. **Scan** for problems using the "What to look for" checklist.
3. **Build a todo list** — one item per fix (location, original phrase, corrected phrase). Skip items that would alter technical terms, acronyms, or domain wording the user chose.
4. **Work the list** — apply each todo item in order; mark it complete before moving to the next. Do not stop for user input between items.
5. **Finish** with the summary format below.

Each todo item should be specific enough to apply without re-reading the whole document — e.g. "`path:line` — \"agree of\" → \"agree on\"".

## Summary format

After all edits, return a brief summary:

```markdown
**Verdict:** [One short sentence — e.g. "Applied N corrections across the document."]

# Changes made

| Location | Issue | Fix |
| -------- | ----- | --- |
| `path:line` | "original phrase" | "corrected phrase" |
```

- List only lines that were actually changed.
- Keep the table brief; group nearby identical fixes if helpful.
- If nothing needed fixing: `**Verdict:** No corrections needed — text is grammatically correct.`

## Anti-patterns

- Do not rewrite entire paragraphs for "flow".
- Do not change technical terms, acronyms, or domain wording the user chose.
- Do not stop mid-document waiting for user input.
- Do not produce a full-document rewrite when targeted fixes are enough.
