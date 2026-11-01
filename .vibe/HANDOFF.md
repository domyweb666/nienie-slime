# Handoff: 手感精修提案 41 條的程式全部做完（v2.7，TestFlight build 0.2.0 (46)）；球在真機：量延遲、一條一條盲測、錄音

> 產出時間：2026-11-01 05:16
> 前一會話的最後狀態，給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼（第五會話，2026-11-01）

- 修掉第 41 條觸手被壓縮時對折（v2.5，build 40）：觸手加橫檔與中軸不折返，固定網格對折幀 282 降到 24。成因是中軸在一節之內反轉 180 度，五個假設量了沒用才找到
- 做完第三批不用盲測的五條（v2.6，build 43）：遊走 smoothstep 加減速與觸手拖尾、減少動態時遊走 ×0.25、材質切換淡入、提示只在前三次、待機 60Hz
- 第三批其餘 12 條全部做成參數、預設對照值（v2.7，build 46）：21 回家彈簧、22 放手餘韻、23 呼吸三項、24 兩指捏 squish（預設開）、25 滑脫、26 黏連、27 局部面積壓力、33 家的高度、34 描邊粗細隨壓縮兩版都有；15 銳利度跟材質、17 啵走觸覺管線、36 格子不配記憶體只在 Swift
- selftest 從 10 項長到 16 項（T11 壓縮網格、T12 拖尾、T13 兩指捏、T14 滑脫、T15 黏連、T16 候選全開），T11、T12 固定亂數可重現，每次 3 遍全過
- 三個版本都推上去：`swiftui-port` 有 Swift＋web＋docs，`main` 有 web＋docs（Pages 自動發布）。雲端編譯每次零 Swift 警告
- 文件同步到 v2.7：提案 41 條每條寫了做法與量到的數字、參數表、測試紀錄第 0e 到 0g 輪、lessons 加 7 列、README、CLAUDE.md

## 🚧 還沒做完 / 待決定

- 真機一次都沒跑過（build 29 到 46 全部）。閘門 3 前兩條沒量：延遲格數、最舊機低電量掉幀
- 第二批 10 條、第三批 10 條候選全部等盲測。26 黏連排最後；17 要先有錄音檔
- 錄音沒錄，app 現在無聲。錄法在 `.uiux/04-手感/錄音指南.md`，檔案放 `ios/NieNie/Resources/` 與 `prototype/web/sfx/`，兩邊都要，檔名填各自的 `manifest.json`
- 第 36 條後半（boundaryPoints 每幀配置、粒子數）只在真機掉幀時做
- 正式外形種子多米還沒挑
- 首次體驗、空狀態、權限時刻表（閘門 2）、上架前檢查、埋點，整段沒碰
- CLAUDE.md 的待決定：收集多種史萊姆、紀錄排行榜、換背景、沒有臉的反應（呼吸變深已是候選 23c）
- 盲測定案後要回來收尾程式：輸的候選拆掉、贏的值寫死回參數表、面板清乾淨

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 修壞掉的東西（第 41 條）可以改預設；手感改動一律做成候選、預設對照值，多米在真機盲測才定案。Agent 不自評手感，程式自測只證明「不壞」
- 表演用位移（拖尾、呼吸、飄）一律寫在參考形狀上，不動力的權重。第 20 條原提案 (b) 回家拉力打折量過會改掉靜止姿勢，不採用
- 自測 T11、T12 固定亂數、時鐘歸零再還原；每個跨幀累積的狀態（相位、計時器、計數）新增時就列進 setup() 與自測的歸零清單
- TestFlight：archive 不簽名、export 才用雲端發佈憑證（Development 憑證有額度）；dispatch 之後到上傳完成前不推同分支，workflow 有 cancel-in-progress
- 候選 17 的 playsHapticsOnly 在引擎啟動時讀旗標，第一次套了要重開 app（Apple 文件：改了要重啟引擎才生效）
- 待機降 60Hz，延遲測試開著時固定 120，閘門 3 數到的才是 120 管線；面板沒碰時 Hz 讀 60 是正常的
- 存 1／存 2 的槽位是整組 JSON，新版加了參數後舊槽位讀不出來，重存一次就好

