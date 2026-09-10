# Known Issues / Troubleshooting Notes

この文書は、AI-Dev-Lab 構築中に実際に遭遇した問題と、切り分け結果を保存します。

「直った設定」だけでなく、**何を疑い、何を試し、何が原因ではなかったか**も残します。

## Windows Computer Use: native apps が見えない

### 症状

Computer Use のアプリ一覧を照会すると:

```json
{
  "apps": [],
  "browsers": [
    {
      "name": "Codex In-app Browser",
      "type": "iab"
    }
  ]
}
```

のようになり、ブラウザだけ認識され、Notepad 等の native Windows app を操作できませんでした。

### 確認済み

- Computer Use plugin installed
- Computer Use skill ON
- `任意のアプリ / Any App` ON
- Chrome/browser control は認識される
- native Windows apps は 0 件
- Hyper-V Enhanced Session ON/OFF の両方で再現
- VM だけでなく main PC でも再現
- Luna / Astra のどちらでも同じ symptom

### 結論

VM 固有の問題として扱わないこと。

2026-09 時点では Windows native Computer Use provider / integration 側の回帰不具合と整合するため、Hyper-V、UAC、VM display 設定を無闇に崩して追いかけない。

修正後に再テストする。

### 最小再現テスト

```text
Computer Useを使用して、現在あなたが操作可能なWindowsアプリの一覧を確認してください。
アプリを起動したり操作したりする必要はありません。
ブラウザだけでなく、ネイティブWindowsアプリが操作対象として認識されているか確認し、結果だけ報告してください。
```

正常化確認は `apps` が空でなくなること。

---

## Blender: Unsupported Graphics Card Configuration

### 症状

Blender 起動時:

```text
A graphics card and driver with support for OpenGL 4.3 or higher is required.
```

### 原因の扱い

通常の Hyper-V 仮想ディスプレイでは、host GPU の OpenGL capability がそのまま guest に提供されるわけではありません。

Computer Use 不具合とは別問題です。

### 対応候補

- GPU virtualization / partitioning を別途構成
- software OpenGL / Mesa llvmpipe を GUI test 用に検討
- 3D rendering 性能ではなく GUI 操作だけを評価するなら、軽量な workaround を優先

VM の GPU 構成を変更する場合は、必ず checkpoint を取ってから行う。

---

## CLaunch: local account rename 後に設定が初期化されたように見える

### 症状

Windows local username を変更した後、CLaunch が `Page 1 / Page 2 / Page 3` の初期状態に戻ったように見えました。

### 原因

CLaunch が username ごとの data directory を使っていました。

旧 username directory に設定が残り、新 username directory に blank config が作られていました。

### 復旧

CLaunch を完全終了し、旧 directory の:

```text
CLaunch.ini
Design.ini
```

を新 username directory へコピーして復元しました。

### 教訓

Windows username rename 前に CLaunch の設定を backup する。

推奨 backup root:

```text
C:\_AI-Dev-Lab\Backups\CLaunch\
```

---

## OneDrive: Known Folder が OneDrive を指す

### 症状

OneDrive unlink / uninstall 後も Desktop / Documents / Pictures が OneDrive path を指したり、Explorer 表示と物理 path が混乱することがあります。

### 対応

`User Shell Folders` を変更する前に registry export を取ります。

最終確認:

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

必要データを確認する前に OneDrive directory を削除しない。

---

## KB16 / VIA shortcut: modifiers は届くが F5/F6 が欠落

### 症状

KB16 から `Ctrl+Shift+Alt+F5` を shortcut として送ると、guest では:

```text
Ctrl + Shift + Alt
```

だけ認識され、F5 が欠落します。

### 切り分け

- F5 単体: OK
- F6 単体: OK
- physical keyboard から複合キー: OK
- host TypeWhisper 終了: 改善なし
- Enhanced Session OFF: 改善なし
- VIA macro に分解: OK

### 現在の workaround

```text
{+KC_LALT}{+KC_LSFT}{+KC_LCTL}{30}{+KC_F5}{30}{-KC_F5}{30}{-KC_LCTL}{-KC_LSFT}{-KC_LALT}
```

詳細: [AUDIO-AND-INPUT.md](AUDIO-AND-INPUT.md)

---

## AGY / Herdr: agent は見えるが session resume できない

過去の Herdr stable では AGY が検出されても `agent_session` が生成されず、native resume できないことがありました。

Herdr preview update + integration update 後に改善しました。

問題時は単なる `agent_status` だけでなく `agent_session` の有無を確認します。

---

## UAC

Computer Use 診断などで UAC を一時 OFF にすることがありますが、通常運用では ON に戻します。

完全 OFF (`EnableLUA=0`) / ON (`EnableLUA=1`) は再起動が必要です。

repo の scripts を利用してください。

---

## Windows: 「PC のセットアップを完了しましょう」が再表示される

### 症状

Windows Update や再起動後に、フルスクリーンで次のような Microsoft サービス推奨画面が出ることがあります。

```text
PC のセットアップを完了しましょう
- OneDrive
- Microsoft Edge
- Microsoft 365
- スマートフォン連携
- Windows Hello
```

これは Windows が壊れた状態ではなく、初期セットアップ後に表示される追加案内です。

AI-Dev-Lab では OneDrive や Microsoft account 依存を増やさない方針なので、必要がなければサービス設定を進めない。

表示された場合は、まず `3 日後に通知する` 等で desktop に戻ってよい。

再表示を避けたい場合は Windows Settings の:

```text
設定
 -> システム
 -> 通知
 -> その他の設定 / 追加の設定
```

付近にある、次の趣旨の項目を OFF にする。

```text
Windows を最大限に活用し、このデバイスの設定を完了する方法を提案する
```

Windows build により日本語表記は多少変わる。

必要なら同じ場所の次のような推奨通知も OFF にする。

```text
更新後やサインイン時に Windows のウェルカム エクスペリエンスを表示する
Windows を使用する際のヒントや提案を入手する
```

---

## 問題記録テンプレート

今後の問題は最低限、次を残します。

```text
症状:
発生日:
環境 / version:
再現条件:
試したこと:
原因ではなかったもの:
workaround:
最終状態:
未解決:
```
