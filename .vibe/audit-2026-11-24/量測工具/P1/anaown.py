# anaown.py：飼主資料。每個動作後牠的反應種類、延遲、機率、重複
import sys, json, math, collections
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
def load(fn): return json.load(open(fn,encoding='utf-8'))
ACTIVE={'flinch','hop','flee','lean','wag','happy','shake','e4','echo','offer','cat','sniff','gaitTo','route','wake'}
for fn in sys.argv[1:]:
    d=load(fn);E=d['E'];S=d['S'];sec=d['job']['sec'];name=fn.split('/')[-1]
    tA=S[0][0];acts=[e for e in E if e['k']=='act'];tEnd=max(a['t1'] for a in acts)
    print('=====',name,'動作',len(acts),collections.Counter(a['kind'] for a in acts).most_common(),'mid',d['mid'])
    # 期間的時間分配（含被碰）
    seq=[r for r in S if r[0]<=tEnd];c=collections.Counter(r[1] for r in seq);print(' 時間分配',{k:round(100*v/len(seq),1) for k,v in c.most_common()})
    # 聲音
    snd=collections.Counter(e['s'] for e in E if e['k']=='snd' and e['t']<=tEnd);tot=sum(snd.values());print(' 聲音(次)',dict(snd.most_common(14)))
    vo=[e for e in E if e['k']=='snd' and e['s'].startswith('voice') and e['t']<=tEnd]
    if vo:
        vs=[e['s'][6:] for e in vo];run=1;mx=1;mk=vs[0]
        for a,b in zip(vs,vs[1:]):
            run=run+1 if a==b else 1
            if run>mx: mx=run;mk=b
        cc=collections.Counter(vs);p=np.array(list(cc.values()))/len(vs)
        iv=np.diff([e['t'] for e in vo]);print(' 牠的聲音',len(vs),'次/',round((tEnd-tA)/60,1),'分，種類',len(cc),'最多的占',round(p.max(),2),cc.most_common(3),'連續同一種最多',mx,mk,'熵',round(float(-(p*np.log2(p)).sum()),2),'間隔中位',round(float(np.median(iv)),2) if len(iv) else None)
    # 每種動作的反應
    by=collections.defaultdict(list)
    for i,a in enumerate(acts):
        nx=acts[i+1]['t0'] if i+1<len(acts) else a['t1']+6
        hi=min(a['t1']+3.5,nx);ev=[e for e in E if a['t0']<=e['t']<=hi and e['k']!='act']
        sig=[]
        for e in ev:
            if e['k'] in('flinch','hop','flee','happy','shake','e4','echo','offer','wake'): sig.append(e['k'])
            elif e['k']=='lean': sig.append('lean+' if e['S']>0 else 'lean-')
            elif e['k']=='snd' and e['s'].startswith('voice'): sig.append(e['s'][6:])
            elif e['k']=='eyeMode' and e['m'] in('happy','squeeze'): sig.append('眼'+e['m'])
        by[a['kind']].append((tuple(sorted(set(sig))),a,ev))
    for k,L in sorted(by.items()):
        cnt=collections.Counter(x[0] for x in L);n=len(L);top=cnt.most_common(3);p=np.array(list(cnt.values()))/n
        # 第一個主動反應的延遲（從落指）
        lat=[]
        for sg,a,ev in L:
            q=[e['t']-a['t0'] for e in ev if e['k'] in('flinch','hop','flee','lean','happy','shake') or (e['k']=='snd' and e['s'].startswith('voice'))]
            lat.append(min(q) if q else None)
        l2=[x for x in lat if x is not None]
        print('  %-9s n=%d 反應組合 %d 種 熵 %.2f 最常見 %s｜有主動反應 %d/%d 第一個反應延遲 中位 %s 秒'%(k,n,len(cnt),float(-(p*np.log2(p)).sum()),[('+'.join(x[0]) or '無',x[1]) for x in top],len(l2),n,round(float(np.median(l2)),2) if l2 else None))
    # m tr w 何時到頂
    for nm,ix,th in (('心情 m>0.9',9,.9),('心情 m<-0.9',9,-.9),('熟 tr>0.9',10,.9),('戒 w>0.6',11,.6)):
        q=[r[0]-tA for r in S if (r[ix]>th if th>0 else r[ix]<th)]
        if q: print('   ',nm,'第一次',round(q[0]),'秒；這 10 分鐘內占',round(100*sum(1 for r in seq if (r[ix]>th if th>0 else r[ix]<th))/len(seq)),'%')
    # 之後無人
    aft=[r for r in S if r[0]>tEnd+2]
    if len(aft)>60:
        c=collections.Counter(r[1] for r in aft);print(' 之後無人',round(len(aft)/120,1),'分',{k:round(100*v/len(aft),1) for k,v in c.most_common()},'m',aft[0][9],'→',aft[-1][9],'w',aft[0][11],'→',aft[-1][11],'x 平均',round(np.mean([r[20] for r in aft]),0))
