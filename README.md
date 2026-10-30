# 捏捏史萊姆

一款 iOS 原生的 2D 卡通史萊姆 App：打開就能捏，拉、壓、推，揉久了會留形，聲音走 ASMR 方向。

## 目前狀態

- `prototype/web/index.html`：**目前採用的手感原型**（程序化動畫：18 個控制點＋彈簧，不做物理模擬）。用 iPhone Safari 打開即可捏。
- `prototype/web/archive/`：試過但手感未達標的版本，僅供參考：
  - `mesh-v7.html`：三角網子軟體（大幅揉捏會打結）
  - `mpm-clay.html`：MPM 顆粒模擬（在 iPhone 上會崩裂、閃爍）
- `.uiux/`：設計檔（核心動作卡、手感參數表、原型規格、測試方法、技術選型）。全部是暫定版。

## 下一步

把網頁原型移植成 SwiftUI App，加上 Core Haptics 震動。詳見 `CLAUDE.md`。
