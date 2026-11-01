# sfx｜音效檔放這裡

> 2026-11-01 起是 Agent 用 `prototype/sfx-design/design_sfx.py` 設計的音效（史萊姆是虛構的，沒有真的可以錄）。改設計就改那支程式重跑，它會同時寫這裡和 `ios/NieNie/Resources/`、更新兩邊的 `manifest.json`。試聽：`listen.html`。

原型會讀這個資料夾的 `manifest.json`，照裡面列的檔名播。沒列的檔不會播，列了但檔案不存在也不會壞，只是安靜。

四類：

| 類別 | 什麼時候響 | 音量跟什麼走 |
|---|---|---|
| `press` | 手指按到身上那一下 | 固定 |
| `pull` | 拉長的過程，每拉長約三分之一個身體響一段 | 拉越長越大聲、音高略降 |
| `release` | 放手那一下 | 放手越快越大聲、音高略升 |
| `rub` | 抓著揉的時候，循環播 | 手指越快越大聲，停手就淡出 |

每類放 8 到 12 段，程式隨機挑、音高上下浮 8%，這樣不會每次一模一樣。

`manifest.json` 長這樣，檔名自己取，副檔名 `.m4a` 直接用（iPhone 語音備忘錄的格式，Safari 和 Chrome 都能解）：

```json
{
  "press":   ["press-01.m4a", "press-02.m4a"],
  "pull":    ["pull-01.m4a"],
  "release": ["release-01.m4a"],
  "rub":     ["rub-01.m4a"]
}
```

怎麼錄見 `.uiux/04-手感/錄音指南.md`。
