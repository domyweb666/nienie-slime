# Handoff: 第十會話，v2.20 到 v2.22 做完（拖拉與拉力、凹痕、印象、ASMR 聲音與 lofi、它會出聲與回應、黏液），build 86 已上傳，還沒被真機捏過

> 產出時間：2026-11-02 07:59
> 前一會話的最後狀態，給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

- v2.20（多米 build 75：拖拉只有形變、凹痕退太久、沒有互動感）：D1 拖著走、D2 凹痕 0.6 秒退完、印象（熟、戒）＋ C1 到 C5。提案 `.uiux/04-手感/互動與拖拉提案-暫定.md`，build 77
- v2.21（多米 build 77 錄影：往右下拉整隻也要往右下靠；配音刺耳；要 lofi）：D1' 拉力 slide（拉長到果凍 0.6R、麻糬 0.9R、黏土 1.5R 就整團被拖走，兩指往兩邊拉不被拖走）；音效 v3 ASMR 版（起音 13 到 45 毫秒、峰值 −12 到 −24 dB）；程式作的原創 lofi `bgm-lofi.m4a`；喇叭三段。多米在試聽頁聽過點頭才進 app。build 79（拉力）、81（加聲音）
- v2.22（多米：還是沒有互動感；繼續做黏液）：E1 它會出聲（8 種共振峰合成的小哼聲）、E2 點／按／蹭／搔癢／被拖都有回應、E3 熟得快且姿勢顏色看得出、E4 熟的時候游過來打招呼、黏液（掉、飄、被吸回去、可以拖、推給你、搶回去，身體最少 0.85）。提案 `.uiux/04-手感/拉力互動聲音黏液提案-暫定.md`，build 86
- 修掉三個藏著的 bug：setup() 沒把拖拉偏移 DRAG 歸零（v2.20）、開心小跳被打斷時 INTRO.sq 沒歸零讓身體一直被撐開（v2.17 就有，只在網頁版）、搔癢計時器存絕對時間（v2.22）
- selftest 到 T37（37 項）：最後一次新頁面連跑 4 輪，後 3 輪全過，第 1 輪只有 T26 3.25（原本就有）
- CLAUDE.md 照多米點頭的草稿改了三次（v2.20、v2.21、v2.22）；測試紀錄補到第 12 輪與自測 0w 輪；lessons 加了 8 條
- 多米決定：E4 留著（11-02）

## 🚧 還沒做完 / 待決定

- build 86 沒人捏過，Swift 版的 v2.22（聲音、黏液、E1 到 E4）只確認雲端編譯過，沒在手機上跑過。要問多米：有沒有比較像在跟你互動、哼聲可不可愛、黏液好不好玩、手機喇叭上音量夠不夠（音效整體小了 8 到 12 dB）、lofi 接回開頭聽不聽得出接縫、拖著走對不對
- 之前一直沒回的：休息會不會太安靜、一縮一衝像不像在游、開場可不可愛、呼嚕舒不舒服、凹痕退得自不自然
- 待決定（CLAUDE.md「待決定」那段）：B2 40 秒沒人碰會睡著、C6 照你點的節奏回你、開場改成游過來、收集多種史萊姆等
- v2.21 第一次連跑 selftest 時第 1 輪多掛 4 項（T2、T12、T16、T25、T31），之後重跑都沒再出現，原因沒抓到。下次再出現先把整份結果存下來
- 舊帳：參數表 `.uiux/04-手感/參數表-暫定.md` 只同步到 v2.8；面板存 1／存 2 的舊數值裝新版可能讀不回來；閘門 3（延遲、最舊機低電量）沒量、盲測沒開始；身體超過約 8.5R 會抖

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 「力」是多米的原話：拖的時候整隻要被拉過去，拉長只是一部分。單指拉到 slide 就整團走，想拉很長用兩指或猛扯（三種材質都這樣，黏土 1.5R；面板可調）
- 聲音走 ASMR：起音慢、小聲、低通、濕細碎、不要卡通的啵。新聲音先放試聽頁給多米聽，點頭才進 app（v2.21 照這個做過）
- lofi 用程式合成的原創曲，品質像試聽版；多米給有授權的曲子就直接換 `bgm-lofi.m4a`，不准用沒授權的歌
- 印象只活在這一次打開 app，背景 10 分鐘歸零；熟不會因為你沒來而退
- E4 主動游過來打招呼：多米 11-02 決定留著（只在 app 開著時、一次最多 3 次、不發通知）
- 回歸測試一律關新功能，三種材質一起關（selftest 開頭把 PRESETS 全換成 OFF 版，跑完換回）；新版本各自一個 T 項

### 環境與設定（不變的事實，沿用上份並補新的）

