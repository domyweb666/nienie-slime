# Handoff: 第十七會話，v2.30 環境互動跑起來、上線；走路網頁片做完；發 TestFlight build 106（只多讀步數）

> 產出時間：2026-11-07 14:23
> 給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

已上線（`?v=232`，程式在 `215e9ff`，之後只有文件；`swiftui-port`、`main` 都已推，沒有沒存檔的改動）：

- v2.30 環境互動第一次跑：修了爬升判定、換層時機、窗框層落地、偽足揮空、擺飾衝量與停止、放手落點、嚇跑跳不出碗。細節在手感測試紀錄第 0ai 輪
- 走路網頁片：面板「走路：假裝 800 步／3500 步／全部重來」。牠從窗外爬回來，身上黏一件小東西，捏一下掉，留在窗框下緣；放著 20 秒自己掉；第二次打開送石頭，點了才問；一天最多三件；放滿 6 件擠掉最舊的。細節在第 0aj 輪
- selftest 48 項（新增 T46 環境、T47 走路）連跑 3 輪全過。T45 改成把碗放回中間量，亂拉路徑在碗移左後會跑到畫面外
- 提案：`.uiux/04-手感/走路提案-暫定.md`、`吹氣提案-暫定.md`（有查原文的研究限制）
- 閘門 1 的測試清單：`.uiux/07-測試/閘門1-三個測試.md`，等多米找人測
- TestFlight build 106（run 42135475761，上傳成功）：手機版只多面板「走路：讀步數」，加 `NSMotionUsageDescription`

## 🚧 還沒做完 / 待決定

- 多米要做的：裝 build 106，打開面板按「走路：讀步數」，回報讀不讀得到、幾天前開始變 0；網頁親手摸 v2.30 和走路（`標準清單.md` 最後兩節）；找人做閘門 1 三個測試
- 第 0ai 輪標的沒驗到：爬的樣子偏飄（重力關掉一縮一衝往上抬，多米還沒看過）；貓推擺飾的力道；盆栽離窗台右端只有 7 點，輕推就掉
- 走路還沒做的：東西素材（現在是程式畫的佔位）、Swift 接真步數、Swift 的權限流程
- 手機版：防打結、眼睛、果凍皮、窗台、環境互動、走路玩法都還沒移植，這是下一個最大的工
- 上一輪多米還沒回的：心情變色在果凍上有點髒（建議 0.35）、部分種子坐碗裡垂一塊（薄荷最明顯）、腮紅碰到不做清單、標題旁每幀毫秒數
- 排隊的玩法：兩指拉斷與合體、含小東西（要半透明皮）。吹氣排在走路後面，走路做完再決定
- `.vibe/CLAUDE-md-v2.24` 到 `v2.30-草稿.md` 都等多米點頭才改 `CLAUDE.md`
- 舊帳：閘門 3 沒量、沒盲測過、新的手 0 輪、核心動作卡沒過閘門 1、買實物沒做、`README.md` 過時

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 多米 11-06：現實連結要走路（最早就想做成像皮克敏），吹氣排後面；好事彈珠、煩惱紙條拿掉；「都先一起做」：網頁片跟閘門 1 測試同時進行
- 走路的規則：牠黏著東西回來，弄下來就是捏；不顯示步數，沒有目標、連續天數、圖鑑、稀有度、通知；沒走沒有損失。可以借走路機制，皮克敏的角色、畫面、種花不碰
- 東西放窗框下緣，放不到窗台（窗台要繞過碗，約 15 秒）。露出約 90 點，放 6 件。放滿擠掉最舊的（代決）
- 權限：第二次打開送石頭，點了才問。沒有權限就無從知道走了多少，所以「第一次撿到才問」做不到
- 放手落點：身體下緣在碗後緣下面 0.5R 以內算不重疊（0.35R 壓在門檻邊會時好時壞）
- 擺飾衝量：慢慢碰每小步最多 1.5，撞得快才放大；推力 1.3
- 先前仍有效的：皮 A、B 先不選；黏液取消；手感定基準，手感層只為基準表的數字改；身體留現在這套；背景藍＝懸空，舊行為不動；TestFlight 等多米開口

