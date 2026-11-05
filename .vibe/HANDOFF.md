# Handoff: 第十五會話，v2.28 預覽（果凍皮切換列，只有網頁），等多米選皮

> 產出時間：2026-11-06
> 給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ⭐ 第十五會話做了什麼（先看這節，下面是第十四會話留下的，仍然有效）

- 多米給了窗台果凍參考原型，要評估。結論在 `.uiux/04-手感/窗台果凍參考評估-暫定.md`：拿外觀、窗台、新玩法，身體留現在這套；不換 metaball（只能幾十顆粒子，拉長和凹痕會退步）。
- 網頁版加切換列：皮（平塗、A 清透、B 奶凍、C 霧面）、身體、臉、背景（藍、白天、夜晚）、「v2.27 原樣」。程式在 `index.html` 的 `VIEW`、`viewOver`、`JSKINS`、`jelRender`、`sceneFor`。素材 `prototype/web/scene/`，由 `prototype/sfx-design/make_scene_assets.py` 產生。
- 物理沒動，Swift 沒動，沒發 TestFlight。selftest 舊項目一律切回 v2.27 畫面，加 T43（皮畫得出來、切皮粒子不動），跑 1 輪 44 項全過。
- 靜態對照圖在 `.uiux/04-手感/果凍皮對照/`。

**多米 11-06 定了：** 身體要圓、不要 8 條腿、要有臉。網頁切換列只剩皮（A、B）和背景。手機版 `FeelParams` 預設也改了（limbs 0、eyes 1、tentSlip 0、tentBump 0、tentAxis 0.85，心情變色留著），雲端編譯過就算，沒上模擬器，也沒發 TestFlight。

**下一步：** 皮在 A、B 之間還沒定，建議等碗做好再選，因為差別主要在透不透、會不會透出碗底。下一片是窗台的重力和碗，開工前要多米先定評估檔裡的衝突表（8 條那列已定）。順便問標題旁的每幀毫秒數（手機上第一次量到）。下面第十四會話的觸手相關待驗都不用再問了，build 99 的側邊快拖、摸、觸覺階梯還在等。

**攢著等發 TestFlight 的：** 圓身體、有眼睛。

**待驗：** iPhone Safari 還沒跑過（WebGL2、RGBA16F）；心情變色放在果凍上，拉扯時薄荷會變灰綠；外框互疊在果凍皮上看不看得出來沒驗到；手指痕跡在果凍皮上沒畫。
**這次的坑：** 預覽伺服器會快取，改完要加 `?v=` 才看得到；面板藏著時 rAF 不跑，測試時把 `requestAnimationFrame` 換成 setTimeout。

## ✅ 這次完成了什麼

- 多米 11-05 要三件事加一句：把眼睛去掉、很多條觸手（選 8 條真的）、心情變色（選平常原色、心情時染色）、觸手碰到會被彈走
- 網頁與 Swift 都做完，selftest 加到 T42（43 項），連跑 3 輪全過。數字在 `.uiux/04-手感/手感測試紀錄-暫定.md` 第 0ae 輪，實測圖 `.uiux/04-手感/v2.27-模擬器實測.png`
- limrun 上編譯過、實測過，實例都刪了。雲端編譯 run 100 過；TestFlight build 101 上傳成功；`swiftui-port`、`main` 都已同步

## 🚧 還沒做完 / 待決定

- 多米還沒捏 build 101
- 多米還沒回報 build 99：側邊快拖抓不抓得住、摸兩三下舒不舒服、觸覺階梯最小各哪一格
- 新的待驗：觸手像海星還是章魚、夠不夠多、會不會太細、顏色好不好看、抓著會不會纏住抖（v2.8 是真機才抖）、手機跑不跑得動（粒子和運算都變多，閘門 3 還是沒量）
- 單指甩很少撞到別條（身體會跟著轉），互撞主要在兩指時看得到；多米可能覺得沒效果
- 黏土亂玩後還留 1 到 3 處互疊，每幀動 8 點；T16 偶爾失敗約 18 輪 3 次，沒查證原因
- 拿掉眼睛後 C2、C5、E2 的「看你」只剩偽足和傾身，v2.23 判斷缺注視，互動感可能掉；多米還沒評
- `.vibe/CLAUDE-md-v2.24-草稿.md` 到 `CLAUDE-md-v2.27-草稿.md` 等多米點頭才改 `CLAUDE.md`
- 原本排在 v2.27 的 F8 肌肉、F9 自己收回形狀、F10 手指下的呼吸順延，還沒做
- 舊帳：閘門 3 沒量；一個參數都沒盲測過；新的手 0 輪；核心動作卡沒過閘門 1；`README.md` 過時

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 環繞的觸手：推到剩靜止長度六成或繞到根後面就滑開；只記長度不記彎；關中軸；只抓著觸手時身體不記形；不是落在觸手上就不抓觸手的粒子。這五條少一條就會回到纏住抖，都量過
- 要讓粒子晃，推參考形狀的速度 QV，不要推粒子（形狀匹配幾小步就拉回來）
- 互撞不是硬牆，跨群不做互不穿透（硬規則）
- 顏色最多染八成，六成會混成灰褐；紅色看拉伸量和猛扯速度，因為身體會跟著手指走、很難撐到想逃
- strokeV 400 維持；limrun 測完立刻刪自己開的實例，別的專案的不動
- 反應的數量夠了，先不加新反應種類；只放大對手指的反應，休息時的呼吸與蠕動比例不動（多米 v2.11）
- 摸跟抓拿不準就算抓；回歸測試分層：舊項目回 v2.23（OFF24 含 OFF25 到 OFF27），T39 到 T41 回 v2.26（PSAVE 疊 OFF27），T42 全開
- 其他 Agent 替多米選的都在 `.vibe/代決清單.md`

