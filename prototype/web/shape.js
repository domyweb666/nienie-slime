// v2.51 不規則外形（多米 11-22：預設形狀要不規則，像一攤軟軟的東西，不要圓）。
// 輪廓是「角度 → 半徑」的函數（×R），從身體中心看出去每個方向只有一個半徑，所以不會有凹進去再凸出來的地方，網格照舊建。
// 角度用螢幕座標：0 右、90° 下、−90° 上。每個種子長得不一樣：
//   下盤重、比高還寬；上面一個歪向一邊的鼓包；對面下方一個小鼓包；另外隨機一處凹一點。
// lump 0 到 1 是不規則的程度。面積對齊舊外形（平均半徑平方 .98²），身體不會因為換外形變大變小。
// index.html（blobR）和 shapes.html（候選一覽）共用這一支；Swift 版照這裡的數字抄（SlimeRig.blobR）。
(function () {
  function rng(seed) { let x = seed * 9301 + 49297; return () => { x = (x * 9301 + 49297) % 233280; return x / 233280; }; }
  function make(seed, lump) {
    const r = rng(Math.round(seed) * 13 + 5), D = Math.PI / 180, k = lump == null ? 1 : lump;
    const side = r() < .5 ? -1 : 1, p1 = r() * 6.28, p2 = r() * 6.28;
    const bumps = [
      { a: (-90 + side * (25 + r() * 35)) * D, k: .20 + r() * .12, w: .42 + r() * .14 },   // 上面歪一邊的鼓包
      { a: (90 + side * (50 + r() * 30)) * D, k: .10 + r() * .08, w: .36 + r() * .12 },    // 對面下方的小鼓包
      { a: (-90 - side * (40 + r() * 70)) * D, k: -(.05 + r() * .05), w: .30 + r() * .10 } // 另一側上方凹一點
    ];
    const raw = a => {
      let v = .10 * Math.sin(a) + .06 * Math.cos(2 * a) + .04 * Math.sin(3 * a + p1) + .025 * Math.sin(5 * a + p2);
      for (const b of bumps) { let d = a - b.a; d = Math.atan2(Math.sin(d), Math.cos(d)); v += b.k * Math.exp(-((d / b.w) ** 2)); }
      return 1 + k * v;
    };
    let s = 0; const n = 360; for (let i = 0; i < n; i++) { const q = raw(i / n * Math.PI * 2); s += q * q; }
    const scale = .98 / Math.sqrt(s / n);
    return { r: a => raw(a) * scale, side, bumps };
  }
  window.SlimeShape = { make };
})();
