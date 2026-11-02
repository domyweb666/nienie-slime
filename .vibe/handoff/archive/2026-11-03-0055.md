# Handoff: 第十一會話，v2.23 做完（黏液修正、眼睛、睡著、照節奏回你、開場游過來、收集四隻），build 89 已上傳，還沒被真機捏過；另外修了三筆舊帳

> 產出時間：2026-11-03 00:55
> 前一會話的最後狀態，給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

- 多米捏 build 86 回報：黏液不自然、形狀不自然、太容易掉、太多；還是沒有互動感（第三次）；想加表情看看；接著做睡著、照節奏回你、開場游過來、收集
- 多米選：表情只加眼睛（不加嘴）；收集一開始全部都有；四個新功能跟黏液、眼睛一起做
- v2.23（網頁＋Swift）：黏液 dropsV、眼睛 eyes、B2 睡著 sleep、C6 節奏 echo、開場游過來 introSwim、收集四隻（蜜蜜、薄荷、芋圓、桃桃）。提案 `.uiux/04-手感/眼睛睡著節奏收集提案-暫定.md`，build 89
- CLAUDE.md 照多米點頭的草稿改了（`.vibe/CLAUDE-md-v2.23-草稿.md`）；核心動作卡不做清單「表情與臉」改成試兩顆眼睛
- 舊帳（11-03，多米說等回報時先做）：
  - Swift 存 1／存 2 舊存檔讀不回：缺的參數用現在的值補（`SlimeController.decodeSlot`）
  - 參數表 `.uiux/04-手感/參數表-暫定.md` 從 v2.8 補到 v2.23，改成程式從 PRESETS／F／SLIMES 產生；網頁與 Swift 的黏土預設逐項比過，116 個一樣
  - selftest 第一輪 T26 老是掛：音效引擎載完檔之後每幀抽 Math.random，把固定種子的手抖錯開。selftest 期間音效改用真的亂數；T26 門檻 3 → 5 點（8 組手抖量到 1.18 到 4.21，真的抖是 13 以上）。新頁面第 1 輪就全過
  - 網頁面板兩條過時說明（拉伸上限、記形上限）改對
- selftest 到 T38（38 項）
- 測試紀錄補到第 13 輪、自測 0x、0y 輪；lessons 加了 3 條

## 🚧 還沒做完 / 待決定

- build 91 已上傳（11-03，含存 1／存 2 修正；第一次推上去在雲端排隊 15 分鐘被取消，重跑才過）。v2.23 的內容跟 build 89 一樣
- build 89／91 沒人捏過。要問多米（提案第七節）：有眼睛之後有沒有比較像在跟你互動、眼睛大小位置；黏液會不會變成太難掉、拉絲自不自然；40 秒睡著會不會太快；點節奏回得出來嗎；游過來的進場；四隻分不分得出來
- 待決定（CLAUDE.md）：眼睛留不留、四隻的外形種子（7、12、4、19 是 Agent 挑的）、連續紀錄、換背景
- 黏液甩出去後離身體不遠：黏土 0.6 秒後只離 0.32 到 0.37R（果凍、麻糬 2.3R），因為黏土拉長那條會跟過去。多米說太近再調
- 更早沒回的：休息會不會太安靜、一縮一衝像不像在游、呼嚕、凹痕；哼聲可不可愛、喇叭音量、lofi 接縫
- 舊帳剩：閘門 3（延遲、最舊機低電量）沒量、盲測沒開始；身體超過約 8.5R 會抖

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 沒有互動感的判斷：缺的是注視（它沒有眼睛，看不出它在看你），不是肢體反應不夠。眼睛是實驗，面板 eyes 0 回沒有臉
- 只加眼睛不加嘴；表情只用眼睛形狀：睜開（眨、瞇、睜大）、∩ 開心、> < 被扯、∪ 睡著
- 黏液只在猛扯「停下那一下」和用力甩放手才掉，從往拉方向最突出的外圈點、帶著尖端自己的速度甩出（在猛扯途中掉會被拉長那條追過去疊在身體上）
- 收集一開始全部都有，不做解鎖、扭蛋、每日任務；各隻印象分開記，只在這一次打開 app
- 回歸測試一律關新功能：selftest 開頭 PRESETS 換 OFF 版（v2.23 是 OFF23），T35 到 T37 用 P0（v2.23 關），T38 用 P1（全開）

### 環境與設定（不變的事實，沿用上份並補新的）

