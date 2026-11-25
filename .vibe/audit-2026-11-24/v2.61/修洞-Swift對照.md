# 修洞：網頁 0844ceb ↔ Swift 對照

2026-11-25。只改 `ios/NieNie/Slime/SlimeRig.swift`（+23 −2）。FeelParams.swift 不用改。沒有編譯過（這台沒有 swiftc），沒上真機。
「算式」指 `修洞-算式對照.js`：Swift 原文機械轉成 JS，跟 index.html 原文吃同一組輸入。

## 1. 這次加的

| 條 | 網頁 index.html | Swift SlimeRig.swift | 有沒有差 | 怎麼驗的 |
|---|---|---|---|---|
| 常數 inR、inC | 663 `ROUGH` | 476 `RoughSet` | 沒有（0.35、0.5） | 算式印出兩邊；改 0.351、0.501 會紅 |
| `drag` 是 0 或負 → 0 | 2238 | 5199 | 沒有（原本就有） | 算式，drag 0 有 33 萬格 |
| C3 熟、戒 | 2239 | 5201 | 沒有（原本就有） | 算式，imp、life2、impC3 各開關 |
| `emo` 關 → 不放鬆 | 2240 | 5202 | 沒有，門檻同 0.5 | 算式，emo 取 0、.49、.5、1 |
| 放鬆讀什麼 | 2240 `roughOn()?Math.max(strain,(tugS\|\|0)*tugIn()):strain` | 5203、5204 | 沒有。`tugS\|\|0` 把 undefined 當 0，Swift 的 `moodTugS` 從 0 起 | 算式，tugS 有兩成五是 undefined；rough 取 0、.49、.5、1 |
| `tugIn` 找手指 | 2243 Map 最後一根 grab、數 n | 5214 到 5216 字典任一根、數 n | 順序不同但沒差：n 是 1 才往下走，那時只有一根 | 算式，Swift 那邊順序打亂，多指 51 萬格；改成 n ≥ 1 會紅 |
| n 不是 1、r0x 沒有、tug → 0 | 2243 `n!==1\|\|f.r0x==null\|\|f.tug` | 5217 | 沒有。tug：網頁 undefined／false／true，Swift nil／false／true，只有 true 回 0 | 算式，沒記 r0x 9.8 萬格、tug 12 萬格；改成 `!= false` 會紅 |
| rl、dx、dy、dl | 2243 | 5218 | 沒有 | 算式 |
| rl、dl 小於 .1R → 0 | 2243 | 5219 | 沒有，都是嚴格小於 | 算式，有剛好 .1R 的輸入；改 .11 會紅 |
| 往中心的角度 | 2244 `-(dx*r0x+dy*r0y)/(rl*dl)` | 5220、5221 | 沒有，先負號再除，跟 JS 的順序同 | 算式；拿掉負號會紅 |
| 兩個 smooth01 相乘 | 2244 | 5222、5223 | 沒有，左右順序同 | 算式；.25 改 .26、.2 改 .21 會紅 |
| smooth01 | 1749 | 4960 | 沒有，夾 0 到 1 後 x²(3−2x) | 算式；改 2.001 會紅 |

## 2. 用到的量：同一個嗎、什麼時候更新

