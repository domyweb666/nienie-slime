# 捏捏史萊姆 iOS 版

`prototype/web/index.html`（v2.2 形狀匹配）的 SwiftUI 移植版。演算法照網頁原型：粒子身體、重疊的剛體區塊、面積壓力、邊界繩子、群內互不穿透、黏土塑性、觸手記憶淡化、呼吸蠕動飄動抖動遊走。參數一樣是 `PRESETS` 那三組，預設黏土。

## 檔案在哪

| 檔案 | 內容 |
|---|---|
| `NieNie/Slime/SlimeRig.swift` | 外形定義（不規則團塊＋觸手）、粒子、區塊、形狀匹配、繩子、互不穿透、塑性、活物感、遊走、手指。對應原型的 `defineShape()`、`setup()`、`substep()`、`plasticity()`、`twitch()` |
| `NieNie/Slime/SlimeView.swift` | UIKit 畫面：120Hz CADisplayLink、多指、coalesced 與 predicted touches、CAShapeLayer 繪圖（懸空、影子跟最低點、亮光跟身體轉）。對應 `draw()` |
| `NieNie/Slime/FeelParams.swift` | 三種預設（果凍／麻糬／黏土）與調整面板的滑桿清單，名字跟原型一樣 |
| `NieNie/Feedback/SlimeHaptics.swift` | Core Haptics：連續震動跟變形量走，放手時一下「啵」 |
| `NieNie/Feedback/SlimeAudio.swift` | 錄音切片播放：讀 bundle 裡的 `manifest.json`，四類各多段隨機挑、音高 ±8%、揉的時候循環播。沒有檔案就安靜 |
| `NieNie/App/SlimeController.swift` | 把同一個事件同時送到畫面、聲音、觸覺 |
| `NieNie/UI/` | 按鈕列與隱藏調整面板 |
| `NieNie/Resources/` | `manifest.json` 與錄音檔。格式跟 `prototype/web/sfx/` 一樣，檔案會被放進 bundle 根目錄 |
| `project.yml` | XcodeGen 設定。`.xcodeproj` 不進 repo，由雲端 Mac 產生 |

隱藏調整面板：長按左上角「捏捏」標題 1.2 秒。用長按是因為三指手勢會撞到系統的復原與拷貝手勢。

## 錄音怎麼放進來

照 `.uiux/04-手感/錄音指南.md` 錄完，`.m4a` 丟進 `NieNie/Resources/`，檔名填進同資料夾的 `manifest.json`，推上 `swiftui-port`。網頁原型那份放 `prototype/web/sfx/`，兩邊都要放。

## 雲端編譯

每次推到 `main` 或 `swiftui-port`，GitHub Actions 會在 macOS 機器上做一次不簽名的編譯。這一步只確認程式碼編得過，不會產生可以安裝的 App。

## 第一次上傳 TestFlight 要準備的東西

2026-10-31 已照這份走完一次，build 0.1.0 (22) 上傳成功。之後只要做第 6 步。

以下都在 Apple 的網站上操作，用 Windows 瀏覽器就可以。TestFlight 內部測試不是公開上架：不經審核，只有你加進去的人（最多 100 人）能裝。

1. 註冊 Bundle ID：到 developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → 新增 App IDs，Bundle ID 填 `org.domyweb.qieji`（多米 2026-10-31 在 App Store Connect 建 App 時用的這個）。想換別的 ID，要一起改 `project.yml` 裡的 `PRODUCT_BUNDLE_IDENTIFIER`，workflow 會從那裡讀。
2. 建立 App：到 App Store Connect → App → 新增 App，平台選 iOS，Bundle ID 選上一步那個，名稱填「捏捏史萊姆」。
3. 建 API 金鑰：App Store Connect → 使用者與存取 → 整合 → App Store Connect API → 「團隊金鑰」分頁 → 新增。角色一定要選 Admin，Developer 角色會在 export 那步回「Cloud signing permission error」（實際踩過）。Issuer ID 在這個分頁最上面，36 字元的 UUID；個人金鑰分頁沒有 Issuer ID 也不能簽名。`.p8` 檔只能下載一次，記下頁面上的 Key ID 和 Issuer ID。
4. 找 Team ID：developer.apple.com → 帳號 → 會員資格詳細資料，十個字元那串。
5. 把四個值放進 GitHub Secrets（repo → Settings → Secrets and variables → Actions）：

   | Secret 名稱 | 填什麼 |
   |---|---|
   | `APPLE_TEAM_ID` | Team ID |
   | `ASC_KEY_ID` | Key ID |
   | `ASC_ISSUER_ID` | Issuer ID |
   | `ASC_PRIVATE_KEY` | `.p8` 檔的全部內容，連 BEGIN、END 兩行一起貼 |

6. 上傳：GitHub → Actions → iOS → Run workflow，勾選 testflight 後執行。第二步的 App 沒建的話，workflow 會在「verify」那步直接報錯，不會白打包。跑完後 App Store Connect 要再處理 10 到 30 分鐘，build 才會出現在 TestFlight 分頁。
7. 把自己加成內部測試者，手機裝 TestFlight App 就能安裝。

## 還沒確認的事

- 全部還沒在真機跑過：延遲、掉幀、觸覺、聲音都是未驗證。
- 效能：網頁版在電腦上每幀約 1 毫秒；Swift 版每幀 3 到 5 個小步，每步跑 70 個區塊、360 顆粒子、互不穿透格子。最舊機（iPhone XS／XR／SE 2）開低電量要實測，掉幀就先減粒子（`h = R / 9` 改 `R / 8`）或區塊。
- 系統設定裡的「系統觸覺」關掉後，Core Haptics 會不會自動停震。iOS 沒有 API 可以讀這個開關，要用真機關掉試一次。
- 減少動態的溫和版：活物感與抖動減半，回饋照常。實際感覺要真機看。
- 驗收照 `CLAUDE.md` 的方式：真機、最舊機加低電量模式、240fps 慢動作數延遲、找沒看過的人捏。
