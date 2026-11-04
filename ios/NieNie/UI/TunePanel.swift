import SwiftUI

/// Hidden tuning panel: one slider per feel parameter, live while you squish, copyable values.
/// Also the blind-test slots (1 號 / 2 號), the second-batch 候選 buttons, the frame readout and the
/// latency flash (手感精修提案 第 37、38、39、40 條).
struct TunePanel: View {
    @EnvironmentObject var controller: SlimeController
    @Binding var isPresented: Bool
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("調整面板").font(.rounded(17, .heavy))
                Text("\(controller.slime.name)・\(controller.material.name)").font(.rounded(13)).foregroundStyle(Palette.inkSoft)
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

            // v2.23: the material moved here from the bottom bar (the same slime on another material, for blind tests)
            HStack(spacing: 6) {
                ForEach(SlimeMaterial.allCases) { m in
                    chip("材質：\(m.name)", on: controller.material == m) { controller.selectMaterial(m) }
                }
                Spacer(minLength: 0)
            }

            // second-batch candidates, one at a time: 存 1 (control) → 套候選 → 存 2 → 切 1／切 2
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Candidate.batch2) { c in
                        chip(c.name) { controller.applyCandidate(c) }
                    }
                }
            }
            Text("候選一次只套一條：存 1（對照）→ 套候選 → 存 2 → 切 1／切 2 盲測")
                .font(.rounded(11, .medium))
                .foregroundStyle(Palette.inkSoft)

            // v2.25 F5 haptic ladder: tap a number, feel it, note the smallest you can feel
            Text("觸覺階梯：點一下震一下，記下最小感覺得到哪一格")
                .font(.rounded(11, .medium))
                .foregroundStyle(Palette.inkSoft)
            ladderRow("單下", continuous: false)
            ladderRow("連續", continuous: true)

            Toggle(isOn: $controller.latencyTest) {
                Text("延遲測試：按下時閃白一幀").font(.rounded(13))
            }
            .tint(Palette.ink)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(TuneField.sections, id: \.self) { section in
                        Text(section)
                            .font(.rounded(12, .heavy))
                            .foregroundStyle(Palette.inkSoft)
                            .padding(.top, 4)
                        ForEach(TuneField.all.filter { $0.section == section }) { f in
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
            }
            .frame(maxHeight: 220)

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
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.8), lineWidth: 1.5))
        }
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 14)
        .background(RoundedRectangle(cornerRadius: 22).fill(.white)
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.ink, lineWidth: 2.5)))
        .frame(maxWidth: 460)
    }

    private static let ladderSteps: [Double] = [0.03, 0.05, 0.08, 0.12, 0.2, 0.3, 0.5, 0.8]

    private func ladderRow(_ label: String, continuous: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Text(label).font(.rounded(12))
                ForEach(Self.ladderSteps, id: \.self) { v in
                    chip(String(format: "%.2f", v)) { controller.hapticTest(v, continuous: continuous) }
                }
            }
        }
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