- 多米沒有 Mac。編譯走 GitHub Actions，裝機走 TestFlight；build 號＝run number。macOS 機器有時排隊十幾分鐘
- `swiftui-port` 有 Swift＋web＋docs；`main` 只放 web＋docs（Pages 自動發布）。推 main：
  `git worktree add <scratchpad>/wt-main origin/main -B main-sync` → `git cherry-pick -n <hash>` → `git checkout HEAD -- ios`（cherry-pick 在 ios 衝突時這步也會解掉）→ `git diff --cached --name-only --diff-filter=A -- ios | xargs -r git rm -q --cached` → 確認 `git diff --cached --quiet <hash> -- prototype .uiux CLAUDE.md` → `git commit -C <hash>` → 確認 `git diff --stat HEAD~1 HEAD -- ios` 是空的 → `git push origin main-sync:main` → 移除 worktree 與分支。main 的 ios 檔應該維持 18 個
- 發 TestFlight：等 push 觸發的編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`；等編譯用 `gh run watch <id> --exit-status`（超過 10 分鐘要放背景）
- 本機預覽：`preview_start` 名稱 `web-proto`，網址 `http://localhost:8765/`。瀏覽器面板藏著時 rAF 被節流：要看畫面就把 `requestAnimationFrame` 換成空函式、自己呼叫 `update(1/60)` 和 `draw()`；截圖看細節時把那塊 canvas 畫到一個放大的覆蓋 canvas 上再截
- selftest 一輪約 2 分鐘，跑的時候頁面不回應（javascript_tool 會逾時，隔一下再問 `window.__runs`）。連跑用 setTimeout 鏈
- 只想重跑某一項：抽 `selftest.js` 開頭到「// T1 輕按」＋那一項的區塊＋收尾，eval
- Swift 這台電腦編譯不了，v2.23 的大改雲端一次過；複雜運算照舊寫明型別
- 長的 Python 補丁寫到 scratchpad 再 `python -I 檔案`；取代字串找不到或出現兩次要停下來（這次 SlimeCanvas 那行出現兩次，順序調過才套上）

## 📂 下個會話最重要的檔案

- `CLAUDE.md` ← 風格（眼睛）、手感 v2.23、互動（眼睛、B2、C6）、黏液、收集
- `.uiux/04-手感/眼睛睡著節奏收集提案-暫定.md` ← v2.23 的設計、量到的數字、要問多米的六題
- `.uiux/04-手感/參數表-暫定.md` ← 程式產生的總表（四隻個性、三種材質全部參數、只在 Swift 的觸覺聲音）
- `.uiux/04-手感/手感測試紀錄-暫定.md` ← 最後面：真機第 13 輪，自測 0x、0y 輪
- `prototype/web/index.html` ← dropSpawn／tipAlong／dropFromTip／dropPts／drawStrands、EYE／eyeStep／drawEyes、SLP／sleepTry／wake、ECHO／echoStep、swimIntro／swimGreet、SLIMES／chooseSlime
- `prototype/web/selftest.js` ← T38；開頭 OFF23、音效改用真的亂數
- `ios/NieNie/Slime/SlimeRig.swift`（同名函式，eyeView、strandViews）、`SlimeView.swift`（眼睛、絲、水滴形）、`FeelParams.swift`（SlimeKind）、`App/SlimeController.swift`（select 換史萊姆、impressions、decodeSlot）、`UI/ContentView.swift`（底部四隻）、`UI/TunePanel.swift`（材質按鈕）

## ⏭️ 下一步從哪繼續

1. 先讀這份，再讀 CLAUDE.md 的「風格」「互動」「黏液」「收集」
2. 跟多米說用 build 91 捏（有存 1／存 2 修正）
3. 問多米 build 91捏起來怎樣，照提案第七節六題問。他說的是「感覺」就照老流程：網頁版用他說的材質、方向、距離重現，量出成因再改；兩版都改；selftest 新頁面連跑 3 輪以上；更新測試紀錄、lessons；CLAUDE.md 先寫草稿給他看；推兩個分支（main 流程）、發 TestFlight
4. 他覺得眼睛不對：先問是大小、位置、還是根本不要；面板 eyes 0 就是沒臉。不要又在肢體反應那層加東西

## 🗑️ 這次會話的雜訊（下次別重新討論）

- T26 第一輪 3.25：查完了，是音效引擎抽亂數，不是物理，已修
- 黏液第一版疊在身體上、第二版被拉長那條追過去：已改成停下那一下從尖端甩出，不用再試
- 網頁版材質切換本來就不換顏色（只有 Swift 換），v2.23 起顏色跟史萊姆走，兩版一樣了
- Swift 的 setup() 會把時鐘歸零（網頁不會）：存絕對時間的計時器兩邊都要防「時鐘倒回」，眨眼已經防了
