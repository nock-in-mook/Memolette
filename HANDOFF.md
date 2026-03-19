# 引き継ぎメモ

## 現在の状況
- **experiment/frosted-folder** ブランチで作業中
- セッション030でタグ編集プレビュー改善、設定画面タグ並び替え等を実装

### セッション030の主な変更点
- TagDetailEditViewのプレビューをリアルなタブデザインに変更（TrapezoidTabShape+ドロップシャドウ+テクスチャドット）
- NewTagSheetViewの親タグ追加時のみリアルなタブプレビュー（子タグは従来のバッジ）
- 新規タグ追加画面のタイトル順序変更（「親タグの追加（フォルダの追加）」）
- サブタイトルフォントサイズ調整（11→13）
- 設定画面タグ編集：ドラッグ並び替え対応（sortOrder順表示、親タグのみ表示）
- タグ編集画面の並び替え説明をタイトル下に移動
- List内ボタン干渉修正（.buttonStyle(.borderless)）
- 全シートから色変更時の `.animation` 削除（シート伸縮防止）

### 解決済み: シートの伸び縮み問題
- iOS 26シミュレータ固有のバグと確認（セッション031で実機検証済み）
- **実機では発生しない** → 対応不要

## ブランチ構成
- **main**: セッション027まで
- **experiment/frosted-folder**: セッション028-030（テクスチャ・影・UI改善・よく見るフォルダ・タグ編集改善）← 現在

## 主要ファイル
- **TabbedMemoListView.swift**: メモ一覧、フォルダタブ、子タグドロワー、背景一元管理、よく見るタブ、色変更シート
- **MemoInputView.swift**: 入力欄、Undo/Redo、最大化ボタン修正
- **MainView.swift**: iPad対応、子タグ反映修正、アニメーション時短
- **MemoInputViewModel.swift**: Undo/Redoスタック、hasText判定、閲覧追跡
- **Memo.swift**: viewCount / lastViewedAt 追加
- **TagEditView.swift**: ColorPaletteGrid、TagDetailEditView（リアルタブプレビュー）、ドラッグ並び替え
- **NewTagSheetView.swift**: 親タグ時リアルタブプレビュー

## 環境
- **Mac②（新）**: MacBook Air — Xcode 26.3, シミュレータ iPhone 17 Pro Max (iOS 26.3.1)
- 実機: 15promax (26.3.1) (00008130-0006252E2E40001C)

## 次のアクション
1. **シートの伸び縮み問題を実機で確認** → シミュレータ固有なら無視
2. **タブの並び替えグラフィカルモード**: 長押し→「フォルダの並び替え」→タブバー上で直接ドラッグ（ぷるぷるアニメ、完了ボタン）
3. ブランチをmainにマージするか判断
4. Specialメニュー（爆速整理モード等）
5. その他ROADMAPのタスク

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **ビルドキャッシュが頑固**: DerivedData削除+アンインストール+clean+フルリビルドが確実
- SourceKitの偽陽性エラー多発→ビルドは成功する
- **バンドルID**: com.sokumemokun.app
- **sheet(isPresented:)のState再利用バグ**: 特殊タブ色変更で発覚。sheet(item:)+独立Viewで解決済み
- **ForEach(0..<count, id: \.self)のcontextMenuキャプチャ問題**: indexが古い値を保持する場合がある
