import sys,json
sys.stdout.reconfigure(encoding='utf-8')
import numpy as np
for f in sys.argv[1:]:
    O=json.load(open(f));by={}
    for o in O:
        for r in o['rows']:
            for m in ('m0','m3','m6'):
                if m in r and r[m].get('dxor') is not None:
                    by.setdefault(r['ph'],{}).setdefault(m,[]).append(r[m]['dxor']/max(1,r[m]['df'])/max(1,r['m0']['per']))
            if 'm6' in r: by.setdefault(r['ph'],{}).setdefault('lost6',[]).append(100*r['m6']['lost']/r['m6']['Ar']);by[r['ph']].setdefault('lost3',[]).append(100*r['m3']['lost']/r['m3']['Ar'])
    print(f,'每幀外框平均位移（像素）中位／p90／p99；m3＝沒平滑，m6＝1€ 平滑')
    for ph,d in by.items():
        print('  %-6s n%4d'%(ph,len(d['m3'])),' m3 %.2f／%.2f／%.2f'%(np.median(d['m3']),np.percentile(d['m3'],90),np.percentile(d['m3'],99)),' m6 %.2f／%.2f／%.2f'%(np.median(d['m6']),np.percentile(d['m6'],90),np.percentile(d['m6'],99)),' 落後（吃掉面積%%）m3 %.2f m6 %.2f p99 %.2f'%(np.mean(d['lost3']),np.mean(d['lost6']),np.percentile(d['lost6'],99)))