## 🧰 環境與流程（不變的事實）

- 多米沒有 Mac。編譯走 GitHub Actions，裝機走 TestFlight；build 號＝run number；只有動到 `ios/` 或 workflow 的 push 才會編譯
- `swiftui-port` 有 Swift＋web＋docs；`main` 只放 web＋docs（Pages 自動發布）。推 main：
  `git worktree add <scratchpad>/wt-main origin/main -B main-sync` → `git cherry-pick -n <hash>` → `git checkout HEAD -- ios`（cherry-pick 在 ios 衝突時這步也會解掉）→ `git diff --cached --name-only --diff-filter=A -- ios | xargs -r git rm -q --cached` → 確認 `git diff --cached --quiet <hash> -- prototype .uiux CLAUDE.md` → `git commit -C <hash>` → 確認 `git diff --stat HEAD~1 HEAD -- ios` 是空的、ios 檔維持 18 個 → `git push origin main-sync:main` → 移除 worktree 與分支
- 多米 11-05：不要每個小功能就發 TestFlight，功能累積一批，他開口才發。commit、push、同步 main 照常。動到 `ios/` 的 push 會自動跑一次只編譯的檢查，不會上傳，也不會出現在 TestFlight，只是用掉一個 run number
- 多米要發 TestFlight 時：等 push 觸發的編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`，上傳完才能再推同一條分支；等編譯用 `gh run watch <id> --exit-status`，放背景跑
- limrun 的 `launch-app` 不會返回，要放背景再 kill。用 `timeout` 包 lim 又搭 `read < <(...)` 的腳本會一路失敗（node 報 UV_HANDLE_CLOSING），原因沒查清；不包 `timeout`、ID 用 `$(python ... | tr -d '\r')` 取就正常，兩次失敗都沒刪到模擬器，所以測完要再 `list` 確認。
- limrun：`npx -y lim@0.51.0`，這台電腦的登入是所有專案共用的。`lim xcode create --ios` 開機器（加 `--label project=nienie-slime`、`--inactivity-timeout 10m`），`lim xcode build ./ios --id <sandbox> --xcodegen-spec project.yml --scheme NieNieSlime --configuration Release --sdk iphonesimulator` 約 1 分鐘編好並裝進模擬器。測完 `ios delete`、`xcode delete`。手勢腳本沒進專案，校正數字在記憶 `reference_limrun_gestures`：`wait` 3 約 18 毫秒、雙指用 `x2`、`y2`、手勢前截圖定位要算進身體會走開
- 本機預覽：`preview_start` 名稱 `web-proto`，網址 `http://localhost:8765/`，viewport 設 393×852
- 瀏覽器面板藏著時 rAF 被節流、截圖會逾時。要看畫面：把 `requestAnimationFrame` 換成空函式，自己呼叫 `update(1/60)` 和 `draw()`，畫到一個 canvas，toBlob 後 POST 到本機小伺服器（node 寫的，收到就存進 scratchpad，用完關掉），再用 Read 看圖
- 跑 selftest 放進固定 393×852 的 iframe（`iframe.contentWindow.eval(src)`）：面板的手機尺寸在回合結束會被清掉，R 從 118 變 160，那輪會多一堆假失敗
- selftest 現在一輪要幾分鐘，跑的時候頁面不回應，javascript_tool 會逾時，隔一下再問。連跑用 setTimeout 鏈，結果放 `window.__runs`；重新載入頁面就沒了，數字要先抄
- 只想重跑某一項：抽 `selftest.js` 開頭到「// T1 輕按」＋那一項的區塊＋收尾，eval。它會把 PRESETS 換成關新功能的版本，收尾要 `Object.assign(PRESETS, P27)` 或重新載入，每輪先印 R 分辨版本。全開的值在 `P27`，`PSAVE` 是疊了 OFF27 的 v2.26
- Swift 這台電腦編譯不了，v2.23 以來的大改雲端都一次過；複雜運算照舊寫明型別
- 補丁一律用 Write 寫成 python 檔再 `python -I 檔案`，路徑用 r 字串，每個取代都檢查次數，全對才寫檔。shell 的 heredoc 裡反斜線會少一半，一次貼兩個 heredoc 也會解析失敗。換行字元用 chr(13)、chr(10)：`SlimeHaptics.swift` 是 CRLF，其他 Swift 檔是 LF
- 參數表重新產生：寫一支 node 腳本，抽 index.html 從 `const PRESETS={` 到 `// v2.24 對照：身體` 那段 eval，照 F 的順序換掉第二節表格，表頭版本改一下，第一節與第三節手動

