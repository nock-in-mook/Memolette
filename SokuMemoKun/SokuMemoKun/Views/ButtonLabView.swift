import SwiftUI

// 押せるボタン用のButtonStyle（長押し対応）
struct PressableButtonStyle: ButtonStyle {
    let shadowHeight: CGFloat
    let shadowColor: Color
    let radius: CGFloat

    init(shadowHeight: CGFloat = 5, shadowColor: Color = .black.opacity(0.25), radius: CGFloat = 1) {
        self.shadowHeight = shadowHeight
        self.shadowColor = shadowColor
        self.radius = radius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? shadowHeight : 0)
            .shadow(
                color: configuration.isPressed ? .clear : shadowColor,
                radius: radius,
                y: configuration.isPressed ? 0 : shadowHeight
            )
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

// タップでもカチッと動くボタン（沈む→待つ→戻る）
struct TapPressableView<Label: View>: View {
    let shadowHeight: CGFloat
    let shadowColor: Color
    let radius: CGFloat
    let action: () -> Void
    let label: () -> Label

    @State private var isPressed = false

    init(
        shadowHeight: CGFloat = 5,
        shadowColor: Color = .black.opacity(0.25),
        radius: CGFloat = 1,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.shadowHeight = shadowHeight
        self.shadowColor = shadowColor
        self.radius = radius
        self.action = action
        self.label = label
    }

    var body: some View {
        label()
            .offset(y: isPressed ? shadowHeight : 0)
            .shadow(
                color: isPressed ? .clear : shadowColor,
                radius: radius,
                y: isPressed ? 0 : shadowHeight
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            withAnimation(.easeIn(duration: 0.035)) { isPressed = true }
                        }
                    }
                    .onEnded { value in
                        withAnimation(.easeOut(duration: 0.05)) { isPressed = false }
                        // 指が大きくずれていなければタップとみなす
                        if abs(value.translation.width) < 50 && abs(value.translation.height) < 50 {
                            action()
                        }
                    }
            )
    }
}

// アニメ塗りボタンラボ: グラデーションに頼らないボタン表現を探る
struct ButtonLabView: View {
    // 3色セット（タイトル編集、本文編集、タグ編集）
    private let colorSets: [(name: String, base: Color, accent: Color)] = [
        ("オレンジ系", .orange, .orange),
        ("グレー系", Color(white: 0.85), Color(white: 0.65)),
        ("シアン系", .cyan, .cyan),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 説明
                VStack(spacing: 4) {
                    Text("アニメ塗りボタンラボ")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("グラデーションに頼らず、フラットUIに馴染むボタン表現を探る")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // 各パターン
                ForEach(0..<patterns.count, id: \.self) { i in
                    patternSection(index: i, pattern: patterns[i])
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("ボタンラボ")
        .navigationBarTitleDisplayMode(.inline)
    }

    // パターン表示（3色×1パターン）
    private func patternSection(index: Int, pattern: ButtonPattern) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("A\(index + 1): \(pattern.name)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)

            HStack(spacing: 16) {
                ForEach(0..<colorSets.count, id: \.self) { ci in
                    let cs = colorSets[ci]
                    TapPressableView(shadowHeight: 5, shadowColor: cs.accent.opacity(0.3)) {
                    } label: {
                        pattern.builder(cs.name == "グレー系" ? "本文編集" : (cs.name == "オレンジ系" ? "タイトル編集" : "タグ編集"),
                                        cs.base, cs.accent)
                    }
                }
            }
            .padding(.horizontal, 16)

            Divider().padding(.horizontal, 16).padding(.top, 4)
        }
    }

    // MARK: - パターン定義

    private struct ButtonPattern {
        let name: String
        let builder: (String, Color, Color) -> AnyView
    }

    private var patterns: [ButtonPattern] {
        [
            // A1: ベタ塗り（完全フラット）
            ButtonPattern(name: "ベタ塗り") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(ArcCapsule().fill(base.opacity(0.25)))
                )
            },

            // A2: ベタ塗り + 細い枠線
            ButtonPattern(name: "ベタ + 枠線") { text, base, accent in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(ArcCapsule().fill(base.opacity(0.2)))
                        .overlay(ArcCapsule().stroke(accent.opacity(0.4), lineWidth: 1))
                )
            },

