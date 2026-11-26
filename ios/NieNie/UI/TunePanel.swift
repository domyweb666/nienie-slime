import SwiftUI

/// Hidden tuning panel: one slider per feel parameter, live while you squish, copyable values.
/// Also the blind-test slots (1 號 / 2 號), the second-batch 候選 buttons, the frame readout and the
/// latency flash (手感精修提案 第 37、38、39、40 條).
struct TunePanel: View {
    @EnvironmentObject var controller: SlimeController
    @Binding var isPresented: Bool
    /// v2.52 B7: the App Store's build has no 調 button; the desk opens from here
    var openFeel: () -> Void = {}
    @State private var copied = false

    var body: some View {
        let eff = controller.feelEffective   // v2.52 A2: what the physics really uses, next to a slider something overrides
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("調整面板").font(.rounded(17, .heavy))
                Text("\(controller.slime.name)・\(controller.material.name)").font(.rounded(13)).foregroundStyle(Palette.inkSoft)
                Spacer()
                Button("手感調節台") { openFeel() }
                    .font(.rounded(13))
                    .foregroundStyle(Palette.inkSoft)
                Button("收起") { isPresented = false }
                    .font(.rounded(13))
                    .foregroundStyle(Palette.inkSoft)
            }

            // readout: real frame rate, worst frame, dropped frames, main-thread work, finger contact radius, audio buffer
            Text(controller.hudText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.inkSoft)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // blind test: save the current numbers as 1 or 2, then switch by number only
            HStack(spacing: 6) {
                chip("存 1", enabled: controller.pullBlind == nil) { controller.saveSlot(1) }
                chip("存 2", enabled: controller.pullBlind == nil) { controller.saveSlot(2) }
                chip("切 1", on: controller.activeSlot == 1, enabled: controller.slotSaved[1] == true && controller.pullBlind == nil) { controller.loadSlot(1) }
                chip("切 2", on: controller.activeSlot == 2, enabled: controller.slotSaved[2] == true && controller.pullBlind == nil) { controller.loadSlot(2) }
                Spacer(minLength: 0)
                Text(controller.activeSlot.map { "\($0) 號" } ?? "未存")
                    .font(.rounded(13))
                    .foregroundStyle(Palette.inkSoft)
            }

            // v2.57 (多米 11-23): all ten in the bottom row. v2.60 (多米 11-24): the look of all ten, opaque (the default) or glossy and see-through
            HStack(spacing: 6) {
                chip("十隻都顯示", on: controller.showAll) { controller.showAll.toggle() }
                chip(controller.glossyClear ? "外觀：亮面透明" : "外觀：不透明", on: controller.glossyClear) { controller.glossyClear.toggle() }
                Spacer(minLength: 0)
            }
            // v2.61b (多米 11-26): 湯圓's core and the opaque edge, each in two versions to compare on the phone
            HStack(spacing: 6) {
                chip(controller.coreSoft ? "湯圓餡：小而淡" : "湯圓餡：原版", on: controller.coreSoft) { controller.coreSoft.toggle() }
                chip(controller.edgeClean ? "邊緣：乾淨" : "邊緣：原版", on: controller.edgeClean) { controller.edgeClean.toggle() }
                Spacer(minLength: 0)
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

            StepProbe()
            // 走路（v2.31 批次 4）：假裝走了一段路，牠從窗外帶東西回來；全部重來清掉窗台上的東西、今天的次數和問過的權限
            HStack(spacing: 6) {
                chip("走路：假裝 800 步") { controller.walkFake(800) }
                chip("假裝 3500 步") { controller.walkFake(3500) }
                chip("全部重來") { controller.walkClear() }
                Spacer(minLength: 0)
            }
            // 搖晃沉澱（v2.31 批次 5）：沒辦法搖手機時假裝；真機直接搖
            HStack(spacing: 6) {
                chip("搖：假裝搖一下") { controller.shakeFake(1) }
                chip("假裝搖三下") { controller.shakeFake(3) }
                chip("立刻沉澱") { controller.shakeSettleNow() }
                Spacer(minLength: 0)
            }
            blindBox   // v2.64 這一批（v2.64）的盲比：B8 甲乙、震動早晚甲乙丙

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(TuneField.sections, id: \.self) { section in
                        Text(section)
                            .font(.rounded(12, .heavy))
                            .foregroundStyle(Palette.inkSoft)
                            .padding(.top, 4)
                        ForEach(TuneField.all.filter { $0.section == section && !controller.hiddenNow($0) }) { f in   // v2.61 甲乙: not shown which side is on
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
                                if let note = eff.note(f.key) {
                                    Text(note).font(.rounded(11.5, .heavy)).foregroundStyle(Color(red: 0.70, green: 0.33, blue: 0.08))
                                }
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

    /* v2.64 這一批（v2.64）盲比（BATCH3 第 8 項之 7；規劃「開關和比法」：iPhone 放「甲」「乙」兩顆大鈕，哪邊是新的不寫，手放開再切）。
       B8：甲、乙、不比，下面一排是比法（兩樣一起、只比起步、只比慢一拍，照網頁）和洗牌。震動早晚（未做 18）：甲、乙、丙對到 0、20、40 毫秒，不寫哪個是哪個。
       長按左邊的「B8 盲比」「震動早晚」1 秒看答案（記一行在盲比紀錄）。放在滑桿上面，不用捲到最下面那一節 */
    private var blindBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                blindLabel("B8 盲比") { controller.b8Reveal() }
                bigChip("甲", on: controller.b8Want == 0) { controller.b8Pick(0) }
                bigChip("乙", on: controller.b8Want == 1) { controller.b8Pick(1) }
                chip("不比", on: controller.b8Want == nil) { controller.b8Pick(nil) }
                Spacer(minLength: 0)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(B8Blind.Kind.allCases) { k in
                        chip(k.button, on: controller.b8Kind == k) { controller.b8PickKind(k) }
                    }
                    chip("洗牌") { controller.b8Shuffle() }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {   // 五顆加字，小手機一排放不下時可以橫著滑
                HStack(spacing: 8) {
                    blindLabel("震動早晚") { controller.hapReveal() }
                    ForEach(HapDelayBlind.names.indices, id: \.self) { i in
                        bigChip(HapDelayBlind.name(i), on: controller.hapWant == i) { controller.hapPick(i) }
                    }
                    chip("不比", on: controller.hapWant == nil) { controller.hapPick(nil) }
                    chip("洗牌") { controller.hapShuffle() }
                }
            }
            Text(controller.blindNote.isEmpty ? "這一批（v2.64）盲比：哪邊是新的不寫，手放開才換。長按左邊的字 1 秒看答案，看完按洗牌重抽。" : controller.blindNote)
                .font(.rounded(11, .medium))
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func blindLabel(_ title: String, reveal: @escaping () -> Void) -> some View {
        Text(title)
            .font(.rounded(13, .heavy))
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 1) { reveal() }
            .accessibilityHint("長按一秒看答案")
    }

    /// v2.64 盲比用的大鈕
    private func bigChip(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.rounded(20, .heavy))
                .frame(minWidth: 44, minHeight: 40)
                .padding(.horizontal, 6)
                .foregroundStyle(on ? .white : Palette.ink)
                .background(Capsule().fill(on ? Palette.ink : .white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)))
        }
        .buttonStyle(.plain)
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
