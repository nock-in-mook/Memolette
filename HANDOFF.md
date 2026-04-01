# 引き継ぎメモ

## 現在の状況
- **remove-tag-suggest** ブランチで作業中（mainにはまだマージしていない）
- セッション055でフォルダのグリッド表示を大幅改善

### セッション055の主な変更点

#### グリッドカード高さの動的計算化
- ハードコード高さ(36/48/104/160pt)を廃止
- `availableHeight`（GeometryReader）から設定行数+覗き分(0.2行)で自動算出
- `topPadding`/`bottomPadding` は不要（geo.size.heightがそのまま可視領域）
- デバッグで `availableHeight=322pt` を実測して計算を検証

#### グリッドサイズ変更
- 3×8 → **3×6** に縮小（カードが大きくなり視認性UP）
- 2×6 → **2×5** に縮小（同上）
- 3×6/2×5の本文フォントをひとまわり拡大（11→13, 13→14）

#### タイトルなしメモの表示改善
- 「(タイトルなし)」を薄グレー・通常ウェイトで表示
- 本文はタイトルの有無に関わらず常に表示（統一感）

#### よく見るフォルダの改善
- FrequentGridOption を 2×5 / 2×3 / 全文 / タイトルのみ の4択に整理
- 列ラベル+padding分のオフセット(36pt)をavailableHeightから減算して高さ調整
- `itemsPerColumn` による件数制限を撤廃、スクロールで全件表示に変更

## 次のアクション（優先順）
1. **remove-tag-suggest ブランチをmainにマージ**
2. **タグ履歴のデバッグ**: 履歴が正しく記録・表示されるか実機確認
3. **ダミーデータ削除**: SokuMemoKunApp.swift の insertDummyTagHistory をリリース前に削除
4. **実機ビルドの問題解決**（CodeSign / Google Driveのxattr問題）
5. **フォルダ上で各メモカードに子タグバッジを表示できるか検討**
6. **並び替え問題の大改修**（ドラッグ並び替えが階層を超えて壊れる問題の根本対策）
7. **ToDoリストごとにアイコンと色を選べる機能**
8. **フォルダタブでTODOタグ選択時にTodoItemsを一覧表示**
9. **タグ（バッグ）への紐付けUI**
10. カラーブラインドモード
11. アプリアイコン

## 主要ファイル（ToDo関連）
- **TodoItem.swift**: ToDoデータモデル（listID, parentID, isDone, memo, tags等）
- **TodoList.swift**: リストモデル（id, title, isPinned, isLocked, manualSortOrder）
- **TodoListView.swift**: リスト編集画面（Listベース、連続入力、選択削除、スワイプ削除、ドラッグ並び替え、階層色帯、インラインメモ、完了バー）
- **TodoListsView.swift**: リスト一覧画面（2列Pinterest風、プレビュー付きカード、長押しメニュー）

## 主要ファイル（爆速モード関連）
- **QuickSortCellView.swift**: セル（カード+ルーレットのみ、コントローラーは外）— キーボード高さ監視・タグ履歴・バッジ表示もここ
- **QuickSortView.swift**: メイン画面（フェーズ管理・カルーセル・コントローラーエリア・操作パネル・各種ダイアログ）
- **QuickSortFilterView.swift**: 事前フィルタ選択シート
- **QuickSortResultView.swift**: 結果表示画面（削除確認リンク付き）
- **CarouselView.swift**: UICollectionViewベースのカルーセル
- **TagDialView.swift**: ルーレット
- **MemoInputView.swift**: メモ入力画面（トレー方式ルーレット・タグ履歴ボタン）
- **LineNumberTextEditor.swift**: 行番号付きエディタ（isEditable/onTapWhileReadOnly対応）

## 主要ファイル（タグ履歴関連）
- **TagHistory.swift**: タグ使用履歴モデル（record/recentHistory）
- **MainView.swift**: tagHistoryListView（フォルダタブゾーンにoverlay表示）
- **MemoInputView.swift**: 履歴ボタン（トレー外overlay）、履歴記録（ルーレット閉じ時）
- **QuickSortCellView.swift**: 履歴ボタン（トレーoverlay）、履歴リスト（カード中央overlay）、履歴記録（ページ送り時・タグ編集閉じ時）

## 環境
- **Mac②（新）**: MacBook Air — Xcode 26.3, シミュレータ iPhone 17 Pro (iOS 26.3)
- 実機: 15promax (26.3.1) — デバイスID: 00008130-0006252E2E40001C
- **実機ビルド**: Wi-Fi経由で接続可能（同じWiFi上なら）、`-allowProvisioningUpdates` フラグ必要
- **ビルド**: Google Drive上のファイル変更検知問題あり。ローカルコピーしてビルドが確実:
  ```
  rm -rf /tmp/SokuMemoKun-src /tmp/SokuMemoKun-DD && cp -R "...SokuMemoKun" /tmp/SokuMemoKun-src && cd /tmp/SokuMemoKun-src && xattr -cr . && xcodebuild ...
  ```

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
- **連続入力のガクつき**: Listの下端スクロールバッファ不足が原因。bottomSpacer(300pt)で解決済み
