# AI Dev Lab

Windows 11 + Hyper-V 上に、AI エージェント／Computer Use／GUI 操作／音声入力を安全に試せる **再現可能な AI 開発 VM** を構築するための記録です。

このリポジトリの目的は、完成した VM 自体を保存することではありません。**数か月後に人間も AI も細部を忘れていても、ここを読めば同じ環境を再構築できること**を目標にします。

> 現在の基準 VM 名: `AI-Dev-Lab`
>
> 構築記録の初期基準日: 2026-09

まず現在地を知りたい場合は [`docs/CURRENT-STATE.md`](docs/CURRENT-STATE.md) を参照してください。

完全再現に向けて「まだ回収すべき値」を確認する場合は [`docs/REPRODUCIBILITY-AUDIT.md`](docs/REPRODUCIBILITY-AUDIT.md) を参照してください。現在の VM が生きているうちに exact Hyper-V / guest state を採取するための helper も [`scripts/inventory/`](scripts/inventory/) に置いています。

## なぜこの VM を作ったのか

AI 開発では、Codex / OpenCode / AGY / Hermes / Grok など複数のエージェントを並行利用したり、AI に Windows GUI を直接操作させたりする場面が増えています。

しかし、普段使いの Windows 環境をそのまま実験場にすると、次の問題があります。

- AI に強い権限を渡す実験をメイン PC で行いたくない
- Computer Use の失敗や誤操作を隔離したい
- ツール、CLI、シェル統合、UI カスタマイズを気軽に試したい
- 壊れた場合にチェックポイントからすぐ戻したい
- AI エージェントを複数同時に動かし、セッションを復帰できる環境がほしい
- GUI 操作型 AI の能力を Blender / DAW / ペイントソフト等で検証したい
- 音声入力中心の開発スタイルを VM 内でも維持したい

そこで、Hyper-V 上に専用の Windows VM を作り、**AI の作業場そのものを使い捨て・復旧可能にする**方針にしました。

## 設計方針

この環境では次を優先します。

1. **再現性** — 手作業だけに依存せず、手順・スクリプト・設定を残す
2. **隔離** — メイン PC の個人データや日常環境から AI 実験を分離する
3. **復旧性** — Hyper-V Checkpoint と設定バックアップの両方を使う
4. **人間可読性** — 数か月後に見ても目的と理由が分かる日本語ドキュメントを残す
5. **秘密情報を Git に置かない** — API キー、認証トークン、ブラウザプロファイル等は保存しない
6. **必要以上に固定しない** — アプリのバージョンアップや新しい AI ハーネスを取り込める構造にする

## 現在の基準構成

### Hyper-V / Windows

- VM 表示名: `AI-Dev-Lab`
- ゲスト PC 名: `AI-DEV-LAB`
- ゲスト OS: Windows 11 Pro
- vCPU: 4
- メモリ: Dynamic Memory を使用
- Hyper-V Enhanced Session: 利用可能
- VM 停止時: **仮想マシンの状態を保存**
- ホスト再起動後: 停止前に動作していた場合は自動起動する設定

現在のローカル Known Folder は OneDrive ではなく、通常のユーザープロファイル配下に戻しています。

```text
Desktop   -> %USERPROFILE%\Desktop
Documents -> %USERPROFILE%\Documents
Pictures  -> %USERPROFILE%\Pictures
```

OneDrive はこの VM では使用しません。

### AI / Harness

Herdr を中心に複数エージェントを扱います。

Herdr の session resume を確認済み:

- Codex
- OpenCode
- Hermes
- AGY / Antigravity CLI

Grok CLI は Herdr integration 追加まで完了しています。resume は今後別途確認します。

Grok CLI 追加手順:

```powershell
# Herdr を更新
herdr update

# Grok CLI
irm https://x.ai/cli/install.ps1 | iex

# 一度起動して ~/.grok を作成
# 初回設定後に終了
grok

# Herdr 統合
herdr integration install grok

# 確認
herdr
```

詳細は [`docs/HERDR.md`](docs/HERDR.md) を参照してください。

### 開発・操作ツール

現在の VM では、用途に応じて次のようなツールを利用しています。

- Git
- GitHub CLI
- Visual Studio Code
- Windows Terminal / PowerShell
- Google Chrome
- Everything
- CLaunch
- Tablacus Explorer
- TypeWhisper
- Codex / ChatGPT Desktop

CLaunch は AI / Development / Utility に分けたランチャーとして利用し、Tablacus Explorer は常時表示でも眩しくなりにくい暗色 UI に調整しています。

### GUI / Computer Use 実験

AI の Windows GUI 操作能力を次の種類のアプリで検証する予定です。

- Krita — ペイント操作
- Cakewalk Sonar — DAW / 音楽制作操作
- Blender — 3D 操作

2026-09 時点では、Windows 版 Computer Use で **ブラウザは認識されるが native Windows apps が `apps: []` になる回帰不具合**を確認しています。VM 固有ではなくメイン PC でも再現したため、Hyper-V の設定問題とは分離して扱います。

