# Handoff: 第九會話，v2.19 活物感（A1 到 A8、影子拿掉）做完，build 75 已上傳，還沒被真機捏過

> 產出時間：2026-11-02 02:49
> 前一會話的最後狀態，給下一個會話接續用。舊版備份在 `.vibe/handoff/archive/`

## ✅ 這次完成了什麼

- 多米捏 build 73 回報兩件事：下方影子有沒有必要；沒有活物感、不像生物，要很自然的生物。先在網頁版量 v2.18：放著 60 秒走 63%、身上有偽足 98%、安靜只有 2%；每段走路速度曲線一樣；手指放在畫面任何地方就整隻凍住；影子平常黏在身體下 0.35R，往上走時留在原地最遠 1.6R
- 寫提案 `.uiux/04-手感/活物感提案-暫定.md`（走 domi-uiux-feel），多米選方案甲：A1 到 A8 一次做成 v2.19
- v2.19 網頁版與 Swift 版都做了：總開關 life2，A1 休息／張望／出發／到了、A2 偽足用來探、A3 一縮一衝、A4 碰著也在呼吸（0.75）＋按在空白處不凍住＋iPhone 按住不動每次吸氣輕震、A5 晚一拍才縮（會習慣）＋拉完甩一甩、A6 呼吸快慢不一＋嘆氣＋喘、A7 探你碰的地方（不走過去）、A8 不畫影子。記形改跟「表演縮放後的參考形狀」比（PSM）
- selftest 加 T34（34 項），連跑 4 輪後 3 輪全過；舊項目一律關 life2
- 推了 swiftui-port 與 main（Pages 已更新），TestFlight build 75 上傳成功（run #75）
- CLAUDE.md 照多米點頭的草稿改了四段：手感 v2.19、場景不畫影子、活物感、待決定
- 測試紀錄補第 10 輪（多米 build 73）與自測 0t 輪；lessons 加兩條

## 🚧 還沒做完 / 待決定

- build 75 沒人捏過。要問多米：休息時會不會太安靜、一縮一衝像不像它自己在游、被碰後晚一拍縮那下看不看得出來、按住時吸氣的輕震舒不舒服。上上份留下來還沒回的：開場跳過來可不可愛、鏡頭跟的速度、背景光點會不會太花、逃的樣子、呼嚕舒不舒服（「走動會不會太忙」已被 v2.19 改掉，不用再問）
- Swift 版 v2.19 只確認雲端編譯過，沒在任何機器上跑過；真機上第一次看到才知道有沒有執行期的問題
- 第二批要多米決定：B1 碰旁邊空白處它走過去看（碰到不做清單原本的「主動找你」）、B2 40 秒沒人碰會睡著。B3 伸懶腰甩一甩、B4 體色只是排在後面
- 開場要不要從「跳過來」改成「游過來」：等多米看過一縮一衝再定
- 掉黏液、自己吸回去：原本排 v2.19，改成 v2.20。計畫在 `.uiux/04-手感/按壓與情緒提案-暫定.md` 第八節；做的時候接 v2.19 的走法：看到那一滴、伸偽足探、游過去、吸回來
- 像不像活的，要沒看過的人看（提案第六節：放著 30 秒請他講畫面發生什麼，記「它想、它怕、它在看」這類話的次數；再玩三分鐘看行為；v2.18 與 v2.19 給不同的人）
- 時好時壞：第一次連跑 4 輪時，第 1 輪除了原本就有的 T26 3.25，還多了 T16（第三批候選全開）一次失敗，細節沒記到。同條件下 v2.18 舊程式第一輪過、v2.19 重開頁面第一輪也過。下次再看到 T16 失敗，先抓當下狀態（lessons 第 49 條的作法）
- 從更早留下來的：閘門 3（延遲格數、最舊機低電量掉幀）沒量、盲測沒開始、參數表 `.uiux/04-手感/參數表-暫定.md` 只同步到 v2.8、面板存 1／存 2 的舊數值裝新版可能讀不回來（FeelParams 每版都加欄位）、身體超過約 8.5R 會抖

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 影子預設拿掉：場景是沒有地面的空中，背景光點當飄著的微塵；面板 A8 可以切回來
- 活的感覺的原則：大半時間是靜的，只在呼吸；動的時候看得出原因和方向，而且是身體自己出力；碰它先物理凹下去，晚一拍才自己縮；同一招玩多了會習慣；跑完會喘。身體怎麼動學水母和變形蟲，脾氣學貓
- 一縮一衝用「整團連同上一幀一起平移」做（不留速度）：黏土阻尼 0.94 每小步扣 6% 速度，靠物理帶不出慣性。到了往前晃一下用最後那一下的速度接著晃，不會突然多一腳
- life2 關掉時跟 v2.18 完全一樣（PSM 也只在 life2 開時用），面板一鍵對照才乾淨
- 碰著的呼吸設 0.75：手指抓住的中間那塊不跟著呼吸，0.75 量起來是沒碰時的六成
- 回歸測試一律關 life2（跟關情緒、關遊走一樣）；v2.19 只在 T34 測
- A7 只探不走過去；走過去是 B1，要多米點頭（不做清單邊緣）
- lifeRest 開著時拿掉隨機偽足與 twitch（沒有原因的抖像故障）；休息時蠕動降到三成，多米 v2.8 說過「平常就要在蠕動」，面板「休息時的蠕動」可以調回來

