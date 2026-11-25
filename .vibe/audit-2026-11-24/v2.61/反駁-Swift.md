# 反駁報告：v2.61 第一批 Swift（716277f..1d630c8）

只讀。工作樹沒動。路徑省略 ios/NieNie/。

## 結論
- 編譯會失敗的：找不到（0 條）。沒有 swiftc，只能逐行讀。
- 這批新加的算式跟網頁不同的：找不到。S3b、S3a、S2 重跑全部一樣。
- 確定的錯 1 組（舊錯，build 158 就有，手機才有）：setup 把時鐘歸零，但四個時間變數沒跟著歸零。
- 工具壞 1 條：S3a-算式對照.js --live 現在跑不起來（不是 Swift 錯）。
- 疑似 4 條。

## 確定

### K1 Slime/SlimeRig.swift:1068-1069（setup）時鐘歸零，slpWakeT、voiceLast、e4LastT、impAskUntil 沒歸零
t = 0 在 1054 行附近。比對 setup 全部歸零清單，這四個不在裡面：
| 變數 | 用在 | 歸零時鐘後 |
|---|---|---|
| slpWakeT | 5886 `t - slpWakeT < 0.8 && !slpSlow` | 差是負的，永遠成立，眼睛放大 1.18 倍，直到新時鐘追上舊的醒來時刻 |
| voiceLast | 5703 `guard t - voiceLast >= 0.3` | 一律不出聲，直到有人把它設回 -9（驚嚇 6050、睡醒 6073、打招呼 6132、吞 5414、搔癢掙脫 5762、節奏開心 6115） |
| e4LastT | 5790 `t - e4LastT > 40` | 熟的牠不會來打招呼，要等新時鐘超過舊的 40 秒 |
| impAskUntil | 2146 `t < impAskUntil` | 下一次碰就當討摸（舒服跳到 0.5、熟 +0.05）。換到有存熟度的那隻不會（setImpression 有歸零）；換到沒存過的那隻（走 resetImpression，5549，沒歸零）和其他重建會 |
觸發 setup 的路：SlimeController.swift:395 換隻（主要的一條；「揉回原形」按鈕走 relax，不會）、SlimeView.swift:309 尺寸變、SlimeRig.swift 的 update 裡換種子／觸手數／大小／密度（調節台）。
換隻之後游到家打招呼（6132）會把 voiceLast 設回 -9，所以平常只沉默游進來那幾秒；游的途中被抓住（2126 把 swimOn 關掉，不打招呼）、調節台改大小這類不游進來的重建，就一路沉默到下一個會強制設回的聲音。
v2.61 讓它多一個相關面：慢醒之後換隻，setup 把 slpSlow 設回 false（1069），本來慢醒「不睜大」的那隻換成新的一隻反而睜大。
網頁沒有這個錯：網頁 setup 不把 t 歸零（index.html:526 只在載入設 0；966 的 Object.assign(SLP,…) 沒有 wakeT 也沒關係）。
影響：看得到（睡醒過之後換隻，新的一隻眼睛一直大）、聽得到（游的途中就抓住牠，戳、哼、開心都沒聲）。
最小修法：1068 行 `flBoost = 1` 後面加 `slpWakeT = -9; voiceLast = -9; e4LastT = -99; impAskUntil = -9`。
會讓「全 0 逐位元同 158」在「睡醒過或出過聲之後重建」這種情況不同，其他不變。建議順手修，因為 setup 裡已經有 slpOpenT、slpAskAt 同一組的歸零，漏這四個不是刻意的。
信心：slpWakeT、voiceLast、e4LastT 的邏輯確定；真機沒看過。

### K2 .vibe/audit-2026-11-24/v2.61/S3a-算式對照.js --live 跑不起來
66 行找 `!(FLN.at>t)){FLN.at=`，W3 之後網頁多了 `&&!SLP.on`；Swift 側也多用了 slpOn，假環境沒有。不加 --live 也停（slpOn is not defined，試過）。
我改了副本（refute-swift/s3a-live.js）：取行字串加 `&&!SLP.on`、假環境加 slpOn:false 與 SLP.on。結果九項全部一樣，最大差 1.3e-15，三顆全 0 對動工前差 0。
修法：照副本那兩處改。

## 疑似（沒有真機不能判）

