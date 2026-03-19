import SwiftUI

// ベース色からRGB成分を取得するヘルパー
private extension Color {
    var components: (r: CGFloat, g: CGFloat, b: CGFloat) {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    var hsb: (h: CGFloat, s: CGFloat, b: CGFloat) {
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h, s, b)
    }
}

// 配色パターン定義
struct ColorPattern: Identifiable {
    let id: String
    let name: String
    let description: String
    // ベース色 → (左列色, 右列色) を返す
    let generate: (Color) -> (left: Color, right: Color)
}

// 配色パターン一覧
private let colorPatterns: [ColorPattern] = [
    ColorPattern(
        id: "same_light",
        name: "同色グラデ",
        description: "同じ色の濃淡で左右を分ける",
        generate: { base in
            let c = base.components
            let left = Color(red: c.r * 0.92, green: c.g * 0.92, blue: c.b * 0.92).opacity(0.3)
            let right = Color(red: c.r * 0.96, green: c.g * 0.96, blue: c.b * 0.96).opacity(0.15)
            return (Color(left), Color(right))
        }
    ),
    ColorPattern(
        id: "warm_cool",
        name: "暖色↔寒色",
        description: "左を暖かく、右をクールに",
        generate: { base in
            let c = base.components
            let left = Color(red: min(c.r + 0.08, 1), green: c.g * 0.95, blue: c.b * 0.85).opacity(0.2)
            let right = Color(red: c.r * 0.85, green: c.g * 0.95, blue: min(c.b + 0.08, 1)).opacity(0.2)
            return (Color(left), Color(right))
        }
    ),
    ColorPattern(
        id: "hue_shift_30",
        name: "色相+30°",
        description: "左はそのまま、右を色相30°ずらす",
        generate: { base in
            let hsb = base.hsb
            let left = Color(hue: hsb.h, saturation: hsb.s * 0.4, brightness: hsb.b).opacity(0.2)
            let rightHue = (hsb.h + 0.083) // 30°/360°
            let right = Color(hue: rightHue.truncatingRemainder(dividingBy: 1.0),
                              saturation: hsb.s * 0.4, brightness: hsb.b).opacity(0.2)
            return (Color(left), Color(right))
        }
    ),
    ColorPattern(
        id: "hue_shift_60",
        name: "色相+60°",
        description: "左はそのまま、右を色相60°ずらす",
        generate: { base in
            let hsb = base.hsb
            let left = Color(hue: hsb.h, saturation: hsb.s * 0.4, brightness: hsb.b).opacity(0.2)
            let rightHue = (hsb.h + 0.167) // 60°/360°
            let right = Color(hue: rightHue.truncatingRemainder(dividingBy: 1.0),
                              saturation: hsb.s * 0.4, brightness: hsb.b).opacity(0.2)
            return (Color(left), Color(right))
        }
    ),
    ColorPattern(
        id: "complement",
        name: "補色",
        description: "左はベース、右は補色（180°反転）",
        generate: { base in
            let hsb = base.hsb
            let left = Color(hue: hsb.h, saturation: hsb.s * 0.35, brightness: hsb.b).opacity(0.2)
            let rightHue = (hsb.h + 0.5).truncatingRemainder(dividingBy: 1.0)
            let right = Color(hue: rightHue, saturation: hsb.s * 0.3, brightness: hsb.b).opacity(0.15)
            return (Color(left), Color(right))
        }
    ),
    ColorPattern(
        id: "saturate_desat",
        name: "鮮やか↔淡い",
        description: "左を少し鮮やかに、右を彩度落とす",
        generate: { base in
            let hsb = base.hsb
            let left = Color(hue: hsb.h, saturation: min(hsb.s * 0.6, 1), brightness: hsb.b).opacity(0.25)
            let right = Color(hue: hsb.h, saturation: hsb.s * 0.15, brightness: hsb.b).opacity(0.15)
            return (Color(left), Color(right))
        }
    ),
    ColorPattern(
        id: "triadic",
        name: "トライアド",
        description: "左はベース、右は120°ずらし",
        generate: { base in
            let hsb = base.hsb
            let left = Color(hue: hsb.h, saturation: hsb.s * 0.4, brightness: hsb.b).opacity(0.2)
            let rightHue = (hsb.h + 0.333).truncatingRemainder(dividingBy: 1.0)
            let right = Color(hue: rightHue, saturation: hsb.s * 0.35, brightness: hsb.b).opacity(0.18)
            return (Color(left), Color(right))
        }
    ),
    ColorPattern(
        id: "split_complement",
        name: "スプリット補色",
        description: "左はベース、右は150°ずらし",
        generate: { base in
            let hsb = base.hsb
            let left = Color(hue: hsb.h, saturation: hsb.s * 0.4, brightness: hsb.b).opacity(0.2)
            let rightHue = (hsb.h + 0.417).truncatingRemainder(dividingBy: 1.0)
            let right = Color(hue: rightHue, saturation: hsb.s * 0.35, brightness: hsb.b).opacity(0.18)
            return (Color(left), Color(right))
        }
    ),
    ColorPattern(
        id: "analogous",
        name: "類似色",
        description: "左を-15°、右を+15°",
        generate: { base in
            let hsb = base.hsb
            let leftHue = (hsb.h - 0.042 + 1.0).truncatingRemainder(dividingBy: 1.0)
            let rightHue = (hsb.h + 0.042).truncatingRemainder(dividingBy: 1.0)
            let left = Color(hue: leftHue, saturation: hsb.s * 0.4, brightness: hsb.b).opacity(0.2)
            let right = Color(hue: rightHue, saturation: hsb.s * 0.4, brightness: hsb.b).opacity(0.2)
            return (Color(left), Color(right))
        }
    ),
    ColorPattern(
        id: "mono_tint",
        name: "モノトーン",
        description: "白寄りの同色系、明度差のみ",
        generate: { base in
            let hsb = base.hsb
            let left = Color(hue: hsb.h, saturation: hsb.s * 0.2, brightness: min(hsb.b + 0.05, 1)).opacity(0.2)
            let right = Color(hue: hsb.h, saturation: hsb.s * 0.1, brightness: min(hsb.b + 0.1, 1)).opacity(0.12)
            return (Color(left), Color(right))
        }
    ),
]

