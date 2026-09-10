# AI-Dev-Lab 再構築手順

この文書は、AI-Dev-Lab をゼロから作り直すための手順です。

目的は「同じ VM イメージを複製すること」ではなく、**必要な構成要素を理解しながら、同等の開発環境へ再到達できること**です。

## 0. 前提

- Host: Windows 11 + Hyper-V
- Guest: Windows 11 Pro
- VM name: `AI-Dev-Lab`
- Guest computer name: `AI-DEV-LAB`
- vCPU: 4
- Dynamic Memory: enabled

メモリの開始値・最小値・最大値はホスト余力に合わせて調整します。数値を固定するより、Dynamic Memory を使うことを設計上の要点とします。

## 1. Hyper-V VM を作成

1. Hyper-V Manager で新規 VM を作成
2. 名前を `AI-Dev-Lab` にする
3. Windows 11 をインストール
4. vCPU を 4 に設定
5. Dynamic Memory を有効化
6. Enhanced Session を利用可能にする

VM の自動処理は、現在次の思想で運用しています。

- Host 停止時: VM state を保存
- Host 起動時: 停止前に動いていた場合は VM を自動起動

これにより、通常のホスト再起動時は AI セッションやアプリをなるべく継続しやすくします。

## 2. Windows 初期設定

この VM は AI 実験専用なので、メイン PC の個人環境を複製しないことを優先します。

- ローカルアカウントを使う
- OneDrive を使わない
- ブラウザ同期は原則 OFF
- 個人ファイルを常駐させない

### Known Folder を確認

PowerShell:

```powershell
[PSCustomObject]@{
    Desktop   = [Environment]::GetFolderPath('Desktop')
    Documents = [Environment]::GetFolderPath('MyDocuments')
    Pictures  = [Environment]::GetFolderPath('MyPictures')
} | Format-List
```

期待値:

```text
%USERPROFILE%\Desktop
%USERPROFILE%\Documents
%USERPROFILE%\Pictures
```

OneDrive を一度接続してしまった場合は、リンク解除・アンインストール後に `User Shell Folders` をローカルへ戻します。レジストリ変更前には必ず export を取ります。

```powershell
New-Item -ItemType Directory "C:\_AI-Dev-Lab\Backups\Windows" -Force | Out-Null

reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" `
  "C:\_AI-Dev-Lab\Backups\Windows\User-Shell-Folders-before-fix.reg" /y
```

必要ならローカルフォルダを作成:

```powershell
New-Item -ItemType Directory "$env:USERPROFILE\Desktop" -Force | Out-Null
New-Item -ItemType Directory "$env:USERPROFILE\Documents" -Force | Out-Null
New-Item -ItemType Directory "$env:USERPROFILE\Pictures" -Force | Out-Null
```

Known Folder の値:

```powershell
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'

New-ItemProperty -Path $key -Name 'Desktop' -Value '%USERPROFILE%\Desktop' -PropertyType ExpandString -Force
New-ItemProperty -Path $key -Name 'Personal' -Value '%USERPROFILE%\Documents' -PropertyType ExpandString -Force
New-ItemProperty -Path $key -Name 'My Pictures' -Value '%USERPROFILE%\Pictures' -PropertyType ExpandString -Force
```

Explorer 再起動またはサインアウト後、最初の確認コマンドでもう一度検証します。

> OneDrive の残骸を削除するのは、ローカル Known Folder と必要ファイルを確認した後にすること。

## 3. 管理用ディレクトリ

最初に次を作ります。

```powershell
New-Item -ItemType Directory 'C:\_AI-Dev-Lab\Backups' -Force | Out-Null
New-Item -ItemType Directory 'C:\_AI-Dev-Lab\Scripts\Windows' -Force | Out-Null
New-Item -ItemType Directory 'C:\Dev' -Force | Out-Null
```

`C:\_AI-Dev-Lab` を管理用の canonical root とし、似た名前の `C:\AI-Dev-Lab` は作らないようにします。

## 4. 基本開発ツール

導入対象:

- Git
- GitHub CLI
- Visual Studio Code
- Windows Terminal
- Google Chrome

確認例:

```powershell
Get-Command git.exe, gh.exe, code.cmd, wt.exe -ErrorAction SilentlyContinue |
    Select-Object Name, Source
