<!-- source: docs/en/SETUP.md blob 861823fd1729c615c35da14425ca5bcc25a08993 -->
[English](../en/SETUP.md) | 日本語 · [目次に戻る](README.md)

> この文書は[英語版](../en/SETUP.md)の翻訳です。内容が異なる場合は英語版が優先されます。

# セットアップ

共有ルールは、`~/.claude/rules/shared` からこのリポジトリの `rules/` ディレクトリへのシンボリックリンクで有効になります。Claude Code は `~/.claude/rules/` 以下のすべての `.md` ファイルを（再帰的に、シンボリックリンクをたどって）すべてのプロジェクトで、プロジェクト自身の指示より先に読み込みます。ユーザースコープのルールには承認ダイアログが出ません。

ここに書いた動作は、2026-10-25 に Claude Code の公式ドキュメント（[Memory](https://code.claude.com/docs/en/memory)、[Settings reference](https://code.claude.com/docs/en/settings-reference)、[Permissions](https://code.claude.com/docs/en/permissions)）で確認しました。記述どおりに動かない場合は再確認してください。

## 前提条件

- `git` が使える macOS または Linux。
- Claude Code CLI、またはデスクトップアプリの Code タブ。バージョン 2.1.281 以上を推奨（`"attribution": false` に必要。シンボリックリンク経由のルールを `claudeMdExcludes` でリンク側のパスで指定するには 2.1.239 以上が必要）。
- このリポジトリにアクセスできる GitHub アカウント。

## インストール

1. リポジトリをクローンします：

   ```bash
   git clone https://github.com/musica-sanare/claude-shared-rules.git ~/repos/claude-shared-rules
   ```

2. リンクを作る場所に何もないことを確認します。`No such file or directory` と表示されれば問題ありません：

   ```bash
   ls -la ~/.claude/rules/shared
   ```

3. リンクを作成します：

   ```bash
   mkdir -p ~/.claude/rules
   ```

   ```bash
   ln -s ~/repos/claude-shared-rules/rules ~/.claude/rules/shared
   ```

共有しない個人用のルールは、引き続き `~/.claude/rules/` に別ファイルとして直接置けます。

## 確認

1. 任意のプロジェクトで**新しい** Claude Code セッションを開始します。実行中のセッションは、追加・変更された指示を読み込みません。
2. `/context` を実行し、**Memory files** の一覧を確認します。`rules/` 内のすべてのファイルが表示されている必要があります：
   `overrides.md`、`language.md`、`documentation.md`、`git.md`、`public-repo-safety.md`、`github-workflow.md`。
3. 任意で、どの共有ルールファイルを読み込んでいるかを日本語か英語で Claude に尋ね、日本語で答えることを確認します。

ファイルが表示されない場合は、`ls -la ~/.claude/rules/` でリンクを確認し、リンク先が存在することを確かめます。

## 推奨設定

ルールは指針であり、強制力はありません。AI 帰属表示を付けないルールを強制し、push の前に必ず確認させるには、次のキーを `~/.claude/settings.json` に追加します。既存のファイルに統合し、置き換えないでください。

```json
{
  "attribution": false,
  "permissions": {
    "ask": ["Bash(git push *)"]
  }
}
```

- `"attribution": false` は、Claude Code が既定で付けるコミットのトレーラーと PR の帰属表示を消します。Claude Code 2.1.281 以上が必要です。それより古いバージョンはこの値を受け付けず、設定ファイル全体を読み飛ばします。古いバージョンでは代わりに次を使います：

  ```json
  { "attribution": { "commit": "", "pr": "", "sessionUrl": false } }
  ```

- `ask` ルールの `Bash(git push *)` により、`git push` で始まるコマンドの前には auto モードでも確認が入ります。`git -C . push` のような別の書き方の push には一致しないため、保証ではなく安全網です。

## 更新

```bash
git -C ~/repos/claude-shared-rules pull
```

新しいセッションから更新後のルールが使われます。実行中のセッションに反映するには再起動します。

## アンインストール

リンクを削除します（末尾にスラッシュを付けないこと。これでリンクだけが消え、リポジトリのファイルは残ります）：

```bash
rm ~/.claude/rules/shared
```

推奨設定を追加していた場合は、`~/.claude/settings.json` から削除します。`~/repos/claude-shared-rules` のクローンは残しても、別途削除してもかまいません。

## 新しいマシン

1. Git と Claude Code をインストールし、GitHub にサインインします。
2. [インストール](#インストール)の手順に従います。
3. 必要なら[推奨設定](#推奨設定)を追加します。
4. 各プロジェクトのリポジトリをクローンし、そのうち一つで[確認](#確認)を行います。

## 既知の制約

- **クラウドセッション**（Claude Code on the web など、リモートのマシンで動くセッション）は、この Mac の `~/.claude/` を参照できないため、共有ルールは読み込まれません。そこでも適用すべきルールは、プロジェクト自身の `CLAUDE.md` に書く必要があります。
- **Cowork セッション**は、セッションの作業ディレクトリの外を指すシンボリックリンクの `~/.claude/rules/` ディレクトリやルールファイルを読み飛ばすため、共有ルールは読み込まれません。通常の Claude Code セッション（CLI とデスクトップの Code タブ）には影響しません。
- **競合**：ユーザールールとプロジェクトルールが競合しても、Claude Code 自体はどちらも優先しません。[上書きとオプトアウト](OVERRIDES.md)の優先順位は、ルール自身がそれを明記しているからこそ機能します。
- **Windows** はこの手順の対象外です。
