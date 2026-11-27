// 試做：顆粒跟手走。每走 d 點一顆（跟手機的震動顆粒同一條規則：12 點 ±30%，每秒最多 20 顆），沒動就沒有；底層換回舊的連續循環
window.__grainOn = () => {
  const c = SFX.ctx, f0 = SFX.frame; const bag = {};
  const pick = (key) => { const l = SFX.buf[key]; if (!l || !l.length) return null; let b = bag[key]; if (!b || !b.length) { b = bag[key] = l.map((_, i) => i); for (let i = b.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1));[b[i], b[j]] = [b[j], b[i]]; } if (bag[key + '_l'] === b[b.length - 1] && b.length > 1) b.unshift(b.pop()); } const k = b.pop(); bag[key + '_l'] = k; return l[k]; };
  const grain = (key, g, rate, lp) => { const b = pick(key); if (!b) return; const s = c.createBufferSource(), G = c.createGain(), L = c.createBiquadFilter(); L.type = 'lowpass'; L.frequency.value = lp; L.Q.value = .5; s.buffer = b; s.playbackRate.value = rate; G.gain.value = g; s.connect(L); L.connect(G); G.connect(SFX.master); s.start(); window.__ng = (window.__ng || 0) + 1; };
  let acc = 0, next = 12, lastT = -9;
  SFX.frame = function (dt, st) {
    f0.call(SFX, dt, st); let sp = 0, stx = st.stretch || 0; for (const f of fingers.values()) if (f.mode === 'grab' || f.mode === 'stroke' && f.on) sp = Math.max(sp, Math.hypot(f.vx, f.vy) * CAM.z);
    if (!fingers.size || sp < 12) { acc = 0; return; } acc += sp * dt; const tense = 1 - .6 * Math.min(1, stx / 2);
    if (acc >= next * tense && c.currentTime - lastT > .05) { acc = 0; next = 12 * (.7 + .6 * Math.random()); lastT = c.currentTime;
      const k = Math.min(1, sp / (3 * R)), pull = st.grabbing && stx > .35; const g = (pull ? .5 : .45) + .4 * Math.sqrt(k);
      if (pull) grain('pull.strand', g, (.55 + .35 * Math.min(1, stx / 4)) * (1 + (Math.random() * 2 - 1) * .12), 3200 + 2500 * Math.min(1, stx / 4));
      else grain('settle.bubble', g, .5 + .25 * k + .12 * (Math.random() * 2 - 1), 2600);
      if (Math.random() < .35) grain('press.air', g * .5, .6 + .2 * Math.random(), 2400); }
  };
};