## 📂 下個會話最重要的檔案

- `.uiux/04-手感/手感測試紀錄-暫定.md` ← 最後面第 0ae 輪：v2.27 量到的問題、修法、T42 數字
- `.uiux/04-手感/v2.27-模擬器實測.png` ← Swift 版實際長相
- `.vibe/標準清單.md`（最後一節 v2.27）、`.vibe/黃金行為.md`、`.vibe/代決清單.md`、`.vibe/CLAUDE-md-v2.27-草稿.md`
- `prototype/web/index.html` ← OFF27、defineShape、blobR、gripTent、tentSlip、tentRest、tentBump、letGo、moodColorStep、tint、reachGrab、fingerGrab
- `prototype/web/selftest.js` ← T42
- `ios/NieNie/Slime/SlimeRig.swift`（同名函式）、`FeelParams.swift`（off27）、`SlimeView.swift`（tinted、tintKey）

## ⏭️ 下一步從哪繼續

1. 讀這份。
2. 第一句話問多米 build 101 捏得怎樣：抓觸手會不會纏住抖、從身體中間拉抓不抓得住、手機卡不卡、像不像海星、身體會不會太小、顏色好不好看、沒眼睛還有沒有互動感。順便問 build 99 那批：側邊快拖、摸兩三下舒不舒服、觸覺階梯「單下」「連續」最小各哪一格。多米還在捏就等，先不要動程式。
3. 照回報走：
   - 纏住或一直抖：先請多米錄影，說抓哪裡、怎麼動。網頁用 T42 的 around、abuse 重現，量每幀最大位移和動的是哪條（`TID`、`TU`）。v2.27 五條防纏（滑開、只記長度、關中軸、抓觸手時身體不記形、抓身體不抓觸手）不要單獨拿掉，每條都量過拿掉會抖。
   - 太容易滑開、抓不住觸手：面板「觸手滑開」往下調，有效就改預設 tentSlip；角度門檻是 `tentSlip` 裡的 0.2，網頁和 Swift 都要改。
   - 手機卡：面板「固定觸手數」先降（8 改 6）看幀時間，再回來量。不要憑感覺優化，閘門 3 順便補量。
   - 像海星、太細、身體太小：比例在 `defineShape` 的 1.32、0.11、`blobR` 的 0.72、`tentHit` 的 1.7-0.85u。先用網頁畫靜態圖給多米挑，再改兩版。身體放大要同步縮觸手長，不然鏡頭會退（現在 0.91）。
   - 撞不到、彈太小：單指時身體會跟著轉是主因。tentBump 調大沒用就要動 `tentBump` 的距離 D（0.16R）或減少被拖時的轉動，先量再改。
   - 顏色不好看：色在 `MCOL`（網頁）和 `tinted`（Swift），比例是面板「心情變色」。
   - 沒眼睛互動感掉了：面板「眼睛 v2.23」設 1 對照，多米定了再改預設。
   - 抓不住身體、快拉滑掉：面板「摸的速度門檻」從 400 往上調（最高 600，0 全關）。
   - 手機感覺不到震：tickMin、grainMin 不能低於階梯量到的最小格。手麻：面板「顆粒每秒最多幾下」往下調。
   - 閃退、東西不動：雲端和 limrun 都跑得起來，先比對 `SlimeRig.swift` 與網頁同名函式。
   - 要回舊外形比較：面板候選「v2.26 對照」回 build 99。
   - 多米說做新東西（F8 肌肉、F9 自己收回形狀、F10 手指下的呼吸順延成 v2.28）：先把標準加進 `.vibe/標準清單.md`，照這次的順序：網頁、selftest 加 T43 連跑 3 輪、limrun 實測後刪實例、Swift、紀錄與參數表、CLAUDE 草稿、推 `swiftui-port`、推 main、更新交接檔。TestFlight 等多米開口。
4. 要改完直接請多米試的東西先放網頁版；要真機才驗得到的（觸覺、效能）累積起來，跟多米說一聲目前攢了哪些，他說發再發。

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 單靠改 tentMem、creep、nearR、橫檔都解不掉纏住抖，試過了
- 直接推粒子做互撞：開關只差 2 點，不用再試
- 量抖動要等停 0.7 秒之後：拉完馬上量會把回彈算進去（這樣量到 7.4 點，靜止後 0.7 點）
- 紅色在模擬器只偏橘是因為手勢短，猛扯那一下才會滿；這不是壞掉
- 手勢腳本放在舊會話的 scratchpad，沒進專案；要重寫看記憶 `reference_limrun_gestures`，尖端位置從截圖沿半徑掃出來
- 早先的雜訊仍然成立：外框尖角試過提高定型門檻、撫平記憶都傷留形；痕跡用小坑疊、細線都不用；凹痕 0.65 蓋掉半個身體
