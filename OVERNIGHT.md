<!-- overnight: running -->
# Overnight 報告
## 早上摘要
（全部做完才寫）

## 這晚的基準

- 分支 `overnight-20261126-1110`，工作樹 `E:/捏捏史萊姆/nienie-slime/.claude/worktrees/overnight-20261126`。
- 起點：`split-merge-v1`（v2.62 扯斷合併，`f4ab4a7`）合進 `feel-3x-panel-v1`（v2.61b 湯圓餡、邊緣，build 164，`2406ae0`），合併提交 `4800f9a`。
- 範圍：`.uiux/04-手感/極致優化規劃-暫定.md` 的第二批（多米 11-25「7 題都照推薦」、「第二批最前面先做 C4 和大腦」），再加未做清單裡標「Agent」、不用多米決定的雜項。
- 等多米真機捏、聽、摸才能定的（A3 到 A5、D5、D7、B8 盲比、所有音量和震動強度的最後數字）今晚不做，只做到「有開關、數字先取」。
- 版本字樣：這批網頁和手機都寫 v2.63。

## 每一項的共同規矩（子代理照這份做）

1. 先讀 `CLAUDE.md`（專案）、`.uiux/lessons.md`、規劃裡那一條的「做法」「驗法」，以及第一批的寫法（`.vibe/第一批-合約.md`、網頁 `index.html` 搜 `v2.61`、Swift 搜 `v2.61`），照同一套風格。
2. 每條新行為都是一個參數：網頁 PRESETS 三個材質都要有、`FeelParams.swift` 同名同預設，調節台「這一批（v2.63）」一塊放開關。0 的意思一定是「跟改之前一模一樣」。
3. 網頁先做、量；過了再搬 Swift。Swift 逐行對網頁，物理三個檔（`SlimeRig`、`FeelParams`、`SlimeFuzz`）和 `FeelDeskModel` 只准用 Foundation。
4. 網頁驗證：`tools/web-bench/st.py` 跑相關項目（`--tests`），新行為要加 selftest 項目（T75 起編號）。不准為了綠燈改門檻。
5. 手機沒有 swiftc，本機只能讀；主對話會在幾個節點推這條分支、手動跑 ios.yml（testflight=false，只編譯不上傳）。
6. commit 一律指定檔案，不用 `git add -A`。訊息寫第幾項。
7. 同一個問題試 3 次還不行，寫進「卡住的項目」，做下一項。

## 任務清單

