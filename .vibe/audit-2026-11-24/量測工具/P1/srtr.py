import json,sys
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
for f in ('sr-tr0','sr-tr6','sr-w6'):
    d=json.load(open(f'../data/{f}.json',encoding='utf-8'));c=d['job']['ctx'];print(f,c)
    for s,L in d['res'].items():
        print('  %-9s 熟 %.2f→%.2f  戒 %.2f→%.2f  心情 %.2f→%.2f'%(s,c['tr'],np.mean([r['tr'] for r in L]),c['w'],np.mean([r['w'] for r in L]),c['m'],np.mean([r['m'] for r in L])))
