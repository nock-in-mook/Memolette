# 引き継ぎメモ

## 現在の状況
- **main** ブランチで作業中
- セッション020で多数のUI改善を実施

### 今回の変更点
- チェックマーク丸印タップでもメモ選択可能に
- 検索バー縮小表示（「メモを探す」、タップで展開、バツで縮小）
- トップに移動・トップに常時固定機能（Memoモデルに isPinned, manualSortOrder 追加）
- 削除/移動の選択モード分離（SelectMode enum: none, delete, moveToTop）
- オリジナルアイコン（MoveToTopIcon: カード横並び＋上矢印）
- 選択モード中のガイドテキスト表示
- 長押し削除に確認ダイアログ追加
- メモ一覧最大化（取っ手タップで発動、↓ボタンで戻る）
- 最大化時のメモタップ→入力欄最大化に遷移（←で最大化に戻る）
- 確定ボタン統一（フッター・ナビバー共通、confirmMemo()関数）
- 保存トースト（「保存しました」1.5秒表示）
- フラッシュ通知（確定時にメモカードが青く点滅）
- ルーレットUI改善途中（タグ付け表記、タブ常時表示、アニメーション）
- ROADMAP大幅更新（Phase 12-14追加、既存Phase充実）

## ブランチ構成
- **main**: 全機能統合済み

## 主要ファイル
- MainView.swift: メモ一覧最大化（isMemoListExpanded）、確定ボタン統一（confirmMemo）、保存トースト、検索バー縮小/展開
- MemoInputView.swift: 確定ボタン（hasDiff/onConfirm）、ルーレットUI改善途中（タブ常時表示）
- TabbedMemoListView.swift: SelectMode enum、トップ移動/固定、MoveToTopIcon、ガイドテキスト、長押し削除確認
- Memo.swift: isPinned, manualSortOrder 追加
- ROADMAP.md: Phase 12-14追加

## 環境
- Mac: MacBook Air M2, macOS
- Xcode: 26.3
- シミュレータ: iPhone 15 Pro Max (95C8A8C5-0972-4BB0-B793-5219096697DF) ← iOS 17.2
- 実機: 15promax (26.3.1) (00008130-0006252E2E40001C)
- ビルド後は毎回「Fit Screen」でウィンドウ縮小する

## 次のアクション
1. **ルーレットのトレー方式への構造変更**（子タグドロワーと同じ方式で右端から引き出す）
   - 現在のHStack+if/else方式だとタブの位置がズレる問題
   - 固定位置にトレーを配置してoffsetでスライドさせる方式に変更
   - チラ見え機能（閉じている時にルーレットが少しだけ覗く）
2. 「このタグにメモ作成」ボタンを薄いグレーにする or メモカード背景を薄いグレーに
3. Specialメニュー実装（30ptスペースからの引き出し）
4. マークダウン編集リニューアル
5. 実機ビルド・テスト

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **実機ビルドキャッシュ問題**: DerivedDataクリーンでも実機に古いビルドが残ることがある。`xcodebuild clean` + フルリビルドが確実
- SwiftUIのButton内テキストが青くなる → `.buttonStyle(.plain)`
- MemoInputViewModelは@Stateで一度だけ生成 → 設定変更はonChangeで反映
- ModelContainerは共有必須
- SourceKitの偽陽性エラー多発→ビルドは成功する
- **子タグ連打フリーズ**: withAnimationの競合が原因。子タグタップのwithAnimationを除去、.animation(.spring)のスコープをドロワーのみに限定して解決
- **グリッドカード高さ**: 動的計算(cardHeight)が効かないためハードコード
- **MemoInputView.onConfirm**: 確定処理はMainView.confirmMemo()に集約。hasDiffで差分検出
