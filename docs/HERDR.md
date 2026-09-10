# Herdr / Multi-Agent Setup

AI-Dev-Lab では Herdr を複数 AI CLI のセッション管理・復帰の中心に置きます。

## 目的

- Codex / OpenCode / Hermes / AGY / Grok などを一つの操作面から扱う
- VM / Herdr 再起動後も、可能なエージェントは native session resume を使う
- AI ごとに別々の復帰手順を覚えなくてよい状態に近づける

Hyper-V Saved State は VM の RAM / process state を保存しますが、外部ネットワーク接続まで完全に保証するものではありません。Herdr の session resume はそれとは別レイヤーの復旧手段として扱います。

## 現在確認済み

次のエージェントで Herdr 統合・復帰を確認しています。

- Codex
- OpenCode
- Hermes
- AGY / Antigravity CLI
- Grok CLI

## 基本運用

Herdr を更新:

```powershell
herdr update
```

Herdr で使う CLI は、まず単体で正常に起動・認証できる状態にします。

その後で:

```powershell
herdr integration install <agent>
```

を実行します。

### Grok CLI

```powershell
# 1. Herdr update
herdr update

# 2. Grok CLI install
irm https://x.ai/cli/install.ps1 | iex

# 3. first launch: create ~/.grok and finish initial auth/setup
grok

# Grok を終了

# 4. Herdr integration
herdr integration install grok

# 5. verify
herdr
```

Windows では `~/.grok` は通常 `%USERPROFILE%\.grok` に対応します。

確認:

```powershell
Get-Command grok -ErrorAction SilentlyContinue |
    Select-Object Name, Source

[PSCustomObject]@{
    GrokConfigExists = Test-Path "$env:USERPROFILE\.grok"
    GrokConfigPath   = "$env:USERPROFILE\.grok"
} | Format-List
```

## CLaunch から Herdr を起動

Windows Terminal 経由で直接起動できます。

- executable: `wt.exe`
- arguments:

```text
-w new new-tab --title "Herdr" powershell.exe -NoExit -Command "herdr"
```

CLI agent を個別に CLaunch へ大量登録するより、基本は Herdr 側へ集約します。

## Herdr の prefix key

Herdr は tmux のような prefix 操作を持ちます。

```text
Ctrl+B
```

を押した後の次キーが Herdr command になります。

例:

```text
Ctrl+B → ?
```

で keybind / help を確認します。

## AGY integration の過去トラブル

Herdr 0.8.2 stable では Windows 上の Antigravity integration で、AGY 自体は検出されても `agent_session` が作られず、resume できない状態を確認しました。

その後:

```powershell
herdr update
```

で preview build へ更新し、integration を更新したところ AGY の native conversation resume が動作しました。

教訓:

- Agent 本体が起動することと、Herdr が session を認識することは別
- Herdr 更新後は integration の再導入・更新が必要な場合がある
- 問題発生時は `agent_status` だけでなく `agent_session` があるかを見る

## 復旧時チェック

```text
[ ] agent CLI が単体で起動する
[ ] 認証が生きている
[ ] Herdr が最新版
[ ] integration が入っている
[ ] Herdr pane に agent が出る
[ ] agent_session / native session id が生成される
[ ] Herdr 再起動後に前 session へ戻れる
```

## Secrets

次は Git に保存しません。

- API keys
- access / refresh tokens
- CLI auth files
- `.grok` の中身そのもの
- Codex `auth.json`
- session transcripts に秘密情報が含まれる場合の raw dump

保存するのは **再設定方法・ファイルの場所・確認コマンド**までにします。
