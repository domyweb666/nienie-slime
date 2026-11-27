import sys,re
sys.path.insert(0,r"C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/p4/scripts")
sys.stdout.reconfigure(encoding='utf-8')
from reviews import load,CATS
apps=[a.split(':',1) for a in sys.argv[1].split(',')]
cats=sys.argv[2].split(',');maxstar=int(sys.argv[3]);k=int(sys.argv[4])
for app,name in apps:
    R=load(app)
    for c in cats:
        rx=re.compile(CATS[c],re.I);n=0
        print('##',name,c)
        for r in R:
            m=rx.search(r[2])
            if m and r[0]<=maxstar:
                s=max(0,m.start()-110);print('  ',r[0],'|',r[2][s:m.end()+130].replace('\n',' '));n+=1
                if n>=k:break
