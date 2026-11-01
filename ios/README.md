# 捏捏史萊姆 iOS 版

`prototype/web/index.html`（v2.7 形狀匹配）的 SwiftUI 移植版。演算法照網頁原型：粒子身體、重疊的剛體區塊、面積壓力、邊界繩子、群內互不穿透、黏土塑性、觸手記憶淡化、呼吸蠕動飄動抖動遊走。參數一樣是 `PRESETS` 那三組，預設黏土。

v2.9／v2.10（2026-11-01，多米真機回報 build 48 與網頁版回饋）：沒有固定觸手，改成會伸縮的偽足（隨機方向、上方也會長）；水母呼吸（3 秒一縮一放、收縮時上浮）；按鈕拿掉硬陰影；自己動放慢；黏土可以拉很長、攤很扁，放著約 10 秒退。面板「候選」最後一顆「v2.7 對照（舊外形）」換回海星外形。沒在真機看過。

v2.8（2026-11-01，多米真機回報 build 46）：底部材質切換與面板的字疊影修掉（陰影只掛背景）；蠕動改成平滑亂數，形狀一直在變（morph）；黏土抓到就記形、被抓的觸手也記形（tentMem），放著約 10 秒退。面板「候選」最後一顆「v2.7 對照：蠕動與回彈」換回原本的。沒在真機看過。

v2.7（2026-11-01，第三批其餘）：提案剩下的 12 條全部做成參數，預設是對照值，面板「候選」一次套一條：21 回家慢、22 放手餘韻、23 呼吸、15 銳利度跟材質、17 啵走觸覺管線（要有錄音檔，第一次套了要重開 app）、25 拉太遠滑脫、26 放手黏連、27 局部鼓、33 家 0.46H、34 描邊粗細；24 兩指捏的 squish 事件預設開；36 互不穿透的格子改成固定陣列不再每小步配記憶體。沒在真機看過。

v2.6（2026-11-01，第三批前五條）：遊走走一段用 smoothstep 加減速、遊走時觸手往後拖（tail 0.12，面板可調、0 關）、減少動態時遊走只剩四分之一；切材質顏色 0.25 秒淡入；提示只在前 3 次啟動；沒碰時畫面降到 60Hz、碰到回 120Hz（延遲測試開著時固定 120）。沒在真機看過。

v2.5（2026-11-01，提案第 41 條）：觸手加「橫檔」（兩邊成對的粒子不翻面、寬度不低於靜止的一半）與「中軸不折返」（每節至少前進靜止節距的 0.85）兩條約束，抓觸手根部往尖端推不再對折。只在要翻面或折返時出手，正常拉、壓不動它；兩版預設開，面板「候選」加「41 對照：關橫檔」。觸手最細只到一半寬，會不會改手感要盲測。

v2.4（2026-11-01，第二批候選）：觸覺跟變化率、質地微震、啵依材質、碰到時凍住、偶發特別回彈、接觸面積壓力、黏滯 0.03，全部做成參數，預設是對照值（v2.3 的行為）；面板「候選」按鈕一次套一條，觸覺與聲音參數全部可調。音訊緩衝改要求 5 毫秒。

v2.3（2026-11-01，手感精修提案第一批）加的：按下去那塊往四周攤開（接觸點先凹）、放手強度看拉伸量與速度取大、抓住 0.2 秒內純彈性 0.6 秒後才記形、揉回原形用動畫不瞬移、取消觸控不啵、預測觸控停下來就回真實位置、揉的音量用 coalesced 距離、連續觸覺遲滯、面板的盲測槽位與幀時間讀數與閃白延遲測試、啟動畫面天空色。全部還沒在真機看過。

## 檔案在哪

| 檔案 | 內容 |
|---|---|
| `NieNie/Slime/SlimeRig.swift` | 外形定義（不規則團塊＋觸手）、粒子、區塊、形狀匹配、繩子、互不穿透、塑性、活物感、遊走、手指。對應原型的 `defineShape()`、`setup()`、`substep()`、`plasticity()`、`twitch()` |
| `NieNie/Slime/SlimeView.swift` | UIKit 畫面：120Hz CADisplayLink、多指、coalesced 與 predicted touches（預測只在有新事件那幀用）、CAShapeLayer 繪圖（懸空、影子跟最低點、亮光跟身體轉）、幀時間讀數、閃白延遲測試。對應 `draw()` |
| `NieNie/Slime/FeelParams.swift` | 三種預設（果凍／麻糬／黏土）與調整面板的滑桿清單，名字跟原型一樣；v2.3 加按壓五個與停留門檻兩個參數 |
| `NieNie/Feedback/SlimeHaptics.swift` | Core Haptics：連續震動跟變形量走（開 0.03、關 0.008、至少 120 毫秒的遲滯），放手時一下「啵」 |
| `NieNie/Feedback/SlimeAudio.swift` | 錄音切片播放：讀 bundle 裡的 `manifest.json`，四類各多段隨機挑、音高 ±8%、揉的時候循環播。沒有檔案就安靜 |
| `NieNie/App/SlimeController.swift` | 把同一個事件同時送到畫面、聲音、觸覺 |
| `NieNie/UI/` | 按鈕列與隱藏調整面板 |
| `NieNie/Resources/` | `manifest.json` 與錄音檔。格式跟 `prototype/web/sfx/` 一樣，檔案會被放進 bundle 根目錄 |
| `project.yml` | XcodeGen 設定。`.xcodeproj` 不進 repo，由雲端 Mac 產生 |

