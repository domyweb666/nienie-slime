// fix2 複本用：mode 7 同時開「薄處不透明」
window.SKM = { get mode() { return JELX.mode; }, set mode(v) { JELX.mode = v; JELX.thinOpq = v === 8 ? 1 : 0; } };
JELX.smooth = 0;
0
