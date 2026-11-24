import sys, json, math, collections, glob, os
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
D='../data/'
def load(f): return json.load(open(D+f,encoding='utf-8'))
ZH=dict(rest='休息',look='張望／探',walk='走',sleep='睡',drowsy='想睡（瞇眼）',greet='來找你',push='推東西',held='被碰',purr='呼嚕',cower='縮著',flee='逃',strain='被扯',air='落下',cling='黏牆',hop='小跳',lure='跟手指',echo='回節奏')
def bouts(seq):
    out=[]
    for s in seq:
        if out and out[-1][0]==s: out[-1][1]+=1
        else: out.append([s,1])
    return out
def budget(files):
    tot=collections.Counter();n=0;per=[]
    for f in files:
        S=load(f)['S'];c=collections.Counter(r[1] for r in S);per.append({k:100*v/len(S) for k,v in c.items()});tot.update(c);n+=len(S)
    ks=[k for k,_ in tot.most_common()];return ks,per
for nm,files in (('網頁 熟0',['idle-taro-tr0-s%d.json'%i for i in(1,2,3)]),('網頁 熟1',['idle-taro-tr1-s%d.json'%i for i in(1,2,3)]),('手機邏輯',['idle-phone-tr0-s1.json','idle-phone-tr0-s2.json','idle-phone-tr1-s1.json'])):
    ks,per=budget(files);print('##',nm);
    for k in ks: print('|',ZH.get(k,k),'|',' | '.join('%.1f%%'%p.get(k,0) for p in per),'| 平均 %.1f%% |'%np.mean([p.get(k,0) for p in per]))
# 轉移矩陣（三顆種子合併，列→欄，%）
def trans(files):
    tm=collections.defaultdict(collections.Counter)
    for f in files:
        B=bouts([r[1] for r in load(f)['S']])
        for a,b in zip(B,B[1:]): tm[a[0]][b[0]]+=1
    return tm
for nm,files in (('熟0',['idle-taro-tr0-s%d.json'%i for i in(1,2,3)]),('熟1',['idle-taro-tr1-s%d.json'%i for i in(1,2,3)])):
    tm=trans(files);ks=['rest','look','walk','drowsy','sleep','greet','push'];ks=[k for k in ks if k in tm]
    print('## 轉移',nm);print('| 從＼到 |',' | '.join(ZH[k] for k in ks),'| 次數 |')
    for a in ks:
        n=sum(tm[a].values());print('|',ZH[a],'|',' | '.join('%d%%'%round(100*tm[a][b]/n) if tm[a][b] else '—' for b in ks),'|',n,'|')
# 睡：間隔分布
iv=[];dur=[];aw=[]
for i in(1,2,3):
    E=load('idle-taro-tr0-s%d.json'%i)['E'];so=[e['t'] for e in E if e['k']=='sleepOn'];sf=[e['t'] for e in E if e['k']=='sleepOff'];iv+=list(np.diff(so))
    for a in so:
        b=[x for x in sf if x>a]
        if b: dur.append(b[0]-a)
print('睡的開始間隔 n=%d 平均 %.0f 秒 sd %.0f CV %.2f 最短 %.0f 最長 %.0f'%(len(iv),np.mean(iv),np.std(iv),np.std(iv)/np.mean(iv),min(iv),max(iv)));print('睡多久 n=%d 平均 %.0f sd %.0f CV %.2f 最短 %.0f 最長 %.0f'%(len(dur),np.mean(dur),np.std(dur),np.std(dur)/np.mean(dur),min(dur),max(dur)))
print(' 間隔直方圖（每 20 秒一格 80 起）',list(map(int,np.histogram(iv,bins=[80,100,120,140,160,180,200,220,240])[0])))
# 自相關（三顆平均）
acs=[]
for i in(1,2,3):
    z=np.array([1.0 if r[1] in('sleep','drowsy') else 0 for r in load('idle-taro-tr0-s%d.json'%i)['S']]);z-=z.mean();acs.append([float((z[:-L]*z[L:]).mean()/z.var()) for L in range(1,1000)])
ac=np.mean(acs,0)
for lo,hi in((60,200),(200,400)):
    k=max(range(lo,hi*1),key=lambda i:ac[i]);print(' 自相關 峰 %.1f 秒 r=%.2f'%((k+1)*.5,ac[k]))
for a in (36,72,75,100,145,150,220,290,300,440): print('   lag %.0f 秒 r=%.2f'%(a,ac[int(a*2)-1]))
