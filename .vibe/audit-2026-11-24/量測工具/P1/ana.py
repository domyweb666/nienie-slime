# ana.py <json> [...]：無人觀察分析
import sys, json, math, collections, random
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
MM=0.1656  # 1 點 = 0.1656 mm（iPhone 393 點寬、460 ppi、3 倍）
IDX=dict(t=0,k=1,st=2,act=3,z=4,q=5,s=6,f=7,e=8,m=9,tr=10,w=11,c=12,a=13,scare=14,purr=15,gx=16,gy=17,mode=18,open=19,x=20,y=21,bw=22,bh=23,area=24,mo=25,mx=26,tr2=27,cell=28,side=29)
def bouts(seq):
    out=[]
    for i,s in enumerate(seq):
        if out and out[-1][0]==s: out[-1][2]+=1
        else: out.append([s,i,1])
    return out
def ent(p):
    p=np.array([x for x in p if x>0],float);p/=p.sum();return float(-(p*np.log2(p)).sum())
def load(fn): return json.load(open(fn,encoding='utf-8'))
def ana(d,verbose=True):
    S=d['S'];E=d['E'];seq=[r[1] for r in S];T=S[-1][0]-S[0][0]
    n=len(seq);cnt=collections.Counter(seq);B=bouts(seq)
    R={}
    R['min']=T/60
    R['budget']={k:round(100*v/n,1) for k,v in cnt.most_common()}
    bl=collections.defaultdict(list)
    for s,i,l in B: bl[s].append(l*.5)
    R['bouts_per_h']={k:round(len(v)/(T/3600),1) for k,v in bl.items()}
    R['bout_dur']={k:(round(float(np.mean(v)),1),round(float(np.std(v)/max(1e-9,np.mean(v))),2)) for k,v in bl.items()}
    # 轉移矩陣（bout 層級）
    labs=sorted(bl);tm={a:collections.Counter() for a in labs}
    for a,b in zip(B,B[1:]): tm[a[0]][b[0]]+=1
    R['trans']={a:dict(c) for a,c in tm.items()}
    # 一階條件熵 vs 零階
    tot=sum(sum(c.values()) for c in tm.values())
    h1=sum(sum(c.values())/tot*ent(list(c.values())) for c in tm.values() if sum(c.values()))
    h0=ent([len(v) for v in bl.values()])
    R['H0']=round(h0,2);R['H1']=round(h1,2)
    # 二階
    tm2=collections.defaultdict(collections.Counter)
    for a,b,c in zip(B,B[1:],B[2:]): tm2[(a[0],b[0])][c[0]]+=1
    tt=sum(sum(c.values()) for c in tm2.values());R['H2']=round(sum(sum(c.values())/tt*ent(list(c.values())) for c in tm2.values()),2) if tt else None
    # 最常見的下一步猜中率
    ok=sum(max(c.values()) for c in tm.values() if c);R['guess1']=round(ok/tot,2)
    ok2=sum(max(c.values()) for c in tm2.values() if c);R['guess2']=round(ok2/tt,2) if tt else None
    # 事件次數
    ev=collections.Counter();
    for e in E:
        k=e['k']
        if k=='snd': ev['聲:'+e['s']]+=1
        elif k=='pick': ev['決定:'+e['w']]+=1
        elif k=='sac': ev['瞄'+('你' if e['you'] else '別處')]+=1
        elif k in('gaitTo','goHome','blink','sigh','wake','offer','cat','drLook','drCrash','hop','happy','pre','sniff','flinch','lookYou','route'): ev[k]+=1
    R['ev_per_h']={k:round(v/(T/3600),1) for k,v in ev.most_common()}
    # 走路：每段位移
    ws=[]
    for s,i,l in B:
        if s=='walk':
            a=S[max(0,i-1)];b=S[min(n-1,i+l)];ws.append(abs(b[IDX['x']]-a[IDX['x']]))
    R['walk_n_per_h']=round(len(ws)/(T/3600),1);R['walk_mm']=(round(float(np.mean(ws))*MM,1),round(float(np.max(ws))*MM,1)) if ws else None
    xs=np.array([r[IDX['x']] for r in S]);R['x_range_mm']=round(float(xs.max()-xs.min())*MM,1);R['x_sd_mm']=round(float(xs.std())*MM,1)
    h=np.histogram(xs,bins=5,range=(4,389))[0];R['cell_share']=[round(100*float(v)/n) for v in h]
    R['dist_m_per_h']=round(float(np.abs(np.diff(xs)).sum())*MM/1000/(T/3600),2)
    # 靜止：外框平均每 0.5 秒動多少（點）
    by=collections.defaultdict(list)
    for r in S: by[r[1]].append(r[IDX['mo']]+r[IDX['tr2']])
    R['move_pt_per_halfsec']={k:round(float(np.mean(v)),2) for k,v in by.items()}
    # 眼睛：看你（偏移 < 2.5 點）比例
    aw=[r for r in S if r[1] not in('sleep',)]
    R['look_you_share']=round(sum(1 for r in aw if math.hypot(r[IDX['gx']],r[IDX['gy']])<2.5)/max(1,len(aw)),2)
    # 睡：開始的間隔
    so=[e['t'] for e in E if e['k']=='sleepOn'];sf=[e['t'] for e in E if e['k']=='sleepOff']
    iv=np.diff(so);R['sleep']={'n_per_h':round(len(so)/(T/3600),1),'interval_s':(round(float(iv.mean()),0),round(float(iv.std()/iv.mean()),2)) if len(iv)>1 else None}
    dur=[]
    for a in so:
        b=[x for x in sf if x>a]
        if b: dur.append(b[0]-a)
    R['sleep']['dur_s']=(round(float(np.mean(dur)),0),round(float(np.std(dur)/np.mean(dur)),2)) if dur else None
    # 自相關：睡 01 序列
    z=np.array([1.0 if s in('sleep','drowsy') else 0 for s in seq]);z=z-z.mean()
    if z.std()>0:
        ac=[float((z[:-L]*z[L:]).mean()/z.var()) for L in range(1,min(n//3,900))]
        L0=20;pk=max(range(L0*2,len(ac)),key=lambda i:ac[i]);R['ac_sleep']=(round((pk+1)*.5,1),round(ac[pk],2))
        # 波谷
        mn=min(range(0,len(ac)),key=lambda i:ac[i]);R['ac_sleep_min']=(round((mn+1)*.5,1),round(ac[mn],2))
    # 重複片語：bout 序列（去掉長度），最長的重複子序列與 4-gram 集中度
    bs=[b[0] for b in B];g4=collections.Counter(tuple(bs[i:i+4]) for i in range(len(bs)-3));
    R['bout_n']=len(bs);R['top4']=[('→'.join(k),v) for k,v in g4.most_common(4)];R['uniq4']=(len(g4),len(bs)-3)
    return R
if __name__=='__main__':
    for fn in sys.argv[1:]:
        R=ana(load(fn));print('=====',fn.split('/')[-1])
        for k,v in R.items(): print(' ',k,':',v)
