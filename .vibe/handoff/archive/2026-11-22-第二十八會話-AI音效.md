# Handoff: 音效全面換成 ElevenLabs 的 AI 音效，反應聲改成純黏液 ASMR，沒有人聲；白噪音做了試聽還沒選

> 產出時間：2026-11-22（第二十七、二十八會話，11-19 到 11-21）
> 上一份（種子 1009、build 131 等回報）在 `.vibe/handoff/archive/2026-11-16-第二十六會話-種子1009.md`，那裡的待辦大多還開著，見下面「上一份留下的」。

## ✅ 這次完成了什麼

- 寫了白噪音合成 `prototype/sfx-design/design_noise.py`：白、粉紅、棕三種，120 秒，頭尾接得起來，試聽檔在 `prototype/sfx-design/preview/noise-*.m4a`（這個資料夾不進 git）。
- 在 Higgsfield（Mirelo）生了 67 段音效，接進 app 之後發了 build 133（11-19，有 TestFlight）。**build 133 裡的是 Higgsfield 版，現在本機已經全部換掉了。**
- 場景音效接線（v2.50，網頁和 Swift 都改）：走路一縮一衝響爬行聲、爬窗框、落地、游進場、黏到窗框、拔開、撕開（加撕裂聲和 0.35 秒後一滴）、睡著每 4 到 7 秒一次、嘆氣、被碰醒和擺飾倒下時嚇一跳。只有網頁版有的：擺飾被碰（含蠟燭）、推倒、掉出窗外、走過布墊（iPhone 版還沒有擺飾的物理）。
- 在 ElevenLabs（Sound Effects v3）用同樣 33 句描述各生 4 個版本，多米聽完說 ElevenLabs 比較好，質感類全部改用 ElevenLabs（commit `7b29cd2`）。
- 多米說不要人聲、全部 ASMR：11 種反應（被戳、開心、被搔癢、不要啦、嚇到、打招呼、討摸、被揉、吞黏液、嘆氣、睡覺）用純黏液聲重生，每種 4 個版本，已經換進 app（commit `3fdfb63`）。
- 比較頁 `prototype/web/sfx/compare-ai.html`：合成、Higgsfield、ElevenLabs、ASMR 四組並排，音量對齊。
- selftest 在 v4.1（場景接線）之後跑過一輪，全過。之後只換音檔，沒再跑。
- 網頁版實測：39 層、208 段都載入，場景聲在對的時機響。

## 🚧 還沒做完 / 待決定

- **本機 commit 沒推**：`5fce44a` 到 `3fdfb63`（ElevenLabs 質感、ASMR 反應）都只在本機。多米 11-22 說「先不要」推。iPhone 版還沒編譯過這幾筆，下一個 build 會是 134。
- **白噪音沒選顏色**：建議粉紅。選了之後要把它加成第四個環境音：`make_ambience.py` 或 `design_noise.py --web --ios` 產 bed，`amb.json` 加場景，網頁 `index.html` 的 `VIEW0AMB` 清單和聲音按鈕列、Swift `SlimeController.ambience` 與 `SlimeAudio` 的選單一起改。
- **舊的合成音檔還在 iOS Resources**：manifest 已經不用（`press-*.wav`、`voice-*.wav` 等），但還打包進 app，AI 音檔另外約 14 MB。多米確認新聲音 OK 後再清，**只清 `ios/NieNie/Resources/`**；`prototype/web/sfx/` 的合成檔不能刪，`make_ai_sfx.py` 量目標音量要讀它們。
- **專案 `CLAUDE.md` 的「聲音」段落沒補 v4**（AI 音效、ElevenLabs、ASMR、場景接線）。全域規則：改之前先把現況給多米看。
- **商用授權**：Higgsfield 和 ElevenLabs 的條款都沒查原文，記在 `.uiux/04-手感/素材授權紀錄.md`，上架前要對。
- 真機還沒聽過 ElevenLabs 版和 ASMR 版。手機喇叭會不會太刺、太小聲，要多米捏過才知道；要調就改 `make_ai_sfx.py` 的 `FX_RMS` 或各層參數重跑。
- 上一份留下的：build 131（水）、破圖（種子 1009）都還等多米回報。

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 聲音一律用 ElevenLabs，不要人聲。它的反應用黏液本身的聲音表達（啵、泡泡、擠壓、吱聲），不用小生物叫聲。
- 白噪音用程式合成，不用 AI 生（Higgsfield 生的不對）。
- `design_sfx.py` 重跑會把 manifest 改回全合成，**重跑之後一定要再跑 `make_ai_sfx.py`**。
- 網頁和 iOS 的 manifest 本來就不一樣（網頁有 `prop`，iOS 有 `ding`），`make_ai_sfx.py` 兩邊各讀各的、只換 AI 那幾層；擺飾類（`prop.*`、`fx.topple`、`fx.fallout`、`fx.cloth`）只寫網頁。
- 黏液掉落功能 11-07 就拿掉了，`fx.drip` 接在撕開之後。
- 多米開口才推、才發 TestFlight（這次 build 133 是他說的；11-22 他說先不要推）。
- 多米 11-16 說先不要整份重跑測試：一輪就好，改動小只跑相關項目，回報講清楚跑了什麼。

