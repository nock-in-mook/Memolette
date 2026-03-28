# 引き継ぎメモ

## 現在の状況
- **main** ブランチで作業中
- セッション052で爆速モードの大改修を実施

### セッション052の主な変更点

#### 爆速モード — 閲覧/編集ビュー統一
- 閲覧モード（TappableReadOnlyText+ScrollView）と編集モード（LineNumberTextEditor）のビュー切替を廃止
- 常にLineNumberTextEditorを使用し、`isEditable`で閲覧/編集を切替
- **スクロール位置が閲覧→編集で保持される**ようになった
- GutteredTextViewに非編集時タップハンドラ追加（UITextViewから直接文字オフセット取得→カーソル配置）

#### 爆速モード — カードUI改善
- カード幅+40pt（左右20ptずつ拡大）
- 本文編集ボタン押下時の自動カード拡大を廃止（カーソルが末尾に出るだけ）
- テキスト上端位置統一（GutteredTextView top: 20→16pt、TappableReadOnlyTextと一致）

#### 爆速モード — キーボード対応
- カードサイズはキーボード表示で変えない方式に変更
- GutteredTextView自身がキーボードとの重なりを計算し、contentInset.bottomで自動調整
- カーソル位置がキーボード下に隠れない

#### 最大化ボタン統一
- MemoInputView・QuickSortCellView共通: 21x21、font 10pt、trailing 3pt/bottom 3pt
- アイコンを`arrow.up.backward.and.arrow.down.forward`系に統一

## 次のアクション（優先順）
1. **実機ビルドの問題解決**（CodeSign / Google Driveのxattr問題）
2. **爆速モードの改修続き**（フリック対応の続き、UI改善等）
3. **並び替え問題の大改修**（ドラッグ並び替えが階層を超えて壊れる問題の根本対策）
4. **キーボード表示時のスクロール改善**
5. **ToDoリストごとにアイコンと色を選べる機能**
6. **フォルダタブでTODOタグ選択時にTodoItemsを一覧表示**
7. **タグ（バッグ）への紐付けUI**
8. カラーブラインドモード
9. アプリアイコン

## 主要ファイル（ToDo関連）
- **TodoItem.swift**: ToDoデータモデル（listID, parentID, isDone, memo, tags等）
- **TodoList.swift**: リストモデル（id, title, isPinned, isLocked, manualSortOrder）
- **TodoListView.swift**: リスト編集画面（Listベース、スワイプ削除、ドラッグ並び替え、階層色帯、インラインメモ）
- **TodoListsView.swift**: リスト一覧画面（2列Pinterest風、プレビュー付きカード、長押しメニュー）

## 主要ファイル（爆速モード関連）
- **QuickSortCellView.swift**: セル（カード+ルーレットのみ、コントローラーは外）— キーボード高さ監視もここ
- **QuickSortView.swift**: メイン画面（フェーズ管理・カルーセル・コントローラーエリア・操作パネル・各種ダイアログ）
- **QuickSortFilterView.swift**: 事前フィルタ選択シート
- **CarouselView.swift**: UICollectionViewベースのカルーセル
- **TagDialView.swift**: ルーレット
- **MemoInputView.swift**: メモ入力画面（トレー方式ルーレット）
- **LineNumberTextEditor.swift**: 行番号付きエディタ（isEditable/onTapWhileReadOnly対応）

## 環境
- **Mac②（新）**: MacBook Air — Xcode 26.3, シミュレータ iPhone 17 Pro (iOS 26.3)
- 実機: 15promax (26.3.1) — デバイスID: 00008130-0006252E2E40001C
- **実機ビルド**: 証明書は別Macから.p12エクスポートでインポート済み、`-allowProvisioningUpdates` フラグ必要

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- **ビルドキャッシュが頑固**: DerivedData削除+アンインストール+clean+フルリビルドが確実
- SourceKitの偽陽性エラー多発→ビルドは成功する
- **バンドルID**: com.sokumemokun.app
- **ダイアログルール**: 全てカスタムリッチダイアログ（標準alertは使わない）
- **SwiftUI再帰ViewBuilder制約**: ツリー表示はフラット化して対応
- **キーボードとダイアログ**: ダイアログはNavigationStack外のZStackに配置（押し潰れ防止）
- **LazyVStack + DragGesture は使わない**: ScrollViewのスクロールが死ぬ。Listを使うこと
- **チェックボックス**: Image+onTapGestureで28x28に限定（Buttonだとタップ判定が広がる）
- **Google Drive上のxattr問題**: ビルド前に`xattr -cr .`が必要（resource fork等のデトリタス）
