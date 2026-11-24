import json,glob,sys
sys.stdout.reconfigure(encoding='utf-8')
for g in sys.argv[1:]:
    fs=sorted(glob.glob(g));iv=[];a={};tot=dict(fallSelf=0,fallCat=0,topple=0,fallout=0,startle=0,voice=0,knock=0,total=0);pct=[];H=0
    for f in fs:
        r=json.load(open(f,encoding='utf-8'));iv+=r['ivs'];H+=r['MIN']/60;pct.append(r['睡pct'])
        for k,v in r['第一動作'].items():a[k]=a.get(k,0)+v
        for k in tot: tot[k]+=r[k]
    m=sum(iv)/len(iv);sd=(sum((x-m)**2 for x in iv)/len(iv))**.5
    print(g,len(fs),'間隔 %.0f±%.0f n%d 最短%d 最長%d'%(m,sd,len(iv),min(iv),max(iv)),a,'睡%',pct,{k:round(v/H/2,1) for k,v in tot.items()},'(每30分)')
