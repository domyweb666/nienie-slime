// fix 複本用：把 SKM.mode 接到 JELX.mode（給 paired.js 用）
window.SKM = { get mode() { return JELX.mode; }, set mode(v) { JELX.mode = v; } };
JELX.smooth = 1; JELX.thinOpq = 0;
0
