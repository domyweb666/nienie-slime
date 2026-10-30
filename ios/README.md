# 捏捏史萊姆 iOS 版

`prototype/web/index.html` 的 SwiftUI 移植版。演算法逐行照抄網頁原型：18 個控制點、每點一個彈簧、手勢規則、塑形記憶，參數一樣是 `DEF` 那三組。

## 檔案在哪

| 檔案 | 內容 |
|---|---|
| `NieNie/Slime/SlimeRig.swift` | 骨架、彈簧、手勢、塑形記憶。對應原型的 `setup()`、`shape()`、`update()` 和 pointer 事件 |
| `NieNie/Slime/SlimeView.swift` | UIKit 畫面：120Hz CADisplayLink、多指、coalesced 與 predicted touches、CAShapeLayer 繪圖。對應 `draw()` |
| `NieNie/Slime/FeelParams.swift` | 三種手感預設（Q彈／麻糬／黏土）與調整面板的滑桿範圍 |
| `NieNie/Feedback/SlimeHaptics.swift` | Core Haptics：連續震動跟變形量走，放手時一下「啵」 |
| `NieNie/Feedback/SlimeAudio.swift` | AVAudioEngine 合成音，三種風格。`SlimeSoundSource` 是之後換錄音切片用的介面 |
| `NieNie/App/SlimeController.swift` | 把同一個事件同時送到畫面、聲音、觸覺 |
| `NieNie/UI/` | 按鈕列與隱藏調整面板 |
| `project.yml` | XcodeGen 設定。`.xcodeproj` 不進 repo，由雲端 Mac 產生 |

隱藏調整面板：長按左上角「捏捏」標題 1.2 秒。用長按是因為三指手勢會撞到系統的復原與拷貝手勢。

## 雲端編譯

每次推到 `main` 或 `swiftui-port`，GitHub Actions 會在 macOS 機器上做一次不簽名的編譯。這一步只確認程式碼編得過，不會產生可以安裝的 App。

## 第一次上傳 TestFlight 要準備的東西

以下都在 Apple 的網站上操作，用 Windows 瀏覽器就可以。

1. 註冊 Bundle ID：到 developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → 新增 App IDs，Bundle ID 填 `org.domyweb.nienieslime`。想換別的 ID，要一起改 `project.yml` 裡的 `PRODUCT_BUNDLE_IDENTIFIER`。
2. 建立 App：到 App Store Connect → App → 新增 App，平台選 iOS，Bundle ID 選上一步那個，名稱填「捏捏史萊姆」。
3. 建 API 金鑰：App Store Connect → 使用者與存取 → 整合 → App Store Connect API → 團隊金鑰 → 新增。角色選 Admin，因為雲端簽名要替你建立發佈憑證，權限低的角色做不到。`.p8` 檔只能下載一次，記下頁面上的 Key ID 和 Issuer ID。
4. 找 Team ID：developer.apple.com → 帳號 → 會員資格詳細資料，十個字元那串。
5. 把四個值放進 GitHub Secrets（repo → Settings → Secrets and variables → Actions）：

   | Secret 名稱 | 填什麼 |
   |---|---|
   | `APPLE_TEAM_ID` | Team ID |
   | `ASC_KEY_ID` | Key ID |
   | `ASC_ISSUER_ID` | Issuer ID |
   | `ASC_KEY_P8` | `.p8` 檔的全部內容，連 BEGIN、END 兩行一起貼 |

6. 上傳：GitHub → Actions → iOS → Run workflow，勾選 testflight 後執行。跑完後 App Store Connect 要再處理 10 到 30 分鐘，build 才會出現在 TestFlight 分頁。
7. 把自己加成內部測試者，手機裝 TestFlight App 就能安裝。

## 還沒確認的事

- 系統設定裡的「系統觸覺」關掉後，Core Haptics 會不會自動停震。iOS 沒有 API 可以讀這個開關，要用真機關掉試一次。
- 減少動態的溫和版：回彈變慢（反應時間至少 0.5 秒、阻尼至少 0.9），每 8 次的特別回彈關掉，觸覺和聲音照常。實際感覺要真機看。
- 合成音是照 WebAudio 版翻過來的，濾波器和壓縮器的算法不完全一樣，聽起來會有些差別。
- 驗收照 `CLAUDE.md` 的方式：真機、最舊機加低電量模式、240fps 慢動作數延遲、找沒看過的人捏。
