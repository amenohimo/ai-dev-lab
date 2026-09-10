# Reproducibility Audit

この文書は、`AI-Dev-Lab` を将来ゼロから再構築するために、**まだ記録が薄い／現在の VM から回収しておくべき情報**を管理します。

README / SETUP / CURRENT-STATE は「何を作ったか」をかなり復元できる状態ですが、完全再現という観点では、まだいくつか重要な値が未固定です。

## 結論

現在の repo は「構築思想・主要手順・既知問題・音声入力・Herdr 構成」を復元するには十分な土台があります。

一方で、VM を完全に失ったあとに迷わず再作成するには、次の 4 領域を追加で記録するのが重要です。

1. **Hyper-V VM の正確な spec**
2. **Windows guest の exact build / locale / security state**
3. **インストール済みアプリとバージョンの inventory**
4. **VM 内だけにある設定バックアップの外部化**

---

## P0: 今の VM が生きているうちに回収する

### 1. Hyper-V VM exact spec

現在わかっている値:

```text
VM display name : AI-Dev-Lab
Guest name      : AI-DEV-LAB
Guest OS        : Windows 11 Pro
vCPU            : 4
Memory          : Dynamic Memory
```

まだ repo 上で exact value を確定していないもの:

```text
[ ] VM Generation (Gen 1 / Gen 2)
[ ] Startup Memory
[ ] Minimum Memory
[ ] Maximum Memory
[ ] Secure Boot state / template
[ ] vTPM state
[ ] Checkpoint type
[ ] Virtual Switch name / type
[ ] NIC settings
[ ] VHDX size / type
[ ] VM configuration version
[ ] Integration Services state
[ ] Automatic Start Action exact setting
[ ] Automatic Stop Action exact setting
```

`../scripts/inventory/Capture-HyperVConfig.ps1` を **ホスト PC の PowerShell** で実行して回収する。

出力先は `.local/` 配下を想定しており、`.gitignore` で除外される。内容を確認し、公開してよい値だけ docs に転記する。

### 2. Guest Windows exact state

回収したいもの:

```text
[ ] Windows edition / build / DisplayVersion
[ ] system locale / UI language
[ ] time zone
[ ] computer name
[ ] current local account model
[ ] PowerShell version
[ ] Known Folder paths
[ ] Enhanced Session で必要な guest-side state
[ ] Smart App Control state
[ ] UAC state
[ ] Windows Update / restart-related decisions
```

`../scripts/inventory/Capture-GuestState.ps1` を **VM 内**で実行する。

### 3. Installed software inventory

最低限、将来の再構築に必要なソフトについて、次を残す。

```text
name | purpose | install method | version | auth required? | config backup location
```

対象例:

- Git
- GitHub CLI
- VS Code
- Windows Terminal
- Chrome
- Codex / ChatGPT Desktop
- Herdr
- Codex CLI
- OpenCode
- Hermes
- AGY / Antigravity
- Grok CLI
- CLaunch
- Everything
- Tablacus Explorer
- TypeWhisper
- Krita
- Cakewalk Sonar
- Blender

`winget` で入らないものは、公式 URL / installer 名 / install command を docs に残す。

バージョンを永久固定する必要はないが、**「当時何で動いていたか」**は復旧時の重要な手掛かりになる。

---

## P0: VM 内バックアップだけでは災害復旧にならない

現在の canonical local backup root:

```text
C:\_AI-Dev-Lab\Backups\
```

これは VM 内の設定破損から戻すには有効だが、VHDX 自体を失った場合には一緒に消える。

したがって、少なくとも次のどちらかを追加する。

### A. sanitized config を GitHub に保存

認証情報を取り除いた設定だけ repo の `configs/` 等へ保存する。

候補:

```text
configs/
├─ claunch/
├─ tablacus/
├─ herdr/
├─ typewhisper/
└─ via/
```

秘密情報・履歴・token を含む raw config をそのまま commit しない。

### B. private binary backup を host 側へ退避

完全な設定バックアップが必要なものは repo ではなく、host 側の非公開 backup へコピーする。