## 🧰 環境與流程（不變的事實）

- 多米沒有 Mac。編譯走 GitHub Actions，裝機走 TestFlight；build 號＝run number；動到 `ios/` 的 push 會自動跑一次只編譯的檢查，不會上傳
- 要發 TestFlight：等 push 觸發的編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`
- `swiftui-port` 有 Swift＋web＋docs；`main` 只放 web＋docs（Pages 自動發布）。推 main：`git worktree add <scratchpad>/wt-main origin/main -B main-sync` → `git checkout <hash> -- prototype .uiux .vibe CLAUDE.md` → 確認 `git diff --cached --name-only -- ios` 是空的 → `git commit -C <hash>` → `git push origin main-sync:main` → 移除 worktree 與分支
- 網頁網址：`https://domyweb666.github.io/nienie-slime/prototype/web/index.html?v=232`。改版就換 `?v=`
- 本機預覽：`preview_start` 名稱 `web-proto`，`http://localhost:8765/`，viewport 393×852
- 面板藏著時 rAF 不跑：把 `requestAnimationFrame` 換成空函式，自己呼叫 `update(1/60)`、`draw()`。要看動作就把多幀畫到一張蓋在上面的 canvas（分鏡），截圖前先 `resize_window`，常要等幾秒重試；畫面放大或重複是面板的問題，數字以 `getBoundingClientRect` 為準
- selftest：放進固定 393×852 的 iframe，`ifr.contentWindow.eval(src)`，結果存 `localStorage`（頁面可能被重新載入，`window` 上的會不見）。一輪約 5.3 分鐘，跑的時候 javascript_tool 會逾時，等下一輪之間才問得到。除錯只跑一段：`src.slice(0, src.indexOf('  // T1 輕按')) + '  res.PASS={};\n' + src.slice(src.indexOf('  // T44 v2.28'))`，約 1 分鐘
- 測試跑的時候不准改 `index.html`：每輪開始才載入，改了會混到不同版本
- 補丁用 Write 寫 python 檔再 `python -I`（heredoc 帶中文會壞），每個取代都檢查次數
- Swift 這台電腦編譯不了。limrun：`npx -y lim@0.51.0`，測完立刻刪自己開的實例。`SlimeHaptics.swift` 是 CRLF，其他 Swift 檔是 LF

## 📂 下個會話最重要的檔案

- `.vibe/標準清單.md` 最後兩節 ← v2.30、走路的驗收
- `.uiux/04-手感/走路提案-暫定.md`、`吹氣提案-暫定.md`
- `.uiux/07-測試/閘門1-三個測試.md`
- `prototype/web/index.html`：搜尋「v2.30 環境互動」「走路（多米 11-06」
- `prototype/web/selftest.js` T46、T47
- `ios/NieNie/UI/StepProbe.swift`

## ⏭️ 下一步從哪繼續

1. 第一句話問多米三件事有沒有結果：build 106 的步數讀到幾天前開始變 0、網頁摸起來怎樣（尤其爬的樣子）、閘門 1 測試做了沒。到交接為止一項都還沒收到。
2. 有回報就照回報改，一次改一件。步數的結果記進 `.uiux/04-手感/走路提案-暫定.md` 的「查得到多久以前」，現在那裡寫的 7 天是別人的回報。
3. 多米沒回報、也沒指定別的，下一件是把窗台移植到手機版，不然真步數接不上畫面。先不要動程式：比對 `prototype/web/index.html` 跟 `ios/NieNie/Slime/SlimeRig.swift`、`ios/NieNie/App/SlimeController.swift`，列出要移植的批次（防打結、眼睛、果凍皮、窗台、環境互動、走路）和每批怎麼驗，給多米點頭才開工。這台電腦編譯不了 Swift，每批都要靠 push 觸發的編譯檢查；TestFlight 累積一批，等多米開口才發。

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 網頁測試頁測麥克風還沒做，吹氣排後面了
- 第一次全跑時頁面被重新載入、結果沒存到，所以結果一律存 `localStorage`
- 擺飾衝量拿掉上限（兩個都飛）、落點門檻 0.35R（時好時壞）都試過，沒留
