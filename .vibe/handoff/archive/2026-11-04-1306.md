# Handoff: 第十三會話，limrun 上第一次跑 Swift 版，修了兩個問題，build 99 已上傳

> 產出時間：2026-11-04 13:06
> 給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

- 多米改用 limrun。v2.24 到 v2.26 的 Swift 第一次實際執行，沒有閃退，按、拉、揉、摸、兩指、果凍放手的晃都有動作。數字在 `.uiux/04-手感/手感測試紀錄-暫定.md` 第 0ad 輪
- 修 v2.26.1（build 99）：開心和睡著時兩隻眼睛之間那條線拿掉；strokeV 150 改 400，側邊快拖抓得住；判斷摸或抓的那幾幀算進舒服
- selftest 42 項連跑 3 輪全過。T41 摸的手指改每秒 500 點，加側邊快拖一項
- 雲端編譯 run 98 過；TestFlight build 99 上傳成功；`swiftui-port`、`main` 都已同步

## 🚧 還沒做完 / 待決定

- 多米還沒捏 build 99，也還沒回報 build 97 那批問題（下面第 2 點）
- Swift 版「摸三下會舒服」沒驗成：試 3 次，身體走開，手指沒打中。網頁版有驗（呼嚕 0.63）
- 起手就很快的拖法（80 毫秒超過 32 點、方向不是往外）現在還是算摸，只有真機知道夠不夠
- 量到但沒動：搔癢扭動很小（寬度變 16 點、重心動 6 點）；黏土放手 2 秒約留六成（標準約八成，網頁 T41 是 0.73，量法不同，只跑一次）
- 完全沒有測過的：F5 觸覺、聲音、真實延遲、接觸面變大算抓，模擬器都量不到
- 等多米回答。v2.26：摸得舒不舒服、手指旁邊那一圈和痕跡好不好看。v2.25：放手晃得對不對、果凍 9 下會不會太久、拖到停會不會飄、一粒一粒舒不舒服、觸覺階梯「單下」「連續」最小各哪一格。v2.24：身體會不會太大、揉 1.3 秒呼嚕來得對不對、反應會不會太誇張
- `.vibe/CLAUDE-md-v2.24-草稿.md`、`CLAUDE-md-v2.25-草稿.md`、`CLAUDE-md-v2.26-草稿.md` 等多米點頭才改 `CLAUDE.md`
- v2.27（F8 肌肉、F9 自己收回形狀、F10 手指下的呼吸）還沒做，等捏完再決定
- 舊帳：閘門 3（延遲、最舊機低電量）沒量；一個參數都沒盲測過；新的手 0 輪；核心動作卡沒過閘門 1；`README.md` 過時
- 更早沒回的：v2.23 眼睛留不留、四隻的外形種子；黏液、睡著、節奏好不好玩

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- strokeV 定 400，多米同意。試過 300，是我誤判呼嚕低跟門檻有關，真正原因是判斷時間沒算進舒服
- limrun 以分鐘計費，測完立刻刪自己開的實例；別的專案（`project=` 標籤）的不動
- limrun 量動作有沒有發生，手感驗收照舊要真機和沒看過的人
- 反應的數量夠了（60 秒自然玩法 14 到 15 種），先不加新反應種類；缺的是看得到、有重量、接觸、觸覺、狀態改物理
- 只放大對手指的反應，休息時的呼吸與蠕動比例不動（多米 v2.11：自身形變不要太大）
- 跟手要量螢幕座標：手指真實位置對被抓那塊畫出來的位置
- 手上的感覺用顆粒，跟手指走的距離綁在一起；連續觸覺只留給呼嚕。按住時吸氣那一下、E2 輕頂算它自己的動作，留著
- 放開手指的路徑都要接 inertiaCatch，掙脫和摸接手都算
- 摸跟抓拿不準就算抓：判錯成摸會覺得抓不住，判錯成抓只是回到 v2.25
- 摸不推真的粒子，推參考形狀 QD：硬推整團會被頂走，手指穿不過外框
- 回歸測試分層：舊項目與 T35 到 T38 回 v2.23（OFF24，含 OFF25、OFF26），T39 回 v2.24（OFF25），T40 回 v2.25（OFF26），T41 全開
- 面板候選「v2.25 對照」回 v2.25，「v2.24 對照」回 v2.24，舊對照都疊在 off24、off25、off26 上
- 其他 Agent 替多米選的（顆粒間距 12、摸完回原位等）都在 `.vibe/代決清單.md`

