import json,sys,os
import numpy as np, soundfile as sf
sys.stdout.reconfigure(encoding='utf-8')
RES=r'E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/ios/NieNie/Resources'
m=json.load(open(os.path.join(RES,'manifest.json'),encoding='utf-8'))
def env(x,sr,win=0.002,hop=0.0005):
    w=int(win*sr);h=max(1,int(hop*sr))
    c=np.concatenate([[0],np.cumsum(x**2)])
    n=np.arange(0,len(x),h)
    a=np.maximum(0,n-w//2);b=np.minimum(len(x),n+w//2+1)
    return np.sqrt((c[b]-c[a])/(b-a)), n/sr*1000
def meas(x,sr):
    e,t=env(x,sr); pk=e.max(); d=20*np.log10(np.maximum(e,1e-9)/pk)
    f=lambda th: float(t[np.argmax(d>=th)])
    c=np.cumsum(x**2);c/=c[-1]
    en=lambda q: float(np.searchsorted(c,q)/sr*1000)
    return dict(t40=f(-40),t20=f(-20),t10=f(-10),t6=f(-6),t3=f(-3),tpk=float(t[e.argmax()]),e10=en(.1),e50=en(.5),rms=20*np.log10(np.sqrt((x**2).mean())+1e-12),pk=20*np.log10(np.abs(x).max()+1e-12),
                first=float(np.argmax(np.abs(x)>10**(-60/20))/sr*1000))
rows=[]
for k in ['press','release','pull','rub','settle','voice','fx','ding']:
    v=m[k]
    if isinstance(v,list): v={'all':v}
    for l,fs in v.items():
        for f in fs:
            x,sr=sf.read(os.path.join(RES,f)); x=x if x.ndim==1 else x.mean(1)
            r=meas(x,sr); r.update(kind=k,layer=l,f=f,dur=len(x)/sr*1000); rows.append(r)
json.dump(rows,open(os.path.join(os.path.dirname(__file__),'onset.json'),'w',encoding='utf-8'),ensure_ascii=False)
def show(sel):
    print('%-26s %5s %6s %6s %6s %6s %6s %6s %6s %6s'%('file','dur','t-40','t-20','t-10','t-6','tpeak','E10%','E50%','pkdB'))
    for r in sel: print('%-26s %5.0f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f'%(r['f'],r['dur'],r['t40'],r['t20'],r['t10'],r['t6'],r['tpk'],r['e10'],r['e50'],r['pk']))
core=[r for r in rows if r['kind'] in('press','release') or (r['kind']=='pull' and r['layer']=='strand')]
if len(sys.argv)>1 and sys.argv[1]=='all':
    show(core)
else:
    print('layer summary (median [min..max])')
    for key in [('press','body'),('press','wet'),('press','air'),('release','air'),('release','wet'),('release','body'),('pull','strand'),('pull','loop'),('rub','loop'),('settle','bubble'),('settle','hiss')]+[('voice',l) for l in m['voice']]+[('fx',l) for l in m['fx']]+[('ding','all')]:
        s=[r for r in rows if (r['kind'],r['layer'])==key]
        g=lambda q:'%5.1f [%5.1f..%5.1f]'%(np.median([r[q] for r in s]),min(r[q] for r in s),max(r[q] for r in s))
        print('%-8s %-9s n=%2d first %s | t-20 %s | t-6 %s | tpk %s | E50 %s | rms %s'%(key[0],key[1],len(s),g('first'),g('t20'),g('t6'),g('tpk'),g('e50'),g('rms')))
    print('slowest 10 by t-6 (press, release, pull.strand)')
    show(sorted(core,key=lambda r:-r['t6'])[:10])
    print('slowest 10 by E50')
    show(sorted(core,key=lambda r:-r['e50'])[:10])
