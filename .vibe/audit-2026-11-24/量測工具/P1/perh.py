import json,sys,collections
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
def cnt(E):
    c=collections.Counter();last={}
    for e in E:
        k=e['k']
        if k=='sniff': c['伸偽足探']+=1
        elif k=='gaitTo': c['走一段']+=1
        elif k=='route': c['走回家']+=1
        elif k=='blink': c['眨眼']+=1
        elif k=='sac': c['瞄你（看正前方）' if e['you'] else '瞄別處']+=1
        elif k=='sigh': c['大口嘆氣']+=1
        elif k=='pre' and e['p']=='sleep': c['瞇眼想睡']+=1
        elif k=='sleepOn': c['睡著']+=1
        elif k=='wake' and e['self']: c['自己醒']+=1
        elif k=='e4' and e['ph']=='wave': c['來找你揮手']+=1
        elif k=='cat': c['走去推東西']+=1
        elif k=='flinch': c['嚇一縮']+=1
        elif k=='snd' and e['s']=='fx.snore': c['聲：鼾']+=1
        elif k=='snd' and e['s'] in('fx.cloth','fx.crawl'): c['聲：走路']+=1
        elif k=='snd' and e['s']=='fx.sigh': c['聲：嘆氣']+=1
        elif k=='snd' and e['s'].startswith('voice'): c['聲：牠出聲（'+e['s'][6:]+'）']+=1
        elif k=='snd' and (e['s'].startswith('knock') or e['s'] in('fx.topple','fx.fallout')): c['聲：東西倒、碰、掉']+=1
        elif k=='drCrash':
            if e['t']-last.get(e['im'],-99)>=4: c['撞倒東西']+=1
            last[e['im']]=e['t']
        elif k=='drLook': c['看有聲音的地方']+=1
    return c
G=[('網頁 熟0',['idle-taro-tr0-s%d'%i for i in(1,2,3)]),('網頁 熟1',['idle-taro-tr1-s%d'%i for i in(1,2,3)]),('手機邏輯 熟0',['idle-phone-tr0-s1','idle-phone-tr0-s2']),('手機邏輯 熟1',['idle-phone-tr1-s1'])]
R={}
for n,fs in G:
    t=collections.Counter()
    for f in fs: t.update(cnt(json.load(open(f'../data/{f}.json',encoding='utf-8'))['E']))
    R[n]={k:v/(len(fs)*.5) for k,v in t.items()}
ks=sorted(set(k for r in R.values() for k in r),key=lambda k:-R['網頁 熟0'].get(k,0))
print('| 每小時次數 |',' | '.join(n for n,_ in G),'|')
for k in ks: print('|',k,'|',' | '.join('%.0f'%R[n].get(k,0) if R[n].get(k,0)>=1 or R[n].get(k,0)==0 else '%.1f'%R[n][k] for n,_ in G),'|')