また Blender は通常の Hyper-V 仮想ディスプレイでは必要な OpenGL 能力を得られず、起動時に `OpenGL 4.3 or higher is required` となる場合があります。これは Computer Use とは別問題です。

詳細は [`docs/KNOWN-ISSUES.md`](docs/KNOWN-ISSUES.md) を参照してください。

## 音声入力

メイン環境の入力系は次の構成です。

```text
SM58
 -> BRIDGE CAST X
 -> Host Windows
 -> Hyper-V Remote Audio Recording
 -> AI-Dev-Lab
 -> TypeWhisper
 -> ElevenLabs Scribe v2
 -> VM 内の入力欄
```

Enhanced Session の **「このコンピューターから録音する」** を有効にすると、ゲスト側に `Remote Audio` 入力が現れ、VM 内 TypeWhisper から音声入力できることを確認しています。

KB16 + VIA から TypeWhisper の `Ctrl+Shift+Alt+F5` を直接送ると、VM 側で F5 が欠落する現象がありました。VIA マクロとしてキーイベントを分解すると動作しました。

現在の実用マクロ:

```text
{+KC_LALT}{+KC_LSFT}{+KC_LCTL}{30}{+KC_F5}{30}{-KC_F5}{30}{-KC_LCTL}{-KC_LSFT}{-KC_LALT}
```

この方式はトグル入力には使えますが、物理ボタンを押している間だけ録音する Hold 動作には向きません。将来的には QMK の `process_record_user()` で物理 key down / key up を個別処理する方式を検討します。

詳細は [`docs/AUDIO-AND-INPUT.md`](docs/AUDIO-AND-INPUT.md) を参照してください。

## Hyper-V Checkpoints

初期構築で作成した主要なチェックポイント:

```text
00-Clean-Windows
01-Local-Account-Ready
Before-SmartAppControl-Off-2026-08-27
02-Herdr-Multi-Agent-Ready
03-Desktop-UX-Ready
04-AI-Dev-Lab-Ready
```

`04-AI-Dev-Lab-Ready` は、基本 OS、AI ハーネス、デスクトップ UX、OneDrive 撤去、Known Folder 正常化まで完了した基準点です。

Checkpoint は便利ですが、**永続的な設定バックアップの代わりにはしません**。CLaunch / Tablacus / スクリプト等は別途ファイルとしてバックアップします。

## ローカル管理ディレクトリ

VM 内の管理用ルートは次に統一します。

```text
C:\_AI-Dev-Lab\
├─ Backups\
│  ├─ CLaunch\
│  └─ TablacusExplorer\
└─ Scripts\
   └─ Windows\
      └─ UAC\
```

`C:\AI-Dev-Lab` のような別名は作らず、`C:\_AI-Dev-Lab` を基準にします。

## 再構築するとき

まず [`docs/SETUP.md`](docs/SETUP.md) を上から順に進めます。

大まかな順序は以下です。

```text
Hyper-V VM 作成
  ↓
Windows 11 / ローカルアカウント
  ↓
OneDrive を使わないローカル Known Folder 構成
  ↓
Git / GitHub CLI / 開発ツール
  ↓
Herdr + 各 AI CLI
  ↓
CLaunch / Tablacus 等の UX
  ↓
Enhanced Session / Remote Audio
  ↓
TypeWhisper + ElevenLabs
  ↓
バックアップ
  ↓
Checkpoint
```

## Git に入れてはいけないもの

このリポジトリはセットアップ手順を保存する場所であり、認証情報のバックアップ場所ではありません。

コミット禁止:

- API key
- GitHub / ChatGPT / xAI / ElevenLabs 等の token
- `auth.json`
- `.grok` 等の認証情報を含む実データ
- Cookie / browser profile
- SSH private key
- 個人的なファイルやメール
- VM のメモリダンプや Saved State

安全なサンプル値や `<REDACTED>` 化した設定のみ保存します。

## ドキュメント

- [`docs/CURRENT-STATE.md`](docs/CURRENT-STATE.md) — 現在地と未解決点。将来の AI はまずここを見る
- [`docs/SETUP.md`](docs/SETUP.md) — ゼロからの再構築手順
- [`docs/REPRODUCIBILITY-AUDIT.md`](docs/REPRODUCIBILITY-AUDIT.md) — 完全再現に向けて未回収の値と優先度
- [`docs/HERDR.md`](docs/HERDR.md) — Herdr / マルチエージェント構成
- [`docs/AUDIO-AND-INPUT.md`](docs/AUDIO-AND-INPUT.md) — Remote Audio / TypeWhisper / KB16
- [`docs/KNOWN-ISSUES.md`](docs/KNOWN-ISSUES.md) — 既知問題と切り分け記録
- [`scripts/inventory/`](scripts/inventory/) — 現在の Hyper-V / guest state をローカル採取する helper

## 方針

新しい設定や回避策を発見したら、「動いた」という結果だけでなく、可能な限り次も残します。

- なぜ変更したか
- 変更前の症状
- 実行したコマンド
- 成功確認方法
- 元へ戻す方法
- バージョンや日付
- 未解決点

この repo 自体を **AI-Dev-Lab の外部記憶 / 再構築マニュアル** として育てていきます。