### 環境與設定（不變的事實）

- 多米沒有 Mac。編譯走 GitHub Actions（`macos-26`、latest-stable Xcode、XcodeGen），裝機走 TestFlight 內部測試
- GitHub Secrets 四個：`APPLE_TEAM_ID`、`ASC_KEY_ID`、`ASC_ISSUER_ID`、`ASC_PRIVATE_KEY`（Admin 團隊金鑰）。不要動
- Bundle ID `org.domyweb.nienieslime`（2026-11-01 改；`org.domyweb.qieji` 是另一個 App「茄記」的，不要用），MARKETING_VERSION 0.2.0，build 號＝run number，最低 iOS 17，SWIFT_VERSION 5.0
- 史萊姆本體 UIKit（UIView＋CAShapeLayer，為了 coalesced／predicted touches），按鈕與面板 SwiftUI；隱藏面板長按「捏捏」標題 1.2 秒
- 網頁原型在 `https://domyweb666.github.io/nienie-slime/prototype/web/index.html`，只能看形狀與手勢，沒有觸覺

## 📂 下個會話最重要的檔案

- `CLAUDE.md` ← 專案規矩、版本沿革 v2.3 到 v2.7、移植硬規則
- `.uiux/04-手感/手感精修提案-暫定.md` ← 41 條每條的現況、做法、量到的數字、驗法；分批表在最後一節
- `.uiux/04-手感/參數表-暫定.md` ← 每個參數的目前值與候選值，定案後貼這裡
- `.uiux/04-手感/手感測試紀錄-暫定.md` ← 第 0c 到 0g 輪；真機與盲測結果記在這
- `.uiux/lessons.md` ← 踩坑清單，改演算法前先掃一遍
- `prototype/web/index.html`、`prototype/web/selftest.js` ← 網頁原型與回歸自測（改演算法必跑，連跑 3 次）
- `ios/NieNie/Slime/SlimeRig.swift`、`ios/NieNie/Slime/FeelParams.swift` ← 核心演算法、參數、候選清單
- `ios/README.md` ← 面板用法（讀數、槽位、候選、延遲測試）、TestFlight 步驟
- `.github/workflows/ios.yml` ← 編譯與上傳流程

## ⏭️ 下一步從哪繼續

1. 先讀這份，再讀提案最後一節的分批表
2. 多米裝 build 0.2.0 (46)（App Store Connect 處理完出現在 TestFlight）。先做閘門 3 前兩條：面板開「延遲測試」，240fps 慢動作數「碰到→閃白」與「碰到→攤開」各幾格；最舊機低電量最大幅度捏，看面板讀數有沒有掉幀。數字記進測試紀錄，標「自測，非盲測」
3. 盲測，一次一條：存 1（對照）→ 套候選 → 存 2 → 切 1／切 2 各捏一分鐘。順序建議第二批 6、12、13、14、19、2、9（18、41 是反向對照），再第三批 21、22、23、15、25、27、33、34，26 最後。每條結果記進測試紀錄，定案值貼回參數表
4. 多米錄完音：檔名填 manifest.json、兩邊都放、推上去；之後才能試候選 17
5. 要再上傳 TestFlight：先把要推的全推完、等編譯過，再跑 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`；觸發後到上傳完成前不推同分支。web 的改動要 cherry-pick 到 `main`
6. 真機結果回來後的程式收尾：拆輸的候選、寫死贏的值、清面板；掉幀才做第 36 條後半；都定了才進閘門 2 的設計線

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 第 41 條試過的五個假設（觸手軸向變硬、互不穿透隔三顆、抓取跟著轉、抓取權重漸層、橫檔不扭轉）都量過沒用，數字在提案第 41 條，別再試
- 第 20 條原提案 (b) 回家拉力打折，量過不採用
- 亂數種子跑 12 次算比例那套作廢（12 次結果全同），改固定情境網格
- TestFlight 的坑（Issuer ID 格式、沒建 App、金鑰角色、憑證額度、dispatch 被自己的 push 取消）都過了，workflow 的 verify 步驟會先報
- 多米曾想用 Expo Go 測，跑不了原生 Swift，已走 TestFlight
