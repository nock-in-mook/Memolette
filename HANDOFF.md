# 引き継ぎメモ

## 現在の状況
- mainブランチで作業中
- セッション058でマークダウン機能を大幅に進化

### セッション058の主な変更点

#### マークダウン記法の拡充
- 番号付きリスト（1. 2. 3.）のスタイリング追加
- 水平線（---/***/___）の表示対応
- リンク記法 [テキスト](URL) のスタイリング
- ネストリスト（インデント付き箇条書き/チェックボックス）対応
- ツールバーに「1.」「──」「🔗」ボタン追加

#### MemoInputViewへのマークダウンエディタ統合
- GutteredTextViewにMDスタイリングを統合（MarkdownContainerView廃止）
- 通常モードもMDモードも同じUITextViewインスタンスを使用（レイアウトずれゼロ）
- MDトグルの動的切り替え対応（inputAccessoryViewの付け外し+スタイルリセット）
- フッターにMDトグルボタン追加（設定でmarkdownEnabled時のみ表示）

#### マークダウンプレビュー機能
- MarkdownPreviewView新設（全記法対応のプレビュー表示）
- 入力欄の中央下端に「プレビュー」ボタン配置（MDモードON時は0文字でも表示）
- プレビュータップで編集に戻る

#### 枠外タップでキーボード閉じるバグ修正
- simultaneousGesture(TapGesture)がUITextView内タップと同時発火する潜在バグを修正
- UIKitのhitTestでタップ先がUITextViewか判定するKeyboardDismissViewを新設
- 入力欄内タップ→カーソル移動のみ、枠外タップ→キーボード閉じる、が両立

#### ルーレットのチラ見え縮小
- タブ幅38→22に縮小（「タグ」テキスト→◀三角マークのみ）
- 円盤のチラ見えオフセットを-50→-42に調整

#### 入力欄の余白調整
- テキストエリアの左右余白を最小化（textInsetLeft: 10, lineFragmentPadding: 0）
- プレースホルダー位置をカーソル位置+1ptで自動計算
- TextAreaLayout定数で全モード（通常/MD/プレビュー/プレースホルダー）統一

#### メンテナンス性の向上
- AppStorageKeys enum新設（19個のキー文字列を集約）
- DesignConstants新設（CornerRadius/Shadow/TagBorder定数化）
- TextAreaLayout定数で全エディタのレイアウト一元管理
- View拡張でshadowLight()/shadowMedium()等のヘルパー追加

#### 最大化時のフロートボタン
- 最大化+キーボード表示時に消しゴム・プレビュー・縮小+⌨️ボタンをフロート表示
- ZStack方式でプレビューを画面中央に固定

#### typingAttributesグレーアウト修正
- MD記号隣接テキストのグレーアウト修正（textViewDidChange後にtypingAttributes再リセット）

## 次のアクション（優先順）
1. **爆速モードでMDファイルをどう扱うか検討**（次回最初に相談）
2. **文字色対応**（独自記法 or カラーピッカー）
3. **下線・ハイライト（蛍光ペン風）**
4. **MemoDetailView（閲覧画面）でのマークダウンプレビュー表示**
5. **タグ履歴のデバッグ**: 履歴が正しく記録・表示されるか実機確認
6. **ダミーデータ削除**: SokuMemoKunApp.swift の insertDummyTagHistory をリリース前に削除
7. **実機ビルドの問題解決**（CodeSign / Google Driveのxattr問題）
8. **並び替え問題の大改修**

## 主要ファイル（マークダウン関連）
- **LineNumberTextEditor.swift**: GutteredTextViewにMDスタイリング統合済み（applyMarkdownStyle/updateMarkdownMode）
- **MarkdownTextEditor.swift**: 旧実装（MarkdownContainerView）— 現在未使用だが残存
- **MarkdownToolbar.swift**: キーボード直上の記号入力バー
- **MarkdownPreviewView.swift**: プレビュー表示（全記法対応）
- **MemoInputView.swift**: MDトグル・プレビューボタン・TextAreaLayout定数

## 主要ファイル（定数管理）
- **Constants/AppStorageKeys.swift**: UserDefaultsキー文字列の一元管理
- **Constants/DesignConstants.swift**: CornerRadius/Shadow/TagBorder定数

## 環境
- **Mac②（新）**: MacBook Air — Xcode 26.3, シミュレータ iPhone 17 Pro (iOS 26.3)
- 実機: 15promax (26.3.1) — デバイスID: 00008130-0006252E2E40001C
- **ビルド**: Google Drive上のファイル変更検知問題あり。xattr -cr . が必要

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **ダイアログルール**: 全てカスタムリッチダイアログ（標準alertは使わない）
- **TextKit 1**: GutteredTextViewはUITextView(usingTextLayoutManager: false)を使用
- **lineFragmentPadding**: 0に設定済み（余白最小化）
- **シミュレータでprintデバッグは使えない**: UI overlay等で対応