## 🧰 環境與流程（不變的事實）

- 多米沒有 Mac。編譯走 GitHub Actions，裝機走 TestFlight；build 號＝run number；只有動到 `ios/` 或 workflow 的 push 才會編譯
- `swiftui-port` 有 Swift＋web＋docs；`main` 只放 web＋docs（Pages 自動發布）。推 main：
  `git worktree add <scratchpad>/wt-main origin/main -B main-sync` → `git cherry-pick -n <hash>` → `git checkout HEAD -- ios`（cherry-pick 在 ios 衝突時這步也會解掉）→ `git diff --cached --name-only --diff-filter=A -- ios | xargs -r git rm -q --cached` → 確認 `git diff --cached --quiet <hash> -- prototype .uiux CLAUDE.md` → `git commit -C <hash>` → 確認 `git diff --stat HEAD~1 HEAD -- ios` 是空的、ios 檔維持 18 個 → `git push origin main-sync:main` → 移除 worktree 與分支
- 發 TestFlight：等 push 觸發的編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`，上傳完才能再推同一條分支；等編譯用 `gh run watch <id> --exit-status`，放背景跑
- limrun：`npx -y lim@0.51.0`，這台電腦的登入是所有專案共用的。`lim xcode create --ios` 開機器（加 `--label project=nienie-slime`、`--inactivity-timeout 10m`），`lim xcode build ./ios --id <sandbox> --xcodegen-spec project.yml --scheme NieNieSlime --configuration Release --sdk iphonesimulator` 約 1 分鐘編好並裝進模擬器。測完 `ios delete`、`xcode delete`。手勢腳本沒進專案，校正數字在記憶 `reference_limrun_gestures`：`wait` 3 約 18 毫秒、雙指用 `x2`、`y2`、手勢前截圖定位要算進身體會走開
- 本機預覽：`preview_start` 名稱 `web-proto`，網址 `http://localhost:8765/`，viewport 設 393×852
- 瀏覽器面板藏著時 rAF 被節流、截圖會逾時。要看畫面：把 `requestAnimationFrame` 換成空函式，自己呼叫 `update(1/60)` 和 `draw()`，畫到一個 canvas，toBlob 後 POST 到本機小伺服器（node 寫的，收到就存進 scratchpad，用完關掉），再用 Read 看圖
- 跑 selftest 放進固定 393×852 的 iframe（`iframe.contentWindow.eval(src)`）：面板的手機尺寸在回合結束會被清掉，R 從 118 變 160，那輪會多一堆假失敗
- selftest 現在一輪要幾分鐘，跑的時候頁面不回應，javascript_tool 會逾時，隔一下再問。連跑用 setTimeout 鏈，結果放 `window.__runs`；重新載入頁面就沒了，數字要先抄
- 只想重跑某一項：抽 `selftest.js` 開頭到「// T1 輕按」＋那一項的區塊＋收尾，eval。它會把 PRESETS 換成關新功能的版本，收尾要 `Object.assign(PRESETS, PSAVE)` 或重新載入，每輪先印 R 分辨版本
- Swift 這台電腦編譯不了，v2.23 以來的大改雲端都一次過；複雜運算照舊寫明型別
- 補丁一律用 Write 寫成 python 檔再 `python -I 檔案`，路徑用 r 字串，每個取代都檢查次數，全對才寫檔。shell 的 heredoc 裡反斜線會少一半，一次貼兩個 heredoc 也會解析失敗。換行字元用 chr(13)、chr(10)：`SlimeHaptics.swift` 是 CRLF，其他 Swift 檔是 LF
- 參數表重新產生：寫一支 node 腳本，抽 index.html 從 `const PRESETS={` 到 `// v2.24 對照：身體` 那段 eval，照 F 的順序換掉第二節表格，表頭版本改一下，第一節與第三節手動

