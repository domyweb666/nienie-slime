import json,sys,collections,glob,os
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
for f in ('own-rough-tr0-s1','own-rough-tr0-s2','own-rough-tr6-s1','own-phone-rough-tr0'):
    d=json.load(open(f'../data/{f}.json',encoding='utf-8'));a=[e for e in d['E'] if e['k']=='act'];by=collections.defaultdict(list);bw=collections.defaultdict(list);bm=collections.defaultdict(list)
    for x,y in zip(a,a[1:]): by[x['kind']].append(y['tr']-x['tr']);bw[x['kind']].append(y['w']-x['w']);bm[x['kind']].append(y['m']-x['m'])
    print(f,{k:('熟 %+.3f'%np.mean(v),'戒 %+.3f'%np.mean(bw[k]),'n=%d'%len(v),'熟變多的比例 %.0f%%'%(100*np.mean(np.array(v)>.005))) for k,v in by.items()})
