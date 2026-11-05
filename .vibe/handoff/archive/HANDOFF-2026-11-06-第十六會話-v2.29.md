# Handoff: 第十六會話，黏液取消、不打結、眼睛不出界，手感研究寫成基準，環境互動提案等多米點頭

> 產出時間：2026-11-06
> 給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

- 多米回報五點（見下面「多米 11-06 五點」），其中第 3、4、5 點做完，第 1 點照他的話不動，第 2 點寫成提案等他點頭
- 黏液取消：網頁整段程式刪掉（連 selftest 的黏液項目）；手機版只把預設關掉，程式等移植時刪
- 打結：身體切成 962 個三角形的網（`buildMesh`、`meshGuard`），每個三角形不准翻面，記住的形狀也一樣。抓著時回正上限 `gripUp` 0.004（窗台原本每小步 20%）、整團被拖的上限 `homeCap`、手指實心 `fingerSolid`、畫面左右上緣軟牆 `softWall`
- 眼睛：`eyePose` 每幀算位置存 `EYE.pose`，眼距上限 1.3 倍、臉最多歪 50 度、離外框至少一顆眼睛的距離，真的出界那一幀夾回來；腮紅不超出外框；眼睛改畫在碗前緣後面
- 手感研究寫成 `.uiux/04-手感/手感研究與基準-暫定.md`：研究表、手感基準 v1、三層分工（手感／皮／個性）、只有多米做得到的三件事
- 環境互動提案 `.uiux/04-手感/環境互動提案-暫定.md`，示意圖 `.uiux/04-手感/環境互動/版面示意.jpg`（四張，是程式合成的靜態圖，還沒有物理）
- selftest 加 T45，共 46 項。數字見基準檔第五節（9840 幀：交叉 1141 變 275、放手後交叉 62 變 0、記住的形狀翻面 139 變 0、眼睛出界 347 變 0）
- `swiftui-port`、`main` 都推了，網頁 `?v=230`

## 多米 11-06 五點（原話）

1. A 和 B 先不選，等其他功能都完善再說
2. 我想要史萊姆可以跟環境有真實互動，比如可以跨出窗外或是爬窗邊，或是打翻擺飾，以及爬出碗或爬進碗內
3. 拉史萊姆會有掉落黏液，取消這項設計
4. 拉扯史萊姆時，眼睛常常會不在史萊姆體內，以及史萊姆常常會打結
5. 有沒有什麼研究紀錄，最好的手感應該要是怎樣，我在想與其那麼多版不如花時間研究最好的手感，然後其它就換皮就好了

## 🚧 還沒做完 / 待決定

- 環境互動：等多米對提案點頭。唯一要他決定的是碗移到左邊（圖在示意圖）
- 手感基準表的門檻由多米定；基準第 1、7、8、10 條只有真機量得到
- 手機版：防打結、眼睛、果凍皮、窗台都還沒移植。手機版只有圓身體、有眼睛、新音樂檔、黏液預設關
- 上一輪還沒回的：心情變色在果凍上有點髒（建議 0.35）、部分種子坐碗裡垂一塊（薄荷最明顯，示意圖時又看到）、腮紅碰到不做清單、標題旁每幀毫秒數（手機沒量過）
- 手指痕跡在果凍皮上沒畫
- 後面排隊的玩法：兩指拉斷與合體、餵煩惱、一起呼吸、含小東西（環境互動做完再談）
- `.vibe/CLAUDE-md-v2.24` 到 `v2.29-草稿.md` 都等多米點頭才改 `CLAUDE.md`。`CLAUDE.md` 現在寫的（懸空、平塗、有黏液）已經落後
- build 99 的回報還在等：側邊快拖、摸兩三下舒不舒服、觸覺階梯
- 舊帳：閘門 3 沒量；一個參數都沒盲測過；新的手 0 輪；核心動作卡沒過閘門 1；買實物沒做；`README.md` 過時

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 皮 A、B 都留著，等其他功能完善才選（多米 11-06）
- 黏液取消（多米 11-06）。不要再做任何會從身體掉出去的東西
- 三層分工：手感層只為基準表上的數字改，一次一個，盲測過才留；皮層隨便換，換皮不准讓粒子多動；個性、環境放外面，不准改手感層參數。版本號不再往上加（多米 11-06 同意方向，門檻他還沒定）
- 量「壞掉」要量內部：外框沒交叉不代表沒打結，三角形翻面才是
- 窗戶是開著的（提案的假設，多米沒推翻前照這個）；原本「黏在窗戶上滑下來」要換掉
- 先前仍有效的：身體留現在這套，不換參考版、不用 metaball；果凍皮做法（遮罩、兩層模糊、當高度算法線）；圓身體、有臉、不要 8 條腿；背景藍＝懸空，白天夜晚＝窗台；strokeV 400；只放大對手指的反應；摸跟抓拿不準就算抓；TestFlight 等多米開口才發；其他 Agent 替多米選的都在 `.vibe/代決清單.md`

