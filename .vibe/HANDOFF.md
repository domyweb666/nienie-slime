# Handoff: 網頁原型 v2.2 手感定案，Swift 版已照 v2.2 重寫並通過雲端編譯，還沒裝上真機

> 產出時間：2026-10-31 06:45
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
- TestFlight 進度（2026-10-31）：4 個 Secrets 都設了（名稱 `APPLE_TEAM_ID`、`ASC_KEY_ID`、`ASC_ISSUER_ID`、`ASC_PRIVATE_KEY`，.p8 那個多米取名 PRIVATE_KEY，workflow 已配合）。run 41177344171：金鑰驗證過、雲端簽名過、ARCHIVE SUCCEEDED，卡在 export「Error Downloading App Information」，原因是 App Store Connect 還沒建 App 紀錄（金鑰看到的 App 清單是空的）。多米在 ASC 建好 App 後重跑 `gh workflow run ios.yml --ref swiftui-port -f testflight=true` 即可
- workflow 多了一步「Write API key and verify it with App Store Connect」：檢查三個值的格式（只印長度）、拿金鑰打 ASC API、沒有 App 紀錄就直接報錯，不用白打包
- Issuer ID 第一次被貼成 7 字元的東西，靠這步才抓到；以後 Secrets 出錯先看這步的輸出
- Bundle ID 定為 `org.domyweb.qieji`（多米建 App 時用的；原本的 nienieslime 沒建成）
- 待真機查證：系統觸覺關閉時 Core Haptics 會不會自動停震（iOS 沒 API 讀這個開關）
- 雲端簽名：開發用簽名（archive）過了；發佈用簽名（export）在 run 41179042074 回「Cloud signing permission error」＋「No profiles for org.domyweb.qieji」，這是 API 金鑰角色不夠（要 Admin，或 App Manager 加勾「可取用雲端管理發佈憑證」）。多米要把金鑰改成 Admin，改不了就建新 Admin 金鑰並重設 `ASC_KEY_ID`、`ASC_PRIVATE_KEY`（Issuer ID 不變），再重跑

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

## ⏭️ 下一步從哪繼續

1. 先讀這份 `.vibe/HANDOFF.md`，再讀 `.uiux/04-手感/技術選型決定-暫定.md`（成因表、改道候選、v2 實作紀錄、愛不釋手機制表）
2. 手感基準已定（v2.2，多米「都對」），Swift 版已移植並編譯通過。下一步是**裝上真機**：Secrets 與簽名都已通過，只差多米在 App Store Connect 建 App 紀錄（已建，Bundle ID `org.domyweb.qieji`）再重跑 workflow，這是閘門 3 的前置條件。他回報的東西記進 `手感測試紀錄-暫定.md`（標「自測，非盲測」）
3. 調參數：一次一個，用隱藏面板的「複製數值」把他調到喜歡的數值貼回來，寫進 `參數表-暫定.md`
4. 真機裝上後先量：延遲（240fps 慢動作）、最舊機低電量最大幅度捏有沒有掉幀（掉幀就 `h = R / 9` 改 `R / 8` 減粒子）、Swift 版的手感跟網頁版一不一樣（粒子數、小步數不同）
5. 錄音：**播放層已做好**（`sfx/manifest.json` 驅動，沒檔就安靜，測試音驗過）。等多米照 `.uiux/04-手感/錄音指南.md` 錄完丟進 `prototype/web/sfx/`，Agent 做切頭尾、rub 無縫循環、音量拉齊，填 manifest，推 main
6. 網頁版與 Swift 版的參數要同步：改一邊的 PRESETS 就改另一邊

## 🗑️ 這次會話的雜訊（下次別重新討論）

- Expo Go 能不能跑 Swift：不能，已確認，別再查
- 原型裡的拍照按鈕、相機相關 CSS 是舊版殘留，「不做清單」已排除拍照分享，移植版沒做
- v1 為什麼打結、v2 為什麼選形狀匹配、線性 beta 為什麼關掉：都寫在技術選型檔與 lessons，別重新推導
- 瀏覽器分頁在背景時 rAF 會被節流，程式自測要自己用固定 dt 呼叫 update()，不要靠 setTimeout 等
