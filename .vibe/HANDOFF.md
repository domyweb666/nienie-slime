# Handoff: 第七會話，v2.13 到 v2.15 加配音，TestFlight 發到 build 0.2.0 (67)，全部還沒經過真機確認

> 產出時間：2026-11-01 21:50
> 前一會話的最後狀態，給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

- 處理多米三輪真機回報，每輪都改網頁版和 Swift 版、自測連跑 3 輪以上全過、推兩個分支、發 TestFlight：v2.13 是 build 59、v2.14 是 61、v2.15 是 63
- v2.13（多米：鏡頭無限拉遠、拉伸上限一起放寬）：鏡頭沒有下限、沒有牆；點加密到每個半徑 12 個（dens）；抓著時鏡頭留邊（camFill 0.7）
- v2.14（build 59 回報：回彈太快、從中間拉沒反應）：回原形 0.3 改 0.05（15 秒退一半），有交叉時照 0.3 退，不然長條的結解不開；從身體裡面抓的話，手指一動就往拉的方向補抓一條到外圈（grabReach），往裡捏不補
- v2.15（build 61 回報：拉到某個程度會抽搐、點一下要有效果）：手指在世界裡只跟著真正的移動走（抽搐的源頭，見關鍵決策）；黏土拉伸 7R、記形 5R；形狀大時鏡頭對準形狀中心並留邊（camCenter 預設開）；點一下留凹痕（dent）
- 第一版配音（多米：史萊姆是虛構的，要 Agent 配音）：`prototype/sfx-design/design_sfx.py` 離線產生 29 段 wav，build 65
- 多米在另一個會話做了 Sound v2（分層音效、拉改成連續的黏絲聲、Swift 的 SlimeAudio 重寫），本機已快轉同步，這個會話替它發了 TestFlight：build 67（提交 `ce07cfd`）
- selftest 從 25 項長到 30 項（T26 重寫成重複抓、T27 從中間拉、T28 回彈、T29 手指停住不抖、T30 凹痕），T25 改成「停住不會自己長」；selftest 的 reset 加上停掉遊走（漏洞：上一輪留下的遊走讓身體飄 58 點，兩指捏時好時壞）
- 測試紀錄補到真機第 6 到 8 輪、自測 0m 到 0p 輪；lessons 加了十條；CLAUDE.md 版本紀錄寫到 v2.15、「聲音」那條改成 Agent 設計的音效

## 🚧 還沒做完 / 待決定

- build 63、65、67 都還沒被真機捏過。最新是 67（v2.15 加 Sound v2）。要問多米三件事：還會不會抽搐、凹痕像不像凹下去、「要拉長得放手再抓」能不能接受
- Sound v2 的聲音好不好聽，只有多米聽得出來。兩個會話都只看過頻譜和數字
- Sound v2 說明裡寫的：大力放手的「啵」改成越用力越低，要多米確認順不順
- 裝新版後面板「存 1／存 2」的盲測數值讀不回來（Sound v2 多了三個參數欄位），要重存
- 已知限制：這套固定點數的身體，形狀超過約 8.5R 就會抖。要真的無限拉長，得讓點數跟著拉長增加（重新分配邊界點），是一個獨立的大工程，還沒開始
- 按在畫面邊拉到 9R 那種極端情況，按著時尾端會交叉幾幀，放手 2 秒內解開（T26 判定只看放手 2 秒後）
- 從上一份 handoff 留下來的：手機版真機測試清單沒做、閘門 3（延遲格數、最舊機低電量掉幀）一次都沒量、盲測沒開始、參數表 `.uiux/04-手感/參數表-暫定.md` 只同步到 v2.8。點數加密到 1.7 倍之後，最舊機掉不掉幀更需要量

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 手指在世界裡的位置只跟著手指真正的移動走：螢幕位移 ÷ 當下鏡頭倍率。不准再每幀把螢幕座標換回世界，那樣會跟會縮放的鏡頭形成正回饋：手指不動，形狀也會自己長，長到抖。v2.12 的「按在畫面邊不放會一直拉長」就是靠這個，已經拿掉
- 要拉更長就放手再抓：形狀大到要縮鏡頭時，鏡頭對準形狀中心、兩邊留邊（沒碰時留 0.8、拉開 0.5R 以上留 0.7），每抓一次多約 1R
- 鏡頭留邊只在真的拉開 0.5R 以上才生效：一按下去就縮的話，手指底下的畫面會動
- 黏土長度上限：拉伸 7R、記形 5R。加阻尼、點加密到 14、整體形狀加強、少跟手、面積壓力限範圍都試過，超過 8.5R 照樣抖
- 回原形 0.05、有交叉時 0.3
- 聲音用離線設計的音效檔，不在 app 裡即時合成，也不錄真的史萊姆（錄音指南留著備用）。目前是多米的 Sound v2：公式在 `.uiux/04-手感/音效參數對應-暫定.md`，網頁和 Swift 照同一張表，改數字三處要一起改
- 時好時壞的測試失敗：先抓一次失敗當下的完整狀態，不要先猜原因去改程式（這次連猜三個都錯）

