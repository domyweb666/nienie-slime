# Handoff: 第十六會話，v2.29 上線（黏液取消、不打結、手感基準）；多米點頭後開工環境互動，第一批程式剛寫完，一次都還沒跑過

> 產出時間：2026-11-06 06:12
> 給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

已上線（`?v=230`，`swiftui-port` 在 `9f38bdb` 那版、`main` 在 `d49b52f`）：

- 黏液取消：網頁整段刪掉；手機版只把預設關掉，程式等移植時刪
- 打結：三角網不准翻面（`buildMesh`、`meshGuard`），記住的形狀也一樣；另加 `gripUp`、`homeCap`、`fingerSolid`、`softWall`。9840 幀：交叉 1141 變 275、放手後交叉 62 變 0、記住的形狀翻面 139 變 0
- 眼睛：`eyePose`、`sdRing`，出界 347 幀變 0；眼距上限 1.3 倍、臉最多歪 50 度
- 手感研究寫成 `.uiux/04-手感/手感研究與基準-暫定.md`；環境互動提案 `.uiux/04-手感/環境互動提案-暫定.md`、示意圖 `.uiux/04-手感/環境互動/版面示意.jpg`
- selftest T45，46 項連跑 3 輪全過

多米按「照提案開工」之後（環境互動 v2.30，只在 `swiftui-port` 備份，`main` 和網頁版都沒動）：

- `.vibe/標準清單.md` 加了 v2.30 一節
- `prototype/web/index.html` 寫完第一批：碗移左、三層（`SILL.plane`）、重力可轉向、路線系統、擺飾剛體、手指抓擺飾、背景拆層。音效 `prototype/sfx-design/design_props.py` 產生 8 個 `prop-*.wav`，`sfx/engine.js` 加 `S.knock`，`manifest.json` 加 `prop`

## 🚧 還沒做完 / 待決定

- v2.30 的程式只過了語法檢查，一次都沒跑過。上次導覽 `localhost:8765` 失敗（預覽伺服器大概關了），還沒看到第一個畫面
- 已知 bug（第一件事修，見下面）：`routeStep` 爬升第一幀就判定到了
- `selftest.js` 還沒改：T44 的 g 項用 `SILL.glass`（已拿掉）、e 項 `lastTouch=t-20` 要大於 25 秒、PASS 裡的 `r.glass`；T46 還沒寫
- 文件還沒補：代決清單、手感測試紀錄第 0ai 輪、`CLAUDE-md-v2.30-草稿`、lessons、提案檔那句「從窗台爬上窗框下緣」（實作改走碗後緣，見關鍵決策，要跟多米說一聲）
- 手機版：防打結、眼睛、果凍皮、窗台、環境互動都還沒移植
- 手感基準表的門檻由多米定；基準第 1、7、8、10 條只有真機量得到
- 上一輪多米還沒回的：心情變色在果凍上有點髒（建議 0.35）、部分種子坐碗裡垂一塊（薄荷最明顯）、腮紅碰到不做清單、標題旁每幀毫秒數（手機沒量過）
- 排隊的玩法：兩指拉斷與合體、餵煩惱、一起呼吸、含小東西
- `.vibe/CLAUDE-md-v2.24` 到 `v2.29-草稿.md` 都等多米點頭才改 `CLAUDE.md`
- build 99 的回報還在等；舊帳：閘門 3 沒量、沒盲測過、新的手 0 輪、核心動作卡沒過閘門 1、買實物沒做、`README.md` 過時

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 多米 11-06：皮 A、B 先不選；黏液取消；碗移到左邊、照提案做環境互動；手感定基準，手感層只為基準表的數字改，其他換皮，版本號不再往上加（門檻他還沒定）
- 三層畫的順序：窗外：天空 → 牠 → 牆加窗框 → 擺飾、碗。窗框層：底圖 → 牠 → 擺飾、碗。窗台層：底圖 → 擺飾、碗 → 牠 → 碗前緣（在碗裡時）。換層只在身體不跟東西重疊的那一刻
- 從窗台到窗框下緣要經過碗（窗台 → 碗 → 翻碗後緣 → 窗框下緣）。擺飾把窗台右邊擋住了，碗的右邊也沒地方讓身體不重疊地換層
- 貼在窗框上就把重力轉向窗框（`SURF`，大小 0.6），身體壓扁是真的物理，走路共用 `GAIT`
- 窗外縮小用 `CAM`（`S.zoom`、樞紐在窗外台階 `g.oy`），`toWorld` 不用改；抓窗外的牠時回窗台層，z 回 1 的 0.2 秒裡手指座標跟著換算
- 擺飾只跟窗台層的牠相撞。換回窗台層時已經疊著的先不撞（`propsMarkOverlap`）
- 不留回 v2.29 的總開關（多米要少一點版本），只留 `envRoam`、`catPush`。原本黏玻璃滑下來拿掉（窗戶是開著的）；跳只留給被嚇到（`sillHop`）；閒著回碗從 12 秒改 25 秒。這幾條要寫進代決清單
- 石頭不會撒出來，整盤一起倒（要撒要另外做素材）
- 先前仍有效的：身體留現在這套，不用 metaball；果凍皮做法；圓身體、有臉、不要 8 條腿；背景藍＝懸空，舊行為不動；strokeV 400；摸跟抓拿不準就算抓；TestFlight 等多米開口

