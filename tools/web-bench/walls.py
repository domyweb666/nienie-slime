import json,sys
O=json.load(open(sys.argv[1],encoding='utf-8'))
for a in sorted({x['arm'] for x in O if 'arm' in x}):
    r=[x for x in O if x.get('arm')==a]
    for nm,f in (('wall',lambda x:x['wh']['surf'] in('lwall','rwall')),('rest',lambda x:x['wh']['surf'] not in('lwall','rwall'))):
        q=[x['j'] for x in r if f(x)]
        if q: print(a,nm,'n',len(q),'mean %.2f'%(sum(q)/len(q)),'>1',sum(j>1 for j in q),'>5',sum(j>5 for j in q))
