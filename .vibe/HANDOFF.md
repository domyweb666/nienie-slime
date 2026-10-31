# Handoff: 第一批（v2.3）與第二批候選（v2.4）都進了兩版，候選預設關、面板一次套一條；下一步裝真機量延遲、盲測

## 🔄 2026-11-01 第四會話：第二批候選（v2.4）

- 多米說「先做第二批」。提案第 6、12、13、14、18、19、2、9、10、38 條做成**候選開關**，預設全部是對照值（v2.3 的行為），Swift 面板「候選」按鈕一次套一條，網頁版有 6、19、2 三顆。盲測做法：存 1（對照）→ 套候選 → 存 2 → 切 1／切 2
  - 12 觸覺跟變化率（hapStatic／hapRate）、13 質地微震（tickSpacing，手指每走 8 點一下，每幀最多兩下，批次排進一個 pattern）、14 啵依材質（popCount／popGap／popDecay／popSharp）、9 接觸面積壓力（pressRadiusGain，基準＝按下 100 毫秒內最小 majorRadius）、19 碰到時凍住（idleFreeze：活物感時鐘停住不歸零）、2 偶發特別回彈（specialEvery）、6 黏滯 0.03（候選按鈕）、18 關停留門檻當對照、10 音訊緩衝要求 5 毫秒（直接做）、38 觸覺與聲音參數全部上面板分組（手感／按壓與記形／活物感／觸覺／聲音／外形）並進 A/B 槽位
- 回歸自測改成逐幀量，分「對折」與「交疊」，候選開著也測；預設值十項照樣全過
- **新發現（第 41 條）**：抓觸手根部往尖端推會壓縮觸手，約一半次數中途對折幾幀，v2.2 就有（關掉按壓一樣），放手後消。邊界對邊界互不穿透 1.2h 試過沒用，已還原。修法會改手感，排第三批
- commit：web、iOS 各一個在 `swiftui-port`，web 那個 cherry-pick 到 `main`；lessons 加兩列
- **全部沒在真機跑過。** 雲端編譯與 TestFlight 結果看本檔最後一段「第四會話結果」

> 產出時間：2026-11-01（第三會話；前兩個會話的紀錄保留在下面）
> 前一會話的最後狀態，給下一個會話接續用

## ✅ 這次完成了什麼

- 把 `domyweb666/nienie-slime` clone 到 `E:\捏捏史萊姆\nienie-slime`
- 開 `swiftui-port` 分支，commit `f7ea521` 已推上 GitHub（main 沒動）
- 照 `prototype/web/index.html` 逐行移植 SwiftUI 版到 `ios/`：rig、彈簧、手勢、塑形記憶、面積守恆、三種手感預設、繪圖
- 加入原生功能：120Hz CADisplayLink、多指、coalesced/predicted touches、Core Haptics（連續＋放手啵）、AVAudioEngine 合成音三種風格、減少動態溫和版、`.ambient` 音訊（靜音開關就不響）、隱藏調整面板（長按「捏捏」標題 1.2 秒）
- 用 XcodeGen（`ios/project.yml`）產生專案，`.xcodeproj` 不進 repo
- 用 Python 畫了 1024 App 圖示（麻糬色水滴）
- 寫 `.github/workflows/ios.yml`：push 時做不簽名編譯；手動 Run workflow 勾 testflight 才簽名上傳
- GitHub Actions 第一次就 BUILD SUCCEEDED，零錯誤零 Swift 警告（run 41139510224）
- 寫 `ios/README.md`（TestFlight 設定步驟），根目錄 README 加一行 ios/ 說明

## 🚧 還沒做完 / 待決定

- **還沒在真機上捏過**：程式只證明編得過，手感、延遲、觸覺都未驗證
- **多米想用 Expo Go 測試**，但 Expo Go 只能跑 React Native，跑不了原生 Swift。已給三條路，多米還沒選：
  1. TestFlight 內部測試（推薦；不公開、不審核、只有加進去的人能裝）
  2. 另做 Expo + React Native Skia 版（Expo Go 做不出連續震動，等於維護兩套，測到的手感不能代表 Swift 版）
  3. 先用 iPhone Safari 開網頁原型（沒觸覺）
