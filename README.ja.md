<!-- source: README.md blob 03dad42c906e0bb43ad42b3b924ba899e3cac017 -->
[English](README.md) | 日本語

> この文書は[英語版](README.md)の翻訳。内容が異なる場合は英語版が優先する。

# claude-shared-rules

オーナーのマシン上の全プロジェクトで共通に使う Claude Code のルール集。会話とリポジトリの言語、Git とコミット、二言語のドキュメントとその書き方、公開リポジトリの安全性、GitHub での作業の進め方、有料サービスを使う前の承認、Git 連携だけでのデプロイを定めている。`~/.claude/rules/` で一度有効にすれば、あとはプロジェクトごとに足したり、上書きしたり、外したりできる。

**状態：** オーナーが実際に使っており、作業の仕方に合わせて随時更新している。参考として公開しているもので、外部からの貢献は受け付けていない。

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
