# 引き継ぎメモ

## 現在の状況
- **main** ブランチで作業中
- セッション025でルーレットSwiftUI化完了、mainにマージ済み
- セッション026で小さなUI修正2件を実施

### セッション026の変更点
- フォルダ並び替えアイコンを上下矢印→左右矢印に変更（`arrow.left.arrow.right`）
- メモカードのタイトル・本文を中央寄せ→上寄せに変更（`.frame` に `alignment: .topLeading`）

## ブランチ構成
- **main**: 全機能統合済み（セッション026まで）

## 主要ファイル
- **TabbedMemoListView.swift**: メモ一覧、フォルダタブ、子タグドロワー、並び替え
- **TagDialView.swift**: Canvas描画+透明ジェスチャーオーバーレイ方式
- **MemoInputView.swift**: トレー方式、長押し編集UI、子タグ追加警告
- **SettingsView.swift**: タグトレー起動時状態設定
- **TagDetailEditView.swift**: タグ名・色の編集
- **TagEditView.swift**: タグ削除ロジック

## 環境
- **Mac②（新）**: MacBook Air — Xcode 26.3, シミュレータ iPhone 17 Pro Max (iOS 26.3.1)
- 実機: 15promax (26.3.1) (00008130-0006252E2E40001C)

## 次のアクション
1. タグサジェストUI、学習機能
2. Specialメニュー（爆速整理モード、グラフリンクモード等）
3. その他ROADMAPのタスク

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **ビルドキャッシュが頑固**: DerivedData削除+アンインストール+clean+フルリビルドが確実
- SwiftUIのButton内テキストが青くなる → `.buttonStyle(.plain)`
- SourceKitの偽陽性エラー多発→ビルドは成功する
- **バンドルID**: com.sokumemokun.app