| 量 | 網頁 | Swift | 有沒有差 |
|---|---|---|---|
| 往回拔 tugS | 1721、1724（手放掉）、1728（拿去往回拔）、1713、963 歸零 | `moodTugS` 301：555 到 558、569、578、540、1054 | 同一個量。rough 關著時 Swift 固定 0、網頁停在舊值，關著時兩邊都不讀；rough 關著又切回開，網頁可能從舊值接，Swift 從 0（S3a 就有，記過） |
| 一格裡的先後 | 2425 判 tug → 2426 dragStep → 2527 moodStep | 2759 → 2760 → 2984 | 沒有。dragFollow 讀的都是上一格的 strain、tugS。腳本查原文先後，另跑閉環 96 萬格 |
| r0x、r0y 寫入 | 1122 落指、1191 摸轉抓，不看 A4 開關 | 2152、2377，不看 A4 開關 | 沒有，不用補。Swift 多一個「身體的群在不在」的保險，抓得到身體時一定在 |
| r0 用的中心 | `globalC` | `clusters[gi]` | 同一個（整身那一群） |
| f.x、f.y | 1216 螢幕位移 ÷ 鏡頭倍數累加 | 2181 `rawX` 同樣算；2656 每格 f.x 取 rawX，有新觸控的那一格取預測點 | 都是世界座標。預測點是手機本來就有的差，dragTarget 用的也是同一個 f.x |
| 縮放平移時 ax、ay 跟著搬 | 581（窗台拉遠那一段） | 651、652（x、y、ax、ay、fx、raw 一起） | 沒有。r0 兩邊都不搬（是相對向量） |
| tug | 724 判一次，之後不重判 | 5363 判一次，之後不重判 | 沒有。摸轉抓兩邊都不清 |
| R | 916 | 916 | 同一個，都是靜止半徑，不含鏡頭 |
| 換指、放手時的 dragRebase | 先從 fingers 拿掉再 rebase（1226、1227） | 先 removeValue 再 dragRelease（2498、2504） | 沒有 |
| 手指是 NaN | max 會傳 NaN | Swift max 會回 strain | 有，正常走不到，沒有另外處理 |

## 3. 數字

- 隨機 200 萬格：`tugIn`、`dragFollow` 最大差 0（門檻 1e-12）。tugIn 中間值 17.5 萬格、滿 10.8 萬格；放鬆真的比 strain 多的 5.6 萬格。
- rough 關：對動工前的 Swift（0844ceb）66.7 萬格位元不同 0。
- 閉環（先 dragFollow 再更新 strain、tugS，拉開量照 slide 公式）96 萬格最大差 0，1000 串裡 245 串跟手比動工前少；rough 關位元不同 0。
- 左邊抓往右下慢拉 3R、按住 3 秒的跟手：Swift 0.105、網頁 0.105、rough 0 是 0.105、動工前的 Swift 0.350。拉開量是公式值乘 1.6，只看量級，不是物理。
- 反證：改壞 15 處，15 處都紅。
- `--live`（網頁讀工作樹）結果相同。
- S3a：預設與 `--live` 全部一樣（最大差 1.3e-15）。S3b：預設 2 項不同（檔頭寫的預期：wakeSoft 開、a2a3b57 那版 tapJudge），`--live` 全部一樣。S2 也重跑，全部一樣。

## 4. 逐字複查這次的 diff

- 括號成對、函式在 class 本體裡、跟前後函式同一層。
- 型別：`rl dx dy dl dot inward wt ease` 都寫明 Double；`n` 是 Int，`g` 是 Finger?；guard let 解開 Optional，沒有強制解開；`f.tug != true` 跟 5243 既有的寫法一樣（Bool? 比 Bool）。
- var／let：`g`、`n` 在迴圈裡改，用 var；其他沒改過，用 let；沒有宣告了沒用的。
- 同名：全 ios/NieNie 只有一個 `tugIn`、一個 `smooth01`；`dot`、`inward`、`ease` 是區域變數（2907 行的 `ease` 是別的函式裡的巢狀函式，碰不到）。
- 存取：`tugIn` private，同檔同 class 呼叫；`RoughSet` private 巢狀 enum，`inR inC` 是 static let。
- 初始化順序：沒有新增儲存屬性。
- 抓到一處：註解「letting go it comes back to 0.46R」會被讀成放手，改成「following less it settles 0.46R off」。程式沒有要改的。
- 檔案換行：工作樹裡這個檔原本就有一行是 LF（1071），其餘 CRLF；新增的行用 CRLF，git 存的都是 LF。

## 5. 待確認、沒驗到

- 待確認：rough 關著再切回開時 tugS 的起點不同（見第 2 節），照 S3a 留著沒動。
- 沒驗到：Swift 編譯；真機的家偏 0.46R；預測點讓 tugIn 在移動那幾格差多少；手機回家力道下的洞讀數。
