<!-- source: README.md blob 59adde681f209230f132a4869faf42d585c681a7 -->
[English](README.md) | 日本語

> この文書は[英語版](README.md)の翻訳。内容が異なる場合は英語版が優先する。

# claude-shared-rules

オーナーのマシン上の全プロジェクトで共通に使う Claude Code のルール集。会話とリポジトリの言語、Git とコミット、二言語のドキュメントとその書き方、公開リポジトリの安全性、GitHub での作業の進め方を定めている。`~/.claude/rules/` で一度有効にすれば、あとはプロジェクトごとに足したり、上書きしたり、外したりできる。

**状態：** 初版。まだ有効化していない。

## クイックスタート

```bash
git clone https://github.com/musica-sanare/claude-shared-rules.git ~/repos/claude-shared-rules
mkdir -p ~/.claude/rules
ln -s ~/repos/claude-shared-rules/rules ~/.claude/rules/shared
```

そのあと新しい Claude Code セッションを開き、`/context` で読み込まれたか確かめる。詳しくは[セットアップ](docs/ja/SETUP.md)を参照。

## ドキュメント

- [ドキュメントの目次](docs/ja/README.md)
- [セットアップ](docs/ja/SETUP.md) · [共有ルールの導入](docs/ja/ADOPTING.md) · [上書きとオプトアウト](docs/ja/OVERRIDES.md)

## ライセンス

[MIT](LICENSE)
