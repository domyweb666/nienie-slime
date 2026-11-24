import SwiftUI

/// 手感調節台 v1 on the phone (v2.52, 多米 11-22 交辦 B 組; 《虛擬手感》3-4 第十一節的規格). v2.39 起 (多米 11-16: 要有個操控數值的地方).
/// Opens from the 調 button at the bottom right, covers the sky, the slime stays squishable below it.
/// Seven main knobs, one for each word on the feel card, the secondary ones under 更多; three slots, switched with nothing added;
/// a blind comparison of two slots; the copied text pastes back to the same numbers; 量測 (the grey box, the bare circle, the layers, the fuzz test).
/// What a knob, a saved feel and the copied text are is in FeelDeskModel.swift; the web's `prototype/web/desk.js` is the same desk.
struct FeelDesk: View {
    @EnvironmentObject var controller: SlimeController
    @Binding var isPresented: Bool
    @State private var copiedText = ""
    @State private var showMore = false
    @State private var showLab = false
    @State private var showStyles = true
    @State private var winSet = -1   // v2.59 窗景: which set is open, -1 none
    @FocusState private var askFocused: Bool

    private static let warn = Color(red: 0.70, green: 0.33, blue: 0.08)
    private static let pairs: [(a: Int, b: Int)] = [(0, 1), (0, 2), (1, 2)]

    var body: some View {
        let eff = controller.feelEffective
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("手感調節台").font(.rounded(17, .heavy))
                Text("\(controller.slime.name)・\(controller.material.name)｜預設 \(FeelKnob.version)").font(.rounded(12)).foregroundStyle(Palette.inkSoft)
                Spacer()
                Button("收起") { askFocused = false; isPresented = false }
                    .font(.rounded(14))
                    .foregroundStyle(Palette.inkSoft)
                    .frame(minWidth: 44, minHeight: 44)
            }

