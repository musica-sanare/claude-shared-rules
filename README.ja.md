<!-- source: README.md blob 44c3a450191680b6c77a6d304478d712637a0c34 -->
[English](README.md) | 日本語

> この文書は[英語版](README.md)の翻訳です。内容が異なる場合は英語版が優先されます。

# claude-shared-rules

オーナーのマシン上のすべてのプロジェクトで共有する Claude Code のルールです。会話とリポジトリの言語、Git とコミットの規約、二言語のドキュメント構成、公開リポジトリの安全性、GitHub のワークフローを扱います。`~/.claude/rules/` で一度有効にすれば、プロジェクトごとに追加、上書き、オプトアウトできます。

**状態：** 初版。まだ有効化していません。

## クイックスタート

```bash
git clone https://github.com/musica-sanare/claude-shared-rules.git ~/repos/claude-shared-rules
mkdir -p ~/.claude/rules
ln -s ~/repos/claude-shared-rules/rules ~/.claude/rules/shared
```

その後、新しい Claude Code セッションを開始して `/context` を確認します。詳細：[セットアップ](docs/ja/SETUP.md)。

## ドキュメント

- [ドキュメント索引](docs/ja/README.md)
- [セットアップ](docs/ja/SETUP.md) · [共有ルールの導入](docs/ja/ADOPTING.md) · [上書きとオプトアウト](docs/ja/OVERRIDES.md)

## ライセンス

[MIT](LICENSE)
