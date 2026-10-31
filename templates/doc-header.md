# Doc header snippets

Copy the matching snippet to the top of each doc. Replace `SPEC.md` with the doc's own file name.

## English stable doc (`docs/en/SPEC.md`)

```markdown
English | [日本語](../ja/SPEC.md) · [Docs index](README.md)

# Specification
```

## Japanese stable doc (`docs/ja/SPEC.md`)

The first line records the English file it was translated from. Get the hash with `git hash-object docs/en/SPEC.md` after the English edit is final; it does not need a commit.

```markdown
<!-- source: docs/en/SPEC.md blob <hash> -->
[English](../en/SPEC.md) | 日本語 · [目次に戻る](README.md)

> この文書は[英語版](../en/SPEC.md)の翻訳。内容が異なる場合は英語版が優先する。

# 仕様
```

## Docs indexes

`docs/en/README.md` and `docs/ja/README.md` link back to the root READMEs instead of to an index. See `docs-index.en.md` and `docs-index.ja.md`.

## Root READMEs

`README.md`:

```markdown
English | [日本語](README.ja.md)
```

`README.ja.md`:

```markdown
<!-- source: README.md blob <hash> -->
[English](README.md) | 日本語

> この文書は[英語版](README.md)の翻訳。内容が異なる場合は英語版が優先する。
```

## Working docs (`docs/working/*.md`)

No language switcher (English only). Optionally start with a link back to the index:

```markdown
[Docs index](../en/README.md)
```
