// 皮的遮罩換法（只在量測複本用）。SKM.mode：
// 0 現在：只填外框路徑（nonzero）
// 1 網格聯集：外框路徑 ∪ 每個三角形（方向統一成正，翻面的也照畫）
// 2 聯集＋最細保底：1 再加裡面的邊（兩端都不是外框點）用 wmin 粗的圓頭線描一次
// 3 聯集＋最細保底（不畫外框路徑，只有網格）
// 4 外框路徑＋保底線（不畫三角形）：看三角形的貢獻
window.SKM = { mode: 0, wmin: .13, n: 0, ms: 0 };
(() => {
  const ex0 = extraMask;
  extraMask = function (m, grow, col) {
    ex0(m, grow, col);
    const md = SKM.mode; if (!md) return;
    const n = N, VX = SKM.VX && SKM.VX.length >= n ? SKM.VX : (SKM.VX = new Float64Array(n + 64)), VY = SKM.VY && SKM.VY.length >= n ? SKM.VY : (SKM.VY = new Float64Array(n + 64));
    for (let i = 0; i < n; i++) { VX[i] = X[i]; VY[i] = Y[i]; }
    const nb = bnd.length; for (let i = 0; i < nb; i++) { const a = bnd[(i + nb - 1) % nb], b = bnd[i], c = bnd[(i + 1) % nb]; VX[b] = X[a] * .25 + X[b] * .5 + X[c] * .25; VY[b] = Y[a] * .25 + Y[b] * .5 + Y[c] * .25; }
    for (let i = 0; i < n; i++) grow(VX[i], VY[i], R * .08);
    if (md !== 4) { m.fillStyle = col || '#fff'; m.beginPath();
      for (let q = 0; q < TRI.length; q += 3) { const a = TRI[q]; let b = TRI[q + 1], c = TRI[q + 2]; if ((VX[b] - VX[a]) * (VY[c] - VY[a]) - (VY[b] - VY[a]) * (VX[c] - VX[a]) < 0) { const s = b; b = c; c = s; } m.moveTo(VX[a], VY[a]); m.lineTo(VX[b], VY[b]); m.lineTo(VX[c], VY[c]); m.closePath(); }
      m.fill(); }
    if (md >= 2) { m.strokeStyle = col || '#fff'; m.lineCap = 'round'; m.lineJoin = 'round'; m.lineWidth = R * SKM.wmin; m.beginPath();
      for (let e = 0; e < EDG.length; e += 2) { const i = EDG[e], j = EDG[e + 1]; if (BIDX[i] >= 0 || BIDX[j] >= 0) continue; m.moveTo(VX[i], VY[i]); m.lineTo(VX[j], VY[j]); }
      m.stroke(); }
  };
})();
0