## 🧰 環境與流程（不變的事實）

- 多米沒有 Mac。編譯走 GitHub Actions，裝機走 TestFlight；build 號＝run number；動到 `ios/` 的 push 會自動跑一次只編譯的檢查，不會上傳
- 要發 TestFlight：等 push 觸發的編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`；等編譯用 `gh run watch <id> --exit-status`
- 目前攢著等發的：圓身體、有眼睛、無縫音樂、黏液預設關。TestFlight 最新還是 build 101
- `swiftui-port` 有 Swift＋web＋docs；`main` 只放 web＋docs（Pages 自動發布）。推 main：`git worktree add <scratchpad>/wt-main origin/main -B main-sync` → 刪掉的檔案先 `git rm --ignore-unmatch` → `git checkout <hash> -- prototype .uiux .vibe CLAUDE.md` → 確認 `git diff --cached --name-only -- ios` 是空的 → `git commit -C <hash>` → `git push origin main-sync:main` → 移除 worktree 與分支
- 網頁網址：`https://domyweb666.github.io/nienie-slime/prototype/web/index.html?v=230`。改版就換 `?v=`，手機才不會吃快取
- 本機預覽：`preview_start` 名稱 `web-proto`，`http://localhost:8765/`，viewport 393×852。預覽伺服器會快取，導覽時要加 `?v=`
- 面板藏著時 rAF 不跑：把 `requestAnimationFrame` 換成空函式，自己呼叫 `update(1/60)`、`draw()`。截圖前要先呼叫一次 `resize_window`，不然比例會跑掉、還可能拿到舊畫面
- 跑 selftest 放進固定 393×852 的 iframe（`iframe.contentWindow.eval(src)`），現在一輪約 5 分鐘，跑的時候 javascript_tool 會逾時，用 `ping -n 110 127.0.0.1` 等一段再問；結果放 `window.__runs`
- 量打結的工具：這次寫的探針存在瀏覽器 `localStorage.__probe`，換機就沒了，邏輯已收進 selftest 的 T45（`paths`、`flips`、`sdRing`）
- 只跑某一項：`selftest.js` 開頭到「// T1 輕按」＋該區塊＋收尾（還原 VIEW、PRESETS、rAF）
- 補丁用 Write 寫 python 檔再 `python -I`，路徑用 r 字串，每個取代都檢查次數；shell heredoc 裡反斜線會少一半。素材放進 Downloads 以外的路徑前都走 `python -I`
- Swift 這台電腦編譯不了。limrun：`npx -y lim@0.51.0`，測完立刻刪自己開的實例；校正數字在記憶 `reference_limrun_gestures`。`SlimeHaptics.swift` 是 CRLF，其他 Swift 檔是 LF

## 📂 下個會話最重要的檔案

