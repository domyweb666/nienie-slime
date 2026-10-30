# Handoff: v1 放射狀 rig 多米實測不達標，已重做成 v2 形狀匹配網頁原型（Pages 可開），等多米手機試

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
- 多米說「還沒要上傳」，可能把 TestFlight 誤會成公開上架，需要再說明一次
- TestFlight 的 4 個 GitHub Secrets 還沒設定：`APPLE_TEAM_ID`、`ASC_KEY_ID`、`ASC_ISSUER_ID`、`ASC_KEY_P8`
- Bundle ID 暫定 `org.domyweb.nienieslime`，多米還沒確認
- 待真機查證：系統觸覺關閉時 Core Haptics 會不會自動停震（iOS 沒 API 讀這個開關）
- testflight job 還沒實際跑過，雲端簽名（API 金鑰 Admin 角色＋`-allowProvisioningUpdates`）可能第一次會卡

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

## ⏭️ 下一步從哪繼續

1. 先讀這份 `.vibe/HANDOFF.md`，再讀 `.uiux/04-手感/技術選型決定-暫定.md`（成因表、改道候選、v2 實作紀錄、愛不釋手機制表）
2. 多米已選**黏土**與**懸空**（v2 預設已改，地面鈕收進隱藏面板）。還沒回報：哪裡還不像活物。他回報的東西記進 `手感測試紀錄-暫定.md`（標「自測，非盲測」）
3. 調參數：一次一個，用隱藏面板的「複製數值」把他調到喜歡的數值貼回來，寫進 `參數表-暫定.md`
4. 錄音：買史萊姆、iPhone 近錄四類聲音，Agent 做切片與觸發
5. 以上定了再談移植 Swift（ios/ 要重寫 rig，Haptics／Audio 層可留）

## 🗑️ 這次會話的雜訊（下次別重新討論）

- Expo Go 能不能跑 Swift：不能，已確認，別再查
- 原型裡的拍照按鈕、相機相關 CSS 是舊版殘留，「不做清單」已排除拍照分享，移植版沒做
- v1 為什麼打結、v2 為什麼選形狀匹配、線性 beta 為什麼關掉：都寫在技術選型檔與 lessons，別重新推導
- 瀏覽器分頁在背景時 rAF 會被節流，程式自測要自己用固定 dt 呼叫 update()，不要靠 setTimeout 等
