import sys,json,os
sys.stdout.reconfigure(encoding='utf-8')
import numpy as np
def go(f):
    O=json.load(open(f));rows=[(o['seed'],r) for o in O for r in o['rows']];n=len(rows)
    modes=sorted([k for k in rows[0][1] if k[0]=='m' and k[1:].isdigit()])
    print(os.path.basename(f),'組',len(O),'量的格',n)
    out={}
    for md in modes:
        q=[r[md] for _,r in rows];sd=[s for s,_ in rows]
        p2=np.array([(x['pieces'][1] if len(x['pieces'])>1 else 0) for x in q],float);hs=np.array([x['hsA'] for x in q],float);Ar=np.array([x['Ar'] for x in q],float);As=np.array([x['As'] for x in q],float);lost=np.array([x['lost'] for x in q],float);gain=np.array([x['gain'] for x in q],float)
        eo=np.array([x.get('eyeOut',0) or 0 for x in q],float);ec=np.array([x.get('eyeC',0) or 0 for x in q],float)
        dx=np.array([ (x.get('dxor') or 0)/max(1,(x.get('df') or 1)) for x in q],float)
        o={'斷成兩塊以上(第二塊>=20px)格%':100*np.mean(p2>=20),'組':len({s for s,v in zip(sd,p2) if v>=20}),'最大第二塊px':p2.max(),'破洞格%':100*np.mean(hs>0),'洞組':len({s for s,v in zip(sd,hs) if v>0}),'最大洞px':hs.max(),'吃掉面積%平均':100*np.mean(lost/Ar),'吃掉最大%':100*(lost/Ar).max(),'補出最大%':100*(gain/Ar).max(),'眼睛邊出界格%':100*np.mean(eo>0),'眼睛中心出界格%':100*np.mean(ec>0),'皮面積平均':As.mean(),'每幀外框變動px平均':dx.mean(),'p95':np.percentile(dx,95)}
        out[md]=o
    ks=list(out[modes[0]].keys())
    print('%-28s'%'','  '.join('%10s'%m for m in modes))
    for k in ks: print('%-28s'%k,'  '.join('%10.3f'%out[m][k] for m in modes))
    # 遮罩面積 mode1/2 比 mode0 多多少
    for m in modes[1:]:
        a=np.array([r[m]['Ar']/r['m0']['Ar']-1 for _,r in rows])*100;b=np.array([r[m]['As']/max(1,r['m0']['As'])-1 for _,r in rows])*100
        print(m,'皮面積比 m0 多：中位 %.2f%% p90 %.2f%% p99 %.2f%% 最大 %.1f%%；沒有翻面的格中位 %.2f%% 最大 %.2f%%'%(np.median(b),np.percentile(b,90),np.percentile(b,99),b.max(),np.median([x for x,(s,r) in zip(b,rows) if r['m0']['inv']==0]),max([x for x,(s,r) in zip(b,rows) if r['m0']['inv']==0])))
    # 有補點的格
    rm=[r for _,r in rows if r['rm']];print('補點格',len(rm),'有翻面的格 %.1f%%'%(100*np.mean([r['m0']['inv']>0 for _,r in rows])),'外框交叉的格 %.1f%%'%(100*np.mean([r['m0']['ringX']>0 for _,r in rows])))
    # 斷開是因為交叉（raw>=2）還是圓角吃掉
    br=[r['m0'] for _,r in rows if len(r['m0']['pieces'])>1 and r['m0']['pieces'][1]>=20];print('斷開的格',len(br),'其中原始路徑就兩塊',sum(x['nr']>1 for x in br),'路徑一塊、圓角切斷',sum(x['nr']==1 for x in br),'；有外框交叉',sum(x['ringX']>0 for x in br),'有翻面',sum(x['inv']>0 for x in br))
for f in sys.argv[1:]: go(f);print()
