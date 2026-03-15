# 引き継ぎメモ

## 現在の状況
- **main** ブランチで作業中（feature/roulette-redesign, feature/input-area-expand-and-view-mode を統合済み）
- セッション019でmainマージ＋グリッドカード高さ修正

### 今回の変更点
- feature/input-area-expand-and-view-mode → mainにマージ
- feature/roulette-redesign → mainにマージ
- 入力欄とフォルダ間の30ptスペーサー復元（マージで抜けていた）
- グリッドカード高さをハードコードで修正（動的計算が効かなかった問題を解決）
  - 3×8: 36pt, 2×6: 48pt, 2×3: 104pt, 1×2: 160pt
  - 3×8フォント: title 13pt, body 11pt, bodyLines 1
- ROADMAP追記: マークダウン編集リニューアル、画像/地図挿入、メモ一覧最大化

## ブランチ構成
- **main**: 全機能統合済み（feature/roulette-redesign, feature/input-area-expand-and-view-mode マージ完了）

## 主要ファイル
- MemoInputView.swift: 展開/縮小、逆さL字タグタブ（「タグ付」表記）、フッター（閉じるボタン追加）
- MemoInputViewModel.swift: loadMemoCounter（閲覧モード切替トリガー）
- MainView.swift: isInputExpanded状態管理、展開時←ボタン、30ptスペース、確認ダイアログ
- TabbedMemoListView.swift: グリッド5段階（高さハードコード）、isCompact対応、ボタンUI改善、子タグドロワー完成、横スクロール対応
- TagDialView.swift: 親子統合Canvas（1つのCanvasで親子描画）
- MemoDetailView.swift: 統合TagDialView対応済み、フッターに「ここに保存」＋確認ダイアログ
- SokuMemoKunApp.swift: テストデータV7（仕事に子タグ15個）

## 環境
- Mac: MacBook Air M2, macOS
- Xcode: 26.3
- シミュレータ: iPhone 15 Pro Max (95C8A8C5-0972-4BB0-B793-5219096697DF) ← iOS 17.2
- 実機: 15promax (26.3.1) (00008130-0006252E2E40001C)
- ビルド後は毎回「Fit Screen」でウィンドウ縮小する

## 次のアクション
1. 実機ビルド・テスト（mainに統合したので要確認）
2. Specialメニュー実装（30ptスペースからの引き出し）
3. マークダウン編集リニューアル（☰メニュー＋Bear風、git: 57341dd参照）
4. テストデータ（sampleDataV7）を元に戻す or 調整
5. FullEditorView.swift の不要コード整理
6. 設定で「子タグルーレットを常に表示」のオンオフ切替
7. ルーレット上のマス長押しでタグ削除メニュー
8. 画像・地図の挿入機能
9. 横画面対応、iPad対応レイアウト、アプリアイコン

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **実機ビルドキャッシュ問題**: DerivedDataクリーンでも実機に古いビルドが残ることがある。`xcodebuild clean` + フルリビルドが確実
- SwiftUIのButton内テキストが青くなる → `.buttonStyle(.plain)`
- **SwiftUIのZStack内Buttonのタップ領域問題**: ZStack内のButtonは周囲の空白もタップ対象になる。ダミー枠（padding+background）で見た目をタップ領域に合わせるアプローチが有効
- MemoInputViewModelは@Stateで一度だけ生成 → 設定変更はonChangeで反映
- ModelContainerは共有必須
- SourceKitの偽陽性エラー多発（tagColor, UIPasteboard, UIResponder等）→ビルドは成功する
- NotificationCenter(.switchToTab, .memoSavedFlash)でクロスビュー通信
- タブインデックスはsortOrderベース（name sortではない）
- タグタブのoverlayは本文ZStackの.topTrailingに配置（仕切り線直下）
- TagDialViewは親子統合Canvas: ドラッグx座標で親/子判定（borderX = cx - parentInnerR）
- switchToTabはルーレット操作では発火しない（新タグ作成時のみ）
- **子タグ連打フリーズ**: withAnimationの競合が原因。子タグタップのwithAnimationを除去、.animation(.spring)のスコープをドロワーのみに限定して解決
- **グリッドカード高さ**: 動的計算(cardHeight)が効かないためハードコード。変更時はMemoCardView.bodyの.frame(height:)を直接修正
