# 引き継ぎメモ

## 現在の状況
- Phase 1 実装完了、UI改善進行中
- 設定画面（⚙️）実装済み: タグ編集、マークダウン設定、バックアップ(準備中)、最大文字数(準備中)
- タグ編集機能: 一覧表示(背景色付き)、タップで編集、新規追加、選択削除
- カラーパレット: 28色(7×4グリッド)
- マークダウン編集機能: 全画面エディタ、ON/OFFトグル、上下分割/タブ切替プレビュー
- デフォルトマークダウンON設定: 設定変更→即反映、保存後リセット
- マークダウンON＋空欄タップで全画面編集を自動起動（ガイドテキスト付き）
- タブごとのグリッド表示切替（1×6/2×6/3×8の3パターン）
- カード高さを画面サイズから動的計算（6行/8行でぴったり収まる）
- メモ追加ボタン（入力欄フォーカス）と選択削除モード
- マークダウンメモにM↓マーク、タップでプレビュー編集画面
- プレビュー表示形式のカスタムアイコン（上下分割=A/B、タブ=A|B）
- メモカードにドロップシャドウ、背景を不透明白に統一
- タブ切替アニメーション削除（瞬時切替）
- ダミーデータ投入済み（アイデア100件含む）

## 主要ファイル
- TabbedMemoListView.swift: グリッド切替、メモ追加/選択削除、MemoCardView（M↓マーク対応）
- FullEditorView.swift: LayoutIcon（カスタムアイコン）追加
- SettingsView.swift: プレビュー表示形式ラベル＋カスタムアイコン
- MemoInputView.swift: @FocusState追加、マークダウンON時の空欄タップ
- MainView.swift: focusInput連携
- Tag.swift: gridSizeプロパティ追加
- SokuMemoKunApp.swift: ダミーデータ投入（V2、アイデア100件+MD5件）

## 環境
- Mac: MacBook Air M2, macOS
- Xcode: 26.3
- シミュレータ: iPhone 15 Pro Max (95C8A8C5-0972-4BB0-B793-5219096697DF) ← iOS 17.2
- ビルド後は毎回「Fit Screen」でウィンドウ縮小する

## 次回検討事項（優先）
1. 書きかけのメモの扱い（自動保存？下書き？破棄確認？）
2. マークダウン編集画面のテコ入れ（アイコンの説明表示、保存ボタンの配置・動作）

## 次のアクション
1. 上記の次回検討事項をユーザーと議論
2. 爆速振り分けモード（フリック×タグホイール連動）
3. Googleドライブバックアップ機能
4. Phase 2: iCloud/CloudKit設定・同期テスト
5. 実機テスト

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- SwiftUIのButton内テキストが青くなる → `.buttonStyle(.plain)`
- MemoInputViewModelは@Stateで一度だけ生成 → 設定変更はonChangeで反映
- ModelContainerは共有必須
- ダミーデータはUserDefaultsの"dummyMemosV2"フラグで制御（再投入はアプリ再インストールで）