## 🧰 環境與流程（不變的事實）

- 多米沒有 Mac。編譯走 GitHub Actions，裝機走 TestFlight；build 號＝run number；動到 `ios/` 的 push 會自動跑一次只編譯的檢查，不會上傳
- 要發 TestFlight：等 push 觸發的編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`；TestFlight 最新還是 build 101
- `swiftui-port` 有 Swift＋web＋docs；`main` 只放 web＋docs（Pages 自動發布）。推 main：`git worktree add <scratchpad>/wt-main origin/main -B main-sync` → `git checkout <hash> -- prototype .uiux .vibe CLAUDE.md` → 確認 `git diff --cached --name-only -- ios` 是空的 → `git commit -C <hash>` → `git push origin main-sync:main` → 移除 worktree 與分支
- 網頁網址：`https://domyweb666.github.io/nienie-slime/prototype/web/index.html?v=230`（現在是 v2.29）。改版就換 `?v=`
- 本機預覽：`preview_start` 名稱 `web-proto`，`http://localhost:8765/`，viewport 393×852。導覽時要加 `?v=`
- 面板藏著時 rAF 不跑：把 `requestAnimationFrame` 換成空函式，自己呼叫 `update(1/60)`、`draw()`。截圖前先呼叫一次 `resize_window`，不然比例會跑掉、還可能拿到舊畫面
- 跑 selftest 放進固定 393×852 的 iframe（`iframe.contentWindow.eval(src)`），一輪約 6 分鐘，跑的時候 javascript_tool 會逾時，用 `ping -n 110 127.0.0.1` 等一段再問；結果放 `window.__runs`
- 量打結：`__probe` 存在瀏覽器 `localStorage.__probe`（換機就沒了），邏輯也收進 T45
- 補丁用 Write 寫 python 檔再 `python -I`，路徑用 r 字串，每個取代都檢查次數。這次的補丁在 scratchpad，會消失，不用找
- Swift 這台電腦編譯不了。limrun：`npx -y lim@0.51.0`，測完立刻刪自己開的實例。`SlimeHaptics.swift` 是 CRLF，其他 Swift 檔是 LF

## 📂 下個會話最重要的檔案

