# 引き継ぎメモ

## 現在の状況
- **main** ブランチで作業中（feature/todo-listはmainにマージ済み）
- セッション051でToDo・ルーレット・入力欄のUI微調整を多数実施

### セッション051の主な変更点

#### ToDo画面
- ＋ボタン行の背景色を正しい階層色に修正
- メモタップを短文/長文問わず統一（展開→編集の2段階）
- メモ編集確定後に省略表示に戻す
- リスト初期表示時にツリー全展開（メモは省略のまま）
- 空リストの案内を＋ボタン横のガイドテキスト「最初の項目を追加しましょう」に変更
- 子項目ガイド「子項目を追加できます」表示（リスト内に子項目が1つもない時のみ）
- ＋ボタンとチェックボックスの中心位置を自動揃え（ルート・子両方）
- チェックボックスのアニメーション廃止（即チェック）
- プレースホルダーを「項目名を入力」に変更

#### ルーレット（メモ編集画面）
- 収納時: パネル色グレー統一・テキスト非表示・針非表示
- 展開時: カラフルパネル・赤い針（従来通り）
- タブ: 三角マーク削除・テキスト「タグ」のみ・幅38pt
- インナーシャドウを薄く
- タグなしパネルの色は0.92のまま

#### 入力欄
- テキスト表示上端を28→20ptに引き上げ
- プレースホルダー位置をカーソル位置に合わせて右にずらし
- 入力欄の高さをルーレット下端基準の固定値(328pt)に変更（機種非依存）
- 最大化ボタン: 23pt・右下寄せ（trailing/bottom各3pt）
- MainView最大化ボタンサイズ修正（16pt/27pt）

#### 爆速モード
- カルーセルのフリックページ送りを有効化（isScrollDisabled: false）

## 次のアクション（優先順）
1. **爆速モードの改修続き**（フリック対応の続き、UI改善等）
2. **並び替え問題の大改修**（ドラッグ並び替えが階層を超えて壊れる問題の根本対策）
3. **キーボード表示時のスクロール改善**
4. **ToDoリストごとにアイコンと色を選べる機能**
5. **フォルダタブでTODOタグ選択時にTodoItemsを一覧表示**
6. **タグ（バッグ）への紐付けUI**
7. カラーブラインドモード
8. アプリアイコン

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
- **LineNumberTextEditor.swift**: 行番号付きエディタ（initialCursorOffset対応）

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
