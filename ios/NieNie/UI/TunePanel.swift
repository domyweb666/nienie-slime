import SwiftUI

/// Hidden tuning panel: one slider per feel parameter, live while you squish, copyable values.
/// Also the blind-test slots (1 號 / 2 號), the frame readout and the latency flash
/// (手感精修提案 第 37、39、40 條).
struct TunePanel: View {
    @EnvironmentObject var controller: SlimeController
    @Binding var isPresented: Bool
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("調整面板").font(.rounded(17, .heavy))
                Text(controller.material.name).font(.rounded(13)).foregroundStyle(Palette.inkSoft)
                Spacer()
                Button("收起") { isPresented = false }
                    .font(.rounded(13))
                    .foregroundStyle(Palette.inkSoft)
            }

            // readout: real frame rate, worst frame, dropped frames, main-thread work, finger contact radius, audio buffer
            Text(controller.hudText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.inkSoft)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // blind test: save the current numbers as 1 or 2, then switch by number only
            HStack(spacing: 6) {
                chip("存 1") { controller.saveSlot(1) }
                chip("存 2") { controller.saveSlot(2) }
                chip("切 1", on: controller.activeSlot == 1, enabled: controller.slotSaved[1] == true) { controller.loadSlot(1) }
                chip("切 2", on: controller.activeSlot == 2, enabled: controller.slotSaved[2] == true) { controller.loadSlot(2) }
                Spacer(minLength: 0)
                Text(controller.activeSlot.map { "\($0) 號" } ?? "未存")
                    .font(.rounded(13))
                    .foregroundStyle(Palette.inkSoft)
            }

            Toggle(isOn: $controller.latencyTest) {
                Text("延遲測試：按下時閃白一幀").font(.rounded(13))
            }
            .tint(Palette.ink)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(TuneField.all) { f in
                        let value = controller.binding(for: f)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(f.name).font(.rounded(14))
                                Spacer()
                                Text(String(format: f.step < 0.01 ? "%.3f" : "%.2f", value.wrappedValue))
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundStyle(Palette.inkSoft)
                            }
                            Text(f.hint).font(.rounded(11.5, .medium)).foregroundStyle(Palette.inkSoft)
                            Slider(value: value, in: f.range, step: f.step)
                                .tint(Palette.ink)
                                .accessibilityLabel(f.name)
                        }
                    }
                }
            }
            .frame(maxHeight: 260)

            HStack(spacing: 8) {
                Button {
                    UIPasteboard.general.string = controller.exportText
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { copied = false }
                } label: {
                    Text(copied ? "已複製" : "複製數值").frame(maxWidth: .infinity).padding(.vertical, 8)
                        .foregroundStyle(.white)
                        .background(Capsule().fill(Palette.ink))
                }
                Button {
                    controller.restoreDefaults()
                } label: {
                    Text("恢復預設").frame(maxWidth: .infinity).padding(.vertical, 8)
                        .foregroundStyle(Palette.ink)
                        .background(Capsule().fill(.white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)))
                }
            }
            .font(.rounded(14))
            .buttonStyle(.plain)

            Text(controller.exportText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Palette.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.8), lineWidth: 1.5))
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 14)
        .background(RoundedRectangle(cornerRadius: 22).fill(.white)
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.ink, lineWidth: 2.5)))
        .shadow(color: Palette.ink, radius: 0, x: 0, y: 4)
        .frame(maxWidth: 460)
    }

    private func chip(_ title: String, on: Bool = false, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.rounded(13))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .foregroundStyle(on ? .white : Palette.ink)
                .background(Capsule().fill(on ? Palette.ink : .white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}
