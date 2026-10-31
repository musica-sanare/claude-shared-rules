# Task: add a UI locale to this product

Run this in a Claude Code session whose working directory is the target repository. Talk to the owner in Japanese. Follow every shared rule and the project's `CLAUDE.md`; this prompt adds the task, not new rules.

The owner names the locale when starting the task (for example French, `fr`). Below, `<locale>` means that code.

## Goal

The product's UI and localized content work in `<locale>` exactly as they do in the existing locales: same features, same fallbacks, same formatting rules, same tests. The project's `CLAUDE.md` lists `<locale>` as supported.

## Scope

- In scope: UI strings, routing and the language switcher, locale detection and defaults, number, date, unit, and currency formatting, accessibility labels, validation and error messages, metadata (`lang`, `hreflang`, page titles), and localized content the project treats as part of the product.
- Out of scope: the project's human-facing docs (`docs/en/`, `docs/ja/`, other doc translations). Do not add a `docs/<locale>/` translation unless the owner asks.
- Do not change behavior that must be locale-neutral (for example calculations, IDs, slugs, stored data keys).

## Constraints

- Follow the project's own localization and translation rules in `CLAUDE.md` (for example "translations are canonical content", "AI drafts are marked `translationStatus: draft`", "the original language is authoritative"). They win over anything here.
- Write natural, idiomatic `<locale>` in the product's existing tone and register. Do not translate word for word from English; compare with the Japanese and Spanish versions where tone matters.
- Machine-drafted creative or authored content (lyrics, descriptions, recipe text) is a draft. Mark it the way the project marks drafts, or list it for the owner's review if the project has no marker. Never invent facts absent from the original.
- If the project's workflow requires a phase plan (`docs/working/PHASE<N>_PLAN.md`) before implementation, write it and get approval first.
- Do not add dependencies without the owner's approval.

## Steps

1. **Read.** `CLAUDE.md`, the docs index, and the localization code (locale list, string files, routing, formatting helpers, content loaders, tests). List every place the existing locales are enumerated or hard-coded.
2. **Plan.** Show the owner, in Japanese: files to change, new files, content to translate (with counts), how drafts are marked, fallback behavior for missing `<locale>` content, and tests to add or extend. Wait for approval.
3. **Infrastructure first.** Add `<locale>` to the locale list, routing, switcher, detection, formatting, and metadata. Missing strings must fall back the way the project already falls back.
4. **Strings and content.** Add all UI strings. Translate content within the approved scope.
5. **Tests.** Extend locale-parameterized tests to `<locale>`. Add tests for formatting and fallback if the existing locales have them. Run the project's full lint, type-check, test, and build commands.
6. **Check in the app.** Run the app and look at the main pages in `<locale>`: no missing keys, no overflowing text, correct formatting, switcher works both ways.
7. **Update project rules and docs.** Add `<locale>` to the supported locales in `CLAUDE.md` and to any stable doc that lists locales (English master and its Japanese twin in the same commit).
8. **Report and propose commits.** In Japanese: what changed, test results, screenshots or pages checked, draft content awaiting the owner's review, `要確認` items. Propose commits per `git.md`, for example infrastructure, then strings and content, then docs. Suggested subject: `feat: add <locale> UI locale`.