### 環境與設定（不變的事實，沿用上份並補新的）

- 多米沒有 Mac。編譯走 GitHub Actions，裝機走 TestFlight；build 號＝run number。push 觸發的編譯約 1.5 分鐘，TestFlight 那趟約 4 分鐘
- `swiftui-port` 有 Swift＋web＋docs；`main` 只放 web＋docs（Pages 自動發布）。推 main 用暫存 worktree：`git worktree add <scratchpad>/wt-main origin/main -B main-sync`，`git cherry-pick -n <commit>`，`git checkout HEAD -- ios`，確認 `git diff --cached --quiet <commit> -- prototype .uiux CLAUDE.md` 一致後 `git commit -C <commit>`、push 到 main，再移除 worktree 與分支。cherry-pick 遇到 ios 檔案會回 exit 1，checkout 過後照樣一致就沒事
- 發 TestFlight：等 push 觸發的編譯過，再 `gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`；上傳完成前不要再推 swiftui-port
- 本機預覽：8765 常被別的會話的伺服器佔著，而且服務的是同一個資料夾，直接開 `http://localhost:8765/` 就好。preview_start 會因為搶不到 8765 失敗（launch.json 的參數寫死 8765）
- selftest：34 項一輪約 80 秒，跑的時候頁面不回應，這時去讀 `window.__runs` 會逾時，等一下再讀。用 setTimeout 連跑 4 輪、結果放 `window.__runs`。瀏覽器面板藏著時 rAF 會停，手動驅動用 `window.requestAnimationFrame=()=>0` 再自己呼叫 `update(1/60)`；截圖前先 `draw()`，zoom 前先 screenshot 一次
- 自己寫的量法也要照 resetAligned 把時鐘、呼吸相位歸零，不然對照組基準對不起來
- 要跟舊版比：`git show HEAD:prototype/web/index.html > prototype/web/__v218.html`（selftest 同理），比完刪掉，不要 commit
- 測試裡模擬手指一律用累加位移（鏡頭在動）
- 改 JS 原型時，取代字串裡的註解放在整段新程式最後；改完用 node 檢查語法：把 index.html 最後一段 `<script>` 抽到 scratchpad 再 `node --check`
- Swift 在這台電腦編譯不了，複雜的三元運算寫明型別（`let e: Double = ...`），減少雲端編譯失敗

## 📂 下個會話最重要的檔案

- `CLAUDE.md` ← 手感 v2.19、場景、活物感、待決定
- `.uiux/04-手感/活物感提案-暫定.md` ← 第三節 A1 到 A8、第四節 B1 到 B4、第六節怎麼驗
- `.uiux/04-手感/手感測試紀錄-暫定.md` ← 最後面是真機第 10 輪與自測 0t 輪
- `.uiux/04-手感/按壓與情緒提案-暫定.md` ← 第八節掉黏液（下一個要做的 v2.20）
- `.uiux/lessons.md` ← 改演算法前先掃
- `prototype/web/index.html` ← LIFE、GAIT、FLN、SHK、BRX、STR、PSM 這幾個狀態；lifeStep、gaitStep、goStart、sniffEnv、lifeRelease；plasticity 的 SX2；draw 的影子開關
- `prototype/web/selftest.js` ← T34；reset、resetAligned 預設 life2 0
- `ios/NieNie/Slime/SlimeRig.swift`（同名函式）、`FeelParams.swift`（life2 到 flinchAmp、候選 218「v2.18 對照」）、`SlimeView.swift`（影子）、`ios/NieNie/App/SlimeController.swift`（按住時的呼吸輕震）

## ⏭️ 下一步從哪繼續

1. 先讀這份，再讀 CLAUDE.md 手感 v2.19 那條、活物感提案第三到第六節
2. 問多米 build 75 捏起來怎樣（他可能已經帶著回報來）。照「🚧」第一條的問題問；他說的是「感覺」就照老流程：網頁版重現、逐幀量出成因再改，兩版都改，selftest 連跑 4 輪，更新測試紀錄、lessons、CLAUDE.md（改 CLAUDE.md 前先把段落給他看），推兩個分支、發 TestFlight
3. 多米覺得 v2.19 可以，就請他決定 B1、B2 做不做，再提 v2.20 掉黏液的簡要計畫（行動前先給計畫、確認再做）
4. 有空檔就推「🚧」最後一條的舊帳：參數表同步到 v2.19、存 1／存 2 讀不回來

## 🗑️ 這次會話的雜訊（下次別重新討論）

- T16 第一輪失敗那次已經查過：life2 關掉時的路徑跟 v2.18 一樣，兩邊重跑都過，先當偶發
- 第一次量「碰著也在呼吸」只有 0.28，是我的量法沒把呼吸相位歸零，app 沒問題
- preview_start 在 8766 起不來、navigate 到 8766 失敗：用 8765
- 提案裡引的研究（Heider 與 Simmel、Tremoulet 與 Feldman、Johnson 等、黏菌習慣化）只是方向，不用再查
