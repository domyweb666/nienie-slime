import json,sys
O=json.load(open(sys.argv[1],encoding='utf-8'));R=[x for x in O if x.get('test')=='R']
for a in sorted({x['arm'] for x in R}):
    r=sorted([x for x in R if x['arm']==a],key=lambda x:-x['j'])
    js=[x['j'] for x in r]
    print('arm',a,'n',len(r),'mean %.2f'%(sum(js)/len(js)),'>.25',sum(j>.25 for j in js),'>.5',sum(j>.5 for j in js),'>1',sum(j>1 for j in js),'max',js[0],'fH8',sum(x['s8']['fH']>0 for x in r),'cQ8',sum(x['s8']['cQ'] for x in r),'rem',sum(x['rm'] for x in r),'len8 %.2f wid8 %.2f'%(sum(x['s8']['len'] for x in r)/len(r),sum(x['s8']['wid'] for x in r)/len(r)))
    if '-v' in sys.argv:
        for x in r:
            if x['j']>.25: print('   sd',x['sd'],x['j'],'rm',x['rm'],'s0',x['s0'],'s8',x['s8'],x['wh'])