## 📂 下個會話最重要的檔案

- `.uiux/04-手感/手感診斷-暫定.md` ← 量到的數字、F1 到 F10、v2.24 到 v2.26 的實作差異、查證紀錄
- `.uiux/04-手感/手感測試紀錄-暫定.md` ← 最後面：自測 0z、0aa、0ab、0ac 輪
- `.vibe/標準清單.md`、`.vibe/黃金行為.md`、`.vibe/代決清單.md`
- `prototype/web/index.html` ← OFF26、fingerGrab、strokeJudge、strokeGrab、strokeStep、substep 開頭的 QD 彈簧與摸、moodStep、drawTrail、pitAt
- `prototype/web/selftest.js` ← T39、T40、T41
- `ios/NieNie/Slime/SlimeRig.swift`（同名函式）、`FeelParams.swift`（off26、off25、off24）、`SlimeView.swift`（trailLayers、trailPath、strokeHeads、highlightFrame）、`App/SlimeController.swift`（handle、frame 的 purrRoll）、`Feedback/SlimeHaptics.swift`（test）、`UI/TunePanel.swift`（ladderRow）

## ⏭️ 下一步從哪繼續

1. 讀這份，再讀 `.uiux/04-手感/手感診斷-暫定.md` 第二節 v2.24 到 v2.27。
2. 第一句話問多米 build 99 捏得怎樣，特別是從側邊快速拖抓不抓得住、摸兩三下會不會舒服，還有觸覺階梯「單下」「連續」最小各哪一格。多米還在捏的話就等，先不要動程式。
3. 照回報走：
   - 抓不住、快拉會滑掉：請多米把面板「摸的速度門檻」從 400 往上調（最高 600，越高越不容易判成摸，0 全關）。有效就改預設 strokeV，網頁 PRESETS 和 `FeelParams.swift` 兩邊都改；不要摸就預設 0。
   - 那一圈或痕跡不好看：面板「凹痕大小」「手指走過的痕跡」先調，多米定了再改 `drawTrail` 和 `SlimeView.swift` 的 `trailPath`。
   - 手機感覺不到震：tickMin、grainMin 不能低於階梯量到的最小格。手麻：面板「顆粒每秒最多幾下」往下調。
   - 回彈太飄：面板「回彈阻尼比」「拖到停會衝過頭」調大。
   - 有東西不動、沒聲音、不震、閃退：那是執行期問題（雲端只確認編譯過），比對 `SlimeRig.swift` 與網頁版同名函式。
   - 說的是感覺：網頁版用同一個材質重現、量數字再改。分不清是哪一版，就用候選「v2.25 對照」「v2.24 對照」一版一版切。
   - 多米說做 v2.27：先把標準加進 `.vibe/標準清單.md`，再照 v2.26 的順序：網頁、selftest 加 T42 連跑 3 輪、Swift、紀錄與參數表、CLAUDE 草稿、推 `swiftui-port`、推 main、發 TestFlight、補 build 號與交接檔。

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 按壓變化大多被手指擋住、反應觸發太少：這兩個是我的猜測，量了都不成立（可見像素佔八成，反應 14 到 15 種）
- 外框尖角試過提高定型門檻、撫平記憶裡的尖角，都傷留形，不用再試
- 搔癢段長量兩點直線距離會量短，已改累加路徑
- 第三輪 relaxClearsMark 是呼吸相位造成的壓線，已查清
- 拖動的慣性效果本來就小（係數 0 到 5，遠端只差約 7 點），衝過頭靠的是 dragSpring
- 痕跡試過小坑疊（一圈一圈的條紋）、細線（像眉毛），都不用；凹痕 0.65 蓋掉半個身體
