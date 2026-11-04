# Handoff: 第十二會話，手感診斷＋v2.24＋v2.25＋v2.26 做完（摸跟抓分開、手指旁邊看得到），build 97 已上傳，三版都還沒人捏過

> 產出時間：2026-11-04 11:15
> 前一會話的最後狀態，給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

- 多米 11-04 問：手感做到極致，要像真的生物、會互動，捏揉按的體感要好。我量完寫了 `.uiux/04-手感/手感診斷-暫定.md`，分四版做（v2.24 看得到、v2.25 有重量與手上有東西、v2.26 摸得到表面、v2.27 身體會變）
- v2.24 build 93：身體 0.30、縮傾蹭看放大、揉打通、抓著時畫面不在手指底下滑
- v2.25 build 95：參考形狀帶慣性（放手第一下 29 毫秒變 158 到 192 毫秒）、拖到停衝過頭約 16 點、觸覺改成跟手指走的顆粒、呼嚕連續低頻、面板觸覺階梯
- 多米選「直接做 v2.26」（沒先捏 build 95）。F6 摸跟抓分開：手指落下 80 毫秒內走超過 12 點、不是往外、不是從中心出發、沒有別根手指，算摸；不釘粒子，手指推參考形狀 QD；整團最多被帶 0.23R 再回到原位（原本 1.07R 到 1.64R，停在 126 到 193 點）；黏土不記形；摸兩三下舒服、呼嚕、熟。摸到一半停住變抓。F7：凹痕 dentSize 0.5、揉時凹痕跟著走、揉和摸留 0.5 秒痕跡、局部鼓起開、亮光跟著拉伸
- selftest 到 T41（42 項），最終版新頁面連跑 3 輪全過。雲端編譯 run 96 一次過、沒有警告，TestFlight build 97 已上傳，`main` 已同步
- 前後對照圖 `.uiux/04-手感/手指旁邊-對照.jpg`（規格寫先給多米看圖，多米選直接做，所以先做了）

## 🚧 還沒做完 / 待決定

- v2.24、v2.25、v2.26 三版都只確認編譯過，沒看過它在手機上跑。手感有問題時用候選「v2.25 對照」「v2.24 對照」一版一版切，才分得出是哪一版
- 要問多米，v2.26 這組：快速拉有沒有被判成摸（最可能要退回）；摸得舒不舒服；手指旁邊那一圈和走過的痕跡好不好看（畫風多米決定）。v2.25 那組：放手晃得對不對、果凍 9 下會不會太久、拖到停會不會飄、手上一粒一粒舒不舒服、觸覺階梯最小感覺得到哪一格。v2.24 那組：身體會不會太大、揉 1.3 秒呼嚕來得對不對、反應會不會太誇張
- `.vibe/CLAUDE-md-v2.24-草稿.md`、`v2.25`、`v2.26` 三份等多米點頭才改 `CLAUDE.md`
- 接下來照診斷第二節：v2.27（F8 肌肉、F9 自己收回形狀、F10 手指下的呼吸）。我的建議是先捏過再做
- 舊帳：閘門 3（延遲、最舊機低電量）沒量；一個參數都沒盲測過；新的手 0 輪；核心動作卡沒過閘門 1；`README.md` 過時
- 更早沒回的：v2.23 眼睛留不留、四隻的外形種子；黏液、睡著、節奏好不好玩

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 反應的數量夠了（60 秒自然玩法 14 到 15 種），先不加新反應種類；缺的是看得到、有重量、接觸、觸覺、狀態改物理
- 只放大對手指的反應，休息時的呼吸與蠕動比例不動（多米 v2.11：自身形變不要太大）
- 跟手要量螢幕座標，手指真實位置對被抓那塊畫出來的位置
- 手上的感覺用顆粒，跟手指走的距離綁在一起；連續觸覺只留給呼嚕。按住時吸氣那一下、E2 輕頂是它自己的動作，留著
- 放開手指的路徑都要接 inertiaCatch，掙脫也算，摸接手也算
- 摸跟抓寧可判成抓：判錯成摸會覺得抓不住，判錯成抓只是回到 v2.25
- 摸不推真的粒子，推 QD：硬推整團會被頂走、手指穿不過外框
- 回歸測試：舊項目與 T35 到 T38 回 v2.23（OFF24，含 OFF25、OFF26），T39 回 v2.24（OFF25），T40 回 v2.25（OFF26），T41 全開
- 面板候選「v2.25 對照」全部回 v2.25，舊對照都疊在 off24、off25、off26 上

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
- 補丁換行：`SlimeHaptics.swift` 是 CRLF，其他 Swift 檔是 LF。補丁開頭先判斷；換行字元在腳本裡寫 chr(13)、chr(10)，在 shell 裡傳反斜線 r、n 會變成真的換行，python 語法會壞
- T40 的數字要看：跑完先別重新載入頁面，`window.__runs` 重新載入就沒了
- 參數表的產生腳本在 v2.25 改過表頭那一行的比對字串，下次重寫時比對「對到 v2.25；v2.23 那次拿 Swift」
- 在 shell 的 heredoc 裡寫 python，反斜線會少一半（路徑、換行都會壞）。補丁一律用 Write 寫成檔案，路徑用 r 字串
- 瀏覽器面板藏著時截不了圖：在頁面畫到一個 canvas，toBlob 後 POST 到本機小伺服器存進 scratchpad，再用 Read 看（第十二會話寫的 recv.js，連接埠 8799，用完關掉）
- 參數表的產生腳本表頭那一行比對「對到 v2.26；v2.23 那次拿 Swift」


