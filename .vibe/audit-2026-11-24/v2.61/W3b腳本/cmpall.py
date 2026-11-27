import json,sys
sys.stdout.reconfigure(encoding='utf-8')
rs=[json.load(open(f,encoding='utf-8')) for f in sys.argv[1:]]
def flat(v,p=''):
    if isinstance(v,dict):
        for k in v: yield from flat(v[k],p+'.'+k)
    elif isinstance(v,list):
        for i,x in enumerate(v): yield from flat(x,p+'.%d'%i)
    else: yield p,v
for k in rs[0]:
    ds=[dict(flat(r.get(k))) for r in rs]
    df=[q for q in ds[0] if any(d.get(q)!=ds[0][q] for d in ds)]
    print(k,len(df),'/',len(ds[0]),[(q,[d.get(q) for d in ds]) for q in df[:3]] if df else '')
