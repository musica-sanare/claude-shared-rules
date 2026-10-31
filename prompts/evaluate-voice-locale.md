# Task: evaluate adding a conversation language to voice-companion-app

Run this in a Claude Code session in `voice-companion-app`. Talk to the owner in Japanese. Follow every shared rule and the project's `CLAUDE.md`; this prompt adds the task, not new rules.

The owner names the language when starting the task (for example French, `fr-FR`). Below, `<language>` means that language.

## Goal

Decide, with evidence, whether `<language>` can be a conversation language with the same quality and constraints as English and Spanish. This task is an evaluation, not an implementation. The result is a working doc the owner can decide from.

## Constraints

- Keep every project principle: fully offline in normal use, personal data outside the repository, Apple Silicon with 16 GB RAM. A candidate that breaks one is rejected, not worked around.
- Keep the architecture invariants in `docs/en/ARCHITECTURE.md` §3. Note any invariant that adding `<language>` would touch.
- No changes to application code on `dev` beyond an approved, isolated experiment (for example a script under `bench/` or a config that is off by default).
- Model downloads and new dependencies need the owner's approval first; state the name, source, license, and size when asking.
- Measure against the owner's running app instance only after asking.

## Steps

1. **Read.** `CLAUDE.md`, `docs/en/ARCHITECTURE.md`, `docs/working/NEXT_STEPS.md`, `docs/working/REQUIREMENTS.md`, `docs/working/TECH_RESEARCH_2026_10.md`, and how English and Spanish are wired through speech recognition, the LLM, speech synthesis, prompts, personas, and the UI.
2. **List what `<language>` needs**, per component: speech recognition, LLM, speech synthesis (voices), prompts and personas, language-practice features (corrections, hints), UI strings, and tests. Mark each as "works with current models", "needs a different model or voice", or "unknown".
3. **Research candidates** for each gap, using current official sources. Record name, version, license, size, memory use, and `<language>` support claims, with links and the date checked.
4. **Plan the measurements** and show them to the owner: which candidates, which downloads, which metrics (recognition error rate, latency, LLM fluency and correction quality, voice naturalness, memory peak), and the test material (generated or licensed, never personal recordings). Wait for approval.
5. **Measure** with the project's existing benchmark approach where possible. Compare with the English and Spanish baselines.
6. **Write `docs/working/<LANGUAGE>_FEASIBILITY.md`** (English, working doc, conclusion first): recommendation (go, go with conditions, or no-go), the evidence table, required changes per component, effort estimate, risks, and open questions marked `要確認`. Link it from both docs indexes.
7. **Report and propose a commit.** In Japanese: the recommendation, the key numbers, and what the owner must decide. Propose one commit per `git.md` for the working doc and any approved experiment files. Suggested subject: `docs: evaluate <language> conversation support`.
