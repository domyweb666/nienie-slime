# Handoff: 第十五會話，網頁版換上果凍皮與窗台（重力、碗），背景音樂無縫循環，等多米捏過選皮

> 產出時間：2026-11-06 03:33
> 給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

- 評估多米給的窗台果凍參考原型，寫成 `.uiux/04-手感/窗台果凍參考評估-暫定.md`：拿外觀、窗台、新玩法，身體留現在這套
- 做靜態對照圖（`.uiux/04-手感/果凍皮對照/`），再把果凍皮接進網頁即時畫面，邊捏邊切
- 多米定案圓身體、有臉、不要 8 條腿；網頁與 Swift 預設都改了
- 網頁版做好窗台：重力、坐進碗、跳、沿窗台走、黏窗、閒著回碗、黏液落在窗台、鏡頭固定
- 背景音樂修成無縫循環（網頁已生效，iPhone 要下次 TestFlight）
- selftest 加 T43、T44，連跑 3 輪 45 項全過。`swiftui-port` 在 `148e061`，`main` 已同步、Pages 已確認上線；雲端編譯 run 103 通過

## 🚧 還沒做完 / 待決定

- 皮選 A 清透還是 B 奶凍：多米還沒定，等他看過坐進碗的樣子
- 多米還沒捏窗台版；手感、iPhone Safari（WebGL2、RGBA16F）、手機幀時間都沒驗。標題旁有每幀毫秒數，是手機效能的第一個數字
- 心情變色放在果凍上，戒備時灰綠、拉扯時粉紅，有點髒。建議染色 0.8 降到約 0.35，等多米看過
- 部分種子坐在碗裡會垂出一塊（薄荷最明顯）。多米想像四隻角色圖那樣圓，要調 `floppy` 或挑種子
- 腮紅碰到不做清單的「眼睛以外的表情」，目前先留，多米沒明確點頭
- 果凍皮、窗台都還沒移植 Swift。Swift 目前只有圓身體、有眼睛、新音樂檔，還是平塗、懸空。果凍皮要換 Metal（現在是 CAShapeLayer）
- 手指痕跡在果凍皮上沒畫；外框互疊在果凍皮上看不看得出來沒驗到（亂拖 120 輪沒拖出互疊）
- 自己沿窗戶往上爬沒做，現在是跳上窗戶再滑下來；跳出碗比目標短約 35 點，原因沒查
- 後面排隊的玩法：兩指拉斷與合體（可用「遮罩模糊後切門檻」做融合）、餵煩惱、一起呼吸、含小東西
- `.vibe/CLAUDE-md-v2.24` 到 `v2.28-草稿.md` 都等多米點頭才改 `CLAUDE.md`。`CLAUDE.md` 現在寫的（懸空、平塗）已經落後
- build 99 的回報還在等：側邊快拖、摸兩三下舒不舒服、觸覺階梯「單下」「連續」最小各哪一格
- 舊帳：閘門 3 沒量；一個參數都沒盲測過；新的手 0 輪；核心動作卡沒過閘門 1；`README.md` 過時

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 身體留現在的 518 顆粒子，不換參考版的身體（拉 2R 就斷、2.4 秒甩回圓，跟多米 build 53、59 的回報相反），也不用 metaball
- 果凍皮做法：外框加黏液和絲畫成遮罩 → 半解析度模糊 0.07R、八分之一解析度模糊 0.42R → 當高度算法線 → 打光。差分距離要剛好一格貼圖（2 點、8 點），不然亮點有鋸齒
- 圓身體、有臉、不要 8 條腿（多米 11-06）。第十四會話的觸手待驗都不用再問
- 背景藍＝懸空，白天、夜晚＝窗台；窗台全部掛在 `SILL.on`，藍底舊行為一條不動，selftest 舊項目一律跑藍底
- 空中不加阻尼（`damp=1`），碰到東西才恢復；上下交給重力，`HOMEY` 跟著身體；`moveHome` 在窗台不動 y
- 碗正上方放手掉進碗；其他地方慢放才黏窗；用力甩就掉。判斷用手指位置，不用重心（黏土被拉長時重心還在碗上）
- 碗口碰撞在碗高 0.5，碗的前半畫在身體前面；窗台上身體 0.27、碗 205 點寬、黏土拉伸 3.2R、記形 2.6R
- 背景音樂：AAC 頭尾會墊空白。網頁頭尾各多寫 1 秒週期內容、只循環中間；iPhone 用 ALAC，長度對齊 4096。濾波要繞一圈才接得起來。換曲子要跑 `design_lofi.py --ios`，不能直接換檔
- 先前仍有效的：strokeV 400；只放大對手指的反應；摸跟抓拿不準就算抓；互撞不是硬牆；TestFlight 等多米開口才發；其他 Agent 替多米選的都在 `.vibe/代決清單.md`

## 🧰 環境與流程（不變的事實）

