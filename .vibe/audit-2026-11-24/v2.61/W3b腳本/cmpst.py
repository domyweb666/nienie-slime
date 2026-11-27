import json,sys
sys.stdout.reconfigure(encoding='utf-8')
keys=sys.argv[1].split(',');fs=sys.argv[2:]
rs=[json.load(open(f,encoding='utf-8')) for f in fs]
def flat(v,p=''):
    if isinstance(v,dict):
        for k in v: yield from flat(v[k],p+'.'+k)
    elif isinstance(v,list):
        for i,x in enumerate(v): yield from flat(x,p+'.%d'%i)
    else: yield p,v
for k in keys:
    ds=[dict(flat(r.get(k))) for r in rs]
    print('##',k)
    for q in ds[0]:
        vs=[d.get(q) for d in ds]
        if any(v!=vs[0] for v in vs): print('  ',q,vs)
