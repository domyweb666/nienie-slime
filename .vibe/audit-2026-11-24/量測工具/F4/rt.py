"""Real-time capture: run the real page (its own rAF loop), drive pointer events, record what the sound engine's master puts out."""
import sys, json, os, base64
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from boot import *
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
REC = r'''
window.__rec = async () => {
  SFX.init(); await SFX.ctx.resume();
  const c = SFX.ctx;
  const code = `class R extends AudioWorkletProcessor{process(i){const x=i[0][0];if(x){const y=new Float32Array(x);this.port.postMessage({f:currentFrame,y},[y.buffer])}return true}}registerProcessor('f4rec',R);`;
  await c.audioWorklet.addModule(URL.createObjectURL(new Blob([code], { type: 'text/javascript' })));
  const n = new AudioWorkletNode(c, 'f4rec', { numberOfInputs: 1, numberOfOutputs: 1, channelCount: 1, channelCountMode: 'explicit' });
  const buf = []; n.port.onmessage = e => { buf.push(e.data); };
  SFX.master.connect(n); if (window.__ambRec) { SFX.master.disconnect(n); SFX.bgmG.connect(n); } const z = c.createGain(); z.gain.value = 0; n.connect(z); z.connect(c.destination);
  // wait until buffers are decoded
  for (let k = 0; k < 100; k++) { const ok = Object.values(SFX.buf).length && Object.keys(SFX.buf).every(q => SFX.buf[q].length >= 1); if (ok) break; await new Promise(r => setTimeout(r, 100)); }
  await new Promise(r => setTimeout(r, 800));
  window.__R = { c, buf, t0: c.currentTime, marks: [], hand: [], n0: () => buf.length };
  return { sr: c.sampleRate, state: c.state, base: c.baseLatency, out: c.outputLatency };
};
window.__ges = async (name) => {
  const R0 = window.__R, c = R0.c, buf = R0.buf;
  SFX.amb = 'none'; SFX.setAmb('none');
  if (name.endsWith('_only')) { SFX.voice = () => {}; SFX.knock = () => {}; SFX.fx = () => {}; name = name.slice(0, -5); for (const p of PROPS) { p.gone = true; } }
  const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  const v = viewV(), q = cv.getBoundingClientRect(); const scr = (wx, wy) => [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top];
  const raf = () => new Promise(r => requestAnimationFrame(r));
  const edge = (ux, uy) => { let b = 0, bd = -1e9; for (const i of bnd) { const p = (X[i] - globalC.xc) * ux + (Y[i] - globalC.yc) * uy; if (p > bd) { bd = p; b = i; } } return scr(X[b] - ux * R * .25, Y[b] - uy * R * .25); };
  await new Promise(r => setTimeout(r, 500));
  const i0 = buf.length, tA = c.currentTime, hand = [], marks = [];
  const mark = (s) => marks.push([+(c.currentTime - tA).toFixed(4), s]);
  const p0 = performance.now(); const el = () => (performance.now() - p0) / 1000;
  const H = (x, y) => { const f = [...fingers.values()][0]; hand.push([+(c.currentTime - tA).toFixed(4), f ? +(Math.hypot(f.vxS, f.vyS) / R).toFixed(3) : 0, f ? +((f.stretch || 0)).toFixed(3) : 0, +SFX.v.toFixed(3)]); };
  const r = R * CAM.z;
  if (name === 'pull3') { // three pulls: slow 1.5 s, hold 1.0 s, back... ; repeated with stops
    const [x, y] = edge(-.3, -.95); ev('pointerdown', 1, x, y); mark('down');
    const seg = async (d0, d1, T) => { const s0 = el(); for (;;) { const u = Math.min(1, (el() - s0) / T), d = d0 + (d1 - d0) * u; ev('pointermove', 1, x - r * .3 * d / 3, y - r * d); await raf(); H(); if (u >= 1) break; } };
    const hold = async (T) => { const s0 = el(); while (el() - s0 < T) { await raf(); H(); } };
    await hold(.4); mark('pull'); await seg(0, 2.4, .6); mark('stop'); await hold(1.2); mark('pull'); await seg(2.4, 1.2, .5); mark('stop'); await hold(1.2); mark('pull'); await seg(1.2, 3.2, .4); mark('stop'); await hold(1.5); mark('up'); ev('pointerup', 1, x, y - r * 3.2); await hold(1.5);
  } else if (name === 'rubstop') {
    const [x, y] = scr(globalC.xc, globalC.yc); ev('pointerdown', 1, x, y); mark('down');
    const hold = async (T) => { const s0 = el(); while (el() - s0 < T) { await raf(); H(); } };
    const rub = async (T, hz, amp) => { const s0 = el(); while (el() - s0 < T) { const a = (el() - s0) * 2 * Math.PI * hz; ev('pointermove', 1, x + Math.sin(a) * r * amp, y + (1 - Math.cos(a)) * r * amp * .3); await raf(); H(); } };
    await hold(.6); mark('rub'); await rub(1.6, 1.2, .35); mark('stop'); await hold(1.2); mark('rub'); await rub(1.6, 2.2, .35); mark('stop'); await hold(1.2); mark('rub'); await rub(1.6, .6, .35); mark('stop'); await hold(1.0); mark('up'); ev('pointerup', 1, x, y); await hold(1.2);
  } else if (name === 'yank5') {
    for (let k = 0; k < 5; k++) { const [x, y] = edge(-.3, -.95); ev('pointerdown', 1, x, y); mark('down'); for (let j = 0; j < 4; j++) { await raf(); H(); } mark('pull'); const s0 = el(); for (;;) { const u = Math.min(1, (el() - s0) / .16); ev('pointermove', 1, x - r * .3 * u, y - r * 2.4 * u); await raf(); H(); if (u >= 1) break; } mark('stop'); const s1 = el(); while (el() - s1 < .5) { await raf(); H(); } mark('up'); ev('pointerup', 1, x, y - r * 2.4); const s2 = el(); while (el() - s2 < 1.6) { await raf(); H(); } }
  } else if (name === 'tap8') {
    for (let k = 0; k < 8; k++) { const [x, y] = scr(globalC.xc, globalC.yc); ev('pointerdown', 1, x, y); mark('down'); const s = el(); while (el() - s < .09) { await raf(); H(); } mark('up'); ev('pointerup', 1, x, y); const s2 = el(); while (el() - s2 < .7) { await raf(); H(); } }
  } else if (name === 'rubrep') {
    for (let k = 0; k < 10; k++) { const [x, y] = scr(globalC.xc, globalC.yc); ev('pointerdown', 1, x, y); mark('down'); let s0 = el(); while (el() - s0 < .7) { await raf(); H(); } mark('rub'); s0 = el(); while (el() - s0 < 1.2) { const a = (el() - s0) * 2 * Math.PI * 1.3; ev('pointermove', 1, x + Math.sin(a) * r * .38, y + (1 - Math.cos(a)) * r * .12); await raf(); H(); } mark('stop'); s0 = el(); while (el() - s0 < .9) { await raf(); H(); } mark('up'); ev('pointerup', 1, x, y); s0 = el(); while (el() - s0 < 1.5) { await raf(); H(); } }
  } else if (name === 'pullrep') {
    for (let k = 0; k < 10; k++) { const [x, y] = edge(-.3, -.95); ev('pointerdown', 1, x, y); mark('down'); let s0 = el(); while (el() - s0 < .5) { await raf(); H(); } mark('pull'); s0 = el(); for (;;) { const u = Math.min(1, (el() - s0) / .7); ev('pointermove', 1, x - r * .3 * u, y - r * 2.0 * u); await raf(); H(); if (u >= 1) break; } mark('stop'); s0 = el(); while (el() - s0 < 1.0) { await raf(); H(); } mark('up'); ev('pointerup', 1, x, y - r * 2.0); s0 = el(); while (el() - s0 < 1.8) { await raf(); H(); } }
  } else if (name === 'amb') {
    SFX.setAmb('rain'); const tap = c.createGain(); SFX.bgmG.disconnect(); SFX.bgmG.connect(c.destination);
    mark('amb free'); await new Promise(r => setTimeout(r, 9000)); const [x, y] = scr(globalC.xc, globalC.yc); ev('pointerdown', 1, x, y); mark('amb held'); await new Promise(r => setTimeout(r, 6000)); ev('pointerup', 1, x, y);
  } else if (name === 'direct') { // direct engine calls, for loudness of each event
    const L = [];
    const wait = (T) => new Promise(r => setTimeout(r, T * 1000));
    const go = async (lab, fn, T = 1.2) => { mark(lab); fn(); await wait(T); };
    for (let k = 0; k < 3; k++) {
      await go('press.7', () => SFX.press(.7)); await go('press.3', () => SFX.press(.3)); await go('rel.35', () => SFX.release(.35)); await go('rel.7', () => SFX.release(.7)); await go('rel1', () => SFX.release(1));
      await go('voice.poke', () => SFX.voice('poke', .7, 1)); await go('voice.mmm', () => SFX.voice('mmm', .6, 1), 2.2); await go('voice.protest', () => SFX.voice('protest', .8, 1), 1.6); await go('voice.happy', () => SFX.voice('happy', .8, 1)); await go('voice.ask', () => SFX.voice('ask', .6, 1), 2); await go('voice.giggle', () => SFX.voice('giggle', .8, 1)); await go('voice.startle', () => SFX.voice('startle', .8, 1)); await go('voice.hello', () => SFX.voice('hello', .8, 1)); await go('voice.gulp', () => SFX.voice('gulp', .6, 1), 1.5); await go('voice.tear', () => SFX.voice('tear', 1, 1), 2.2);
      await go('fx.land', () => SFX.fx('land', .6, 1)); await go('fx.cling', () => SFX.fx('cling', .6, 1), 2); await go('fx.unstick', () => SFX.fx('unstick', .9, 1), 1.4); await go('fx.crawl', () => SFX.fx('crawl', .4, 1)); await go('fx.snore', () => SFX.fx('snore', .5, 1), 3); await go('fx.sigh', () => SFX.fx('sigh', .45, 1), 3); await go('fx.drip', () => SFX.fx('drip', .6, 1));
      await go('knock.candle', () => SFX.knock('candle', .4, 1)); await go('knock.bell', () => SFX.knock('bell', .4, 1), 3); await go('strand', () => SFX.strand(.8));
    }
  }
  mark('end'); await new Promise(r => setTimeout(r, 150));
  const fEnd = Math.round(c.currentTime * c.sampleRate), fA = Math.round(tA * c.sampleRate);
  for (let k = 0; k < 200; k++) { if (buf.length && buf[buf.length - 1].f >= fEnd - 256) break; await new Promise(r => setTimeout(r, 50)); }
  const n = fEnd - fA; const all = new Float32Array(Math.max(0, n)); for (let i = Math.max(0, i0 - 2000); i < buf.length; i++) { const o = buf[i].f - fA; if (o >= 0 && o + buf[i].y.length <= n) all.set(buf[i].y, o); }
  const b = new Uint8Array(all.buffer); let s = ''; for (let i = 0; i < b.length; i += 0x8000) s += String.fromCharCode.apply(null, b.subarray(i, i + 0x8000));
  return { pcm: btoa(s), marks, hand, sr: c.sampleRate, frames: n };
};
'''
def capture(names, mode2=True):
    port = 9300 + os.getpid() % 100
    srv = serve(port); out = {}
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b = p.chromium.launch(executable_path=CH, headless=True, args=['--mute-audio', '--autoplay-policy=no-user-gesture-required'])
        pg = b.new_context(viewport={'width': 393, 'height': 852}, device_scale_factor=2, has_touch=True).new_page()
        errs = []; pg.on('pageerror', lambda e: errs.append(str(e))); pg.set_default_timeout(0)
        pg.goto(f'http://127.0.0.1:{port}/index.html', wait_until='load'); pg.wait_for_timeout(9000)
        pg.evaluate('()=>{IMPSV.noSave=true;WALK.noSave=true}')
        if 'amb' in names: pg.evaluate('()=>{window.__ambRec=true}')
        if os.environ.get('OLD'): pg.evaluate("()=>{SFX.manifest.pull.loop=['pull-loop-01.wav','pull-loop-02.wav'];SFX.manifest.rub.loop=['rub-loop-01.wav','rub-loop-02.wav','rub-loop-03.wav']}")
        pg.evaluate(REC+';0')
        info = pg.evaluate('()=>window.__rec()')
        if os.environ.get('GRAIN'): pg.evaluate(open(os.path.join(HERE,'grain.js'),encoding='utf-8').read()+';0'); pg.evaluate('()=>{window.__grainOn();0}'); print('audio', info)
        for n in names:
            r = pg.evaluate('(n)=>window.__ges(n)', n)
            out[n] = r; print(n, 'marks', len(r['marks']), 'frames', r['frames'], 'dur', round(r['frames'] / r['sr'], 2), 'hand samples', len(r['hand']))
            pg.wait_for_timeout(1500)
        b.close()
    srv.shutdown()
    if errs: print('ERR', errs[:3])
    return out
if __name__ == '__main__':
    names = sys.argv[1].split(',')
    out = capture(names)
    for n, r in out.items():
        pcm = np.frombuffer(base64.b64decode(r['pcm']), dtype=np.float32)
        n2=n+os.environ.get('SUF',''); np.save(os.path.join(HERE, 'rt_%s.npy' % n2), pcm); json.dump({k: r[k] for k in ('marks', 'hand', 'sr')}, open(os.path.join(HERE, 'rt_%s.json' % n2), 'w'))
