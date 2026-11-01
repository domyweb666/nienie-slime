# sfx｜音效檔放這裡

> 2026-11-01 起是 Agent 用 `prototype/sfx-design/design_sfx.py` 設計的音效（史萊姆是虛構的，沒有真的可以錄）。改設計就改那支程式重跑，它會同時寫這裡和 `ios/NieNie/Resources/`、更新兩邊的 `manifest.json`、清掉不在 manifest 裡的舊檔。試聽：`listen.html`。

## v2 分層版

聲音不是「觸發一段音檔」，是物理參數決定每一層多大聲、多高、多亮。播放程式是 `engine.js`（網頁原型和試聽頁共用），Swift 版 `ios/NieNie/Feedback/SlimeAudio.swift` 照同一張表。表在 `.uiux/04-手感/音效參數對應-暫定.md`。

| 類別 | 層 | 什麼時候響 |
|---|---|---|
| `press` | `body` `wet` `air` | 按到身上；力道越大越多層、越低、越亮 |
| `release` | `air` `wet` `body` | 放手；越用力「啵」越大顆越低，加彈回的份量 |
| `pull` | `loop` `strand` | 拉著的時候連續播；拉越長越高越亮、拉越快越大聲，路上細絲一根根斷 |
| `rub` | `loop` | 抓著揉；手指越快越大聲越亮，拉遠了讓位給拉絲 |
| `settle` | `bubble` `hiss` | 放手後的餘韻：拉過冒小氣泡，按久了放開一聲小嘶 |

`manifest.json` 長這樣：

```json
{
  "version": 2,
  "press":   {"body": ["press-body-01.wav"], "wet": ["press-wet-01.wav"], "air": ["press-air-01.wav"]},
  "release": {"air": [...], "wet": [...], "body": [...]},
  "pull":    {"loop": [...], "strand": [...]},
  "rub":     {"loop": [...]},
  "settle":  {"bubble": [...], "hiss": [...]}
}
```

舊的平坦格式 `{"press": ["press-01.m4a"], ...}` 兩邊播放程式都還吃（一類整包當一層），想換回真錄音照 `.uiux/04-手感/錄音指南.md` 錄完直接用。沒列的檔不會播，列了但檔案不存在也不會壞，只是安靜。
