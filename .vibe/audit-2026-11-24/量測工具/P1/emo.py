# emo.py：情緒與需求到身體的可見量。每個條件固定住 12 秒（跳過前 3 秒），量外框平均寬高、呼吸幅度、眼睛，跟基準比
import sys;sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/P1work/run')
from drv import *
from playwright.sync_api import sync_playwright
import numpy as np
JS="""(c)=>{const O=OBS;O.reset({seed:c.seed||77,tr:0.5});const hold=()=>{if(c.m!=null){BRAIN.m=c.m;BRAIN.mS=c.m}if(c.tr!=null){IMP.tr=c.tr}if(c.w!=null){IMP.w=c.w}if(c.mc!=null){MOOD.c=c.mc}if(c.scare!=null)MOOD.scare=c.scare;if(c.ex!=null)BRX.exert=c.ex;if(c.slp){SLP.on=true;LIFE.st='sleep'}
 for(const k of ['z','q','s','e'])if(c[k]!=null)BRAIN[k]=c[k];if(c.cower)MOOD.cowerUntil=t+1;
 LIFE.st=c.slp?'sleep':'rest';LIFE.until=t+99;if(!c.slp)SLP.on=false;LIFE.att=null;GAIT.on=false;EYE.sacT=t+2;EYE.sx=0;EYE.sy=0;EYE.nextBlink=t+3;BRX.sighNext=t+50};
 const out=[];let b0=null;for(let i=0;i<60*15;i++){hold();update(1/60);if(i>=60*4){const s=O.shape();out.push([s.x1-s.x0,s.y1-s.y0,s.y0,s.A/A0,EYE.openD*EYE.wideD,EYE.mode,BR.phase])}}
 const n=bnd.length,P=[];return{out,R,MC:[MC.c,MC.s,MC.w,MC.z],col:tint('#D2C2FF',false),eye:EYE.mode}}"""
conds=[('基準 m.15',{}),('心情 +1',{'m':1}),('心情 +0.5',{'m':.5}),('心情 -0.5',{'m':-.5}),('心情 -1',{'m':-1}),('熟 0',{'tr':0}),('熟 1',{'tr':1}),('戒 0.3',{'w':.3}),('戒 0.6',{'w':.6}),('戒 1',{'w':1}),('舒服 c=1',{'mc':1}),('緊張 scare=1',{'scare':1}),('喘 exert=1',{'ex':1}),('睡著',{'slp':1}),('縮著',{'cower':1}),('睏 z=0.95',{'z':.95}),('好奇 q=1',{'q':1}),('想被摸 s=1',{'s':1}),('想動 e=1',{'e':1}),('基準(另一亂數)',{'seed':78})]
serve()
res={}
with sync_playwright() as p:
    b,pg,errs=page(p)
    for n,c in conds:
        r=pg.evaluate(JS,c);o=r['out'];a=np.array([x[:5] for x in o],float)
        ph=[x[6] for x in o];res[n]={'w':a[:,0].mean(),'h':a[:,1].mean(),'area':a[:,3].mean(),'wpp':a[:,0].max()-a[:,0].min(),'hpp':a[:,1].max()-a[:,1].min(),'open':a[:,4].mean(),'mode':r['eye'],'col':r['col'],'breathT':len(o)/60/(ph[-1]-ph[0]) if ph[-1]>ph[0] else None,'hsd':a[:,1].std(),'wsd':a[:,0].std()}
    b.close()
base=res['基準 m.15'];MM=.1656
print('基準 寬 %.1f 點(%.1f mm) 高 %.1f 點(%.1f mm) 呼吸造成的高低差 高 %.1f 點(%.1f mm) 寬 %.1f 點 呼吸週期 %.2f 秒'%(base['w'],base['w']*MM,base['h'],base['h']*MM,base['hpp'],base['hpp']*MM,base['wpp'],base['breathT']))
for n,r in res.items():
    print('%-16s 寬 %+.1f mm  高 %+.1f mm  面積 %+.1f%%  眼開 %.2f %s  呼吸 %.2f 秒 高低差 %.1f mm  色 %s'%(n,(r['w']-base['w'])*MM,(r['h']-base['h'])*MM,(r['area']/base['area']-1)*100,r['open'],r['mode'],r['breathT'] or 0,r['hpp']*MM,r['col']))
json.dump(res,open(BASE+'/data/emo.json','w',encoding='utf-8'),ensure_ascii=False)