- 多米沒有 Mac。編譯走 GitHub Actions，裝機走 TestFlight；build 號＝run number；動到 `ios/` 的 push 會自動跑一次只編譯的檢查，不會上傳
- 要發 TestFlight：等 push 觸發的編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`；等編譯用 `gh run watch <id> --exit-status`
- 目前攢著等發的：圓身體、有眼睛、無縫音樂。TestFlight 最新還是 build 101
- `swiftui-port` 有 Swift＋web＋docs；`main` 只放 web＋docs（Pages 自動發布）。推 main：`git worktree add <scratchpad>/wt-main origin/main -B main-sync` → 刪掉的檔案先 `git rm --ignore-unmatch` → `git checkout <hash> -- prototype .uiux .vibe CLAUDE.md` → 確認 `git diff --cached --name-only -- ios` 是空的 → `git commit -C <hash>` → `git push origin main-sync:main` → 移除 worktree 與分支
- 網頁網址：`https://domyweb666.github.io/nienie-slime/prototype/web/index.html?v=229`。改版就換 `?v=`，手機才不會吃快取
- 本機預覽：`preview_start` 名稱 `web-proto`，`http://localhost:8765/`，viewport 393×852。預覽伺服器會快取，導覽時要加 `?v=`
- 面板藏著時 rAF 不跑：把 `requestAnimationFrame` 換成空函式，自己呼叫 `update(1/60)`、`draw()`，再截圖
- 跑 selftest 放進固定 393×852 的 iframe（`iframe.contentWindow.eval(src)`），一輪約 4 分鐘，跑的時候 javascript_tool 會逾時，用 `ping -n 110 127.0.0.1` 等一段再問；結果放 `window.__runs`
- 只跑某一項：`selftest.js` 開頭到「// T1 輕按」＋該區塊＋收尾（還原 VIEW、PRESETS、rAF）。T44 用 `P27.clay`，因為開頭把 PRESETS 換成舊版了
- 補丁用 Write 寫 python 檔再 `python -I`，路徑用 r 字串，每個取代都檢查次數；shell heredoc 裡反斜線會少一半。素材放進 Downloads 以外的路徑前都走 `python -I`
- Swift 這台電腦編譯不了。limrun：`npx -y lim@0.51.0`，測完立刻刪自己開的實例；校正數字在記憶 `reference_limrun_gestures`。`SlimeHaptics.swift` 是 CRLF，其他 Swift 檔是 LF

## 📂 下個會話最重要的檔案

- `.uiux/04-手感/窗台果凍參考評估-暫定.md` ← 評估、衝突表、施工順序
- `.uiux/04-手感/手感測試紀錄-暫定.md` ← 最後面第 0af、0ag 輪
- `.vibe/標準清單.md`（最後兩節 v2.28）、`.vibe/代決清單.md`、`.vibe/CLAUDE-md-v2.28-草稿.md`
- `prototype/web/index.html` ← 窗台：`SILL`、`sillGeo`、`sillInit`、`sillHit`、`sillHop`、`sillLaunch`、`sillGo`、`sillStep`；皮：`VIEW`、`viewOver`、`JSKINS`、`jelRender`、`drawBlush`；背景：`sceneFor`、`bowlFront`、`drawBowlFront`
- `prototype/web/selftest.js` ← T43、T44
- `prototype/web/sfx/engine.js`（`BGM_PAD`）、`prototype/sfx-design/design_lofi.py`、`prototype/sfx-design/make_scene_assets.py`
- `ios/NieNie/Slime/FeelParams.swift`（新預設）、`ios/NieNie/Feedback/SlimeAudio.swift`（音樂檔）

## ⏭️ 下一步從哪繼續

1. 讀這份。
2. 第一句話問多米窗台捏起來怎樣：掉進碗、拉起來、甩到窗台、黏窗、走路、回碗的時機；A、B 選哪個；標題旁每幀幾毫秒（手機第一次量到）。還在捏就等，先不要動程式。
3. 照回報走：
   - 選定皮：`viewSync`、切換列拿掉另一個，`VIEW.skin` 預設改選定的。
   - 心情變色太髒：面板「心情變色」試 0.35，多米點頭再改預設。
   - 坐不進碗、坐得太高：`sillGeo` 的 `rim`（0.5）、`bf`、`cav`；身體大小在 `viewOver` 的 `bodySize`。
   - 太容易或太難黏窗：`sillStep` 裡的 `sp<R*2.5`。
   - 掉太快太慢：`SILLG`（14）。跳的高度在 `sillLaunch`，出門機率在 `sillGo`。
   - 回碗太快太慢：`sillStep` 最後一行的 12 秒。
   - 手機卡：先看每幀毫秒數，再降 `jelRender` 的模糊半徑或解析度。不要憑感覺優化。
   - 白畫面或「不支援果凍皮」：問機型與 iOS 版本，查 WebGL2 和 RGBA16F。
   - 身體想更圓：先畫靜態圖給多米挑 `floppy` 或種子，再改。
4. 窗台定了才移植 Swift，順序照標準清單：先定皮 → 果凍皮換 Metal 並量閘門 3 → 窗台物理（同名函式）→ limrun 實測後刪實例 → TestFlight 等多米開口。
5. 多米說做新玩法：先加進 `.vibe/標準清單.md`，再網頁、selftest 加 T45 連跑 3 輪、紀錄、推 `swiftui-port`、推 main、更新交接檔。

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 不要再比 metaball：比過了，差別都寫在評估檔
- 靜態對照圖的 C 霧面、平塗已經被多米排除；`JSKINS.C` 只留給 T43，切換列沒有
- 窗台上進碗判定第一版沒限制高度，開場一幀進一幀出，已修
- 舊 m4a 的接縫跳動量起來不大，真正的問題是解碼器墊空白，不用再量舊檔
- 能量比例量不出接縫（音樂本身每拍會掉到三成），看「接縫跳動 vs 平常 p99」才準