GitHub は **再構築手順と sanitized state**、host backup は **private raw state** と役割を分ける。

---

## P1: 再構築をさらに楽にするために記録したいもの

### Hyper-V / Windows

- Hyper-V 有効化手順
- BIOS / UEFI virtualization prerequisite
- Windows 11 ISO の入手元と edition
- VM 作成時の Generation / Secure Boot / TPM
- virtual switch の作り方
- Enhanced Session を host / guest のどこで有効にするか
- VMConnect Remote Audio Recording の設定手順
- host reboot 時の VM start / stop policy

### Windows 初期設定

- Microsoft account を必須にしない方針
- OneDrive を接続しないこと
- OneDrive を誤って接続した場合の Known Folder 復旧
- browser sync を原則 OFF にすること
- Windows の "PC のセットアップを完了しましょう" / SCOOBE を不要なら無効化すること
- taskbar / dark mode / animation / transparency 等の UX 方針

### Security

- UAC は通常 ON
- 一時 OFF の用途と戻し方
- Smart App Control の現在状態を記録
- Defender exclusion は必要性と範囲を確認してから設定し、安易な広域除外はしない
- secret は public repo に保存しない

### Applications / UX

CLaunch と Tablacus は「入れた」だけでは元の使用感を再現できないので、次を残す。

```text
[ ] exact install location
[ ] settings location
[ ] backup command / procedure
[ ] restore command / procedure
[ ] dark theme / CSS
[ ] launcher layout / important entries
```

### AI / Harness

各 agent ごとに:

```text
[ ] install method
[ ] first-run auth/setup
[ ] config directory
[ ] Herdr integration command
[ ] resume verification status
[ ] known incompatibilities
```

「integration 済み」と「resume 確認済み」は別ステータスとして記録する。

### Audio / Input

すでに `AUDIO-AND-INPUT.md` に主要経路は記録済み。

追加で残すとよいもの:

```text
[ ] TypeWhisper version
[ ] ElevenLabs plugin/model setting
[ ] VM 側 Remote Audio device name
[ ] TypeWhisper hotkey
[ ] KB16 exact revision
[ ] VIA firmware / definition version
[ ] VIA macro export / screenshot
[ ] QMK custom keycode を導入した場合の source + firmware build hash
```

---

## P1: "構築できた" の acceptance test

再構築完了判定を、見た目ではなくテストで決める。

```text
[ ] Windows boots and local account signs in
[ ] Known Folders are local, not OneDrive
[ ] Internet / DNS works
[ ] Git / gh / code / wt resolve
[ ] Codex / ChatGPT Desktop signs in
[ ] Herdr starts
[ ] required agents start independently
[ ] required Herdr integrations are visible
[ ] native session resume works for agents marked as verified
[ ] CLaunch layout restored
[ ] Tablacus dark UI restored
[ ] Enhanced Session works
[ ] clipboard works when expected
[ ] Remote Audio output works
[ ] Remote Audio input works
[ ] TypeWhisper transcribes through ElevenLabs Scribe v2
[ ] KB16 macro triggers VM-side TypeWhisper
[ ] local backup root exists
[ ] stable Hyper-V checkpoint created
```

Computer Use と Blender GPU は既知問題の影響を受けるため、基盤 VM の acceptance test とは分離する。

---

## P2: あると便利

- `winget export` または独自 manifest による基本アプリ一括導入
- PowerShell bootstrap script
- sanitized CLaunch / Tablacus config restore script
- VM health-check script
- `CURRENT-STATE.md` を更新する inventory helper
- screenshots ディレクトリ（秘密情報が写っていないものだけ）
- decision log / ADR（大きな方針変更時のみ）

---

## 更新ルール

新しい作業をしたときは、最低限どこかに次を残す。

```text
Why       : なぜ必要だったか
Before    : 変更前の状態 / 症状
Change    : 何をしたか
Verify    : どう成功確認したか
Rollback  : 元に戻す方法
Version   : 関係する version
Status    : verified / provisional / unresolved
```

この audit の P0 が埋まれば、`AI-Dev-Lab` は「思い出せる repo」から **実際に再構築できる repo** にかなり近づく。