// サンプルに使うベース色（代表的なタブカラーから抜粋）
private let sampleBaseColors: [(name: String, color: Color)] = [
    ("水色", Color(red: 0.55, green: 0.80, blue: 0.95)),
    ("オレンジ", Color(red: 0.95, green: 0.70, blue: 0.55)),
    ("緑", Color(red: 0.70, green: 0.90, blue: 0.70)),
    ("紫", Color(red: 0.90, green: 0.70, blue: 0.90)),
    ("赤", Color(red: 0.95, green: 0.60, blue: 0.60)),
    ("ティール", Color(red: 0.35, green: 0.65, blue: 0.80)),
    ("ゴールド", Color(red: 0.90, green: 0.80, blue: 0.50)),
    ("ローズ", Color(red: 0.85, green: 0.45, blue: 0.55)),
]

// MARK: - カラーラボ メイン画面

struct ColorLabView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("「よく見る」タブの左右列配色パターン")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                ForEach(colorPatterns) { pattern in
                    VStack(alignment: .leading, spacing: 8) {
                        // パターン名
                        HStack {
                            Text(pattern.name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Spacer()
                            Text(pattern.description)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)

                        // 各ベース色でのサンプル（横スクロール）
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(sampleBaseColors, id: \.name) { sample in
                                    colorSampleCard(
                                        baseName: sample.name,
                                        baseColor: sample.color,
                                        pattern: pattern
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("カラーラボ")
        .navigationBarTitleDisplayMode(.inline)
    }

    // 1つのサンプルカード
    private func colorSampleCard(baseName: String, baseColor: Color, pattern: ColorPattern) -> some View {
        let colors = pattern.generate(baseColor)
        return VStack(spacing: 4) {
            // タブ（ベース色）
            Text(baseName)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(baseColor)
                )

            // 左右分割プレビュー
            HStack(spacing: 2) {
                // 左列
                VStack(spacing: 3) {
                    Text("よく見る")
                        .font(.system(size: 7, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(uiColor: .systemBackground))
                        .frame(height: 18)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(uiColor: .systemBackground))
                        .frame(height: 18)
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(colors.left)
                )

                // 右列
                VStack(spacing: 3) {
                    Text("最近見た")
                        .font(.system(size: 7, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(uiColor: .systemBackground))
                        .frame(height: 18)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(uiColor: .systemBackground))
                        .frame(height: 18)
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(colors.right)
                )
            }
            .frame(width: 120, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(baseColor.opacity(0.15))
            )
        }
    }
}
