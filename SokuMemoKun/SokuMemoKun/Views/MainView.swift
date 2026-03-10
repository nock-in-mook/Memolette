import SwiftUI
import SwiftData

struct MainView: View {
    @State private var viewModel = MemoInputViewModel()
    @State private var isKeyboardVisible = false
    @State private var showSettings = false
    @State private var focusInput = false
    @AppStorage("defaultMarkdown") private var defaultMarkdown = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 入力エリア（大枠で囲まれた入力欄+ルーレット）
                MemoInputView(viewModel: viewModel, focusInput: $focusInput)

                // 台形タブ付きメモ一覧
                TabbedMemoListView(onAddMemo: {
                    focusInput = true
                })
            }
            .navigationTitle("即メモ君")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onChange(of: defaultMarkdown) { _, newValue in
                // 入力欄が空のときだけデフォルト設定を即反映
                if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    viewModel.isMarkdown = newValue
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isKeyboardVisible {
                    Button {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Circle().fill(.blue))
                            .shadow(radius: 3)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isKeyboardVisible)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
        }
    }
}