隱藏調整面板：長按左上角「捏捏」標題 1.2 秒。用長按是因為三指手勢會撞到系統的復原與拷貝手勢。

面板最上面三樣是測試工具（手感精修提案第 37、39、40 條）：

- 讀數一行：實際 Hz、最近一秒最長一幀的毫秒、掉幀數、主執行緒每幀算的毫秒、手指接觸半徑（`majorRadius`）、音訊緩衝毫秒。掉幀看這裡，不用 Instruments。沒碰時 Hz 讀 60 是正常的（第 35 條待機降頻），碰到要回 120。
- 「存 1」「存 2」把目前數值存成 1 號 2 號（存在 UserDefaults），「切 1」「切 2」切換，畫面只顯示幾號不顯示數值，給盲測用。動任何滑桿就離開槽位。槽位存的是整組數值的 JSON，新版加了參數之後舊槽位讀不出來（切了沒反應），重存一次就好。
- 「候選」那一排：第二批候選一次套一條（6 黏滯 0.03、12 觸覺跟變化率、13 質地微震、14 啵依材質、18 關停留門檻當對照、19 碰到時凍住、2 偶發特別回彈、9 接觸面積壓力、41 對照：關橫檔；第三批 21 回家慢、22 放手餘韻、23 呼吸、15 銳利度跟材質、17 啵走觸覺管線、25 拉太遠滑脫、26 放手黏連、27 局部鼓、33 家 0.46H、34 描邊粗細；v2.8 加「v2.7 對照：蠕動與回彈」）。盲測做法：存 1（對照）→ 套一條 → 存 2 → 切 1／切 2 各捏一分鐘。「恢復預設」回到對照值。
- 「延遲測試」開關：手指按下那一幀整個畫面閃白一幀。用 240fps 慢動作同時拍手指和螢幕，數「指尖碰到→閃白」（輸入到畫面的管線延遲）與「碰到→攤開」（含物理）各幾格，每格約 4 毫秒。開關開著時不降 60Hz，數到的是 120 管線。

## 錄音怎麼放進來

照 `.uiux/04-手感/錄音指南.md` 錄完，`.m4a` 丟進 `NieNie/Resources/`，檔名填進同資料夾的 `manifest.json`，推上 `swiftui-port`。網頁原型那份放 `prototype/web/sfx/`，兩邊都要放。

## 雲端編譯

每次推到 `main` 或 `swiftui-port`，GitHub Actions 會在 macOS 機器上做一次不簽名的編譯。這一步只確認程式碼編得過，不會產生可以安裝的 App。

## 第一次上傳 TestFlight 要準備的東西

2026-10-31 到 11-01 上傳的 build（0.1.0 (22)；0.2.0 (29)、(35) 之後幾個）都傳進了用茄記 Bundle ID `org.domyweb.qieji` 建的那個 App；那個 App 2026-11-01 已從 App Store Connect 移除，`org.domyweb.qieji` 從此不能再建 App。同一天改成捏捏史萊姆自己的 `org.domyweb.nienieslime`，第 1、2 步要用新 ID 重做一次；之後只要做第 6 步。

簽名的做法（2026-11-01 改）：archive 那步不簽名，export 時才用雲端管理的 Apple Distribution 憑證簽。原本 archive 用自動簽名，每次全新的 CI 機器都會新建一張 Apple Development 憑證，Apple 兩張就滿額（run #33 失敗）。帳號裡 CI 建的那幾張 Development 憑證可以到 developer.apple.com → Certificates 刪掉，留著也沒影響。

以下都在 Apple 的網站上操作，用 Windows 瀏覽器就可以。TestFlight 內部測試不是公開上架：不經審核，只有你加進去的人（最多 100 人）能裝。

1. 註冊 Bundle ID：到 developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → 新增 App IDs，Bundle ID 填 `org.domyweb.nienieslime`。`org.domyweb.qieji` 是茄記的，不要用。想換別的 ID，要一起改 `project.yml` 裡的 `PRODUCT_BUNDLE_IDENTIFIER`，workflow 會從那裡讀。
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

- 全部還沒在真機跑過：延遲、掉幀、觸覺、聲音都是未驗證。v2.3 的按壓看起來大不大、`majorRadius` 在你的手機上跳得多厲害、閃白有沒有剛好一幀，也都要真機看。
- 效能：網頁版在電腦上每幀約 1 毫秒；Swift 版每幀 3 到 5 個小步，每步跑 70 個區塊、360 顆粒子、互不穿透格子。最舊機（iPhone XS／XR／SE 2）開低電量要實測，掉幀就先減粒子（`h = R / 9` 改 `R / 8`）或區塊。
- 系統設定裡的「系統觸覺」關掉後，Core Haptics 會不會自動停震。iOS 沒有 API 可以讀這個開關，要用真機關掉試一次。
- 減少動態的溫和版：活物感與抖動減半，回饋照常。實際感覺要真機看。
- 驗收照 `CLAUDE.md` 的方式：真機、最舊機加低電量模式、240fps 慢動作數延遲、找沒看過的人捏。