## 📂 下個會話最重要的檔案

- `.uiux/04-手感/手感診斷-暫定.md` ← 量到的數字、F1 到 F10、v2.24 到 v2.26 的實作差異、查證紀錄
- `.uiux/04-手感/手感測試紀錄-暫定.md` ← 最後面：自測 0z、0aa、0ab、0ac 輪
- `.vibe/標準清單.md`、`.vibe/黃金行為.md`、`.vibe/代決清單.md`、`.vibe/CLAUDE-md-v2.24-草稿.md`、`v2.25`、`v2.26`
- `prototype/web/index.html` ← OFF26、fingerGrab、strokeJudge、strokeGrab、strokeStep、substep 開頭的 QD 彈簧與摸、moodStep、drawTrail、pitAt
- `prototype/web/selftest.js` ← T39、T40、T41
- `ios/NieNie/Slime/SlimeRig.swift`（同名函式）、`FeelParams.swift`（off26、off25、off24）、`SlimeView.swift`（trailLayers、trailPath、redraw 裡的 strokeHeads、highlightFrame）、`App/SlimeController.swift`、`Feedback/SlimeHaptics.swift`、`UI/TunePanel.swift`

## ⏭️ 下一步從哪繼續

1. 先讀這份，再讀診斷第二節
2. 第一個動作：問多米 build 97 捏了沒、快速拉有沒有抓不住、對照圖的畫風可不可以。多米說要做 v2.27 就照診斷做，說哪裡不對就先調
3. 多米說抓不住：先把面板「摸的速度門檻」調高（300 以上幾乎不會判成摸），或 0 全關；真的不要就把 strokeV 預設改 0
4. 多米說 Swift 版有東西不動、沒聲音、不震，那是執行期問題（雲端只確認編譯過），先比對 `SlimeRig.swift` 與網頁版同名函式。多米說的是「感覺」就照老流程：網頁版用同一個材質重現、量數字，再改
5. 回彈太飄：面板「回彈阻尼比」調大、「拖到停會衝過頭」調大。顆粒太弱或感覺不到：先看觸覺階梯的結果，tickMin 不能低於最小感覺得到的那格

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 按壓變化大多被手指擋住、反應觸發太少：這兩個是我的猜測，量了都不成立（可見像素佔八成，反應 14 到 15 種）
- 外框尖角試過提高定型門檻、撫平記憶裡的尖角，都傷留形，不用再試
- 搔癢段長量兩點直線距離會量短，已改累加路徑
- 第三輪 relaxClearsMark 是呼吸相位造成的壓線，已查清
- 拖動的慣性效果本來就小（係數 0 到 5，遠端只差約 7 點），衝過頭靠的是 dragSpring
- 痕跡試過小坑疊（一圈一圈的條紋）、細線（像眉毛），都不用；凹痕 0.65 蓋掉半個身體
