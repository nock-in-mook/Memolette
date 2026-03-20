# 引き継ぎメモ

## 現在の状況
- **main** ブランチで作業中
- セッション037でUI改善多数＋爆速振り分けモード設計完了

### セッション037の主な変更点
- **feature/tag-suggest-ui → mainマージ**: 辞書20000語＋グリッド改修＋UI改善を統合
- **メモ最大文字数制限**: 5万文字（MemoInputView + MemoDetailView）
- **文字数カウンター**: 消しゴム右にフロートバッジ表示（設定でON/OFF）
- **行番号表示**: TextKit1ベースUITextView + ガター（編集・閲覧両対応、設定でON/OFF）
- **ルーレット展開パフォーマンス改善**: テキスト幅変更を廃止→半透明オーバーレイ方式
- **UNDO/REDO統合**: 本文+タイトル+タグをスナップショットで一括管理
- **フォルダタブのタグ名省略**: 全角5文字（半角10文字）で切り詰め
- **タグサジェスト修正**: 確定後の誤表示防止、全画面時の位置修正、「タグの提案」タイトル追加
- **サジェスト新規タグ作成**: リッチダイアログ（おまかせカラー/色指定/戻る）
- **ルーレット長押しダイアログ**: カスタムUI化（色付きバッジ+編集+削除+閉じる）
- **トップ移動チェックマーク**: 赤→青に変更
- **テストデータV9**: 1万文字超テストメモ追加

## 次のアクション（優先順）
1. **爆速振り分けモードの実装** — ROADMAP詳細設計済み（QuickSortView）
2. **実機テスト** — 行番号・文字数カウンター・長文パフォーマンス確認
3. **アプリアイコン**
4. **編集時/閲覧時の文字サイズ変更**
5. **有料版機能の詳細打ち合わせ**

## 主要ファイル
- **LineNumberTextEditor.swift**: 行番号付きUITextViewラッパー（新規）
- **MemoInputViewModel.swift**: UNDO統合スナップショット、最大文字数定数
- **MemoInputView.swift**: 文字数カウンター、ルーレット展開オーバーレイ、長押しカスタムダイアログ
- **MainView.swift**: サジェスト位置修正、新規タグ作成リッチダイアログ
- **TagDialView.swift**: 長押しをonLongPressコールバックに委譲
- **TabbedMemoListView.swift**: タブ名省略、チェックマーク青化
- **SettingsView.swift**: 文字数カウンター・行番号トグル追加
- **NewTagSheetView.swift**: initialName/initialColorIndexパラメータ追加

## 環境
- **Mac②（新）**: MacBook Air — Xcode 26.3, シミュレータ iPhone 17 Pro Max (iOS 26.3.1)
- 実機: 15promax (26.3.1) (00008130-0006252E2E40001C)

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **ビルドキャッシュが頑固**: DerivedData削除+アンインストール+clean+フルリビルドが確実
- SourceKitの偽陽性エラー多発→ビルドは成功する
- **バンドルID**: com.sokumemokun.app
- **テストデータバージョン**: sampleDataV9
- **MainViewのhueFromColorIndex内RGBテーブル**: tabColorsと同じ値を維持すること（別々に管理しているため同期注意）