- `.uiux/04-手感/環境互動提案-暫定.md`、`.uiux/04-手感/環境互動/版面示意.jpg`
- `.uiux/04-手感/手感研究與基準-暫定.md`
- `.uiux/04-手感/手感測試紀錄-暫定.md` 最後面第 0ah 輪
- `.vibe/標準清單.md`（最後一節 v2.29）、`.vibe/代決清單.md`、`.vibe/CLAUDE-md-v2.29-草稿.md`
- `prototype/web/index.html`：防打結 `buildMesh`、`meshGuard`；眼睛 `eyePose`、`sdRing`；窗台 `SILL`、`sillGeo`、`sillHit`、`sillHop`、`sillLaunch`、`sillGo`、`sillStep`；背景 `sceneFor`、`bowlFront`、`drawBowlFront`；步態 `gaitTo`、`gaitStep`
- `prototype/web/selftest.js` ← T44、T45

## ⏭️ 下一步從哪繼續

1. 讀這份。
2. 看多米對環境互動提案怎麼回。還沒回就等，順手問手機上標題旁每幀幾毫秒。
3. 多米點頭後照提案施工，先加進 `.vibe/標準清單.md`，再網頁、selftest 加 T46 連跑 3 輪、紀錄、推 `swiftui-port`、推 main、更新交接檔。Swift、TestFlight 等他開口。

技術筆記（提案的做法，還沒寫程式）：

- 三層 `SILL.plane`：`room`（地板 `g.fl`，撞擺飾、畫面左右）、`frame`（地板是窗框下緣 `g.gy+g.gh`，撞左右窗框 `g.gx`、`g.gx+g.gw`、上窗框 `g.gy`、碗的外側）、`out`（地板約窗框下緣往下 20 點，只撞地板）。
- 畫的順序：天空 → 牠（out）→ 牆加窗框 → 擺飾、碗 → 牠（room、frame）→ 碗前緣（在碗裡時）。frame 跟 room 畫在同一層，換層不會跳；frame 另外跟碗的外側碰撞，身體才不會浮在碗前面。`sceneFor` 要拆成天空、牆、擺飾三張，擺飾每幀畫。示意圖的合成程式就是這個拆法。
- 換層只在身體不跟東西重疊時：底部高過窗框下緣（room ↔ frame）、底部高過窗框下緣而且準備往後（frame ↔ out）。窗外縮小用現成的 `CAM`：`CAM.z` 慢慢到 0.8，樞紐放在窗外地板的高度，螢幕 y 不動，`toWorld` 不用改。抓窗外的牠時先回到 room（舉起來），0.25 秒回到 z 1。
- 碗移位：`sillGeo` 的 `bx` 從 `W/2` 改約 108 點，`sceneFor` 的 `place(a.bowl…)` 跟著改。碗放左邊時右邊窗框下緣約 139 點寬，身體 180 點，要靠碗外側的碰撞擠窄一點。
- 爬：路徑一段一段走，每段用現成的 `GAIT` 一縮一衝；爬的時候重力降到約 0.15、上下也開家的彈簧、接觸的點加附著力。卡超過幾秒就放棄，交給重力掉下來。手指抓到就全部取消。臉不跟著轉（`eyePose` 已限制 50 度）。
- 擺飾：凸多邊形剛體（位置、角度、速度），跟地板和彼此碰撞用頂點；粒子碰多邊形時粒子推出去、反向給剛體衝量（用 `X−PX` 當速度）。倒了就倒著，手指可以抓著扶正（抓著時加回正力矩）。推出畫面外：播一聲，約 20 秒後淡入回原位；`relax`（↺）全部歸位。
- 手感基準不准退步：T45、T28 留形、T36 拉力。

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 不要再比 metaball，也不要回頭救黏液
- 試過防翻面一小步跑三遍，交叉幀 275 變 387，沒留
- `meshGuard` 放在碰撞之後會陷進地板 0.7 點，已改到碰撞之前
- 碗留中間、走碗後面的路線（從碗後緣爬上窗框）想過，身體大半時間被碗擋住，不採用
