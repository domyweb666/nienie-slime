# 各版（不同資料夾）的補點踢：A 原本 D 家跟著移（fix7） E 多邊形重心（fix8） F 偏移慢慢退（fix9）
from common import *
import multiprocessing as mp, numpy as np
JS=open(BASE+'/tools/remfix.py',encoding='utf-8').read().split("JS='''")[1].split("'''")[0]
def run(a):
    port,fn,seeds,arm=a
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        b,pg,errs=page(p,port)
        for f in ('skinmodes.js','paired.js'): pg.evaluate(open(BASE+'/tools/'+f,encoding='utf-8').read())
        r=pg.evaluate(JS,[fn,seeds,'A',{}]);b.close();return (fn,arm,r)
if __name__=='__main__':
    ports={};srvs=[]
    for arm,d in (('A','prototype/web'),('D','fix7/prototype/web'),('E','fix8/prototype/web'),('F','fix9/prototype/web')):
        ports[arm]=freeport();srvs.append(serve(ports[arm],BASE+'/'+d))
    fn=sys.argv[1];n=int(sys.argv[2]);sd=list(range(1,n+1));jobs=[(ports[a],fn,sd[k::3],a) for a in ports for k in range(3)]
    with mp.Pool(6) as P: R=P.map(run,jobs,chunksize=1)
    for arm in ports:
        L=[x for f,a,r in R if a==arm for x in r['out']];S=[r['stats'] for f,a,r in R if a==arm]
        print(arm,'組',sum(s['tot'] for s in S),'四分之一以上跑出螢幕的組',sum(s['off'] for s in S),'最多 %.0f%%'%(100*max(s['worst'] for s in S)),'面積最低 %.2f'%min(s['minA'] for s in S))
        for name,sel in (('d',lambda x:x['ph']=='d' and not x['back']),('pull',lambda x:x['ph']=='pull' and not x['back']),('hold',lambda x:x['ph']=='hold' and not x['back']),('換回',lambda x:x['back'])):
            q=[x for x in L if sel(x)]
            if q: g=lambda k:np.array([x[k] for x in q],float);print('   %-4s n%3d 粒子平均跳 %.0f｜同一格整隻移 中位 %.1f p90 %.1f｜兩格後 中位 %.1f p90 %.1f｜八格後 中位 %.1f p90 %.1f'%(name,len(q),np.median(g('dm')),np.median(g('a0')),np.percentile(g('a0'),90),np.median(g('a1')),np.percentile(g('a1'),90),np.median(g('a8')),np.percentile(g('a8'),90)))
    for s in srvs: s.shutdown()
