# 引き継ぎメモ

## 現在の状況
- **remove-tag-suggest** ブランチで作業中（mainにはまだマージしていない）
- セッション054でTodo連続入力・選択削除・UI改善を実施

### セッション054の主な変更点

#### Todo連続入力機能
- Enter確定で同じ階層に次の行を自動生成して即編集開始
- 空のままEnterで連続入力を抜ける（アイテム削除）
- isChainEditingフラグでonSubmit/onChangeの競合を防止
- commitEdit遅延（20ms）でフォーカス競合を回避
- Listの末尾に透明300ptスペーサー行（bottomSpacer）でスクロールバッファ確保
  → キーボード閉じ→開き時のリスト引き戻し（ガクつき）を解消

#### 編集中のUI改善
- +ボタンを編集中・メモ編集中も表示（タップで現在の編集を確定→新アイテム作成）
- 展開ボタン・メモボタンを編集中もタップ可能（編集確定→機能起動）
- メモ欄タップで編集確定+メモ展開が1タップで
- 罫線・L字線は編集中・メモ編集中は非表示（編集抜けたら復活）
- 「完了」バー: アイテム編集中・メモ編集中ともにキーボード直上に表示
- .scrollDismissesKeyboard(.never)でスクロール時のキーボード閉じを防止

#### 選択削除機能
- 下部「削除」ボタン→ダイアログで「選択して削除」/「全件削除」を選択
- 選択モード: チェックボックスが赤丸に変わり、複数選択→一括削除
- 親チェックで子孫も自動チェック、親解除で元の個別選択状態を復元（スナップショット方式）
- 選択モード中: メモボタン・+ボタン非表示、スワイプ削除無効、タイトルタップで選択トグル
- 展開ボタンは選択モード中も使える（子項目確認用）

#### その他
- 「タスク」→「項目」に文言統一（ダイアログ・コメント全般）
- ガイドテキスト（「最初の項目を追加しましょう」）タップでも項目追加起動
- LineNumberTextEditorのinputAccessoryView(UIToolbar)は削除済み（各画面の既存確定ボタンで対応）

## 次のアクション（優先順）
1. **remove-tag-suggest ブランチをmainにマージ**
2. **タグ履歴のデバッグ**: 履歴が正しく記録・表示されるか実機確認
3. **ダミーデータ削除**: SokuMemoKunApp.swift の insertDummyTagHistory をリリース前に削除
4. **実機ビルドの問題解決**（CodeSign / Google Driveのxattr問題）
5. **並び替え問題の大改修**（ドラッグ並び替えが階層を超えて壊れる問題の根本対策）
6. **ToDoリストごとにアイコンと色を選べる機能**
7. **フォルダタブでTODOタグ選択時にTodoItemsを一覧表示**
8. **タグ（バッグ）への紐付けUI**
9. カラーブラインドモード
10. アプリアイコン

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