- 多米沒有 Mac。編譯走 GitHub Actions，裝機走 TestFlight；build 號＝run number
- `swiftui-port` 有 Swift＋web＋docs；`main` 只放 web＋docs（Pages 自動發布）。推 main 的流程更新了（舊的會把新增的 iOS 檔帶過去，v2.22 帶了 32 個 wav，已移掉）：
  `git worktree add <scratchpad>/wt-main origin/main -B main-sync` → `git cherry-pick -n <hash>`（直接寫 hash，不要用範圍）→ `git checkout HEAD -- ios` → `git diff --cached --name-only --diff-filter=A -- ios | xargs -r git rm -q --cached` → 確認 `git diff --cached --quiet <hash> -- prototype .uiux CLAUDE.md` → `git commit -C <hash>` → 確認 `git diff --stat HEAD~1 HEAD -- ios` 是空的 → push 到 main → 移除 worktree 與分支
- 發 TestFlight：等 push 觸發的編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`；等編譯用 `gh run watch <id> --exit-status`
- 本機預覽：別的會話的 8765 伺服器常常不在。用 `preview_start` 名稱 `web-proto`（`E:\捏捏史萊姆\.claude\launch.json`，服務 `prototype/web`），網址根目錄就是原型 `http://localhost:8765/`
- 瀏覽器面板藏著時 `innerWidth` 是 0：先 `resize_window` mobile 再量
- selftest 一輪約 100 秒，跑的時候頁面不回應；連跑用 setTimeout 鏈、結果放 `window.__runs`。單獨跑對、整組跑錯：用「跑一段可疑動作，接著跑那個測試」逐段找（這次找到 INTRO.sq）；要比舊版就 `git show HEAD:prototype/web/index.html > prototype/web/__vXXX.html`，比完刪掉
- 聲音：`design_sfx.py` 預設 v3（含 voice），會同時寫 web 與 iOS 兩邊；`--v2` 只寫 `sfx/v2/`。`design_lofi.py --ios` 才寫 iOS。執行要 `PYTHONIOENCODING=utf-8 python ...`（主控台 cp950，`-I` 會忽略這個環境變數）
- 長的 Python 補丁腳本不要用 heredoc 塞進 bash（會壞），寫到 scratchpad 再 `python -I 檔案`
- Swift 這台電腦編譯不了，這次三次大改都一次過雲端編譯；複雜運算照舊寫明型別

## 📂 下個會話最重要的檔案

- `CLAUDE.md` ← 手感 v2.20 到 v2.22、互動（C1 到 C5、E1 到 E4）、黏液、聲音 v3
- `.uiux/04-手感/拉力互動聲音黏液提案-暫定.md` ← v2.21、v2.22 的提案與實作差異
- `.uiux/04-手感/手感測試紀錄-暫定.md` ← 最後面：真機第 11、12 輪，自測 0u、0v、0w 輪
- `.uiux/lessons.md` ← 最後 8 條是這次的
- `prototype/web/index.html` ← DRAG／slide（dragTarget）、IMP／LURE、E2／E4／DROPS（e2Step、e4Step、dropsStep、dropSeek）、tint、drawDrops
- `prototype/web/selftest.js` ← T35 到 T37；開頭 PRESETS 換 OFF 版
- `prototype/sfx-design/design_sfx.py`（v3 與 voice）、`design_lofi.py`；`prototype/web/sfx/engine.js`（voice、drip、背景音樂）、`listen.html`（新舊切換、它的聲音）
- `ios/NieNie/Slime/SlimeRig.swift`（同名函式）、`SlimeView.swift`（黏液圖層、tint）、`Feedback/SlimeAudio.swift`（voice、drip、AVAudioPlayer 背景音樂）、`App/SlimeController.swift`（三段喇叭、nudge、背景 10 分鐘歸零）

## ⏭️ 下一步從哪繼續

1. 先讀這份，再讀 CLAUDE.md 的「互動」「黏液」「聲音 v3」三段
2. 問多米 build 86 捏起來怎樣（他可能已經帶著回報來）。照「🚧」第一條的問題問。他說的是「感覺」就照老流程：網頁版用他說的材質、方向、距離重現，量出成因再改；兩版都改；selftest 連跑 4 輪；更新測試紀錄、lessons；CLAUDE.md 先寫草稿給他看；推兩個分支（用新的 main 流程）、發 TestFlight
3. 如果他說 Swift 版有東西不動、沒聲音、黏液沒出現：那是執行期問題（雲端只確認編譯過），先比對 SlimeRig.swift 與網頁版同名函式
4. 他覺得 v2.22 可以，就提下一步的選項讓他挑（B2 睡著、C6 節奏回應、開場改游過來、收集多種史萊姆），行動前先給計畫

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 「刺耳」不是高頻太多：量過 3 kHz 以上幾乎沒有，是起音快、太大聲、擠在 500 到 1800 Hz
- v2.20 的 D1（跟手三成五）已被 v2.21 的 slide 取代，slide 0 才回到 D1
- T28 掉到 0.76、T37 第二輪起搔癢沒反應：兩個都查完修好了（INTRO.sq、gigNext），不用再查
- main 誤帶 32 個 iOS 聲音檔：已在 main 補 commit 移掉，main 回到 18 個 iOS 檔