- `.vibe/標準清單.md` 最後一節 v2.30 ← 這批的驗收標準
- `.uiux/04-手感/環境互動提案-暫定.md` ← 多米同意的內容
- `prototype/web/index.html`：搜尋「v2.30 環境互動」就是整段（`sillClampX` 到 `propsStep`）；其他改動：`sillGeo`、`updateCam`、`substep` 的 `Gh`、`hxOn`、`gaitConst` 的 `climb`、`down` 的 `sillTouch`、`sceneFor`、`drawProps`、`drawFront`、`draw`
- `prototype/web/selftest.js` ← T44 要改、T46 要寫
- `.uiux/04-手感/手感研究與基準-暫定.md` ← 手感層不准退步（T45、T28、T36）

## ⏭️ 下一步從哪繼續

1. 第一句話告訴多米：v2.30 程式寫完但還沒跑過，接下來先跑起來，網頁版還是 v2.29。
2. 修已知 bug。`routeStep` 這行順序錯了：

   ```js
   const hit=q.k==='move'&&(q.y<Q.y0?S.y1<=q.y:S.y1>=q.y);if(Q.y0==null||Q.i0!==Q.i){Q.y0=S.y1;Q.i0=Q.i}
   ```

   `Q.y0` 要在算 `hit` 之前設定（`Q.i0!==Q.i` 就重設），不然爬升第一幀判成已到，步驟直接跳過。

3. `preview_start` 名稱 `web-proto`，導覽到 `index.html?v=231b`，`resize_window` 393×852，看有沒有錯誤（小心 `PROPS`、`RT` 這些 `const` 在第一次 `setup()` 之前有沒有定義好）。截圖確認碗在左、擺飾在右。393×852 的幾何：`R` 106、`bx` 108.5、`by` 491、`rim` 564、`lip` 574、`back` 498、`bt` 593、`gx` 41、`jr` 352、`gy` 214.5、`oy` 615、`fl` 636.7。

4. 在頁面裡一條一條跑路線、截圖。先 `mat.envRoam=0;mat.catPush=0` 關掉牠自己出門，再呼叫：`routeStart(rtOutFront(null))`、`rtIntoFront()`、`rtOverBack(g.jr-R)`、`rtBackIn()`、`rtFrameLoop()`、`rtClimbDrop()`、`rtGoOut()`、`rtComeBack()`、`rtPoke(PROPS[0])`。每跑一段印 `SILL.plane/surf/inBowl/y1/x0/x1`、`S.route` 現在第幾步。要看的：換層那一幀有沒有跳、爬的時候像不像爬、會不會卡到逾時、貼窗框有沒有壓扁、轉角會不會甩出去。

5. 擺飾：把牠甩過去、用走的推、`rtPoke`，看倒不倒、會不會飛走。要調的：`PROP_PUSH`、`PROP_MU`、`PROPDEF` 的 `m`、`rtPoke` 的偽足長度。推出畫面右邊、20 秒回來、`relax` 歸位、手指抓、輕點會晃都要試。

6. 手指：抓窗外露出來的部分回到房間；窗框、牆、碗遮住的地方抓不到；窗框旁邊慢放會黏、甩過去不黏；窗戶中間放手落在窗框下緣；碗正上方放手進碗；碗前面放手落在窗台。

7. 放它自己跑 2 分鐘看節奏（`sillGo` 的機率，大半時間要在休息）。

8. 改 T44、寫 T46（標準清單每一條都要有：路線都走得完、換層時不重疊、擺飾倒得了也回得來、手指那幾條、自己跑 2 分鐘不爆、T45 不退步），連跑 3 輪。

9. 補文件（代決清單、測試紀錄第 0ai 輪、`CLAUDE-md-v2.30-草稿`、lessons、提案檔），存檔，推 `swiftui-port`，照流程推 main，網址換 `?v=231`，更新交接檔。Swift、TestFlight 等多米開口。

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 不要再比 metaball，也不要回頭救黏液
- 防翻面一小步跑三遍試過，交叉幀 275 變 387，沒留
- `meshGuard` 放在碰撞之後會陷進地板 0.7 點，已改到碰撞之前
- 碗留中間走後緣的方案、把擺飾放到窗框下緣的方案都想過：前者身體大半被碗擋住，後者窗框下緣更擠，都不採用