- **TestFlight 已上傳成功**（2026-10-31，run 41180288580，build 0.1.0 (22)）。4 個 Secrets：`APPLE_TEAM_ID`、`ASC_KEY_ID`、`ASC_ISSUER_ID`、`ASC_PRIVATE_KEY`（.p8 那個多米取名 PRIVATE_KEY，workflow 已配合）。金鑰是多米重建的 Admin 團隊金鑰。之後要再上傳：`gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`，build 號自動用 run number
- 設定過程踩到的坑（細節在 `.uiux/lessons.md`）：Issuer ID 貼錯、App Store Connect 沒建 App、金鑰角色不是 Admin、workflow 檔只在 swiftui-port 上所以手動觸發 422。workflow 現在有「verify」步會在簽名前把這些一次報出來
- Bundle ID 定為 `org.domyweb.qieji`（多米建 App 時用的；原本的 nienieslime 沒建成）
- 待真機查證：系統觸覺關閉時 Core Haptics 會不會自動停震（iOS 沒 API 讀這個開關）
- 雲端簽名（Admin 金鑰＋`-allowProvisioningUpdates`）實證可行：開發與發佈憑證、profile 都由 Xcode 在 CI 上自動建

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 雲端編譯走 GitHub Actions（repo 公開，macOS 機器免費），runner 用 `macos-26` + `latest-stable` Xcode
- 多米已有 Apple Developer Program 帳號
- 推到 `swiftui-port` 分支，確認沒問題才合併 main
- 史萊姆本體用 UIKit（UIView + CAShapeLayer），按鈕和面板用 SwiftUI。理由：只有 UIKit 拿得到 coalesced/predicted touches
- 最低 iOS 17；`SWIFT_VERSION 5.0`（避開 Swift 6 嚴格並行檢查，因為沒 Mac 不能快速迭代）
- 隱藏面板用長按標題，不用三指手勢（會撞系統復原手勢）
- 不用 Rive（CLAUDE.md 已定）

## 📂 下個會話最重要的檔案

- `CLAUDE.md` ← 專案規矩與移植規格
- `ios/README.md` ← 檔案對照表、TestFlight 設定步驟、待查證清單
- `ios/NieNie/Slime/SlimeRig.swift` ← 核心演算法
- `ios/NieNie/Slime/SlimeView.swift` ← 繪圖與觸控
- `ios/NieNie/App/SlimeController.swift` ← 事件分派到聲音與觸覺
- `.github/workflows/ios.yml` ← 編譯與上傳流程
- `.uiux/04-手感/參數表-暫定.md` ← 參數與減少動態版數值

## 🔄 2026-10-31 第二會話

- 多米在 Pages 上捏了 v1（18 點放射狀 rig）：描邊打結、回彈不順、合成音難聽、不是他要的塑形。成因與三條改道寫在 `.uiux/04-手感/技術選型決定-暫定.md`
- 多米選「重做，形狀匹配」，另外補了三個新要求：**要愛不釋手、要像活物（沒碰也會動）、考慮懸空取消地面**
- v2 已寫好：`prototype/web/index.html`（v1 搬到 `archive/radial-v1.html`）。形狀匹配＋塑性＋活物感＋懸空／地面切換＋三預設＋隱藏面板（長按「捏捏」）。**無音效**（等錄音）
- Agent 程式自測：拉、壓、兩指、亂甩、放著，全部零自交、面積回 100%、放手回正。數字在技術選型檔「v2 實作紀錄」。**多米還沒摸過 v2**
- GitHub Pages 已開（吃 main 根目錄）：`https://domyweb666.github.io/nienie-slime/prototype/web/index.html`。prototype 與文件已同步到 main
- `CLAUDE.md` **已更新為 v2 做法**（多米 10-31 看過提案後說「照提案改」）：形狀匹配、黏土、懸空、自己會動、錄音切片、移植硬規則
- `ios/` 的 Swift 版是 v1 演算法，也過時了；等 v2 手感定案再重移植
- **v2.1 觸手版**（多米：要觸手、不要完整形體、軟踏踏）：不規則團塊＋5 條垂下的觸手。多米摸了，回「對，繼續」
- **v2.2**（多米手機實測三點：要一直蠕動、拉久觸手變細線打結、要會移動）：行進波蠕動、粒子互不穿透（只在群內）、觸手記憶淡、家會遊走。多米摸了，回「**都對**」。**v2.2 是手感基準**
- 音效播放層已做（`sfx/manifest.json`），等多米錄音
- **Swift 移植完成**（多米「開始移植」）：`ios/NieNie/Slime/SlimeRig.swift` 整個照 v2.2 重寫，SlimeView 改懸空繪圖，SlimeAudio 改錄音切片（bundle 裡的 `manifest.json`），FeelParams／TunePanel 對齊 `PRESETS`，預設黏土。GitHub Actions run 41151191438 **BUILD SUCCEEDED，零錯誤零警告**，commit 27f61e5 在 `swiftui-port`。**還沒裝上真機**，效能、延遲、觸覺全部未驗證

## 🔄 2026-11-01 第三會話：手感精修提案與第一批

