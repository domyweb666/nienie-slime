# mem.py：記得什麼、記多久
import sys;sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work/run')
from drv import *
from playwright.sync_api import sync_playwright
import numpy as np, collections
serve()
out={}
def shares(S):
    x=np.array([s[20] for s in S]);h=np.histogram(x,bins=5,range=(4,389))[0];return [round(100*float(v)/len(x)) for v in h],round(float(x.mean()),0)
with sync_playwright() as p:
    b,pg,errs=page(p)
    pg.evaluate(open(BASE+'/run/own.js',encoding='utf-8').read())
    # M1 習慣：連戳 12 下（間隔 1 秒），再隔 G 秒戳一下
    print('== M1 連戳的縮（%身體）')
    for gap in (3,6,10,20,40):
        r=pg.evaluate("""g=>{OBS.reset({seed:31+g,tr:.3});OBS.ownerSeed(3);OBS.idle(4);const amps=[],snd=[];const poke=()=>{const e0=OBS.take();const [x,y]=OBS.bodyPt(0,-.1);OBS.tap(x,y,.1);OBS.idle(.9);const E=OBS.take().E;const f=E.find(e=>e.k==='flinch');amps.push(f?f.amp:0);snd.push(E.filter(e=>e.k==='snd'&&e.s.startsWith('voice')).map(e=>e.s.slice(6)).join('+'))};for(let i=0;i<12;i++)poke();const w=IMP.w,m=BRAIN.m;OBS.idle(g);BRAIN.z=.2;poke();return{amps,snd,w,m}}""",gap)
        print(' 隔',gap,'秒後：前 12 下',[round(100*a,1) for a in r['amps'][:12]],'→ 再戳',round(100*r['amps'][12],1),'聲',r['snd'][:4],r['snd'][12],'w',round(r['w'],2),'m',round(r['m'],2))
    # M3 被粗魯對待後多久看不出來
    print('== M3 粗魯 1 分鐘後放著')
    r=pg.evaluate("""()=>{OBS.reset({seed:55,tr:.5});OBS.ownerSeed(9);OBS.rough(60);const row=()=>{const s=OBS.shape();return{t:+t.toFixed(0),w:+IMP.w.toFixed(2),m:+BRAIN.m.toFixed(2),tr:+IMP.tr.toFixed(2),bw:+(s.x1-s.x0).toFixed(0),bh:+(s.y1-s.y0).toFixed(0),x:+globalC.xc.toFixed(0),k:OBS.klass(),cell:BMEM.cell.map(v=>+v.toFixed(2))}};const o=[row()];for(const g of [30,30,60,60,120,120,180,300]){OBS.idle(g);o.push(row())}return o}""")
    for x in r: print(' ',x)
    out['M3']=r
    # M4 地方記性：拖到左邊揉 3×8 秒 → 之後 10 分鐘待哪；對照：在中間揉；在家被嚇 10 次
    print('== M4 地方記性')
    for nm,js in (('在左邊揉3次',"""OBS.idle(2);{const [x,y]=OBS.bodyPt(0,-.1);OBS.drag(x,y,-.8,1);}OBS.idle(1);for(let k=0;k<3;k++){const [x,y]=OBS.bodyPt(0,-.15);OBS.rub(x,y,8,.25,1.4);OBS.idle(1)}"""),('在中間揉3次',"""OBS.idle(2);for(let k=0;k<3;k++){const [x,y]=OBS.bodyPt(0,-.15);OBS.rub(x,y,8,.25,1.4);OBS.idle(1)}"""),('在家連戳10組',"""OBS.idle(2);for(let k=0;k<10;k++){for(let j=0;j<3;j++){const [x,y]=OBS.bodyPt(0,-.1);OBS.tap(x,y,.08);OBS.idle(.17)}OBS.idle(1.5)}"""),('沒碰',"OBS.idle(30)")):
        sh=[];mx=[];cells=None;of=0
        for sd in (1,2,3):
            pg.evaluate("s=>{OBS.reset({seed:s,tr:.5});OBS.ownerSeed(s)}",600+sd);pg.evaluate("()=>{"+js+"}")
            cells=pg.evaluate("BMEM.cell.map(v=>+v.toFixed(2))");pg.evaluate("OBS.take()")
            pg.evaluate("OBS.idle(60)");pg.evaluate("OBS.take()")   # 跳過第一分鐘
            S=[];E=[]
            for m in range(9): pg.evaluate("OBS.idle(60)");q=pg.evaluate("OBS.take()");S+=q['S'];E+=q['E']
            a,bm=shares(S);sh.append(a);mx.append(bm);of+=sum(1 for e in E if e['k']=='offer')
        print(' ',nm,'格子',cells,'之後 9 分鐘各格佔%',sh,'平均 x',mx,'靠過來',of,'次')
    # M5 邊記性
    print('== M5 常摸左邊')
    for sd in (1,2):
        r=pg.evaluate("""s=>{OBS.reset({seed:700+s,tr:.6});OBS.ownerSeed(s);OBS.idle(2);for(let k=0;k<10;k++){const [x,y]=OBS.bodyPt(-.75,-.15);OBS.rub(x,y,2.5,.15,1.2);OBS.idle(1)}const side=BMEM.side;OBS.take();OBS.idle(240);const E=OBS.take().E;return{side,offer:E.filter(e=>e.k==='offer').map(e=>e.t),greet:E.filter(e=>e.k==='e4'&&e.ph).length,picks:E.filter(e=>e.k==='pick').map(e=>e.w)}}""",sd)
        print(' side',round(r['side'],2),'4 分鐘內靠過來',len(r['offer']),'次',r['offer'][:4],'招呼',r['greet'],collections.Counter(r['picks']))
    # M6 東西倒的習慣
    print('== M6 東西倒 8 次（每次扶回）的縮')
    r=pg.evaluate("""()=>{OBS.reset({seed:800,tr:.5});OBS.ownerSeed(2);const o=[];for(let k=0;k<8;k++){OBS.idle(9);BRAIN.z=.2;OBS.take();const p=PROPS.find(p=>p.im==='d_candle');propHome(p);p.alpha=1;p.fade=0;p.crashAt=null;p.a=0;drCrash(p,.35);OBS.idle(1.2);const E=OBS.take().E;const f=E.find(e=>e.k==='flinch');o.push([f?+(100*f.amp).toFixed(1):0,E.filter(e=>e.k==='snd'&&e.s.startsWith('voice')).length])}return o}""")
    print(' 第 1 到 8 次 [縮%,出聲]',r)
    b.close()
json.dump(out,open(BASE+'/data/mem.json','w',encoding='utf-8'),ensure_ascii=False)