```

GitHub CLI はブラウザ認証を使用し、認証 token を repo に保存しません。

## 5. Codex / ChatGPT Desktop

Codex / ChatGPT Desktop をインストールし、必要なアカウントで認証します。

診断:

```powershell
codex doctor
```

Doctor の警告はそのまま無視せず、OS・runtime・sandbox・network・Desktop App を確認します。

## 6. Herdr と AI CLI

Herdr を中心に複数 AI CLI を配置します。

詳細: [HERDR.md](HERDR.md)

Herdr 更新:

```powershell
herdr update
```

各 CLI は単体で一度起動し、初回設定・認証・設定ディレクトリ生成を終えてから Herdr 統合を追加するのが安全です。

例: Grok

```powershell
irm https://x.ai/cli/install.ps1 | iex
grok
# 初回設定後に終了
herdr integration install grok
herdr
```

## 7. CLaunch

用途:

- AI / Harness
- Development
- Utility

の3グループ程度に分け、頻繁に使うものを一か所から起動します。

導入実績:

```powershell
winget install --id Pyonkichi.CLaunch -e --source winget
```

Herdr 起動例:

- file: `wt.exe`
- arguments:

```text
-w new new-tab --title "Herdr" powershell.exe -NoExit -Command "herdr"
```

CLaunch はユーザー名変更時に設定ディレクトリが分かれることがあるため、設定バックアップを残します。

推奨バックアップ先:

```text
C:\_AI-Dev-Lab\Backups\CLaunch\
```

## 8. Tablacus Explorer

Tablacus Explorer は常時表示するため、選択タブを強く発光させず、背景差だけで識別できるようにします。

現在の active tab の基本方針:

```css
.activetab {
    color: #d2cdca !important;
    background: #2d2a2e !important;
    border-bottom: none !important;
}
```

通常タブも暗色にし、選択中だけが視線を奪わないようにします。

推奨バックアップ先:

```text
C:\_AI-Dev-Lab\Backups\TablacusExplorer\
```

アプリ本体、`config`、`addons`、`%APPDATA%\tablacus` を保護対象にします。

## 9. Enhanced Session / Audio

Enhanced Session は画面・clipboard・Remote Audio の利便性のため利用します。

マイクを VM に渡すには VMConnect の Remote Audio Recording で:

```text
このコンピューターから録音する
```

を選択します。

ゲスト側の Sound Settings で input device に `Remote Audio` が現れることを確認します。

詳細: [AUDIO-AND-INPUT.md](AUDIO-AND-INPUT.md)

## 10. TypeWhisper

VM 側にも TypeWhisper をインストールし、次の経路で音声入力します。

```text
SM58
 -> BRIDGE CAST X
 -> Host
 -> Hyper-V Remote Audio
 -> Guest TypeWhisper
 -> ElevenLabs Scribe v2
 -> text input
```

入力デバイスは VM の `Remote Audio` を選択します。

API key は Git に保存しません。

## 11. UAC の一時変更

Computer Use 等の診断中、一時的に UAC を完全 OFF にする必要がある場合だけ使用します。

repo の [`scripts/windows/uac/`](../scripts/windows/uac/) に ON/OFF バッチを置いています。

`EnableLUA` の変更には再起動が必要です。

通常運用では UAC ON を基本とします。

## 12. Checkpoint

構築過程での基準点:

```text
00-Clean-Windows
01-Local-Account-Ready
Before-SmartAppControl-Off-2026-08-27
02-Herdr-Multi-Agent-Ready
03-Desktop-UX-Ready
04-AI-Dev-Lab-Ready
```

再構築時も、壊れたときに戻りたい意味のある節目で checkpoint を作ります。

## 13. 完了確認

最低限確認すること:

```text
[ ] Windows がローカルアカウント中心で動く
[ ] Desktop/Documents/Pictures が OneDrive を指していない
[ ] Git / gh / VS Code / Terminal が起動する
[ ] Herdr が起動する
[ ] 必要な AI CLI が Herdr から扱える
[ ] CLaunch / Tablacus の UI が復元できる
[ ] Enhanced Session が使える
[ ] Remote Audio input が VM に見える
[ ] TypeWhisper から音声入力できる
[ ] C:\_AI-Dev-Lab にバックアップがある
[ ] 安定状態の Hyper-V checkpoint がある
```

## 14. 再現性のルール

今後何か追加したら、可能な限り以下をこの repo に反映します。

- インストールコマンド
- 設定理由
- 成功確認方法
- 壊れたときの戻し方
- secrets を含まない設定例
- 既知の失敗例
