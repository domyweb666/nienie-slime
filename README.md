# 捏捏史萊姆

一款 iOS 原生的 2D 卡通史萊姆 App：打開就能捏，拉、壓、推，揉久了會留形，聲音走 ASMR 方向。

## 目前狀態

- `prototype/web/index.html`：**目前採用的手感原型 v2.2：形狀匹配軟體（Shape Matching）＋塑性＋活物感＋觸手＋蠕動＋遊走**。外形是癱軟的不規則團塊加 5 條垂下來的觸手（頭頂一個鼓包當方向感），約 360 顆粒子，每幀被拉回「最接近的剛體擺放」，數學上不會爆、不會打結；粒子互不穿透所以觸手拉不成細線；觸手越靠末端越軟、記憶很淡會彈回，身體才留形；沒碰時整個輪廓被幾個慢速行進波掃過一直在蠕動，觸手各自飄，家會在畫面裡慢慢遊走，碰它就停；懸空。預設黏土（另有果凍、麻糬）。長按「捏捏」開調整面板，「外形亂數種子」可換形狀。聲音讀 `prototype/web/sfx/manifest.json` 的錄音切片，還沒錄所以目前安靜；怎麼錄見 `.uiux/04-手感/錄音指南.md`。用 iPhone Safari 打開即可捏。線上版（GitHub Pages）：<https://domyweb666.github.io/nienie-slime/prototype/web/index.html>。網頁版沒有觸覺、延遲與原生版不同，只能看形狀與手勢邏輯，不能當手感驗收。
- `prototype/web/archive/`：試過但手感未達標的版本，僅供參考：
  - `mesh-v7.html`：三角網子軟體（大幅揉捏會打結）
  - `mpm-clay.html`：MPM 顆粒模擬（在 iPhone 上會崩裂、閃爍）
  - `radial-v1.html`：18 點放射狀程序化 rig（大幅拉扯描邊會自交、回彈各點獨立不像果凍、做不出塑形）
- `.uiux/`：設計檔（核心動作卡、手感參數表、原型規格、測試方法、技術選型）。全部是暫定版。
- `ios/`（在 `swiftui-port` 分支）：radial-v1 的 SwiftUI 移植版，加上 Core Haptics 和 AVAudioEngine 合成音。**演算法已過時**，等 v2 手感在網頁上定下來後要改移植 v2。編譯和上傳 TestFlight 的步驟寫在 `ios/README.md`。

## 下一步

1. 多米用手機捏 v2 網頁原型，決定要果凍、麻糬還是黏土的手感，以及懸空還是地面。
2. 買一盒真的史萊姆，照 `.uiux/04-手感/錄音指南.md` 錄四類聲音（按、拉、放手、持續揉），丟進 `prototype/web/sfx/` 就會響。
3. 手感定了再把 v2 演算法移植成 Swift，加 Core Haptics。`CLAUDE.md` 的移植規格是 v1 的，要改。