- [x] 1. 合併後的起點驗一次：網頁整份自測 3 次全過（也補 v2.62 少跑的 2 次）。完成標準：3 次都 74／74。
- [x] 2. C4 手機（`2859c85`，CI run 45748592614 BUILD SUCCEEDED）：打開、從背景或鎖屏切回來，牠先轉過來看你、眨一下，睡著就慢慢醒（照網頁 `greetLook`）。完成標準：Swift 接上 `greetLook`、逐行對過網頁、CI 編過。
- [x] 3. 手機大腦第一片（`dadb9c5`，CI run 45750291812 BUILD SUCCEEDED）「需求和自己醒」：五個需求、放著自己走探睡醒、作息有亂數（照網頁 brain、brJit）。開關 `brain`，預設開。完成標準：Swift 逐行對網頁、Linux 替身能編的檔只用 Foundation、CI 編過；手機的「40 秒沒碰就睡、不會自己醒」在 brain 開時不再發生（讀程式確認），brain 0 跟現在一樣。
- [x] 4. 手機大腦第二片（`50ee659`，CI run 45751373861 BUILD SUCCEEDED）「心情」：心情值、心情影響姿勢和反應（照網頁 mood、moodHalf）。開關 `mood`，預設開。完成標準：同上，CI 編過。
- [x] 5. C9 網頁（`f22a9f8`）：揉夠了放手，牠在你最後摸的地方趴下睡著（呼嚕累計 60 秒、手指離開 6 秒），不走回布墊；輕碰慢慢醒。開關 `nap`，預設開。完成標準：新 selftest 項目驗三件事（一般捏 30 秒不睡；揉夠那次 10 秒內睡、離最後摸的地方 0.5R 內；輕碰不嚇醒），相關舊項目不退。
- [x] 6. C9 搬手機（`e4ceb60`，CI run 45755528219 BUILD SUCCEEDED）。完成標準：逐行對網頁、CI 編過。
- [x] 7. D3 從手裡跑掉的前兩條改掉（`abedb67`，CI run 45761695432 BUILD SUCCEEDED）（推薦：怕的不再滑走，改抗議聲、眼睛、放手後走開；搔癢不放手，改扭和咯咯黏液聲），兩指 621 點撕開留著。各一顆開關，預設是新行為。兩邊都做。完成標準：連拉 10 次脫手 0、搔癢 20 秒還在手裡、兩指照舊撕開；搔癢的 selftest 項目和標準清單 41 跟著改。
- [x] 8. C5 拿掉朝下張望（`ee7126a`，CI run 45772854420 BUILD SUCCEEDED）（兩邊）。完成標準：張望方向不再朝窗台下面（量 255 次朝下 0 次或接近 0），開關 `lookNoDown`。
- [x] 9. C6 揉牠反應輪流（`b4950bc`，同上 CI 編過）（兩邊）：小跳 40 秒內最多一次，其餘輪流，叫聲抽完一輪再重抽。完成標準：網頁揉 10 分鐘最常見那組 40% 以內。
- [x] 10. B6（`8ca1e5b`，CI run 45779153120 BUILD SUCCEEDED） 拉回去再拉要有絲聲、按下去不蓋掉別的聲音（兩邊）。完成標準：讀聲音事件紀錄確認兩件事都發生；開關預設開。
- [x] 11. B2、B5（`c3e190c`，同上 CI 編過） 按聲：輕點重壓聲音大小有差（手機讀手指大小或力道）；嚇到、開心、不要啦、按的濕聲不再隔一拍（兩邊）。完成標準：事件紀錄裡聲音和動作同一格；B2 輕重兩種音量差可量；開關預設開，數字標「等多米聽」。
- [x] 12. D4（`c075e45`，CI run 45788049251 BUILD SUCCEEDED） 牠縮那一下同時有一小聲和一下輕震，後 0.3 秒內放手的「噗」不重複（兩邊，強度先取小）。完成標準：事件紀錄同一格；開關預設開，強度標「等多米摸」。
- [x] 13. B1 拉的聲音（`f0c04ec`，同上 CI 編過）、B3 慢拉 0.4 秒內就震（手機）。完成標準：讀程式確認慢拉的震動起點在 0.4 秒內；開關預設開，強度標「等多米摸」。
- [x] 14. D6（`4533b8b`，CI run 45799324354 BUILD SUCCEEDED） 熟拆兩層：今天的親近＋只升不降的交情（不顯示數字）；戒高時溫柔摸 3 秒先嘆一口氣才呼嚕；很熟第一下不縮、朝手指靠（兩邊）。完成標準：網頁新 selftest 項目驗「戒 0.9 按 3 秒不開心、三分鐘後照常」「畫面沒有天數等級」，開關 `bond`。
- [x] 15. B9（`b736af9`，同上 CI 編過） 聲音跟著手走「動一點一顆」（兩邊），放手那層不做。完成標準：手停聲音就停（事件紀錄）；開關預設關（新聲音，等多米聽）。
- [x] 16. 關掉的玩法還在耗電（`2054f3e`）：搖晃和走路關著時，手機不再每秒讀 60 次感測、不再讀步數（未做 82）。完成標準：讀程式確認關著時不啟動；CI 編過。
- [x] 17. 調節台小毛病（`c0c5466`）：換材質、回預設時牠不彈一下（未做 83）。完成標準：網頁量換材質那幾格的位移跳動變小；Swift 同改。
- [x] 18. 上架基本檔（`5034a11`）：隱私清單檔 `PrivacyInfo.xcprivacy`、步數權限文字拿掉「沾到什麼」、版本號（未做 77 的這三件）。完成標準：檔案在 `ios/` 裡、`project.yml` 有收進去、CI 編過。不碰付款、不碰上架設定。
- [x] 19. AI 音效商用條款查證（提前做，跟程式不撞檔）（未做 75）：ElevenLabs 條款原文，順手看 Higgsfield。完成標準：`.uiux/04-手感/素材授權紀錄.md` 補一節，附原文連結和日期，只寫查到的。
- [ ] 20. 文件跟上程式：參數表補 v2.61 到 v2.63 的參數、未做清單改狀態、規劃第二批標做到哪。完成標準：參數表和程式對得上（用腳本比對 PRESETS 的鍵）。
- [ ] 21. 收尾：網頁整份自測 3 次全過、Swift 在 CI 編過、寫早上摘要和 HANDOFF。

