---
name: generate-prose
description: Generates 140-180 word Hungarian prose as writing prompts for English learners to translate. Drafts plain text first, then enriches it with practice-dictionary vocabulary marked by @. Supports iterative revisions with the same draft-then-enrich cycle. Use when the user asks for an essay, writing task, writing prompt, translation practice, or mentions generate-prose.
disable-model-invocation: true
argument-hint: "[topic]"
---

# generate-prose

Generates Hungarian prose that serves as a translation writing task for English practice.

## Purpose

The user receives Hungarian prose and translates it into English on their own. This removes the burden of choosing a topic while letting them practice English writing — especially vocabulary from the practice dictionary.

## Usage

```
/generate-prose
/generate-prose climate change
/generate-prose a memorable trip
```

If no topic is given, ask the user what they want to write about.

## Workflow

Every version of the prose — initial or revised — follows the same two-phase process: **draft first**, then **enrich from the dictionary**.

### Phase A — Draft (no dictionary)

Write plain Hungarian prose only. Do not consult the dictionary yet.

- Natural, coherent text with a clear opening, development, and closing.
- **140–180 words** (count words; stay in range).

### Phase B — Enrich and deliver

1. **Load dictionary** — read [references/dictionary.csv](references/dictionary.csv). Columns: `front` (English target vocabulary), `back` (Hungarian meaning), `hint` (example sentence).
2. **Enrich the draft** — swap plain Hungarian wording for dictionary entries where they fit naturally. Prioritize idioms, collocations, and eloquent phrasing from the `back` column over single common words. Aim to replace as many spots as the prose can support without sounding forced.
3. **Mark dictionary spots** — append `@` immediately after every word or expression taken from the dictionary (no space before `@`). Example: `megállíthatatlan@`, `beeadja a derekát@`. The `@` suffix never appears in normal Hungarian text, so it flags where the user should reach for their dictionary when translating.
4. **Deliver** — output the marked prose only. Do **not** provide an English translation, word list, or hints unless the user explicitly asks.

### 1. Initial generation

1. **Confirm topic** — from invocation argument or user message; ask if missing.
2. Run **Phase A**, then **Phase B**.

### 2. Revisions

After delivery, the user may ask for changes — e.g. remove a sentence, swap one for another, or add a new sentence.

1. **Apply the requested edits** to the current text as a new plain draft (strip existing `@` markers while editing). Keep the same topic unless the user says otherwise. Re-check **140–180 words**.
2. Run **Phase B** again on the revised draft — do not reuse the previous enriched version; re-enrich from scratch.

Treat every revision request as a full draft-then-enrich cycle, not a patch on the already-marked text.

## Writing guidelines

- Natural, coherent Hungarian prose — not a vocabulary dump.
- Match register to topic (formal/informal as appropriate).
- Draft first for flow; enrich second for vocabulary practice — on every generation and every revision.
- Each `@`-marked span should map to a `back` entry whose English `front` term the user is expected to produce in translation.

## Output format

```markdown
## Írási feladat: [topic in Hungarian]

[Prose text — Hungarian only, 140–180 words, dictionary expressions marked with @]
```

## Constraints

- **Language**: Hungarian only in the prose body (`@` markers excluded from word count).
- **Length**: 140–180 words — verify before responding.
- **No translation**: the user translates independently.
- **Dictionary**: maximize `@`-marked vocabulary from `references/dictionary.csv` without sacrificing readability.
