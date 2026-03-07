# 開発ログ

## 2026-03-05
- プロジェクト初期化（Git + GitHub）
- 各種プロジェクトファイル作成

## 2026-03-05 Phase1 実装
- 技術スタック: SwiftUI + SwiftData (iOS 17+)
- データモデル: Memo（本文/タイトル/タグ/日時）、Tag（名前/メモリスト）
- 画面構成: MainView → MemoInputView + MemoListView + TagFilterPickerView
- 保存後シート: TagTitleSheetView（タイトル・タグ設定、スキップ可）
- Xcodeプロジェクトファイル（project.pbxproj）手書き作成
- CloudKit互換: @Attribute(.unique)不使用、全プロパティにデフォルト値
- ファイル数: Swift 10ファイル + Assets 3ファイル + pbxproj
