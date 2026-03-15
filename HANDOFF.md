# 引き継ぎメモ

## 現在の状況
- **feature/roulette-redesign** ブランチで作業中
- 子タグ引き出しパネルを実装済み（TabbedMemoListView.swift）
  - 親タグタブ選択時に右端「子タグ」タブ表示→タップで展開
  - 子タグ横スクロール（タップ選択、「すべて」オプション）
  - 子タグフィルタリングでメモ絞り込み
  - パネル内「+」で子タグ追加連携
  - 「すべて」「タグなし」タブでは非表示
  - タブ切替時にリセット
- グリッドサイズボタンを右上→左下フロートに移動
- ルーレットタブ表記「タグ」→「タグ付」に変更（MemoInputView.swift）
- 親子ルーレットを1つのCanvasに統合
- 「確定」ボタン廃止→「記入中のメモをここに保存」ボタンに統一
- 保存時にタブ+カードのフラッシュアニメーション追加

## ブランチ構成
- **main**: 安定版
- **feature/input-area-expand-and-view-mode**: 展開/縮小・タグタブ改善（マージ待ち）
- **feature/roulette-redesign**: ルーレット統合Canvas・UI改善・子タグパネル（現在作業中）

## 主要ファイル
- MemoInputView.swift: 展開/縮小、逆さL字タグタブ（「タグ付」表記）、フッター
- MemoInputViewModel.swift: loadMemoCounter（閲覧モード切替トリガー）
- MainView.swift: isInputExpanded状態管理、展開時←ボタン、タグQuery追加
- TabbedMemoListView.swift: グリッド5段階、isCompact対応、「ここに保存」ボタン、フラッシュアニメーション、**子タグ引き出しパネル**
- TagDialView.swift: 親子統合Canvas（1つのCanvasで親子描画）
- MemoDetailView.swift: 統合TagDialView対応済み

## 環境
- Mac: MacBook Air M2, macOS
- Xcode: 26.3
- シミュレータ: iPhone 15 Pro Max (95C8A8C5-0972-4BB0-B793-5219096697DF) ← iOS 17.2
- 実機: 15promax (26.3.1) (00008130-0006252E2E40001C)
- ビルド後は毎回「Fit Screen」でウィンドウ縮小する

## 次のアクション
1. 子タグパネルの動作確認・UIブラッシュアップ（ドラッグスナップ未実装）
2. feature/roulette-redesignをfeature/input-area-expand-and-view-modeにマージ
3. さらにmainにマージ
4. 実機ビルド・テスト
5. FullEditorView.swift / MemoDetailView.swiftの不要コード整理
6. 設定で「子タグルーレットを常に表示」のオンオフ切替
7. タグ選択時にフォルダ自動移動しない設定オプション
8. ルーレット上のマス長押しでタグ削除メニュー
9. マークダウン編集画面のテコ入れ
10. 横画面対応、iPad対応レイアウト、アプリアイコン

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- SwiftUIのButton内テキストが青くなる → `.buttonStyle(.plain)`
- MemoInputViewModelは@Stateで一度だけ生成 → 設定変更はonChangeで反映
- ModelContainerは共有必須
- SourceKitの偽陽性エラー多発（tagColor, UIPasteboard, UIResponder等）→ビルドは成功する
- NotificationCenter(.switchToTab, .memoSavedFlash)でクロスビュー通信
- タブインデックスはsortOrderベース（name sortではない）
- タグタブのoverlayは本文ZStackの.topTrailingに配置（仕切り線直下）
- TagDialViewは親子統合Canvas: ドラッグx座標で親/子判定（borderX = cx - parentInnerR）
