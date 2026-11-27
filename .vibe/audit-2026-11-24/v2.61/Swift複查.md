# Swift 複查：716277f..HEAD（df8a573）ios/

方法：只讀，逐行讀 diff 與相關整檔。這台沒有 swiftc，Docker 沒開，WSL 沒有 Swift，所以沒有任何東西真的編過。
環境：Swift 語言模式 5.0、沒設嚴格並行、iOS 17、沒有額外編譯旗標；CI 是 macos-26 + 最新 Xcode、Release。
路徑一律省略 ios/NieNie/。

## A. 確定會錯：Xcode CI 編譯

0 條。

## B. 確定會錯：Linux 預檢（tools/swift-linux-check），不影響 Xcode

B1. Slime/SlimeRig.swift:6308 `extension SlimeRig: SkinMeshSource`
- 協定宣告在 Slime/JellySkin.swift:7（import Metal、UIKit）。SlimeRig 從此依賴 JellySkin.swift，破了 README「物理三個檔只准用 Foundation」這條。
- check.sh 第一段沒有列 JellySkin.swift，harness-main 也沒有，兩處都會 cannot find type 'SkinMeshSource'。亂捏與 desk 的 Linux 實跑因此也不能用。
- 最小修法：把 JellySkin.swift:5-16 的 protocol 整段搬到 SlimeRig.swift（只用 Foundation 型別，不用改一個字）。
B2. tools/swift-linux-check/check.sh 兩段檔案清單都沒有 UI/LabProbe.swift（SlimeController、SlimeView 都用到 LabProbe.shared）；LabProbe 又用到 SkinMesh，所以第一段還要加 JellySkin.swift 或一個替身。
B3. stubs/AppStubs.swift:4-24 的 SlimeSoundSource／SlimeAudio 替身沒有 snd61、engineLatency → SlimeController.swift:316、:879 找不到成員。
B4. 疑似：stubs 裡 grep 不到 DispatchSemaphore 以外的 supportsTextureSampleCount、drawIndexedPrimitives、setScissorRect、memoryless、systemVersion，MetalStub／UIKit 替身也要補。確認法：補完 B1-B3 後在 Linux 上跑 check.sh。
- 影響：不擋 CI，但「推上去之前先驗」這條路目前是斷的。補起來之後可以替這批真的跑一次型別檢查，值得在推 CI 之前做。

## C. 確定的接線缺口（不會編譯錯）

C1. wakeSoft、nearFast、eyeTrue 在 SlimeRig／SlimeView 沒有任何讀取點（grep 整個 ios/NieNie，只有 FeelParams 宣告、TuneField、FeelBatch.keys）。HANDOFF 寫 S3b 未做，所以是已知待辦。現在的狀態：
- FeelParams.swift:894-896 三條滑桿、FeelDeskModel.swift:125-126 的「睡醒」和「眼睛和旁邊」兩顆按鈕，按了什麼都不會變（greetLook 也沒接，所以「眼睛和旁邊」整組是空的）。
- 這樣發 TestFlight，多米會試到沒有作用的開關。最小修法：等 S3b，或先把這兩組從 FeelBatch.groups 和 TuneField 拿掉。
C2. App/SlimeController.swift:482-487 restoreDefaults 會把 batch（含拉的三顆）歸回預設，但沒有 feelSave()；其他改 batch 的路徑（batchDone、binding、feelApply、feelDefaults）都有存。結果：隱藏面板按回預設之後重開 app，A3/A4/A5 會從 nienie.feel 又回來。（13 顆旋鈕在 v2.60 就有同樣的行為，這批把三顆開關也帶進去。）修法：函式最後加 feelSave()。loadSlot（:951-965）同一類：setPull 之後沒存。
C3. feelStale 不是 nil 時（舊預設的提示還沒答）：feelSave（:525-529）寫的是 keep.k，所以這段時間按的拉的三顆不會存；按「留著我的」時 feelApply(old)（:670 → :538）會用舊存檔的值蓋掉剛按的三顆。只在「舊戳記 + 提示沒答」時發生。修法：feelKeepMine 先 old.setPull(batch.pullOn) 再套。

## D. 疑似（附確認法）

D1. UI/LabProbe.swift:397、:404 `t += pa[y * w + max(0, min(w - 1, x + i - r))] * g[i]`：一行有 5 個算子、泛型 min/max 巢狀、下標多載、SIMD 的 += 與 * 多載。所有變數型別已知，多半會過，是整批裡最像「unable to type-check this expression in reasonable time」的地方。
- 確認：build.log 搜 "reasonable time"。修法：先 `let k: Int = max(0, min(w - 1, x + i - r))` 再取值。
D2. UI/FeelDesk.swift:132-133 onAppear/onDisappear：ContentView 用 0.2 秒 .transition(.opacity) 進出。收起後 0.2 秒內再打開，SwiftUI 若走「新的先 onAppear、舊的後 onDisappear」，LabProbe.on 會停在 false，面板開著卻不記。
- 確認：真機連點「調」開關，看「觸控」那行會不會更新。修法：改成 ContentView `.onChange(of: showFeel)` 設。
D3. App/SlimeController.swift:147-153 量測在靜音（soundMode 2、灰盒）或觸覺不支援時照樣記「叫完聲音／震動」，因為包在外面，裡面其實提早 return。複製文字只寫灰盒，沒寫喇叭靜音。數字會很小，容易被讀成「很快」。修法：lagCopy 加 soundMode 與 haptics 狀態。
D4. 碰著固定 120（lock120）不看面板開著沒有，收起面板後仍生效到關掉 app。註解寫「不存」，沒寫「收起就停」；耗電那點要知道。SlimeView.swift:406、LabProbe.swift:11。
D5. Swift 並行只會是警告：LabProbe.swift:202-205 巢狀 closure 用 weak self、SlimeController 非 @MainActor 用 UIDevice.current（:886）。現有程式已有同樣寫法（UIScreen.main、fuzzRun）且編得過，語言模式 5 下不該是 error。確認：build.log 搜 "main actor-isolated"、"Sendable"，若有 error: 才處理。
D6. Slime/SlimeView.swift:121 `(rig as AnyObject) as? SkinMeshSource` 合法；可能多一條警告，不是錯。
D7. Metal jelMeshFragment 的 `in` 沒用到：最多警告。

