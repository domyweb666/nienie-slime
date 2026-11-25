import json,sys,collections
sys.stdout.reconfigure(encoding='utf-8')
R=[]
for f in ['out/e2_taro.json','out/e2_v260.json','out/e2_oth.json']:
    for r in json.load(open(f,encoding='utf-8')): r['cf']=('v260' if 'v260' in f else r['cf']);R.append(r)
nm={2:'芋圓',1:'薄荷',5:'湯圓',7:'汽水'};av=lambda a:sum(a)/len(a)
def q(sl,cf,g,d,v): return [r for r in R if r['sl']==sl and r['cf']==cf and r['g']==g and r['d']==d and r['v']==v]
for sl in (2,1,5,7):
    print('==',nm[sl],'欄：3R快頭/3R慢1.5/3R 4R/s 各「停住高→放2秒記」｜4R 1.5、4、15R/s 停2秒高｜5R 25R/s(抓頂實4.69、抓中間實5)：1秒高、再1→3秒長')
    for cf in ('v260','def','A3','A4','A5','all','def_r0','A5_r0','all_r0'):
        o=[]
        for g,v in (('head',18),('tip',1.5),('tip',4)):
            a=q(sl,cf,g,3,v)
            if a:o.append(f"{av([r['s'][-1] for r in a]):.2f}→{av([r['q2'] for r in a]):.2f}(低{min(r['q2'] for r in a):.2f})")
        if not o: continue
        p=[]
        for v in (1.5,4,15):
            a=q(sl,cf,'tip',4,v);p.append(f"{av([r['s'][-1] for r in a]):.2f}/記{av([r['q2'] for r in a]):.2f}")
        s=[]
        for g in('tip','cen'):
            a=q(sl,cf,g,5,25);s.append(f"{av([r['s'][0] for r in a]):.2f}+{av([r['s'][-1]-r['s'][0] for r in a]):.2f}/記{av([r['q2'] for r in a]):.2f}")
        print(f"{cf:<7}",' '.join(o),'|',' '.join(p),'|',' '.join(s))