S1 幀率：手速用 30 毫秒平滑。畫面 120Hz、觸控 60Hz 送達時，平滑值一格高一格低，峰值是平均的 1.138 倍、谷值 0.862 倍（算式）。任何「一格超過就算」的門檻等於低 12%：D1 快扯 6 變約 5.3（SlimeRig.swift:2693、2694 的 vMax 不會退）、C1 猛按 4 變約 3.5（6012）。C3 慢摸上緣 10 到 14 也會抖。60Hz 畫面、觸控跟畫面同步時沒有這個差。確認法：真機印 vxS。
S2 睡著被按住 0.35 到 1.2 秒（C1 翻身那段，手指還在、impTrust > 0.7）：e2Step（5732-5785）沒看 slpOn，會有三成機率推一下（送 .nudge：press 聲 0.2 加一下震動）、0.8 秒開始蹭並出「mmm」聲，眼睛閉著。C1 註解寫翻身「沒有聲音、沒有震動」。網頁 2022 行 e2Step 一樣沒看 SLP，所以不是移植錯，是規則漏寫。要改兩邊都加 !slpOn。
S3 舊戳記提示沒答時按「build 158」這一檔：feelPullPressed（SlimeController.swift:540）用「值有沒有變」判斷按過，原本就全關就不會寫進舊存檔，之後按「留著我的」會把舊存檔裡開著的三顆帶回來。現在的舊存檔沒有三顆（等於全關），這批不會發生；等以後預設指紋再改一次才會。改法：三檔那顆不看變沒變，直接 setPull。
S4 盲比的等放手：pullBlindApply 只看 rig.isTouched，另一隻手還按在別處時等於沒放（看到 .none 以外就算按著），所以換的那一刻一定在放手後一格。但 A5 的放手 0.8 秒限速、回正限速會用「換過去那一邊」的值跑那次放手的後半段。單手操作按鈕時手不在身上，兩邊同；雙手才會有差。

## 逐項查過、反駁不了

編譯：FeelBatch 的 index 兩個多載、KeyPath 相等、Tier／Group 巢狀命名、init 裡 self.init() 後改值、Binding 裡的 set、onChange 兩參數、SkinMesh.Scratch 泛型與 private 存取、Slot、巢狀函式 maxBlend（不碰 self）、withUnsafeBytes 的閉包、addCompletedHandler 的單行 signal、LabProbe 的 `open` 變數、Column 的 KeyPath、SkinReader.Job 的 init、Metal 的 flat 插值與 strip 順序。
新檔進專案：project.yml 的 sources 是整個 NieNie 目錄，xcodegen 在 CI 產生，LabProbe.swift、四個 ai-rub-loop61 音檔、manifest.json 都會進；平放在 Resources，Bundle.main 讀得到。
loop61：manifest 的 rub.loop61 四檔，44100 單聲道 16 位元、97020 取樣，跟 rub.loop 一樣長，手機與網頁檔名一致；key 是 "rub.loop61"；缺檔 bank 為空就回 rub.loop；切換不會打斷正在播的。
S3b：softTouch、tapJudge、rollStep、softDrop、wake、sleepStep、idleSec、lifeStep 的 hear、eyeStep、所有 slpOn 分支，逐行對網頁，加 S3b-算式對照.js --live 重跑：203 萬格差 0，三個都 0 對動工前 93 萬格差 0。x y 用 rawX rawY、hv 用 camZ÷R、減少動態減半、moveHome 帶前一格。slpTap 是強引用，手指移除後下一格就放掉。
S5：feelPullPressed、restoreDefaults、loadSlot、labDesk 的接線與存檔時機都合理；舊存檔缺三鍵當全關；FeelKnob.stamp 不含新鍵，所以升版不會跳舊預設提示；feelStyleNow 的 matches 只比 FeelKnob.keys，不受三顆影響；解析 #nienie-feel 多三鍵不會壞。
存檔：nienie.feel 舊格式（v2.39 到 v2.51 的 {base,v,A,B}）走 Old 解，三鍵缺就關。隱藏面板的 feelSlot1、2 舊存檔缺鍵用現在的值補（decodeSlot），三顆另從原文讀。
0 的路徑：wakeSoft 0 時 softDrop 每格只清已經是預設的值、softTouch 一律 false、slpOn 在落指後必 false，逐位元同（上面 93 萬格）；其餘開關照複查 E 段，我抽查 relCap、rotK、kc、heldBack、shortEnough、grows、moodRelease、flTc 都在 0 時化簡成原式，亂數取用次數沒變。
崩潰：HRC[HRX.count]（homeRing 一起更新，初始 [0]）、SkinMesh rekey 的索引都先驗界、半徑 0 不進、Int() 前都 clamp（NaN 時 min／max 退回 fw，不會崩）、near／third 大小跟 count、nb 一致、補點後 count 或 tri 或 ring 不同就 rekey、index 用新 buffer、三組 buffer 配信號量、LabProbe 只把陣列複本丟去背景、Metal 的 vBytes 用 stride 算、Cap 32 bytes 對 CapIn。
A5 等：relCap 條件跟網頁 1297 行同（fingers 空、0.8 秒、不是開場、不是 sillHop）；upright 1408、noFlee 1681 同。

## 方法與限制
- 重跑：S3b --live（全部一樣）、S2（全部一樣）、S3a（改副本後全部一樣）。
- 沒有 swiftc、沒上真機、沒過 metal 編譯器。C1 翻身的觀感、S1 的抖動、皮的 GPU 畫面都沒驗。