### 環境與設定（不變的事實）

- 多米沒有 Mac。編譯走 GitHub Actions，裝機走 TestFlight；build 號＝run number
- `swiftui-port` 有 Swift＋web＋docs；`main` 只放 web＋docs（Pages 自動發布）。推 main 用暫存 worktree cherry-pick，`ios/` 保留 main 自己的（cherry-pick 乾淨套上時要記得把 ios 的改動拿掉再 amend），`prototype/`、`.uiux/`、`CLAUDE.md`、`.vibe/`、`.gitignore` 取 swiftui-port 的版本
- 發 TestFlight：等 push 觸發的編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`；上傳完成前不推同分支。另一個會話（雲端）觸發時會被權限擋，本機這裡可以
- selftest 在本機跑：`E:\捏捏史萊姆\.claude\launch.json` 的 web-proto（python http.server 8765），手機尺寸 375×812。一輪 30 項約 40 秒，頁面跑的時候不回應，javascript_tool 等 45 秒就逾時：用 setTimeout 讓它背景跑、結果放 `window.__runs`，分次讀。重新整理頁面之後再排程，不然排程會被重新整理吃掉
- 量測輔助：在 `prototype/web/` 放暫時的 `_probe.js`（已在 `.git/info/exclude`），fetch 後 eval；用完刪掉
- 測試裡模擬手指要用累加位移：每幀 `螢幕位置 += (世界目標 − 手指現在的世界位置) × 鏡頭倍率`，不能直接把世界目標換成螢幕座標（v2.15 之後手指是累加的）
- JS 原型很多一行多句：註解一律加在行尾最後；用 python 插入程式時，注意原本行尾的註解會被接到新插入的那一行後面
- Windows 的 Bash heredoc 遇到很長、含很多引號的 python 會出錯，改用 Write 寫到 scratchpad 再執行

## 📂 下個會話最重要的檔案

- `CLAUDE.md` ← 外形、手感（v2.13 到 v2.15）、場景、聲音
- `.uiux/04-手感/手感測試紀錄-暫定.md` ← 最後面是真機第 6 到 8 輪、自測 0m 到 0p 輪
- `.uiux/lessons.md` ← 這次加了十條，改演算法前先掃
- `.uiux/04-手感/音效參數對應-暫定.md` ← Sound v2 的公式（多米的會話寫的）
- `prototype/web/index.html` ← move()（手指累加）、updateCam（留邊、對準形狀）、reachGrab、DENTS、plasticity 的退形
- `prototype/web/selftest.js` ← T25、T26、T29、T30 新寫法；reset 停遊走
- `ios/NieNie/Slime/SlimeRig.swift`、`FeelParams.swift`、`SlimeView.swift` ← 同上的 Swift 版；凹痕畫在 dentShadeLayer、dentLitLayer
- `prototype/sfx-design/design_sfx.py`、`prototype/web/sfx/engine.js`、`prototype/web/sfx/listen.html`、`ios/NieNie/Feedback/SlimeAudio.swift` ← Sound v2

## ⏭️ 下一步從哪繼續

1. 先讀這份，再讀 CLAUDE.md 的手感、聲音兩條和測試紀錄最後三張表
2. 問多米 build 67 捏起來、聽起來怎樣（他可能已經帶著回報來）。手感問：還會不會抽搐、凹痕像不像、放手再抓能不能接受；聲音問：哪一類哪裡不對（例如「放手 重 太悶」）
3. 手感回報照這次的流程：網頁版重現、逐幀量出成因再改；兩版都改；selftest 連跑 3 輪以上全過（第一輪過不算數）；更新測試紀錄、lessons、CLAUDE.md；推兩個分支、發 TestFlight
4. 聲音回報：音色改 `design_sfx.py` 重跑；跟手的反應改 `音效參數對應-暫定.md`，網頁與 Swift 一起改
5. 手感穩下來之後：補參數表 v2.9 以後的列；做手機版真機測試清單；量閘門 3（點數多了 1.7 倍，最舊機更要量）

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 「按在畫面邊鏡頭自己一直退」（edgeZoom）：鏡頭退到看不見、形狀卻停住，撤掉
- 「拉越長定身越鬆」（anchorFade）和「定身只拉遠端」（anchorTail）：一個讓整隻被拖走，一個對交叉沒幫助，都撤掉
- 「拉長了不蠕動」「小結拉直範圍加大」：跑 5 次跟原本分不出差別，撤掉
- 「放手那一幀把形狀整個記下來」（releaseBake）：放手時本來就沒有彈性的部分，量了沒差，撤掉
- 「面積壓力推量限在離重心 1.2R 內」（areaReach）：沒有改善，撤掉
- 我第一版的 29 段配音已經被 Sound v2 取代，不用回頭看
