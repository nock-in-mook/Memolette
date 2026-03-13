# 引き継ぎメモ

## 現在の状況
- Phase 1 実装完了、UI改善進行中
- 設定画面（⚙️）実装済み: タグ編集、マークダウン設定、バックアップ(準備中)、最大文字数(準備中)
- タグ編集機能: 一覧表示(背景色付き)、タップで編集、新規追加、選択削除
- カラーパレット: 28色(7×4グリッド)
- マークダウン編集機能: 全画面エディタ、ON/OFFトグル、上下分割/タブ切替プレビュー
- デフォルトマークダウンON設定: 設定変更→即反映、保存後リセット
- マークダウンON＋空欄タップで全画面編集を自動起動（ガイドテキスト付き）
- タブごとのグリッド表示切替（3×8/2×6/2×2/1×2/1全文の5パターン）
- カード高さを画面サイズから動的計算（6行/8行でぴったり収まる）
- メモ追加ボタン（入力欄フォーカス）と選択削除モード
- マークダウンメモにM↓マーク、タップでプレビュー編集画面
- プレビュー表示形式のカスタムアイコン（上下分割=A/B、タブ=A|B）
- メモカードにドロップシャドウ、背景を不透明白に統一
- タブ切替アニメーション削除（瞬時切替）
- 親タグ・子タグの階層構造実装済み（parentTagID）
- タグダイアル（ルーレット）で親タグ＋子タグ選択可能
- 子タグダイアルは常時表示（「子」タブ突起 or 展開状態）
- ルーレット↔タブ連動: ルーレット操作でタブが自動切替
- 新規タグ追加→ルーレット同期＋対応タブへ自動切替
- 保存ボタン→対応タブへ自動切替
- フォルダ左上にメモ枚数表示（背景に馴染む色でひっそり表示）
- テストデータ生成関数を強化（sampleDataV4: 120枚、テキスト長/タグ/タイトル/MDランダム）
- 子タグダイアルのドラッグ引出し＋回転をリアルタイム化（externalDragY）
- 閉じるタブの矢印を右向き（›）に変更

## 主要ファイル
- TabbedMemoListView.swift: グリッド切替(5段階)、メモ追加/選択削除、MemoCardView（M↓マーク対応）、tabItemsで親タグのみフィルタ、メモ枚数表示（darkenedColor）
- FullEditorView.swift: LayoutIcon（カスタムアイコン）追加
- SettingsView.swift: プレビュー表示形式ラベル＋カスタムアイコン
- MemoInputView.swift: タグダイアル（親+子）、保存/タグ変更時のタブ同期（NotificationCenter）、子ダイアル外部ドラッグ（childExternalDragY）
- MainView.swift: selectedTabIndex管理、switchToTab通知受信
- TagDialView.swift: Canvas描画ルーレット、syncRotationToSelection、isInternalChange guard、externalDragY対応
- NewTagSheetView.swift: onTagCreatedコールバック追加
- Tag.swift: gridSizeプロパティ、parentTagID追加
- SokuMemoKunApp.swift: テストデータ生成関数（createTags, generateVariedMemos, SeededRNG, sampleDataV4）

## 環境
- Mac: MacBook Air M2, macOS
- Xcode: 26.3
- シミュレータ: iPhone 15 Pro Max (95C8A8C5-0972-4BB0-B793-5219096697DF) ← iOS 17.2
- 実機: 15promax (26.3.1) (00008130-0006252E2E40001C) ← USB接続確認済み
- ビルド後は毎回「Fit Screen」でウィンドウ縮小する

## 次のアクション
1. **実機ビルド・テスト**（iPhone 15 Pro Max実機、署名設定が必要）
2. 子タグダイアルのドラッグ引出し→回転が実機で動くか確認（シミュレータでは回転しなかった）
3. 設定で「子タグルーレットを常に表示」のオンオフ切替
4. 書きかけのメモの扱い（自動保存？下書き？破棄確認？）
5. マークダウン編集画面のテコ入れ（アイコンの説明表示、保存ボタンの配置・動作）
6. 子タグのバッグ表示（タブに子タグも並べる or 親バッグ内で切替）
7. バッグからの「新規追加」→入力欄フォーカス＋そのタグを自動選択済み

## 注意点
- DerivedData キャッシュ → `rm -rf ~/Library/Developer/Xcode/DerivedData/SokuMemoKun-*`
- SwiftUIのButton内テキストが青くなる → `.buttonStyle(.plain)`
- MemoInputViewModelは@Stateで一度だけ生成 → 設定変更はonChangeで反映
- ModelContainerは共有必須
- サンプルデータはUserDefaultsの"sampleDataV4"フラグで制御（再投入はアプリ再インストールで）
- NotificationCenter(.switchToTab)でルーレット↔タブ間のクロスビュー通信
- TagDialViewのsyncRotationToSelectionはisInternalChangeフラグでドラッグ中の干渉を防止
- iOS 17.2では Color.mix(with:by:) が使えない → UIColor + getHue で手動計算
