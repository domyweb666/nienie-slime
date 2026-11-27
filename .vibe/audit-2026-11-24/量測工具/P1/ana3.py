import sys, json, math, collections
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
MM=.1656
def load(fn): return json.load(open(fn,encoding='utf-8'))
D='../data/'
# 1 發現曲線：看得出不同的動作種類，第一次出現的時間
def kinds(E):
    out={}
    def add(k,t): out.setdefault(k,t)
    for e in E:
        k=e['k'];t=e['t']-3
        if k=='sniff': add('伸偽足探',t)
        elif k=='gaitTo': add('走一段',t)
        elif k=='route': add('走回家',t)
        elif k=='blink': add('眨眼',t)
        elif k=='sac': add('瞄你' if e['you'] else '瞄別處',t)
        elif k=='sigh': add('大口嘆氣',t)
        elif k=='pre' and e['p']=='sleep': add('想睡（瞇眼）',t)
        elif k=='sleepOn': add('睡著',t)
        elif k=='wake' and e['self']: add('自己醒',t)
        elif k=='e4' and e['ph']: add('來找你打招呼',t)
        elif k=='cat': add('推東西',t)
        elif k=='offer': add('把那邊靠過來',t)
        elif k=='drCrash': add('撞倒東西',t)
        elif k=='flinch': add('嚇一下（縮）',t)
        elif k=='snd' and e['s']=='fx.snore': add('鼾聲',t)
        elif k=='hop': add('小跳',t)
        elif k=='drLook': add('看有聲音的地方',t)
    return out
for nm,fs in (('tr0',['idle-taro-tr0-s%d.json'%i for i in(1,2,3)]),('tr1',['idle-taro-tr1-s%d.json'%i for i in(1,2,3)])):
    print('== 發現曲線',nm)
    for f in fs:
        k=kinds(load(D+f)['E']);v=sorted(k.items(),key=lambda x:x[1]);print(' ',f,len(v),'種；最後一種新的出現在',round(v[-1][1]/60,1),'分',v[-1][0],'；第 5 分鐘看過',sum(1 for x in v if x[1]<300),'種；全部:',[(a,round(b)) for a,b in v])
# 2 各狀態的寬高
print('== 各狀態外形（點）寬 高 面積比（平均±標準差）')
S=[r for i in(1,2,3) for r in load(D+'idle-taro-tr0-s%d.json'%i)['S']]
for k in ('rest','look','walk','drowsy','sleep'):
    a=np.array([[r[22],r[23],r[24]] for r in S if r[1]==k]);print(' ',k,len(a),'寬 %.1f±%.1f 高 %.1f±%.1f 面積 %.3f'%(a[:,0].mean(),a[:,0].std(),a[:,1].mean(),a[:,1].std(),a[:,2].mean()))
# 3 眼睛
aw=[r for r in S if r[1] in('rest','look','walk','drowsy')]
g=np.array([[r[16],r[17]] for r in aw]);mag=np.hypot(g[:,0],g[:,1])*MM
print('== 眼睛位移 mm 中位 %.2f 九成位 %.2f；看你(<0.4mm)佔 %.0f%%；左 %.0f%% 右 %.0f%% 上 %.0f%% 下 %.0f%%'%(np.median(mag),np.percentile(mag,90),100*(mag<.41).mean(),100*(g[:,0]<-3).mean(),100*(g[:,0]>3).mean(),100*(g[:,1]<-3).mean(),100*(g[:,1]>3).mean()))
# 每次換視線間隔
E=[e for i in(1,2,3) for e in load(D+'idle-taro-tr0-s%d.json'%i)['E']]
for i in(1,):
    e=[x['t'] for x in load(D+'idle-taro-tr0-s%d.json'%i)['E'] if x['k']=='sac'];iv=np.diff(e);iv=iv[iv<10];print('  換視線間隔 平均 %.2f 秒 CV %.2f'%(iv.mean(),iv.std()/iv.mean()))
    e=[x['t'] for x in load(D+'idle-taro-tr0-s%d.json'%i)['E'] if x['k']=='blink'];iv=np.diff(e);iv=iv[iv<20];print('  眨眼間隔 平均 %.2f 秒 CV %.2f 每分 %.1f'%(iv.mean(),iv.std()/iv.mean(),60/iv.mean()))
# 4 心情在無人時的範圍
m=np.array([r[9] for r in S]);f=np.array([r[7] for r in S]);print('== 無人時心情 最低 %.2f 最高 %.2f；怕 最高 %.2f 平均 %.3f；想被摸(s) tr0 最高 %.2f'%(m.min(),m.max(),f.max(),f.mean(),max(r[6] for r in S)))
for k,ix in(('睏',4),('好奇',5),('想被摸',6),('怕',7),('想動',8)):
    v=np.array([r[ix] for r in S]);print('   ',k,'平均 %.2f sd %.2f 最低 %.2f 最高 %.2f'%(v.mean(),v.std(),v.min(),v.max()))
