import json,sys
O=[x for x in json.load(open(sys.argv[1],encoding='utf-8')) if x.get('test')=='T65']
for a in sorted({x['arm'] for x in O}):
    r=[x['val'] for x in O if x['arm']==a]
    f=lambda k,q:'%.2f/%.2f'%(sum(v[k][q] for v in r)/len(r),(max if q in('gap','flips') else min)(v[k][q] for v in r))
    ok=sum(v['up']['gap']<.5 and v['up']['held']>=5 and v['up']['flips']<=60 and v['up']['xs']==0 and v['up']['after']>=3.5 and v['diag']['held']>=5 and v['diag']['xs']==0 and v['diag']['after']>=3.5 and v['up']['endX']==0 and v['diag']['endX']==0 for v in r)
    print('arm',a,'pass %d/%d'%(ok,len(r)),'up gap',f('up','gap'),'held',f('up','held'),'after',f('up','after'),'fl',f('up','flips'),'| diag gap',f('diag','gap'),'held',f('diag','held'),'after',f('diag','after'),'fl',f('diag','flips'),'xs',sum(v['up']['xs']+v['diag']['xs'] for v in r),'endX',sum(v['up']['endX']+v['diag']['endX'] for v in r))