## 📂 下個會話最重要的檔案

- `prototype/sfx-design/make_ai_sfx.py` ← 所有 AI 音效怎麼切、哪層用哪批、音量
- `prototype/sfx-design/prep_ai_compare.py`、`prototype/web/sfx/compare-ai.html` ← 比較頁
- `prototype/sfx-design/design_noise.py` ← 白噪音
- `prototype/sfx-design/el_recv.py` ← 從 ElevenLabs 存音檔的接收器
- `prototype/web/sfx/engine.js`（`S.fx`）、`prototype/web/index.html`（搜尋 `v2.50`、`gaitSfx`）
- `ios/NieNie/Slime/SlimeRig.swift`（搜尋 `v2.50`）、`ios/NieNie/Feedback/SlimeAudio.swift`（`fx`）、`ios/NieNie/App/SlimeController.swift`（`.fx`）
- 原始素材：`E:\捏捏史萊姆\素材\elevenlabs\slime\_opus\`（`<種類>-N.opus`、`as-<種類>-N.opus`），`E:\捏捏史萊姆\素材\higgsfield\slime\`（已不使用）
- `.uiux/04-手感/素材授權紀錄.md`

## ⏭️ 下一步從哪繼續

1. 讀這份。
2. 問多米三件事，照他的答案做：
   - 要不要推上去發 build 134？要的話：`git push origin swiftui-port`，再 `gh workflow run ios.yml --ref swiftui-port -f testflight=true`（push 自己觸發的編譯會被這個取消，正常）。
   - 白噪音選哪個顏色？選了就照「待決定」那條接進 app。
   - `CLAUDE.md` 的聲音段落要不要補？先把現況給他看。
3. 他捏過 build 134 回報哪個聲音不好：先在比較頁找那一種，要重生就照下面的流程。

## 🔁 重生音效的流程（試過很多條路，這條才穩）

1. **生成**：內建瀏覽器開 `https://elevenlabs.io/app/sound-effects`（多米已登入）。時長滑桿點一下之後用方向鍵，一格 0.1 秒；設定會記住。每生一次給 4 個版本，3 秒約 40 點、4 秒約 52 點。
2. **存檔**：內建瀏覽器的下載不會存到電腦，改用 Chrome（多米已登入、已允許多檔下載和區域網路存取）。先在背景跑 `python prototype/sfx-design/el_recv.py <輸出資料夾>`，Chrome 開 `.../history?q=沒有結果的字`，頁面裡掛 `URL.createObjectURL` 攔 `audio/*` 的 blob，再把搜尋框改成那句描述裡獨有的幾個字，等 4 個 blob 出現，`fetch('http://127.0.0.1:8799/save?name=<種類>-N.opus',{method:'POST',body:blob})`。**每一種要重新載入頁面一次**，不然已經載過的音檔不會再建立 blob。
3. **進 app**：`make_ai_sfx.py` 改來源，跑完再跑 `prep_ai_compare.py --src <資料夾> --out ../web/sfx/el` 更新比較頁。

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 內建瀏覽器存不了下載檔，iframe、彈出視窗、直接連本機都被擋，別再試。
- Chrome 用點擊下載會漏（分頁在背景時選單打不開、連點太快），別再用這招。
- `swimIntro(side)` 一定要給方向（1 是從右邊），不給整隻變 NaN。這是測試時誤用，不是 bug。
- 預覽埠 8791 被多米另一個專案「人蔘修煉」佔著，所以 `.claude/launch.json` 加了 `web-proto-8793`。
- Higgsfield 的 Mirelo 目錄寫「只給遊戲流程用」，實際生得出來，但已經不用了。