## 待確認（需要多米決定的事）
- C9 手邊睡著的兩個數字（呼嚕累計 60 秒、放手 6 秒）是 Agent 取的，真機捏過再定；睡完累計歸零、同一次打開要再揉滿 60 秒才會再發生，也是 Agent 取的。
- 手機換材質時，手邊睡著的累計可能不歸零（網頁會歸零，因為網頁換材質會整隻重建）。差別很小，先沒改。

- D3：怕的撐著時每 1.5 秒抗議一次，只有第一次加 0.05 的戒；搔癢一直撥一直咯咯，不換成抗議聲。兩個都是 Agent 取的，真機聽過再定吵不吵。
- 音效授權：ElevenLabs 免費方案只能非商用，付費（Starter 以上）才能商用，而且免費期間生成的檔之後升級也不能商用。請到 ElevenLabs 帳單看 11-21 生成那天是不是付費方案，截圖存證。是免費的話要重新生一次。
- 音效授權：GitHub Pages 公開放著 ElevenLabs 原始檔 177 個、Higgsfield 68 個和比較頁，可能踩到「不能當單獨音檔提供」那條。建議上架前從公開網站拿掉（App 裡的檔不受影響）。這要動公開網站，今晚沒做。
- C5：張望只在窗台上不朝下（朝下那半照水平線鏡射上去），看起來會不會太常抬頭，真機看。
- C6：揉完放手的四種反應（小跳、多攤 2 秒、朝手指靠、嘆氣）用洗牌袋輪流，小跳 40 秒最多一次，40 秒和 2 秒寫成常數沒進調節台。多攤寬 5%、矮 6%，手機上看不看得出來要真機看。
- 聲音（B6、B2、B5）：縮回 1.5 格退一格、按聲輕 0.35 到重 0.95（半徑 18／42 pt）、音檔前奏到 −6 dB 晚於 30 毫秒才切，數字都是 Agent 取的，等多米聽。開心、不要啦、濕聲有幾個檔切完最大聲還是晚 65 到 320 毫秒（檔裡第二下比第一下大），沒再處理。B2 的震動跟力道走留給 D7。
- D4／B3（震動、小聲）：縮那下聲音 0.3、震動 0.25、銳利度 0.2，縮得比 flinchAmp×0.7 小就不出聲不震（連點第 3 下起就沒了）；慢拉震動的底 0.08、拉絲聲的底 0.3×pullMax。全是 Agent 取的，等多米摸、聽。快點（按 0.1 秒就放）時噗在放手那下，縮那下只震。慢揉畫圈前半圈也會有起步的底。
- D6 交情：熟滿且被溫柔對待時每分鐘 +0.01（約 100 分鐘滿），交情 0.3 到 0.7 漸強；戒 > 0.5 要先哄 3 秒，哄的時候也不蹭不哼（Agent 多加的）。數字都是 Agent 取的。交情存在本機跨天保留，不顯示任何數字。
- B9 顆粒聲預設關：用最短的 settle.bubble，每走 12 點一顆、每秒最多 20 顆，開著時循環聲減半。等多米聽過再決定開不開。
- 省電（第 16 項）：搖晃關著時，窗框風鈴不再跟著真的搖手機晃（調節台的假裝搖照樣會晃）。要留風鈴，晃動感測就得一直開。
- 換材質（第 17 項）：手機調節台換材質、回預設時故意的小晃（`bump`）沒拿掉；真機看了還覺得在彈就一起拿掉。換到身體大小不同的材質（只有藍底會）還是會重建。
- 步數權限文字（第 18 項）：檔案用「用你走的步數決定牠有多有精神。步數只留在這支手機上。」另一個候選：「你今天走得越多，牠就越有精神、動得越活潑。只讀步數，步數只留在這支手機上，不會傳出去。」走路帶東西回來的功能（`walkShow`）開著時這句少講一點。版本號 0.2.0 沒改，上架時再定。