- 多米問「怎麼把手感微調到完美」。Agent 讀完兩版程式、參數表、lessons、書 2-4 與 3-4，寫了 `.uiux/04-手感/手感精修提案-暫定.md`：40 條分六層（缺件、輸入延遲、觸覺、物理活物感、周邊、調整面板），每條附現況行號、改法、驗法，分三批。三個最大的洞：按下那一幀零反應（參數表的「接觸點先凹」在 v2 重寫時掉了）、黏滯 0.12 秒寫在輸入端等於 120 毫秒延遲、連續觸覺跟靜態變形量走
- 多米說「做第一批」。做了提案第 1、3、4、5、7、8、16、28、29、37、39、40 條，外加第 18 條的停留門檻（沒有它輕按會留痕）：
  - 兩版都做：按壓攤開（pressBase 0.12R、按住再攤 0.18R、第一幀 50%、時間常數 0.06 秒）；放手強度＝甩多快與拉多遠取大；抓住 0.2 秒內純彈性、0.6 秒後全速記形；揉回原形改成半秒淡回不瞬移；取消觸控不啵；從外面推進來第一次碰到有 press 音；速度 30 毫秒平滑＋80 毫秒峰值
  - 只有 Swift：預測觸控只在有新事件那幀用（停下來就回真實位置）；coalesced 距離接進揉的音量；觸覺遲滯（開 0.03、關 0.008、至少 120 毫秒）；面板加「存 1／存 2／切 1／切 2」盲測槽位（UserDefaults）、幀時間讀數（Hz、最長幀、掉幀、算的毫秒、majorRadius、音訊緩衝）、「延遲測試：按下閃白一幀」；啟動畫面天空色；MARKETING_VERSION 0.2.0
- 網頁版回歸自測全過（第 0c 輪，`手感測試紀錄-暫定.md`），腳本存成 `prototype/web/selftest.js`
- commit：提案 5701081、web 3c57123、iOS f895a06（`swiftui-port`）；web 那個 cherry-pick 成 2e1fe13 推上 `main`（Pages 已是 v2.3）
- 參數表逐列對過程式並改寫（黏土數字以程式為準）；lessons 加一列「換演算法要逐列對參數表」
- Swift 版雲端編譯成功（run 41223390965，零警告）；TestFlight 上傳成功（run 41223922362，**build 0.2.0 (29)**，commit d2f6cc1）。第一次觸發的 run #26 被我自己接著推的 docs commit 取消（workflow 有 cancel-in-progress），重觸發才過，lessons 已記
- **全部沒在真機跑過。**

## ⏭️ 下一步從哪繼續

1. 先讀這份 `.vibe/HANDOFF.md`，再讀 `.uiux/04-手感/手感精修提案-暫定.md`（第一批做了什麼、第二批要盲測什麼）
2. build 0.2.0 (29) 已上傳 App Store Connect，處理 10 到 30 分鐘後出現在 TestFlight；多米是內部測試者就能裝。之後要再上傳：先把要推的全推完、等編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`，觸發後到上傳完成前不要再推同分支
3. 多米裝真機後先做閘門 3 的前兩條：面板開「延遲測試」，240fps 慢動作數「碰到→閃白」與「碰到→攤開」各幾格；最舊機低電量最大幅度捏，看面板讀數有沒有掉幀。回報記進 `手感測試紀錄-暫定.md`（標「自測，非盲測」）
4. 第二批候選已在面板上：一次套一條盲測（存 1 對照 → 套候選 → 存 2 → 切 1／切 2）。順序建議 6、12、13、14、19、2、9；18 是反向對照；每條的結果記進 `手感測試紀錄-暫定.md`，定案的值貼回 `參數表-暫定.md`
4b. 第三批先看第 41 條（觸手被壓縮時對折）：三個候選修法都要 12 次統計對照再盲測
5. 錄音：播放層已做好，等多米照 `.uiux/04-手感/錄音指南.md` 錄完丟進 `prototype/web/sfx/` 與 `ios/NieNie/Resources/`
6. 網頁版與 Swift 版的參數要同步：改一邊的 PRESETS 就改另一邊；改演算法就跑 `prototype/web/selftest.js`

## 🗑️ 這次會話的雜訊（下次別重新討論）

- Expo Go 能不能跑 Swift：不能，已確認，別再查
- 原型裡的拍照按鈕、相機相關 CSS 是舊版殘留，「不做清單」已排除拍照分享，移植版沒做
- v1 為什麼打結、v2 為什麼選形狀匹配、線性 beta 為什麼關掉：都寫在技術選型檔與 lessons，別重新推導
- 瀏覽器分頁在背景時 rAF 會被節流，程式自測要自己用固定 dt 呼叫 update()，不要靠 setTimeout 等
