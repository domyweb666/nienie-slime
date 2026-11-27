# tryfix.py：只在觀察器裡蓋上去試（不改專案）：A 睡醒時間加亂數；B 打開時需求隨機
import sys;sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work/run')
from drv import *
from playwright.sync_api import sync_playwright
import numpy as np, collections, math
serve()
JS_A="""()=>{const r=OBS.seeded(99);const N=()=>Math.sqrt(-2*Math.log(Math.max(1e-9,r())))*Math.cos(6.283*r());
 const set=()=>{mat.brAwakeT=Math.min(3600,Math.max(120,900*Math.exp(.9*N())));mat.brSleepT=Math.min(900,Math.max(20,150*Math.exp(1.0*N())))};set();const w=wake;wake=function(){const on=SLP.on;const q=w.apply(this,arguments);if(on)set();return q};}"""
def stats(E,S):
    so=[e['t'] for e in E if e['k']=='sleepOn'];sf=[e['t'] for e in E if e['k']=='sleepOff'];iv=np.diff(so);du=[min(x for x in sf if x>a)-a for a in so if any(x>a for x in sf)]
    c=collections.Counter(r[1] for r in S);n=len(S);z=np.array([1.0 if r[1] in('sleep','drowsy') else 0 for r in S]);z-=z.mean();ac=[float((z[:-L]*z[L:]).mean()/z.var()) for L in range(1,1200)]
    k=max(range(120,1199),key=lambda i:ac[i])
    return dict(sleep_per_h=round(len(so)/(n/7200),1),interval=(round(float(iv.mean())),round(float(iv.std()/iv.mean()),2)) if len(iv)>1 else None,dur=(round(float(np.mean(du))),round(float(np.std(du)/np.mean(du)),2)) if len(du)>1 else None,budget={k2:round(100*v/n,1) for k2,v in c.most_common(5)},ac_peak=((k+1)*.5,round(ac[k],2)))
with sync_playwright() as p:
    b,pg,errs=page(p)
    for nm,js in (('現在',None),('A 睡醒加亂數',JS_A)):
        pg.evaluate("OBS.reset({seed:4242,tr:.3})")
        if js: pg.evaluate(js)
        E=[];S=[]
        for m in range(60): pg.evaluate('OBS.idle(60)');q=pg.evaluate('OBS.take()');E+=q['E'];S+=q['S']
        print(nm,stats(E,S),flush=True)
    b.close()
    b,pg,errs=page(p)
    cnt=collections.Counter();first=collections.Counter()
    for k in range(24):
        pg.evaluate("s=>{OBS.reset({seed:s,tr:.3,raw:1,bseed:s*7919});const r=OBS.seeded(s);BRAIN.z=.7*r();BRAIN.q=r();BRAIN.e=r();BRAIN.s=.6*r()}",700+k);pg.evaluate('OBS.idle(40)');E=pg.evaluate('OBS.take()')['E'];pk=[e['w'] for e in E if e['k']=='pick'][:3];cnt[','.join(pk)]+=1;first[pk[0] if pk else '—']+=1
    p_=np.array(list(cnt.values()))/24;print('B 打開時需求隨機：第一個',dict(first),'前三個組合',len(cnt),'種 熵 %.2f'%float(-(p_*np.log2(p_)).sum()),cnt.most_common(4))
    b.close()
