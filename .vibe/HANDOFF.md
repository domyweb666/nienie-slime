# Handoff: 第十二會話，手感診斷＋v2.24 做完（身體放大、對手指的反應放大、揉打通、畫面不在手指底下滑），build 93 已上傳，等多米捏

> 產出時間：2026-11-04 09:33
> 前一會話的最後狀態，給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

- 多米 11-04 問：手感做到極致，要像真的生物、會互動，捏揉按的體感要好。我量完寫了 `.uiux/04-手感/手感診斷-暫定.md`：身體 3 公分寬、按著時的反應不到 1 毫米、放手 33 毫秒彈完、一般手速的揉沒反應、揉時觸覺約 0.05、狀態不改物理。F1 到 F10 分四版
- 多米按「開始做 v2.24」。網頁與 Swift 都做了：F1 身體 0.30、F2 縮傾蹭看放大、臉躲手指、F3 揉 rubSpeed 12、搔癢 tickRev 6 與 tickSeg 48、掙脫 6 秒、補抓 reachV。量到才加的：camGrip（抓著時畫面不滑，v2.23 拉 70 點差 79 點、往下 300 點差 145 點）、pressLocal（按著不動只有手指附近記形，折角 50 度變 18 度）、leanMove、搔癢不記形
- selftest 到 T39（40 項），新頁面連跑 3 輪全過；relaxClearsMark 門檻 1 改 1.5（呼吸相位雜訊 0.87 到 1.01，壞掉時 19）
- Swift 雲端編譯一次過、沒有警告（run 92），TestFlight build 93 已上傳；`main` 已同步
- 參數表從程式重新產生到 v2.24；測試紀錄第 0z、0aa 輪；lessons 加 9 條；`.vibe/` 新增標準清單、黃金行為、代決清單

## 🚧 還沒做完 / 待決定

- 多米還沒捏 build 93。Swift 版的 v2.24 只確認編譯過，沒看過它在手機上跑
- 要問多米：身體 0.30 會不會太大、走路出畫面可不可以；揉 1.3 秒呼嚕來得對不對；縮、靠過去、蹭、臉滑會不會太誇張；很快小撥才算搔癢好不好觸發；拉著停住有沒有比較跟手；拉長時鏡頭退得夠不夠（v2.13 多米要「拉多大推多遠」）
- `.vibe/CLAUDE-md-v2.24-草稿.md` 等多米點頭才改 `CLAUDE.md`
- 接下來照診斷第二節：v2.25（F4 參考形狀帶慣性、F5 觸覺重做）、v2.26（F6 摸跟抓分開、F7 手指旁邊看得到）、v2.27（F8 肌肉、F9 自己收回形狀、F10 手指下的呼吸）。F4 的實驗數字在診斷第一節第 3 點，黏土有 8 幀交叉要先解
- 舊帳：閘門 3（延遲、最舊機低電量）沒量；一個參數都沒盲測過；新的手 0 輪；核心動作卡沒過閘門 1；`README.md` 過時
- 更早沒回的：v2.23 眼睛留不留、四隻的外形種子；黏液、睡著、節奏好不好玩

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 反應的數量夠了（60 秒自然玩法 14 到 15 種），先不加新反應種類；缺的是看得到、有重量、接觸、觸覺、狀態改物理
- 只放大對手指的反應，休息時的呼吸與蠕動比例不動（多米 v2.11：自身形變不要太大）
- 跟手要量螢幕座標，手指真實位置對被抓那塊畫出來的位置
- 回歸測試：舊項目與 T35 到 T38 一律回 v2.23（OFF24），v2.24 只在 T39 測（用 PSAVE 全開）
- 面板候選「v2.23 對照」全部回 v2.23，舊對照都疊在 off24 上

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
- 抽 selftest 開頭除錯（2026-11-04 踩到）：它會把 PRESETS 換成關新功能的版本，收尾要 `Object.assign(PRESETS, PSAVE)` 或重新載入頁面，每輪先印 R 分辨版本；shell 一次貼兩個 heredoc 會解析失敗，補丁用 Write 寫檔再 `python -I`
- 參數表重新產生：抽 index.html 從 `const PRESETS={` 到 `// v2.24 對照：身體` 那段 eval，照 F 的順序換掉第二節表格，第一節與第三節手動

## 📂 下個會話最重要的檔案

- `.uiux/04-手感/手感診斷-暫定.md` ← 量到的數字、F1 到 F10、v2.24 的實作差異、查證紀錄
- `.uiux/04-手感/手感測試紀錄-暫定.md` ← 最後面：自測 0z、0aa 輪
- `.vibe/標準清單.md`、`.vibe/黃金行為.md`、`.vibe/代決清單.md`、`.vibe/CLAUDE-md-v2.24-草稿.md`
- `prototype/web/index.html` ← OFF24、updateCam（camGrip、CAMR）、reachGrab、plasticity（pressLocal）、moodStep、e2Step（tickOn、tkP）、eyeStep（dodge）、drawEyes
- `prototype/web/selftest.js` ← T39
- `ios/NieNie/Slime/SlimeRig.swift`（同名函式）、`FeelParams.swift`（off24）、`SlimeView.swift`（lookX、lookY）

## ⏭️ 下一步從哪繼續

1. 先讀這份，再讀診斷第二節
2. 第一個動作：問多米 build 93 捏了沒。他說要做 v2.25 就照診斷做，說哪裡不對就先調 v2.24
3. 他說 Swift 版有東西不動、沒聲音、臉不見，那是執行期問題（雲端只確認編譯過），先比對 `SlimeRig.swift` 與網頁版同名函式。他說的是「感覺」就照老流程：網頁版用他說的材質、方向、距離重現，量出成因再改；兩版都改；selftest 新頁面連跑 3 輪以上；更新測試紀錄、lessons；CLAUDE.md 先寫草稿；推兩個分支（main 流程）、發 TestFlight
4. 他嫌放大太大或太小：面板「身體大小」範圍 0.15 到 0.40，超過約 0.34 鏡頭靜止時就會縮，要先調 camPad

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 按壓變化大多被手指擋住、反應觸發太少：這兩個是我的猜測，量了都不成立（可見像素佔八成，反應 14 到 15 種）
- 外框尖角試過提高定型門檻、撫平記憶裡的尖角，都傷留形，不用再試
- 搔癢段長量兩點直線距離會量短，已改累加路徑
- 第三輪 relaxClearsMark 是呼吸相位造成的壓線，已查清