            // A3: ベタ塗り + 下だけ濃い（2段セル塗り）
            ButtonPattern(name: "2段セル塗り") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(
                            ZStack {
                                ArcCapsule().fill(base.opacity(0.35))
                                // 上半分だけ明るく
                                ArcCapsule().fill(Color.white.opacity(0.4))
                                    .mask(
                                        VStack(spacing: 0) {
                                            Rectangle()
                                            Color.clear
                                        }
                                    )
                            }
                        )
                )
            },

            // A4: ベタ + 上部ハイライトライン（アニメ光沢）
            ButtonPattern(name: "上部ハイライト線") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(
                            ArcCapsule().fill(base.opacity(0.25))
                        )
                        .overlay(
                            ArcCapsule()
                                .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                                .mask(
                                    VStack(spacing: 0) {
                                        Rectangle().frame(height: 8)
                                        Spacer()
                                    }
                                )
                        )
                )
            },

            // A5: ベタ + 白インナーシャドウ
            ButtonPattern(name: "インナーシャドウ") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(ArcCapsule().fill(base.opacity(0.3)))
                        .overlay(
                            ArcCapsule()
                                .stroke(Color.white.opacity(0.9), lineWidth: 3)
                                .blur(radius: 2)
                                .mask(ArcCapsule())
                        )
                )
            },

            // A6: ベタ + 下エッジだけ暗い（影彫り風）
            ButtonPattern(name: "下エッジ影彫り") { text, base, accent in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(ArcCapsule().fill(base.opacity(0.22)))
                        .overlay(
                            ArcCapsule()
                                .stroke(accent.opacity(0.3), lineWidth: 1.5)
                                .mask(
                                    VStack(spacing: 0) {
                                        Color.clear
                                        Rectangle().frame(height: 6)
                                    }
                                )
                        )
                )
            },

            // A7: 不透明ベース + 色うすがけ（現行方式の改良）
            ButtonPattern(name: "不透明ベース+色") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(
                            ZStack {
                                ArcCapsule().fill(Color(white: 0.95))
                                ArcCapsule().fill(base.opacity(0.15))
                            }
                        )
                )
            },

            // A8: 不透明ベース + 色 + 上ハイライト
            ButtonPattern(name: "不透明+色+ハイライト") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(
                            ZStack {
                                ArcCapsule().fill(Color(white: 0.95))
                                ArcCapsule().fill(base.opacity(0.18))
                            }
                        )
                        .overlay(
                            ArcCapsule()
                                .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                                .mask(
                                    VStack(spacing: 0) {
                                        Rectangle().frame(height: 6)
                                        Spacer()
                                    }
                                )
                        )
                )
            },

            // A9: ベタ塗り + パキッと2色（上白/下色）
            ButtonPattern(name: "パキッと2色") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(
                            ZStack {
                                ArcCapsule().fill(base.opacity(0.3))
                                ArcCapsule().fill(Color.white.opacity(0.5))
                                    .mask(
                                        VStack(spacing: 0) {
                                            Rectangle()
                                            Color.clear
                                        }
                                    )
                            }
                        )
                        .overlay(ArcCapsule().stroke(base.opacity(0.2), lineWidth: 0.5))
                )
            },

            // A10: マット塗り（ベタ + 微量ノイズ風テクスチャ）
            ButtonPattern(name: "マット塗り") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(
                            ZStack {
                                ArcCapsule().fill(base.opacity(0.2))
                                ArcCapsule().fill(Color(white: 0.5).opacity(0.03))
                            }
                        )
                        .overlay(ArcCapsule().stroke(Color(white: 0.75), lineWidth: 0.5))
                )
            },

            // A11: ぷっくり（中央明るめ、端暗め、境界パキッと）
            ButtonPattern(name: "ぷっくりセル塗り") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(
                            ZStack {
                                ArcCapsule().fill(base.opacity(0.3))
                                // 上1/3を白くする（パキッとハイライト）
                                ArcCapsule().fill(Color.white.opacity(0.45))
                                    .mask(
                                        VStack(spacing: 0) {
                                            Rectangle().frame(height: 10)
                                            Color.clear
                                        }
                                    )
                            }
                        )
                        .overlay(ArcCapsule().stroke(base.opacity(0.15), lineWidth: 0.5))
                )
            },

            // A12: エアブラシ（放射状ハイライト）
            ButtonPattern(name: "エアブラシ") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(
                            ZStack {
                                ArcCapsule().fill(base.opacity(0.25))
                                RadialGradient(
                                    colors: [Color.white.opacity(0.5), .clear],
                                    center: UnitPoint(x: 0.35, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 40
                                )
                                .clipShape(ArcCapsule())
                            }
                        )
                )
            },

            // A13: 影だけ（背景なし、影で浮かせる）
            ButtonPattern(name: "影のみ（背景なし）") { text, _, accent in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(ArcCapsule().fill(Color(uiColor: .systemBackground)))
                        .shadow(color: accent.opacity(0.3), radius: 3, y: 2)
                )
            },

            // A14: くっきり枠 + ベタ（コミック風）
            ButtonPattern(name: "コミック枠") { text, base, accent in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(ArcCapsule().fill(base.opacity(0.15)))
                        .overlay(ArcCapsule().stroke(accent.opacity(0.5), lineWidth: 2))
                )
            },

            // A15: すりガラス風
            ButtonPattern(name: "すりガラス風") { text, base, _ in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(
                            ZStack {
                                ArcCapsule().fill(.ultraThinMaterial)
                                ArcCapsule().fill(base.opacity(0.1))
                            }
                        )
                )
            },

            // A16: ベタ + 白インナー + 枠（合わせ技）
            ButtonPattern(name: "ベタ+インナー+枠") { text, base, accent in
                AnyView(
                    Text(text)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
                        .background(ArcCapsule().fill(base.opacity(0.25)))
                        .overlay(
                            ArcCapsule()
                                .stroke(Color.white.opacity(0.85), lineWidth: 2.5)
                                .blur(radius: 1.5)
                                .mask(ArcCapsule())
                        )
                        .overlay(ArcCapsule().stroke(accent.opacity(0.25), lineWidth: 0.5))
                )
            },
        ]
    }
}