## E. 逐類查過、沒看到問題

編譯
- SkinMeshSource 只有 SlimeRig 一個實作，四個屬性型別都對得上；private 的 TRI/EDG/Q0X/worldWalls 在同檔 extension，可存取。
- SlimeSoundSource 只有 SlimeAudio 一個實作，snd61、engineLatency 都有；AVAudioOutputNode.presentationLatency 存在。
- SlimeRig 新的儲存屬性都在 class 本體（31-6224），不在 extension；Finger.PetPath 逐項初始化參數對得上。
- FeelBatch：index 的兩個多載（String／KeyPath）不會含混；KeyPath 與 WritableKeyPath 比較走 AnyKeyPath；巢狀 Group／Key／Result 沒有跟 SwiftUI／標準庫撞（FeelDesk 一律用全名或不用）。
- SlimeView 的 skinSrc 在 super.init 前設值，init?(coder:) 是 fatalError；LabProbe 的 `open` 當變數名可行（SlimeView.trailPath 早就這樣用）。
- FeelDesk：捲動區、batchBox、labBox 各 10 個子元件，沒超過；chip 的參數標籤兩個檔都對；ternary 樣式跟原有寫法一樣。
- TuneField 名稱、key、FeelParams 屬性名無重複（程式掃過）。
- Metal：CapIn 32 bytes 對 SkinMesh.Cap；float2 對 SIMD2<Float>（8）；buffer 0/1 一致；vid/iid 同型別；r8Unorm 可 MSAA／resolve／blend；PSO 的 sample count 跟貼圖同一個來源；memoryless 在模擬器有換成 private。

執行
- 補點改變點數：update 先比 count／tri／ring，不同就 rekey 並重驗全部索引；near、third、cap 容量都跟著換；rekey 失敗回 false 走外框路，不會用舊索引。outline 是 boundaryPoints，數量固定等於 bnd。HRC[HRX.count] 初始為 [0]，不會越界。
- 信號量 3 對 3 組緩衝；nextDrawable 失敗有 signal；commit 必到；handler 持有信號量，JellySkin 釋放不會踩 libdispatch 的 assert。index buffer 換新不覆寫舊的。
- 剪裁矩形：±inf 先 clamp，x1>x0、高至少 1、不超出貼圖。NaN：rl=0 那支 along 變 NaN，但 away 由 rl<c0 先成立，petG 不會被污染；A4 的 dl=0 有守；A5 的 rm 有下限 0.5R。
- SkinReader 只在自己的序列佇列用；結果回主執行緒；skinGen 擋掉舊的；flood 的堆疊每點最多進一次。

接線
- 14 顆一律由 current 疊上去：換隻、換材質、候選、滑桿、存檔都經過 pushParams；各材質 defaults 沒有另外設這 14 顆。
- UserDefaults 沒有新鍵；拉的三顆併進 nienie.feel 的 k；舊存檔缺鍵＝關；戳記沒變，升版不會跳「舊預設」提示。網頁 FEELVER 同為 v2.61。
- 甲乙：pending 由每幀檢查 isTouched 放開，push 手指也算；收起面板再打開能繼續或結束；期間殺掉 app，存的是 keep；存／切 1、2、貼上匯入、回預設、滑桿、複製都有擋或藏，沒找到會透露答案的地方。
- skinU=0：meshSkin 回 nil → paint 走舊順序、litPath nil → 舊遮罩。灰盒與沒有 Metal 的手機在 meshSkin 之前就 return。
- snd61：manifest 有 rub.loop61、四檔在；缺檔 bank 為空自動回 rub.loop；雨以外仍 0.6。
- LabProbe.begin／frame／skinFrame 都以 on 為前提。

0 的路徑（逐條對 diff）
- rough、tapSoft、petSlow、pullHold、pullWhole、pullSoft、skinU、snd61 各自為 0：沒有多抽亂數、沒有換運算順序，算式化簡後跟 v2.60 相同。flAt 的亂數仍只抽一次；dragTarget 多加的 wx、wy 是 0。
- 只有這些非物理的差：多配兩張貼圖（maskG、maskMS）；複製文字多一行「這一批」、表頭是 v2.61、#nienie-feel 多三個鍵；「回到預設」回到「只修錯」而不是 build 158（註解寫是故意的）。

## F. 沒查到

- 沒編譯、沒跑、沒上真機；Metal shader 沒過 metal 編譯器。
- S3a、S2 的數值跟網頁是不是逐點相同（S3a-對照有它自己的算式對照，我沒重跑）。A3/A4/A5 的手感對不對。
- 皮的畫面對不對（聯集、保底線、眼睛裁切的繞向，我只驗了方向推理）。
- 效能：SkinMesh.update 是外框點數平方、每幀一次，補點後外框點數變多時的毫秒數沒有量。
- 網頁檔、音檔內容沒看。