            if let blind = controller.feelBlind {
                // 3-4 鏈四: while the two are being compared no number is on screen
                blindBox(blind)
            } else if let pb = controller.pullBlind {
                pullBlindBox(pb)   // v2.61
            } else {
                if let stale = controller.feelStale { stalePrompt(stale) }
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // v2.58 (QC-0007 #48): all ten, here where one looks for them (the bottom row stays behind 十隻都顯示)
                        Text("選史萊姆").font(.rounded(13, .heavy))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), alignment: .leading, spacing: 6) {
                            ForEach(SlimeKind.allCases) { k in
                                chip(k.name, on: controller.slime == k) { controller.pickSlime(k) }
                            }
                        }
                        windowBox   // v2.59
                        HStack(spacing: 6) {
                            Text("從哪個材質開始").font(.rounded(12)).foregroundStyle(Palette.inkSoft)
                            ForEach([SlimeMaterial.clay, .mochi, .jelly]) { m in
                                chip(m.name, on: controller.material == m) { controller.feelStartFrom(m) }
                            }
                            Spacer(minLength: 0)
                        }
                        batchBox   // v2.61
                        DisclosureGroup(isExpanded: $showStyles) {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(stride(from: 0, to: FeelStyle.all.count, by: 2)), id: \.self) { r in
                                    HStack(spacing: 6) {
                                        ForEach(FeelStyle.all[r..<min(r + 2, FeelStyle.all.count)]) { st in
                                            chip(st.name, on: controller.feelStyleNow == st.id) { controller.feelStyle(st) }
                                        }
                                        Spacer(minLength: 0)
                                    }
                                }
                                Text("按一個就套到黏土上（只動幾個旋鈕，下面看得到）。每一種的數學在按下去後的說明裡。")
                                    .font(.rounded(11.5, .medium)).foregroundStyle(Palette.inkSoft)
                            }
                            .padding(.top, 6)
                        } label: {
                            Text("手感風格（10 選 1，v2.54）").font(.rounded(13, .heavy))
                        }
                        .tint(Palette.ink)
                        ForEach(FeelKnob.sections, id: \.self) { section in
                            Text(section)
                                .font(.rounded(12, .heavy))
                                .foregroundStyle(Palette.inkSoft)
                                .padding(.top, 2)
                            ForEach(FeelKnob.main.filter { $0.section == section }) { k in
                                knobRow(k, eff)
                            }
                        }
                        strandRow
                        DisclosureGroup(isExpanded: $showMore) {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(FeelKnob.more) { k in knobRow(k, eff) }
                            }
                            .padding(.top, 6)
                        } label: {
                            Text("更多（副旋鈕）").font(.rounded(13, .heavy))
                        }
                        .tint(Palette.ink)
                        DisclosureGroup(isExpanded: $showLab) {
                            labBox.padding(.top, 6)
                        } label: {
                            Text("量測").font(.rounded(13, .heavy))
                        }
                        .tint(Palette.ink)
                    }
                    .padding(.bottom, 4)
                }
                .frame(maxHeight: 300)

                slotRow
                blindRow
                ioRow
            }

            Text(controller.feelNote)
                .font(.rounded(12, .medium))
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            if !copiedText.isEmpty && controller.feelBlind == nil && controller.pullBlind == nil {
                Text(copiedText)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(5)
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

    // MARK: - v2.61 這一批 (the same words as the web's box)

    private var batchBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("這一批（v2.61）").font(.rounded(13, .heavy))
            HStack(spacing: 5) {
                ForEach(FeelBatch.Tier.allCases) { t in
                    chip(t.name, on: controller.batch.tier == t) { controller.batchTier(t) }
                        .accessibilityAddTraits(controller.batch.tier == t ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 5) {
                Text("拉").font(.rounded(12)).foregroundStyle(Palette.inkSoft)
                ForEach(FeelBatch.pull, id: \.self) { id in
                    chip(FeelBatch.pullName(id), on: controller.batch[id]) { controller.batchTogglePull(id) }
                        .accessibilityAddTraits(controller.batch[id] ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
            small("停住：拉長停下來，就定在那裡。整隻先走：往身體裡拉，整隻先跟著走再拉長。收回去：拉很長放手，會收回來。這三顆會跟著存檔。")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), alignment: .leading, spacing: 6) {
                ForEach(FeelBatch.groups) { g in
                    chip(g.name, on: controller.batch.all(g.ids)) { controller.batchToggleGroup(g) }
                        .accessibilityAddTraits(controller.batch.all(g.ids) ? .isSelected : [])
                }
            }
            small("按一下關，再按開。關掉的那組就跟 build 158 一樣。不跟著存檔，重開 app 會回到開。震動那組第二批才有。")
            Text("甲乙比拉").font(.rounded(13, .heavy)).padding(.top, 2)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 2), alignment: .leading, spacing: 6) {
                ForEach(PullBlind.What.allCases) { w in
                    chip(w.name, on: controller.pullWhat == w) { controller.pullWhat = w }
                }
            }
            HStack(spacing: 8) {
                bigButton("甲", note: "", on: false) { controller.pullBlindPick(0) }
                bigButton("乙", note: "", on: false) { controller.pullBlindPick(1) }
            }
            small("按甲或乙開始。哪邊是哪一種每次開始都重抽，按「揭曉」才會寫。手放開才會換。")
        }
    }

    /// 甲乙 in progress: nothing here says which side is which until 揭曉
    private func pullBlindBox(_ b: PullBlind) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("甲乙：" + b.what.name).font(.rounded(13, .heavy))
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { i in
                    bigButton(PullBlind.name(i), note: b.pending == i ? "放開手就換" : (b.shown == i ? "現在是這個" : ""), on: b.shown == i) { controller.pullBlindPick(i) }
                }
            }
            if b.revealed { Text(b.answer).font(.rounded(13)).fixedSize(horizontal: false, vertical: true) }
            HStack(spacing: 6) {
                chip("揭曉", enabled: !b.revealed) { controller.pullBlindReveal() }
                chip("結束") { controller.pullBlindStop() }
                Spacer(minLength: 0)
            }
        }
    }

    private func bigButton(_ title: String, note: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title).font(.rounded(22, .heavy))
                if !note.isEmpty { Text(note).font(.rounded(11, .medium)) }
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .foregroundStyle(on ? .white : Palette.ink)
            .background(RoundedRectangle(cornerRadius: 16).fill(on ? Palette.ink : .white).overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.ink, lineWidth: 2.5)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(note.isEmpty ? title : title + "，" + note)
    }

    private func small(_ s: String) -> some View {
        Text(s).font(.rounded(11.5, .medium)).foregroundStyle(Palette.inkSoft).fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - v2.59 窗景

    /// The original window and the three sets; a set opens its four. Day and night below (the scenes look different in each).
    @ViewBuilder private var windowBox: some View {
        let all: [WindowDef] = WindowLibrary.all
        if !all.isEmpty {
            let now: WindowDef? = WindowLibrary.def(controller.winId)
            VStack(alignment: .leading, spacing: 6) {
                Text("窗外").font(.rounded(13, .heavy))
                HStack(spacing: 6) {
                    chip("原本", on: now == nil) { controller.pickWindow("") }
                        .accessibilityLabel("窗外：原本")
                        .accessibilityAddTraits(now == nil ? .isSelected : [])
                    ForEach(0..<WindowLibrary.setNames.count, id: \.self) { i in
                        chip(WindowLibrary.setNames[i], on: now?.set == i) { winSet = winSet == i ? -1 : i }
                            .accessibilityLabel("窗外：" + WindowLibrary.setNames[i])
                            .accessibilityValue(winSet == i ? "展開" : "收起")
                    }
                    Spacer(minLength: 0)
                }
                if winSet >= 0 {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 2), alignment: .leading, spacing: 6) {
                        ForEach(all.filter { $0.set == winSet }, id: \.id) { w in
                            chip(w.name, on: now?.id == w.id) { controller.pickWindow(w.id) }
                                .accessibilityHint(w.line)
                                .accessibilityAddTraits(now?.id == w.id ? .isSelected : [])
                        }
                    }
                }
                HStack(spacing: 6) {
                    chip("白天", on: controller.sceneShown == 1) { controller.pickNight(false) }
                        .accessibilityAddTraits(controller.sceneShown == 1 ? .isSelected : [])
                    chip("夜晚", on: controller.sceneShown == 2) { controller.pickNight(true) }
                        .accessibilityAddTraits(controller.sceneShown == 2 ? .isSelected : [])
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - The knobs

    /// One knob: the word and the parameter's own name, the number with what it means in time, how to squeeze to judge it,
    /// what the physics really uses when something overrides it (交辦 A2), and the three materials' values.
    private func knobRow(_ k: FeelKnob, _ eff: FeelEffective) -> some View {
        let value = controller.feelBinding(k)
        let number = FeelKnob.fmt(value.wrappedValue), unit = FeelKnob.unit(k.id, value.wrappedValue)
        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(k.name).font(.rounded(15))
                Text(k.id).font(.system(size: 11, design: .monospaced)).foregroundStyle(Palette.inkSoft)
                Spacer()
                Text(unit.isEmpty ? number : number + "｜" + unit)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
            }
            Text(k.hint).font(.rounded(11.5, .medium)).foregroundStyle(Palette.inkSoft)
            Slider(value: value, in: k.range, step: k.step)
                .tint(Palette.ink)
                .accessibilityLabel(k.name)
                .accessibilityValue(unit.isEmpty ? number : number + "，" + unit)
            if let note = eff.note(k.key) {
                Text(note).font(.rounded(11.5, .heavy)).foregroundStyle(Self.warn)
            }
            Text("黏土 \(FeelKnob.fmt(SlimeMaterial.clay.defaults[keyPath: k.key]))・麻糬 \(FeelKnob.fmt(SlimeMaterial.mochi.defaults[keyPath: k.key]))・果凍 \(FeelKnob.fmt(SlimeMaterial.jelly.defaults[keyPath: k.key]))")
                .font(.rounded(11, .medium))
                .foregroundStyle(Palette.inkSoft)
        }
    }

    /// 韌 has two halves since v2.51: how far the body itself pulls, and whether a strand takes over past a stable length.
    private var strandRow: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text("韌的另一半").font(.rounded(12)).foregroundStyle(Palette.inkSoft)
                chip(controller.feelStrand ? "黏條 開" : "黏條 關", on: controller.feelStrand) { controller.feelToggleStrand() }
                Spacer(minLength: 0)
            }
            Text("開：身體只拉到穩定的長度，再遠是黏條。關：身體自己拉到「韌」那麼長。")
                .font(.rounded(11.5, .medium))
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Slots and the blind comparison

    private var slotRow: some View {
        HStack(spacing: 5) {
            Text("存成").font(.rounded(12)).foregroundStyle(Palette.inkSoft)
            ForEach(0..<3, id: \.self) { i in
                chip("\(i + 1)") { controller.feelStore(i) }
                    .accessibilityLabel("存成 \(i + 1)")
            }
            Text("換到").font(.rounded(12)).foregroundStyle(Palette.inkSoft).padding(.leading, 6)
            ForEach(0..<3, id: \.self) { i in
                chip("\(i + 1)", enabled: controller.feelSlots[i] != nil) { controller.feelGo(i) }
                    .accessibilityLabel("換到 \(i + 1)")
            }
            Spacer(minLength: 0)
        }
    }

    private var blindRow: some View {
        HStack(spacing: 5) {
            Text("盲比").font(.rounded(12)).foregroundStyle(Palette.inkSoft)
            ForEach(0..<3, id: \.self) { n in
                let a = Self.pairs[n].a, b = Self.pairs[n].b
                chip("\(a + 1) 對 \(b + 1)", enabled: controller.feelSlots[a] != nil && controller.feelSlots[b] != nil) {
                    controller.feelBlindStart(a, b)
                }
                .accessibilityLabel("盲比存檔 \(a + 1) 對 \(b + 1)")
            }
            Spacer(minLength: 0)
        }
    }

    /// The two slots are called 1 號 and 2 號 at random; which is which is told only after choosing, and one line is logged.
    private func blindBox(_ blind: FeelBlind) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("盲比中").font(.rounded(12, .heavy)).foregroundStyle(Palette.inkSoft)
                chip("摸 1 號", on: blind.current == 0) { controller.feelBlindShow(0) }
                chip("摸 2 號", on: blind.current == 1) { controller.feelBlindShow(1) }
                Spacer(minLength: 0)
            }
            TextField("這次比哪個詞？例：哪個比較彈（可以不填）", text: $controller.feelQuestion)
                .font(.rounded(13))
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .focused($askFocused)
                .onSubmit { askFocused = false }
            HStack(spacing: 6) {
                chip("選 1 號") { askFocused = false; controller.feelBlindEnd(choice: 0) }
                chip("選 2 號") { askFocused = false; controller.feelBlindEnd(choice: 1) }
                chip("分不出來") { askFocused = false; controller.feelBlindEnd(choice: nil) }
                chip("取消") { askFocused = false; controller.feelBlindCancel() }
                Spacer(minLength: 0)
            }
        }
    }

    /// B4: the numbers on the desk were tuned on other defaults than this build's
    private func stalePrompt(_ stale: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("預設已更新到 \(FeelKnob.version)，現在用的是新預設。你之前存的數字是在「\(stale)」上調的，要用回去就按「留著我的」。")
                .font(.rounded(12))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                chip("用新預設") { controller.feelUseNewDefaults() }
                chip("留著我的") { controller.feelKeepMine() }
                Spacer(minLength: 0)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 1, green: 0.953, blue: 0.839)))
    }

    // MARK: - 量測 (B6, A5, C4)

    private var labBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                chip("灰盒", on: controller.labGrey) { controller.labGrey.toggle() }
                chip("純圓", on: controller.labCircle) { controller.labCircle.toggle() }
                chip("延遲測試", on: controller.latencyTest) { controller.latencyTest.toggle() }
                chip("讀數歸零") { controller.labResetReadouts() }
                Spacer(minLength: 0)
            }
            Text(controller.labText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            // v2.61 B7, A7
            Text(controller.labProbeText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 5) {
                chip("複製量測") {
                    let text = controller.labCopyText
                    UIPasteboard.general.string = text
                    copiedText = text
                    controller.feelNote = "量測複製好了。同一段字也在下面的框裡。"
                }
                chip(controller.labSkinOn ? "量皮中……" : "量皮 5 秒", enabled: !controller.labSkinOn) { controller.labSkinStart() }
                chip("碰著固定 120", on: controller.lab120) { controller.lab120.toggle() }
                Spacer(minLength: 0)
            }
            small("觸控：面板開著時，每點一下就記，靜音時不記聲音。量皮：按下去 5 秒內數皮有幾塊、幾個洞、外框跳多大，用電腦照同一套圖重畫來數，會多吃一點電。碰著固定 120：手指碰著時要求螢幕一秒 120 張，低電量模式系統會關掉，耗電比較多，收起面板就停，不存。")
            Text("圖層：關掉一層，看上面「整格」少幾毫秒").font(.rounded(11.5, .medium)).foregroundStyle(Palette.inkSoft)
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { col in
                        let layer = SlimeController.labLayers[row * 3 + col]
                        let dead = controller.labLayerDead(layer.id)
                        chip(layer.name, on: !dead && !controller.labLayersOff.contains(layer.id), enabled: !dead) {
                            controller.labToggleLayer(layer.id)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            HStack(spacing: 5) {
                chip(controller.fuzzRunning ? "亂捏測試中……" : "跑亂捏測試（約一分鐘）", enabled: !controller.fuzzRunning) { controller.fuzzRun() }
                Spacer(minLength: 0)
            }
            if !controller.fuzzText.isEmpty {
                Text(controller.fuzzText)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("灰盒：只留物理（平塗、沒有聲音和震動、牠不會自己動、擺飾收起來；牆、窗台、碗還在）。純圓：一個直徑約 2 公分的圓，圓心就是手指，沿著尺拖，量系統本身的落後。延遲測試：手指落下那一格全畫面閃白。亂捏測試：30 組固定的亂拉，用台上現在的數字，看會不會翻面、打結，保險多常出手。這一組都不存，下次打開是關的。")
                .font(.rounded(11, .medium))
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Out and back in (B5)

    private var ioRow: some View {
        HStack(spacing: 6) {
            Button {
                let text = controller.feelText
                UIPasteboard.general.string = text
                copiedText = text
                controller.feelNote = "複製好了，貼給 Agent 就行。同一段字也在下面的框裡。"
            } label: {
                Text("複製數值給 Agent").frame(maxWidth: .infinity).padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Capsule().fill(Palette.ink))
            }
            Button {
                if controller.feelImport(UIPasteboard.general.string ?? "") { copiedText = "" }
            } label: {
                Text("貼上匯入").padding(.horizontal, 12).padding(.vertical, 10)
                    .foregroundStyle(Palette.ink)
                    .background(Capsule().fill(.white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)))
            }
            Button {
                controller.feelDefaults()
                copiedText = ""
            } label: {
                Text("回到預設").padding(.horizontal, 12).padding(.vertical, 10)
                    .foregroundStyle(Palette.ink)
                    .background(Capsule().fill(.white).overlay(Capsule().stroke(Palette.ink, lineWidth: 2.5)))
            }
        }
        .font(.rounded(14))
        .buttonStyle(.plain)
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
