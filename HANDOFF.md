# 引き継ぎメモ

## 現在の状況
- **feature/roulette-redesign** ブランチで作業中
- 子タグ引き出しドロワー実装済み（TabbedMemoListView.swift）
  - 「◁子タグ」取っ手をドラッグで任意の位置まで引き出し可能
  - 不透明グレー帯デザイン、スプリングアニメーション
  - 子タグの数に応じた幅で停止
  - タップで全開/全閉トグル
- メモ閲覧時のフォルダ自動移動を廃止
  - onChange(of: selectedTagID)からswitchToTab発火を完全削除
  - ルーレット操作でもフォルダ移動しない
  - 新タグ作成時のみフォルダ移動を残す
- 「ここに保存」ボタンのタップ領域をダミー枠で見た目と一致させた
- メモソートをcreatedAt降順に変更
- メモカードのタップ処理をMemoCardView内部に移動
- ツールバーエリアのスワイプでフォルダ移動しないよう修正

## ブランチ構成
- **main**: 安定版
- **feature/input-area-expand-and-view-mode**: 展開/縮小・タグタブ改善（マージ待ち）
- **feature/roulette-redesign**: ルーレット統合Canvas・UI改善・子タグドロワー（現在作業中）

## 主要ファイル
- MemoInputView.swift: 展開/縮小、逆さL字タグタブ（「タグ付」表記）、フッター
- MemoInputViewModel.swift: loadMemoCounter（閲覧モード切替トリガー）
- MainView.swift: isInputExpanded状態管理、展開時←ボタン、タグQuery追加
- TabbedMemoListView.swift: グリッド5段階、isCompact対応、「ここに保存」ボタン、フラッシュアニメーション、**子タグ引き出しドロワー**、memoGridItem関数分離
- TagDialView.swift: 親子統合Canvas（1つのCanvasで親子描画）
- MemoDetailView.swift: 統合TagDialView対応済み

## 環境
- Mac: MacBook Air M2, macOS
- Xcode: 26.3
- シミュレータ: iPhone 15 Pro Max (95C8A8C5-0972-4BB0-B793-5219096697DF) ← iOS 17.2
- 実機: 15promax (26.3.1) (00008130-0006252E2E40001C)
- ビルド後は毎回「Fit Screen」でウィンドウ縮小する

## 次のアクション
1. 「記入中のメモをここに保存」の誤タップ問題（問題3、未着手）
2. 追加したメモが一番上に保存されない問題（createdAtソートに戻した影響）
3. feature/roulette-redesignをfeature/input-area-expand-and-view-modeにマージ
4. さらにmainにマージ
5. 実機ビルド・テスト
6. FullEditorView.swift / MemoDetailView.swiftの不要コード整理
7. 設定で「子タグルーレットを常に表示」のオンオフ切替
8. ルーレット上のマス長押しでタグ削除メニュー
9. マークダウン編集画面のテコ入れ
10. 横画面対応、iPad対応レイアウト、アプリアイコン

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
