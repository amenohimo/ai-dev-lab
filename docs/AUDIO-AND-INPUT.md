# Audio / Voice Input / KB16

AI-Dev-Lab では、メイン PC 側の既存マイク環境をできるだけ維持したまま、VM 内でも音声入力・録音を使えるようにします。

## 目標構成

```text
SM58
 -> BRIDGE CAST X
 -> Host Windows
 -> Hyper-V Enhanced Session
 -> Remote Audio Recording
 -> Guest Windows
 -> TypeWhisper
 -> ElevenLabs Scribe v2
 -> text
```

## Remote Audio Recording

VMConnect の Enhanced Session で Remote Audio の録音設定を開き、次を選択します。

```text
このコンピューターから録音する
```

ゲスト側の Windows Sound Settings で input device に `Remote Audio` が表示されることを確認します。

これで VM 内アプリからマイク入力を受け取れます。

### 注意

`Remote Audio` は BRIDGE CAST X の ASIO / 低遅延 / 複数チャンネル機能をそのまま VM に渡すものではありません。

GUI 操作テスト、音声入力、簡単な録音には十分ですが、本格 DAW 用途では別のデバイス転送方式を検討する余地があります。

## TypeWhisper

ホスト側 TypeWhisper の global hotkey は、VMConnect が active のとき期待通り動かないことがありました。

そのため TypeWhisper はゲスト側にもインストールし、VM 内で直接 hotkey を処理させます。

推奨設定:

```text
Input device        : Remote Audio
Transcription engine: ElevenLabs
Model               : Scribe v2
Auto paste          : ON
```

API key は Git に保存しません。

## KB16 + VIA の問題

TypeWhisper の main dictation hotkey:

```text
Ctrl + Shift + Alt + F5
```

KB16 からこれを単一の shortcut として送ると、VM 側では `Ctrl + Shift + Alt` までしか認識されず、F5 が欠落しました。

確認したこと:

- F5 単体は KB16 から VM に届く
- F6 に変更しても複合 shortcut では function key が欠落
- physical keyboard から `Ctrl+Shift+Alt+F5/F6` を直接入力すると正常
- host 側 TypeWhisper を完全終了しても変化なし
- Enhanced Session OFF でも同様
- VIA macro に分解すると正常動作

したがって、Hyper-V Enhanced Session 固有よりも、KB16/VIA/QMK が送る複合 HID 入力の表現と VM 入力経路の相性問題として扱います。

## 現在の VIA macro

現在実用している macro:

```text
{+KC_LALT}{+KC_LSFT}{+KC_LCTL}{30}{+KC_F5}{30}{-KC_F5}{30}{-KC_LCTL}{-KC_LSFT}{-KC_LALT}
```

意味:

```text
Left Alt down
Left Shift down
Left Ctrl down
30 ms wait
F5 down
30 ms wait
F5 up
30 ms wait
Left Ctrl up
Left Shift up
Left Alt up
```

30 ms は VM で動作確認した実績値です。

## VIA macro の limitation

VIA dynamic macro は、物理キーを押した時点で macro 全体を再生するため、TypeWhisper の次の操作を完全には再現できません。

```text
短押し: toggle
長押し: 押している間だけ dictation
離す  : stop
```

現在の macro は toggle 用としては問題ありませんが、physical hold をそのまま TypeWhisper hold に対応させることはできません。

## 将来案: QMK custom keycode

将来的には QMK の `process_record_user()` で physical key down / key up を別々に処理します。

概念例:

```c
enum custom_keycodes {
    TW_PTT = SAFE_RANGE,
};

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    switch (keycode) {
        case TW_PTT:
            if (record->event.pressed) {
                register_code(KC_LALT);
                register_code(KC_LSFT);
                register_code(KC_LCTL);
                wait_ms(30);
                register_code(KC_F5);
            } else {
                unregister_code(KC_F5);
                wait_ms(30);
                unregister_code(KC_LCTL);
                unregister_code(KC_LSFT);
                unregister_code(KC_LALT);
            }
            return false;
    }

    return true;
}
```

この場合、KB16 の物理キーを押している時間そのものを `F5 down` の保持時間として扱えます。

### 実装前の注意

- KB16 の exact revision を確認する
- 現在の VIA / firmware configuration をバックアップする
- QMK/VIA compatibility を維持する
- wrong revision firmware を書き込まない

## 復旧時チェック

```text
[ ] Enhanced Session が有効
[ ] Remote Audio Recording = このコンピューターから録音する
[ ] Guest Sound Settings に Remote Audio input がある
[ ] TypeWhisper が Remote Audio を選択している
[ ] ElevenLabs / Scribe v2 が設定済み
[ ] KB16 macro から VM 内 TypeWhisper が反応する
```
