# open.py：每次打開 app 的前 60 秒（24 次），牠做什麼；tr 0、0.6、1；另外大腦關（手機）
import sys;sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work/run')
from drv import *
from playwright.sync_api import sync_playwright
import collections, numpy as np
serve()
BR0={'brain':0,'mood':0,'brPre':0,'brMem':0,'decoReal':0,'decoBody':0,'decoReact':0,'decoCat':0}
out={}
with sync_playwright() as p:
    b,pg,errs=page(p)
    for name,o in [('web tr0',{'tr':0}),('web tr1',{'tr':1}),('web tr1 昨天摸左邊',{'tr':1,'cell':[0,1,0,0,0],'side':-.8}),('phone tr0',{'tr':0,'over':BR0}),('phone tr1',{'tr':1,'over':BR0})]:
        rec=[]
        for k in range(16):
            oo=dict(o);oo.update(seed=9000+k*7,raw=1)
            pg.evaluate('o=>OBS.reset(o)',oo);pg.evaluate('OBS.idle(75)');r=pg.evaluate('OBS.take()')
            ev=[e for e in r['E'] if e['k'] in('pick','pre','sleepOn','e4','offer','route','lookYou','sniff','gaitTo') or (e['k']=='snd' and e['s'].startswith('voice'))]
            picks=[(e['w'],round(e['t'],1)) for e in r['E'] if e['k']=='pick']
            life=[(e['to'],round(e['t'],1)) for e in r['E'] if e['k']=='life']
            fv=[e['t'] for e in r['E'] if e['k']=='snd' and e['s'].startswith('voice')]
            fl=[e['t'] for e in r['E'] if e['k']=='lookYou']
            fsn=[e['t'] for e in r['E'] if e['k']=='sniff'];fso=[e['t'] for e in r['E'] if e['k']=='sleepOn'];fg=[e['t'] for e in r['E'] if e['k']=='gaitTo']
            xs=[s[20] for s in r['S']]
            rec.append(dict(picks=picks,life=life,voice=fv[:1],look=fl[:1],sniff=fsn[:1],sleep=fso[:1],go=fg[:1],x=(round(xs[8],0),round(xs[-1],0))))
        out[name]=rec
        print('==',name)
        print('第一個決定',collections.Counter(x['picks'][0][0] if x['picks'] else '無' for x in rec),'時間',[x['picks'][0][1] if x['picks'] else None for x in rec][:10])
        print('前三個決定',collections.Counter(','.join(q[0] for q in x['picks'][:3]) for x in rec).most_common(5))
        for key in ('look','voice','sniff','go','sleep'):
            v=[x[key][0] for x in rec if x[key]];print(' 第一次',key,'發生',len(v),'/',len(rec),'平均',round(np.mean(v),1) if v else None,'秒 最早',round(min(v),1) if v else None,'最晚',round(max(v),1) if v else None)
    b.close()
json.dump(out,open(BASE+'/data/open.json','w',encoding='utf-8'),ensure_ascii=False)
