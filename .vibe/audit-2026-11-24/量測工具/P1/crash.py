import json,sys,collections
sys.stdout.reconfigure(encoding='utf-8')
for grp in ('tr0','tr1'):
    tot=0;sc=0;H=0;bykind=collections.Counter();ser=[]
    for i in (1,2,3):
        d=json.load(open(f'../data/idle-taro-{grp}-s{i}.json',encoding='utf-8'));E=d['E'];H+=.5;last={}
        seq=[]
        for e in E:
            if e['k']!='drCrash': continue
            if e['t']-last.get(e['im'],-99)<4: 
                last[e['im']]=e['t'];continue
            last[e['im']]=e['t'];tot+=1;sc+=e['scared'];bykind[e['im']]+=1;seq.append('嚇' if e['scared'] else '－')
        ser.append(''.join(seq))
    print(grp,'每小時撞倒',round(tot/H,1),'次，其中有被嚇到',sc,'/',tot,dict(bykind));print('  依序',ser)