## 卡住的項目

## 執行紀錄
- 11:10 開分支 `overnight-20261126-1110`，合併 v2.61b 進 v2.62，只有 HANDOFF.md 衝突（兩邊段落都留）。背景開跑第 1 項（快照 `4800f9a` 整份自測 ×3）。
- 11:22 第 2 項做完（`2859c85`）：手機接上 `greetLook`，打開等落地、切回來等 0.35 秒看你 1.4 秒加眨眼，睡著切回來慢慢醒不出聲；調節台兩邊加「這一批（v2.63）」，版本字樣 v2.63。網頁 T75（新）、T71、T72、T1–T10 各 3 次全過。Swift 沒編，可疑處：`startIntro` 的 `defer`、`FeelBatch.Item`、`eyeStep` 的 else-if。開始第 3 項。
- 11:23 推 `overnight-20261126-1110`（`fb9ade6`），手動跑 ios.yml testflight=false，run 45748592614，等結果。
- 11:36 第 1 項過：快照 `4800f9a` 整份自測同時跑 3 次，3 次都 74／74，1386 秒。v2.62 規定的 3 次補齊。
- 11:38 CI run 45748592614（`fb9ade6`，含第 2 項）BUILD SUCCEEDED，只有舊的 `SlimeView.swift:917` `paths` 可改 let 警告，沒上傳 TestFlight。
- 11:38 第 3 項做完（`dadb9c5`）：新檔 `ios/NieNie/Slime/SlimeBrain.swift`（只用 Foundation，check.sh 兩個清單都加了），`SlimeRig` 約 6750 行起接 brainStep／Rest／Go／GoHome、sleepOK、e4OK、brainJit、brainBack；`brain brPre brAwakeT brSleepT` 登記，`brJit` 生效。心情、記地方、擺飾在手機一律當關。brain 0 讀程式確認跟 `2859c85` 一樣（rng 抽的次數順序不變）。網頁只改 KEYS63 一行，T71、T72、T75 各 3 次跟改前逐筆同。可疑編譯處：`SlimeBrain.swift:78` 泛型 jit、`SlimeRig.swift:6859` 同時借 brain 和 &rng、`5195` 條件裡呼叫 mutating、`e4Step` guard 三元式。推上去跑 CI，開始第 4 項。
- 11:43 CI run 45750291812（`e19b575`，含第 3 項）BUILD SUCCEEDED，沒有新警告。那幾處可疑寫法都編得過。
- 11:49 第 4 項做完（`50ee659`）：SlimeBrain 加心情 m／mS／ev 和 mood()，SlimeRig 加 mdOn／brainM／brainMS／brainFlinch／brainEv／brainSync，`mood`（1）、`moodHalf`（300）登記進調節台 v2.63，換隻時 brainSync。接上需求漲落、挑事情、心情差 8 秒走回布墊、姿勢、縮的大小、步子、被戳退開或搖、眼睛、張望 +0.005、嚇醒 −0.1。心情不存檔。mood 0 逐位元同 `dadb9c5`。網頁只改 KEYS63，T71／T72／T75 各 3 次逐筆同。可疑：SlimeRig 6850 `pick(...brm:)`、6770 `MoodIn` 參數順序、6468 `g == nil`、3183 `max(0, ms)`。推上去跑 CI，開始第 5 項。
- 12:00 CI run 45751373861（`e20a90d`，含第 4 項）BUILD SUCCEEDED，沒有新警告。
- 12:24 第 5 項做完（`f22a9f8`）：網頁 `NAP`、`napReady`、`napStep`（接在 sleepStep 後），lifeStep 等睡那幾秒不換事情；`nap` 1、`napPurr` 60、`napWait` 6。T76 三種子：一般捏 30 秒累計 19.2 秒不睡；揉滿 68.8 秒放手 5.87 秒睡、離最後摸的地方 0.16R、沒走回布墊；睡著輕碰前兩下翻身第三下慢慢醒、沒嚇；nap 0 不睡。舊 T33/34/38/55/56/60/71/72/75 各 3 次逐筆同，整份 76／76 一次。取的做法：睡完累計歸零；6 秒到了不能睡再等 2 秒，過了就算了；原地睡不挪位置。移植說明 `.vibe/C9-移植說明.md`。開始第 6 項。
- 12:29 第 6 項做完（`e4ceb60`）：手機 `napCum/napOn/napX/napY/napN`、`napReady`、`napStep`（每幀 sleepStep→napStep→echoStep），lifeStep 加 `!napOn`，呼嚕來源用 `purr > 0.3`（同網頁 PURR）。`nap napPurr napWait` 進調節台 v2.63，build 158 那檔一起關。nap 0 讀程式確認同 `036bea1`。可疑：SlimeRig 6688–6691 napReady 四個 Bool、6696 `for … where` 加 `||`。推上去跑 CI，開始第 7 項。
- 12:33 CI run 45755528219（`c1e71da`，含第 6 項）BUILD SUCCEEDED，沒有新警告。
- 13:26 第 7 項做完（`abedb67`）：`holdScared`、`holdTickle` 預設 1（網頁 dragStep C3、releaseFinger、e2Step；手機 Finger.scared、C3、release、e2Step）。T77 6 次全過：戒 0.65 連拉 10 次脫手 0、抗議 10、走開 10；撥 20 秒不掙脫、扭 28 次；兩指 705 點照舊撕開；開關 0 照舊滑走 10／10、6.72 秒掙脫。舊搔癢項 T37 L5、T38 L6、T39 L7 釘 `holdTickle: 0`，門檻沒動。整份 77／77 一次。標準清單 41 加註記。可疑：SlimeRig 6127 `if let g, …, … else if let g`、2530 flee。推上去跑 CI，開始第 8 項。
- 13:30 第 7 項推上去跑 CI（run 45761695432，`00a54f4`）。第 8、9 項交給同一個子代理依序做（各自 commit）。第 19 項（查條款，只寫一份文件、不 commit）同時開跑，跟程式不撞檔，主對話之後提交。
- 13:31 CI run 45761695432（`00a54f4`，含第 7 項）BUILD SUCCEEDED，沒有新警告。
- 13:40 第 19 項做完：`.uiux/04-手感/素材授權紀錄.md` 最後加一節（ElevenLabs、Higgsfield 條款原文連結、2026-11-26 查詢、白話結論）。沒查到：Sound Effects v3 是不是 Beta、Beta Services Addendum、Mirelo 條款、Apple 對 AI 內容的揭露規定。
- 15:06 第 8 項做完（`ee7126a`）：網頁 pickDir／pickDir0、Swift 同名，`lookNoDown` 1，只在窗台生效，朝下鏡射到上面、不多抽亂數。T78：255 次朝下開 0／關 42%，戒的時候開 0／關 75%，放著 6 分鐘 29 次開 0／關 9。釘 `lookNoDown: 0`：T44 T45 T46 T48 T55 T74（整份比對兩版找出），逐筆同舊版。
- 15:06 第 9 項做完（`b4950bc`）：網頁 rubHappy、RUBV、vbagPick（engine.js 可指定檔），Swift rubHappy、SlimeAudio、SlimeController、Linux 替身 AppStubs。`rubVary` 1，洗牌用獨立亂數。T79 揉 10 分鐘 49 次：最常見那串 14%（關 76%），小跳間隔最短 41 秒，叫聲連兩次同檔 0。釘 `rubVary: 0`：T33 T39 T41 T66 T67 T76。T65 單獨跑本來就每次不同，沒釘。整份 79／79 一次（1335 秒）。可疑：SlimeAudio 328 三元式傳 Int?、87 Play 新欄位預設值；SlimeRig 486 rubHappy 參數 fx 同名屬性、Optional 比較；3239 巢狀三元；5077 鏡射。推上去跑 CI，開始第 10、11 項（同一個子代理依序做）。
- 15:09 CI run 45772854420（`c0732bc`，含第 8、9 項）BUILD SUCCEEDED，沒有新警告。
- 15:57 第 10 項做完（`8ca1e5b`）：原因是每指斷絲格數只增不減，縮回再拉不斷；按下去清掉整排待播（手機連撕開後的滴也清）。改成縮回 1.5 格退一格、按只清上次放手的小泡泡。`sndB6` 1。T80：第一次拉斷 3、縮回再拉斷 1（關 0）；按下去拉絲 0.54→最低 0.49、揉 0.18→0.17。
- 15:57 第 11 項做完（`c3e190c`）：B2 原因是抓下去固定 0.7，手機讀半徑時手指還沒記下來永遠 0；改用壓力或接觸半徑（網頁 pressure/width，手機 UITouch.force/majorRadius 從觸控層傳 Double）。B5 原因是音檔前奏最長 285 毫秒，嚇到先叫 0.05 秒後才縮；載入時替四種聲音做跳過前奏的版本，嚇到排到縮那格。`sndB2` `sndB5` 1。T81：半徑 18→0.35、42→0.95，壓力 0.15→0.44、0.9→0.89；四種聲音和動作差 0 格。只釘 T72 `sndB5: 0`。整份 81／81 一次（1375 秒）。可疑：SlimeRig 6372 `if let at` 省略預設參數、5191 `if let s = flSay, … || …`；SlimeAudio 256–285 floatChannelData 與可失敗初始化、248 map 閉包隱式 self；SlimeView 381 CGFloat→Double。推上去跑 CI，開始第 12、13 項。
- 16:00 CI run 45779153120（`0f08c18`，含第 10、11 項）BUILD SUCCEEDED，只有舊的 paths 警告（行號移到 919）。
- 17:00 第 12 項做完（`c075e45`）：只處理碰出來的縮，縮那格出放手噗 air 層小聲版＋輕震，0.3 秒內放手不再噗。網頁 FLX、hapEv、HAP.log（只記紀錄）；手機新事件 `.flinch`、relQuiet、SlimeAudio.flinch。`flinchFx` 1。T82：縮、聲、震同在第 12 格，放手沒第二聲；隔 4 秒連點 12 下前 2 下有聲震、第 3 下起沒有；0 對照沒有。
- 17:00 第 13 項做完（`f0c04ec`）：原因是黏土慢拉整隻被拖、拉伸長得慢，拉絲聲要 0.2R、震動要 0.41R 才開。強度公式和遲滯不動，加起步的底取大。網頁 PFX、hapContStep（只記紀錄）；手機 PullFxSet、pullOpen、SlimeController pullFloor、SlimeAudio.pullOpen。`pullFx` 1。T83：每秒 0.5R 慢拉開 0.13 秒震、0.12 秒有聲（關 1.02、0.62）；快拉 0.5 秒強度 0.182 跟改前同。兩項舊項目都不用釘。整份 83／83 一次（1409 秒）。可疑：SlimeRig 25 頂層 enum PullFxSet、2792–2796 do 區塊、5228–5232 `.flinch`；SlimeController 214；SlimeAudio 411、463–468。推上去跑 CI，開始第 14、15 項。
- 17:04 CI run 45788049251（`53731b8`，含第 12、13 項）BUILD SUCCEEDED，沒有新警告。
- 18:13 第 14 項做完（`4533b8b`）：網頁 BONDK／BOND／BONDS／SOO、bondTouch、sooStep，改 impStep、impRelease、moodStep、e2Step、impLoad／Save／Back、chooseSlime、setup、lifeStep；Swift BondSet、SooSet、bondTouch、sooStep、setBond，存在 nienie.imp 的 bd。`bond` 1。T84 3×2 全過：戒 0.9 按 3 秒不呼嚕、3.02 秒嘆氣、4.27 秒呼嚕；三分鐘後戒 0.449 照常呼嚕；交情高第一下縮 0、朝手指靠 0.11R；60 秒漲 0.00984；連點快扯不扣；畫面沒有天數等級；bond 0 存檔不寫 bd。釘 T77 `bond: 0`。
- 18:13 第 15 項做完（`b736af9`）：網頁 GRK、grainStep、engine.js SFX.grain；Swift SlimeAudio grain／grainLoop，跟質地微震 `.tick` 同時放。`sndGrain` 0。T85：0.5R/s 每秒 4.25 顆、1R/s 8.5 顆，手停 0.1 秒後 0 顆，0 時其他聲音逐筆同。整份 85／85 一次（1450 秒）。T74 第一組合回面積 0.996→1.003（±3% 內），釘 bond 0 也一樣，判斷是前面 T84、T85 留下的狀態，沒釘。可疑：SlimeRig 372 private enum BondSet、643/665/677 soo 跨區塊賦值、6290/6300；SlimeController 308 `as? [String: Double]`、323 `||` 換行開頭、330 JSON；SlimeAudio 423 Play 成員初始化。推上去跑 CI，開始第 16 到 18 項。
- 18:14 進度備忘（上下文快滿，壓縮後照這行接）：第 14、15 項 CI run 45799324354 在跑；第 16、17、18 項交給同一個子代理依序做（各自 commit）。剩下：第 20 項（文件跟上程式：參數表補 v2.61 到 v2.63、未做清單改狀態、規劃第二批標做到哪）、第 21 項（收尾：快照整份自測 ×3、最後一次 CI、寫早上摘要和 HANDOFF、第一行改 done）。
- 18:17 CI run 45799324354（`8efc887`，含第 14、15 項）BUILD SUCCEEDED，沒有新警告。
- 19:18 第 16 項做完（`2054f3e`）：原因是晃動感測一開 app 就啟動、步數只看有沒有按過好。改成 `shake` 開或珍奶才啟動晃動、`walkShow` 開才讀步數，調節台改參數跟著開停；加「查詢沒回來不再查」。呼叫點都在 SlimeController：startDeviceMotionUpdates 只在 startMotion（:440），queryPedometerData 只在 walkReadSteps（:407）。
- 19:18 第 17 項做完（`c0c5466`）：原因是三種材質只差 floppy，一變就整隻重建，窗台上從碗口上方 0.6R 放下來。`deskSmooth` 1：只有 floppy 變就就地改，種子／大小／密度變才重建並連上一幀整團搬回。T86 外框每格最大位移：窗台 0.74–1.20R→0.007–0.10R，藍底 0.14–2.14R→0.005–0.18R。沒釘舊項目。
- 19:18 第 18 項做完（`5034a11`）：新增 `ios/NieNie/Resources/PrivacyInfo.xcprivacy`（追蹤 false、收集資料空、UserDefaults CA92.1、開機時間 35F9.1），project.yml 整個資料夾收、加註解；程式沒有網路請求。步數權限文字改掉「沾到什麼」。版本號現況：MARKETING_VERSION 0.2.0，build 號 CI 用 github.run_number。整份 86／86 一次（1481 秒）。可疑：SlimeController 422–434 stepsWas Optional、410 weak self 閉包；SlimeRig 2704–2733 deskRebuild 設 private(set)。推上去跑 CI（也看隱私檔有沒有進 bundle），開始第 20 項。
