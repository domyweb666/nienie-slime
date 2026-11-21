# 沒有 Mac 時在 Linux 上驗 Swift（v2.52 起）

多米沒有 Mac，以前每次改手機版都是「推上去才知道編不編得過」。這個資料夾讓 Agent 在推之前先驗一輪。

| 檔案 | 做什麼 |
|---|---|
| `check.sh` | 建替身模組，型別檢查控制器、調節台、SwiftUI 畫面、`SlimeView`、`JellySkin`。在 repo 根目錄跑，`swiftc`（Swift 6.x Linux 工具鏈，swift.org 下載）要在 PATH 上。沒有印出 error 就是過 |
| `stubs/` | 假的 UIKit、SwiftUI、Metal、QuartzCore、AVFoundation、CoreMotion，和 app 自己幾個重度依賴系統的類別（聲音、觸覺、場景圖）的替身。只有型別，什麼都不會動 |
| `harness-main.swift` | 真的跑物理：`swiftc -O -swift-version 5 -I <mod> harness-main.swift ../../ios/NieNie/Slime/{SlimeRig,FeelParams,SlimeFuzz}.swift ../../ios/NieNie/UI/FeelDeskModel.swift`（另外要把 `stubs/UIKit.swift` 編成一個靜態庫連進去），然後 `./a.out fuzz 1000 1029` 跑亂捏 30 組、`desk <網頁匯出的字>` 對匯出格式 |
| `run_web.py` | 無頭 Chrome（Playwright）跑網頁版：`run_web.py prototype/web selftest`（整套自測，約 15 分鐘）、`fuzz --seeds 1000-1029`、`eval --js 某檔.js` |

規矩：

- 物理三個檔（`SlimeRig`、`FeelParams`、`SlimeFuzz`）和 `FeelDeskModel` 只准用 Foundation，這樣 Linux 上能真的跑。
- 替身不等於真的 SDK。這裡過了 CI 還是可能有錯；這裡不過，CI 一定不過。
- 用到替身沒有的系統 API 時，先確認上一版原檔在這裡是過的（表示替身夠用），再補替身。不要為了讓檢查過去而改 app 的程式。
