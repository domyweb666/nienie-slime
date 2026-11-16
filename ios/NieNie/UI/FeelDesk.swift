import SwiftUI

/// One knob on the 手感調節台: a plain-language name for one feel parameter.
struct FeelKnob: Identifiable {
    let id: String   // the parameter's name in the web prototype (same keys in the copied text and in "nienie.feel")
    let key: WritableKeyPath<FeelParams, Double>
    let name: String
    let hint: String
    let range: ClosedRange<Double>
    let step: Double
    let section: String

    /// Same nine as the web's v2.39 調節台 (FEEL in prototype/web/index.html), same ranges as the hidden panel.
    static let all: [FeelKnob] = [
        FeelKnob(id: "alpha", key: \.alpha, name: "軟硬", hint: "越右越硬，放手回得越快", range: 0.05...0.8, step: 0.01, section: "捏下去"),
        FeelKnob(id: "pressSink", key: \.pressSink, name: "按下去沉多久", hint: "手指按著不動，凹下去要幾秒", range: 0.05...2, step: 0.05, section: "捏下去"),
        FeelKnob(id: "lag", key: \.lag, name: "慢一拍", hint: "被抓的那塊跟手指差多少；越右越黏、越拖", range: 0...0.3, step: 0.01, section: "捏下去"),
        FeelKnob(id: "yield", key: \.yield, name: "多用力才留形", hint: "越左輕輕捏就留下形狀，越右要捏很大力", range: 0.02...1.5, step: 0.01, section: "捏完"),
        FeelKnob(id: "creep", key: \.creep, name: "留形快慢", hint: "捏著的時候形狀被記住的速度；0 完全不留形", range: 0...6, step: 0.1, section: "捏完"),
        FeelKnob(id: "recover", key: \.recover, name: "回原形快慢", hint: "放著不動時慢慢變回原本的樣子；越左越久", range: 0...1.5, step: 0.01, section: "捏完"),
        FeelKnob(id: "inertiaZ", key: \.inertiaZ, name: "晃幾下", hint: "放手後晃動停得多快；越左晃越多下", range: 0.05...1, step: 0.01, section: "放手"),
        FeelKnob(id: "inertiaHz", key: \.inertiaHz, name: "晃多快", hint: "放手後每秒晃幾下", range: 0...6, step: 0.1, section: "放手"),
        FeelKnob(id: "slide", key: \.slide, name: "拉多長整隻跟著走", hint: "拉長到這個長度（幾個半徑），再拉整隻就被拖著走", range: 0...3, step: 0.1, section: "拉"),
    ]
    static let sections = ["捏下去", "捏完", "放手", "拉"]

    static func fmt(_ v: Double) -> String {
        let r = (v * 1000).rounded() / 1000
        return r == r.rounded() ? String(Int(r)) : String(r)
    }
}

/// v2.39 手感調節台 on the phone (多米 11-16: 要有個操控數值的地方，我自己調試看怎樣手感最好).
/// Opens from the 調 button at the bottom right, covers the sky, the slime stays squishable below it.
struct FeelDesk: View {
    @EnvironmentObject var controller: SlimeController
    @Binding var isPresented: Bool
    @State private var note = "拉一條，馬上捏捏看。"
    @State private var showText = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("手感調節台").font(.rounded(17, .heavy))
                Text("\(controller.slime.name)・\(controller.material.name)").font(.rounded(13)).foregroundStyle(Palette.inkSoft)
                Spacer()
                Button("收起") { isPresented = false }
                    .font(.rounded(14))
                    .foregroundStyle(Palette.inkSoft)
                    .frame(minWidth: 44, minHeight: 44)
            }

            HStack(spacing: 6) {
                Text("從哪個材質開始").font(.rounded(12)).foregroundStyle(Palette.inkSoft)
                ForEach([SlimeMaterial.clay, .mochi, .jelly]) { m in
                    chip(m.name, on: controller.material == m) {
                        controller.feelStartFrom(m)
                        note = "換成\(m.name)的預設值。"
                    }
                }
                Spacer(minLength: 0)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(FeelKnob.sections, id: \.self) { section in
                        Text(section)
                            .font(.rounded(12, .heavy))
                            .foregroundStyle(Palette.inkSoft)
                            .padding(.top, 2)
                        ForEach(FeelKnob.all.filter { $0.section == section }) { k in
                            knobRow(k)
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            .frame(maxHeight: 300)

            HStack(spacing: 6) {
                chip("存成 A") { controller.feelStore("A"); note = "現在的手感存成 A。" }
                chip("存成 B") { controller.feelStore("B"); note = "現在的手感存成 B。" }
                chip("換到 A", enabled: controller.feelA != nil) {
                    controller.feelGo("A"); note = "換到 A（\(controller.material.name)起點）。捏一分鐘再換另一個。"
                }
                chip("換到 B", enabled: controller.feelB != nil) {
                    controller.feelGo("B"); note = "換到 B（\(controller.material.name)起點）。捏一分鐘再換另一個。"
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Button {
                    UIPasteboard.general.string = controller.feelText
                    showText = true
                    note = "複製好了，貼給 Agent 就行。下面框裡也有同一段字。"
                } label: {
                    Text("複製數值給 Agent").frame(maxWidth: .infinity).padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(Capsule().fill(Palette.ink))
                }
                Button {
                    controller.feelDefaults()
                    showText = false
                    note = "回到預設（\(controller.material.name)），A、B 也清掉了。"
                } label: {
                    Text("回到預設").frame(maxWidth: .infinity).padding(.vertical, 10)
                        .foregroundStyle(Palette.ink)
                        .background(Capsule().fill(.white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)))
                }
            }
            .font(.rounded(14))
            .buttonStyle(.plain)

            Text(note).font(.rounded(12, .medium)).foregroundStyle(Palette.inkSoft)

            if showText {
                Text(controller.feelText)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.8), lineWidth: 1.5))
            }
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 12)
        .background(RoundedRectangle(cornerRadius: 22).fill(.white)
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.ink, lineWidth: 2.5)))
        .frame(maxWidth: 460)
    }

    private func knobRow(_ k: FeelKnob) -> some View {
        let value = controller.feelBinding(k)
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(k.name).font(.rounded(15))
                Spacer()
                Text(FeelKnob.fmt(value.wrappedValue))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
            }
            Text(k.hint).font(.rounded(11.5, .medium)).foregroundStyle(Palette.inkSoft)
            Slider(value: value, in: k.range, step: k.step)
                .tint(Palette.ink)
                .accessibilityLabel(k.name)
                .accessibilityValue(FeelKnob.fmt(value.wrappedValue))
            Text("黏土 \(FeelKnob.fmt(SlimeMaterial.clay.defaults[keyPath: k.key]))・麻糬 \(FeelKnob.fmt(SlimeMaterial.mochi.defaults[keyPath: k.key]))・果凍 \(FeelKnob.fmt(SlimeMaterial.jelly.defaults[keyPath: k.key]))")
                .font(.rounded(11, .medium))
                .foregroundStyle(Palette.inkSoft)
        }
    }

    private func chip(_ title: String, on: Bool = false, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.rounded(13))
                .padding(.horizontal, 10).padding(.vertical, 8)
                .foregroundStyle(on ? .white : Palette.ink)
                .background(Capsule().fill(on ? Palette.ink : .white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}
