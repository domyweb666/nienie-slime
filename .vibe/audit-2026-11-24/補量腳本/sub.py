from an import *
G={x:get('mix_'+x)[0] for x in 'abcde'}
for x in 'abcde': print(x,end=' ')
print()
keys=sorted({(q['c']['k'],q['c'].get('grab') or '') for q in G['a'].values()})
for k in keys:
    ids=[i for i,q in G['a'].items() if (q['c']['k'],q['c'].get('grab') or '')==k and all(i in G[x] for x in G)]
    print(k,len(ids),'破',[sum(G[x][i]['brk'] for i in ids) for x in 'abcde'],'按住末',['%.2f'%av([G[x][i]['Lhold'] for i in ids]) for x in 'abcde'],'最長',['%.2f'%av([G[x][i]['Lmax'] for i in ids]) for x in 'abcde'],'4秒',['%.2f'%av([G[x][i]['Lrel'] for i in ids]) for x in 'abcde'],'落後按住',['%.2f'%av([G[x][i]['lagH'] for i in ids]) for x in 'abcde'])
for nm,f in(('同側拉3R以上或到邊',lambda c:c['k']=='pull' and c.get('grab') in('near','regrab') and c['dist'] in(3,4.5,6,'edge')),('中間3R以上',lambda c:c['k']=='pull' and c.get('grab')=='center' and c['dist'] in(3,4.5,6,'edge')),('對側3R以上',lambda c:c['k']=='pull' and c.get('grab')=='far' and c['dist'] in(3,4.5,6,'edge')),('短拉1.5R以下',lambda c:c['k']=='pull' and c['dist'] not in(3,4.5,6,'edge'))):
    ids=[i for i,q in G['a'].items() if f(q['c']) and all(i in G[x] for x in G)]
    print(nm,len(ids),'破',[sum(G[x][i]['brk'] for i in ids) for x in 'abcde'],*[(kk,['%.2f'%av([G[x][i][kk] for i in ids]) for x in 'abcde']) for kk in('Lhold','Lmax','Lrel','lagH')])
