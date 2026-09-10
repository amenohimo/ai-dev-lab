# Current State

最終更新の初期基準: 2026-09

このファイルは「今どこまで出来ているか」を人間と AI が短時間で把握するための復帰地点です。

## 基準 VM

```text
Hyper-V VM display name : AI-Dev-Lab
Guest computer name     : AI-DEV-LAB
Guest OS                : Windows 11 Pro
vCPU                    : 4
Memory                  : Dynamic Memory
Management root         : C:\_AI-Dev-Lab
Dev root                : C:\Dev
```

Known Folders はローカルに復帰済み:

```text
Desktop   : %USERPROFILE%\Desktop
Documents : %USERPROFILE%\Documents
Pictures  : %USERPROFILE%\Pictures
```

OneDrive:

```text
Unlinked
Uninstalled
Known Folder redirect removed
remaining local remnants cleaned
```

Windows の追加セットアップ提案は無効化済み。

```text
設定
 -> システム
 -> 通知
 -> 追加の設定

OFF: Windows を最大限に活用し、このデバイスの設定を完了する方法を提案する
OFF: Windows を使用する際のヒントや提案を入手する
```

この VM では OneDrive / Microsoft 365 等の再提案を避け、ローカル中心の開発環境を維持する。

## Hyper-V checkpoint

現在の重要な基準点:

```text
04-AI-Dev-Lab-Ready
```

この checkpoint は、以下まで完了した状態を示します。

- Windows 基本設定
- local account 運用
- OneDrive 撤去
- Known Folder 正常化
- Herdr multi-agent 基盤
- desktop UX
- CLaunch
- Tablacus Explorer dark customization

過去 checkpoint:

```text
00-Clean-Windows
01-Local-Account-Ready
Before-SmartAppControl-Off-2026-08-27
02-Herdr-Multi-Agent-Ready
03-Desktop-UX-Ready
04-AI-Dev-Lab-Ready
```

## Herdr

確認済み integration / resume 対象:

```text
Codex     OK
OpenCode  OK
Hermes    OK
AGY       OK
Grok      added
```

Grok の追加は README / HERDR.md を参照。

## Desktop UX

### CLaunch

目的別ページ:

```text
AI / Harness
Development
Utility
```

設定は local username に紐づくことがあるため backup 必須。

Backup root:

```text
C:\_AI-Dev-Lab\Backups\CLaunch
```

### Tablacus Explorer

Dark mode + user stylesheet を利用。

active tab は常時表示でも目を奪わないよう、太い accent line を使わず暗い background 差で表現。

```css
.activetab {
    color: #d2cdca !important;
    background: #2d2a2e !important;
    border-bottom: none !important;
}
```

Backup root:

```text
C:\_AI-Dev-Lab\Backups\TablacusExplorer
```

## Audio / Voice Input

Remote Audio Recording は設定済み。

Guest の input に `Remote Audio` が表示され、host microphone の音が VM へ届くことを確認済み。

想定経路:

```text
SM58
 -> BRIDGE CAST X
 -> Host Windows
 -> Hyper-V Remote Audio
 -> Guest Windows
 -> TypeWhisper
 -> ElevenLabs Scribe v2
```

## KB16 / TypeWhisper

TypeWhisper hotkey:

```text
Ctrl + Shift + Alt + F5
```

KB16/VIA から shortcut として直接送ると F5 が guest で欠落。

VIA macro へ分解すると動作:

```text
{+KC_LALT}{+KC_LSFT}{+KC_LCTL}{30}{+KC_F5}{30}{-KC_F5}{30}{-KC_LCTL}{-KC_LSFT}{-KC_LALT}
```

未解決:

- この VIA macro は toggle 用には使える
- physical key を hold している間だけ TypeWhisper を録音させる動作は未実装
- QMK `process_record_user()` による key-down / key-up 分離を将来検討

## Computer Use

Windows native app control は現在ブロック中。

観測:

```json
{
  "apps": [],
  "browsers": [ ... ]
}
```

確認済み:

- Any App ON
- Computer Use plugin installed
- skill ON
- browser control available
- native apps unavailable
- Enhanced Session ON/OFF とも同じ
- main PC でも同じ

したがって VM 構成を原因と決めつけず、Windows Computer Use 側の回帰不具合として追跡中。

## Blender

Blender は Hyper-V guest で次の error:

```text
A graphics card and driver with support for OpenGL 4.3 or higher is required.
```

これは Computer Use と別問題。

将来候補:

- GPU virtualization / partitioning
- software OpenGL / Mesa llvmpipe

## Next candidates

優先候補:

```text
1. Windows Computer Use native app support の復旧後に再テスト
2. Krita / Sonar で Astra Computer Use GUI benchmark
3. Blender の OpenGL workaround
4. KB16 QMK custom keycode で TypeWhisper hold 対応
5. setup script / package inventory の自動化
6. CLaunch / Tablacus backup の再現手順をさらに自動化
```

## Resume instruction for future AI

この repo を読んで作業を再開する AI は、まず次を読むこと。

```text
README.md
↓
docs/CURRENT-STATE.md
↓
docs/SETUP.md
↓
対象分野の詳細 docs
```

分からない点を推測で canonical 化せず、実 VM または user に確認すること。
