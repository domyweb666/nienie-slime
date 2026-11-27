# ana2.py：每一輪醒睡的內容、走路之前之後、決定的理由、撞倒東西
import sys, json, math, collections
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
MM=.1656
def load(fn): return json.load(open(fn,encoding='utf-8'))
agg=collections.defaultdict(list)
fns=sys.argv[1:]
first=collections.Counter();second=collections.Counter();ttf=[];cyc_seq=[];cyc_len=[];awake=[]
walk_prev=collections.Counter();walk_after=collections.Counter();walk_dirok=[];walk_len=[];walk_trig=collections.Counter()
look_dir=[];look_n=0;crash=collections.Counter();crash_src=collections.Counter();pick_dec=collections.Counter();why=collections.Counter()
lead_sleep=[];eye_lead=[];tot_h=0;home_first=0;nsleep=0
for fn in fns:
    d=load(fn);E=d['E'];S=d['S'];tot_h+=(S[-1][0]-S[0][0])/3600
    # 每一輪：醒來到下次睡
    wk=[i for i,e in enumerate(E) if e['k']=='sleepOff'];so=[e['t'] for e in E if e['k']=='sleepOn']
    for i in wk:
        tw=E[i]['t'];nx=[x for x in so if x>tw]
        if not nx: continue
        awake.append(nx[0]-tw)
        seq=[e for e in E if tw<e['t']<=nx[0] and e['k']=='pick']
        s=[e['w'] for e in seq];cyc_seq.append(tuple(s))
        if s: first[s[0]]+=1;ttf.append(seq[0]['t']-tw)
        if len(s)>1: second[s[1]]+=1
    for e in E:
        if e['k']=='pick': pick_dec[e['w']]+=1
    # 睡前：決定睡的那一刻到睡著，有沒有先走回家
    for i,e in enumerate(E):
        if e['k']=='sleepOn':
            nsleep+=1
            pre=[x for x in E if x['k']=='pre' and 0<e['t']-x['t']<4]
            if pre: lead_sleep.append(e['t']-pre[-1]['t'])
    # 走路
    for i,e in enumerate(E):
        if e['k']=='gaitTo' or e['k']=='route':
            # 觸發：上一個 life/pick 事件
            pk=[x for x in E[max(0,i-6):i] if x['k']=='pick' and e['t']-x['t']<.05]
            lk=[x for x in E[max(0,i-12):i] if x['k']=='sniff' and e['t']-x['t']<6]
            kind='route(回家)' if e['k']=='route' else 'walk'
            if kind=='walk':
                walk_trig['探完才走' if not pk else '休息直接走']+=1
                if lk and not pk:
                    walk_dirok.append((math.cos(lk[-1]['a'])>0)==(e['x']>e['from']))
                walk_len.append(abs(e['x']-e['from'])*MM)
            else: walk_trig[kind]+=1
        if e['k']=='sniff': look_dir.append(e['a'])
        if e['k']=='drCrash':
            # 走路中或身體動造成
            near=[x for x in S if abs(x[0]-e['t'])<=.6];kk=near[0][1] if near else '?'
            crash[(e['im'],'被嚇' if e['scared'] else '沒反應')]+=1;crash_src[kk]+=1
    # 到了之後做什麼
    seq=[r[1] for r in S]
    for a,b in zip(seq,seq[1:]):
        if a=='walk' and b!='walk': walk_after[b]+=1
n=len(cyc_seq)
print('檔',len(fns),'總時數',round(tot_h,2))
print('醒著的長度 平均',round(np.mean(awake),1),'秒 標準差',round(np.std(awake),1),'CV',round(np.std(awake)/np.mean(awake),2),'最短最長',round(min(awake),1),round(max(awake),1),'n',n)
print('醒來後第一個決定',dict(first),'延遲平均',round(np.mean(ttf),2),'秒, sd',round(np.std(ttf),2))
print('第二個決定',dict(second))
uc=collections.Counter(cyc_seq);print('每輪決定序列種類',len(uc),'/',n,' 前五:',[(','.join(k),v) for k,v in uc.most_common(6)])
print('全部決定',dict(pick_dec))
print('睡前有前兆的次數',len(lead_sleep),'/',nsleep,'前兆長度 平均',round(np.mean(lead_sleep),3),'sd',round(np.std(lead_sleep),3))
print('走路起因',dict(walk_trig),'；探完才走時方向對得上',(sum(walk_dirok),len(walk_dirok)))
print('走路長度 mm 平均',round(np.mean(walk_len),1),'sd',round(np.std(walk_len),1))
print('走完接著',dict(walk_after))
h=np.histogram(np.mod(np.array(look_dir),2*math.pi),bins=8,range=(0,2*math.pi))[0];print('探的方向八等分',list(map(int,h)),'每小時',round(len(look_dir)/tot_h,1))
print('東西倒',{str(k):v for k,v in crash.items()},'每小時',round(sum(crash.values())/tot_h,1),'當時在',dict(crash_src))
