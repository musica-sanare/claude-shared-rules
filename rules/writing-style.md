# Writing style for human-facing docs

## Scope

- Applies in full to text people read: stable docs (`docs/en/`, `docs/ja/`), root `README.md` and `README.ja.md`, directory READMEs next to code, and PR descriptions.
- Working docs (`docs/working/`): apply "Conclusion first" and "Sentences". Layering and diagrams are optional.
- Does not apply to Claude-only files (see `documentation.md`), rule files, prompts, or design and implementation instructions written for Claude. Write those for Claude's reading efficiency: dense, explicit, unambiguous, no padding for human comfort.
- Commit messages follow `git.md`.

## Layering

- Open every doc with a short overview (2 to 4 sentences or a few bullets): what it is, who it is for, and what the reader can do with it. A reader who stops there must still know whether to read on.
- Put details after the overview, in sections a reader can skip.
- Move details into a separate doc and link to it when they serve a different reader or task (for example reference versus how-to), or when they would make the doc long enough to bury the main path.
- Order sections by how many readers need them: the common task first; edge cases, background, and history last.
- One doc, one purpose. Do not repeat what another doc says; link to it.
- Headings say what the section contains (`Install`, `Why a symlink`), so the heading outline alone shows the structure.

## Conclusion first

- Start each section and paragraph with its point: the answer, the decision, or the action. Reasons, conditions, and details follow.
- In instructions, give the step first, then the reason if one is needed.
- Exception: put a warning that changes what the reader does before the step it applies to, not after.

## Sentences

- One idea per sentence. Aim for about 25 English words or 60 Japanese characters; split longer sentences.
- Active voice with a concrete subject. Plain words over formal ones.
- Define a term at first use, then use the same term for the same thing throughout.
- Cut filler ("basically", "it should be noted that", "in order to") and empty hedges. When something is uncertain, say what is uncertain.

## Visual structure

- Bullets for parallel items, numbered lists for steps, tables for items compared on the same attributes.
- Keep prose where the reasoning depends on connectives (because, unless, so). Do not chop an argument into bullets.
- Nest lists at most two levels deep.
- Use a diagram when structure, flow, sequence, or state is easier to see than to read: architecture, data flow, processes, state machines. Skip it when a short list says the same.
- Use GitHub alerts (`> [!NOTE]`, `> [!WARNING]`) for the few points a reader must not miss. Use bold sparingly.
- Put each command a reader copies in its own fenced code block.

## Diagrams that render on GitHub

- Prefer Mermaid in a fenced `mermaid` block: it is text, diffs cleanly, and is translated with the doc.
- Use only established diagram types (`flowchart`, `sequenceDiagram`, `stateDiagram-v2`, `classDiagram`, `erDiagram`, `gantt`). Avoid beta or experimental types and recently added syntax; GitHub's bundled Mermaid version lags the latest release.
- Quote labels that contain spaces or punctuation (`A["Install (once)"]`). Keep a diagram to about 15 nodes; split larger ones.
- Do not set themes, `%%{init}%%` directives, or hard-coded colors. Diagrams must be readable in GitHub's light and dark themes.
- Check that each diagram renders before proposing the commit: a local Mermaid parser or preview if available, otherwise list the diagrams for the owner to check on GitHub. Say which check was done.
- Use SVG only when Mermaid cannot express the picture. Store it in `docs/assets/`, reference it with a relative path and alt text, and make it readable on light and dark backgrounds. Avoid text inside SVGs; if text is needed, provide `name.en.svg` and `name.ja.svg`. Keep the editable source next to an exported SVG.
- In the Japanese twin, translate diagram labels and keep node IDs unchanged.

## Japanese text

- Write natural Japanese, not translationese. A translation keeps the English doc's meaning, sections, order, lists, and diagrams, but restructures sentences freely to read naturally.
- Use the plain form (常体: 「〜する」「〜だ」) everywhere, including notices and link text. Never です・ます; it adds length without meaning. List items and table cells may end in a noun; be consistent within one list or table.
- Avoid: 「〜することができる」 (write 「〜できる」), 「〜を行う」 where a direct verb exists, 「〜である」 where 「〜だ」 or a verb ending is enough, literal passives, long chains of noun modifiers, and katakana where a common Japanese word exists (established technical terms such as コミット stay).
- Follow the repository's existing punctuation and spacing conventions. If there are none: 「、」「。」, full-width parentheses and colons in Japanese sentences, and a half-width space between Japanese and Latin words or code.

## Before proposing a doc change

- The overview alone tells a reader what the doc is and whether to read on.
- The first sentence of each section states its point.
- Long sentences are split unless there is a reason.
- Every diagram's render check is done or listed for the owner.
- The Japanese twin reads naturally on its own, without the English beside it.
