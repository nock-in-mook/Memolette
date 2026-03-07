# 引き継ぎメモ

## 現在の状況
- Phase 1 のコード実装完了（全Swiftファイル + Xcodeプロジェクト）
- コマンドラインビルド(xcodebuild)は成功済み
- シミュレータはXcode 15.1がmacOS 26と非互換でクラッシュ → Xcodeアップデート待ち

## 環境
- Mac: MacBook Air M2, macOS 26.3.1
- Xcode: 15.1 → 16.x にアップデート中
- xcode-select は /Applications/Xcode.app/Contents/Developer に設定済み

## プロジェクト概要
- 「即メモ君」= 起動→即書ける→後から分類 のiPhoneメモアプリ
- SwiftUI + SwiftData、iOS 17+、軽量MVVM

## ファイル構成（14ファイル）
```
SokuMemoKun/
├── SokuMemoKun.xcodeproj/project.pbxproj
└── SokuMemoKun/
    ├── SokuMemoKunApp.swift
    ├── Assets.xcassets/ (3ファイル)
    ├── Models/ (Memo.swift, Tag.swift)
    ├── Views/ (MainView, MemoInputView, MemoListView, MemoRowView, TagFilterPickerView, TagTitleSheetView)
    └── ViewModels/ (MemoInputViewModel.swift)
```

## 次のアクション
1. Xcodeアップデート完了後、再度ビルド＆シミュレータ起動
2. シミュレータで基本動作確認（メモ保存・表示・コピー）
3. Phase 2（タグフィルター動作確認 + iCloud同期設定）に進む

## 注意点
- pbxproj は手書きだが xcodebuild ビルドは通った
- DEVELOPMENT_TEAM は空欄 → Xcode上で自分のApple IDチームを設定する必要あり
