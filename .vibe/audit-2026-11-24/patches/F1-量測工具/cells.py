import json,random,sys
A='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/'
DN={'U':'往上','D':'往下','L':'往左','R':'往右','UR':'右上','UL':'左上','DR':'右下'};GN={'center':'抓中間','near':'抓同側邊','far':'抓對側邊','regrab':'再抓那條'}
def pulls(dirs,dists,sps,grabs,reps,pre=''):
    o=[]
    for d in dirs:
        for s in sps:
            for g in grabs:
                for ds in dists:
                    xs=['c'] if d in('U','D') or (ds not in('edge',) and ds<3) else (['o'] if ds!='edge' else ['c','o'])
                    for x in xs:
                        for r in range(reps):
                            far='拉到螢幕邊' if ds=='edge' else ('拉%sR'%ds)
                            o.append(dict(k='pull',dir=d,dist=ds,sp=s,grab=g,x0=x,rep=r,seed=101+37*r,id=f'{pre}P_{d}_{ds}_{s}_{g}_{x}_{r}',label=GN[g]+DN[d]+far+('快扯' if s=='fast' else '慢拉')+('(從對面)' if x=='o' else '')))
    return o
def others(reps,pre=''):
    o=[]
    for r in range(reps):
        sd=201+41*r
        for ang in (0,90,45,135):
            for ds in (1.5,3,'edge'):
                for s in('slow','fast'):
                    for fr in('mid','edge'):
                        far='拉到邊' if ds=='edge' else '各%sR'%ds
                        o.append({'k':'opp','ang':ang,'dist':ds,'sp':s,'from':fr,'rep':r,'seed':sd,'id':f'{pre}O_{ang}_{ds}_{s}_{fr}_{r}','label':f"兩指往反方向{ang}度{far}"+('快' if s=='fast' else '慢')+('(邊緣起)' if fr=='edge' else '(中間起)')})
        for nf in(2,3):
            for gr in(0,1):
                for sg in(1,-1):
                    for s in('slow','fast'): o.append(dict(k='rot',nf=nf,grow=gr,sg=sg,turns=1.5,sp=s,rep=r,seed=sd,id=f'{pre}R_{nf}_{gr}_{sg}_{s}_{r}',label=('兩' if nf==2 else '三')+'指旋轉1.5圈'+('邊轉邊拉開' if gr else '')+('快' if s=='fast' else '慢')))
        for ang in(0,90,45):
            for s in('slow','fast'): o.append(dict(k='pinch',ang=ang,sp=s,rep=r,seed=sd,id=f'{pre}K_{ang}_{s}_{r}',label=f"兩指{ang}度往裡捏"+('快' if s=='fast' else '慢')))
        for ds in(1,2,3):
            for s in('slow','fast'): o.append(dict(k='three',dist=ds,sp=s,rep=r,seed=sd,id=f'{pre}T_{ds}_{s}_{r}',label=f"三指各拉開{ds}R"+('快' if s=='fast' else '慢')))
        for ang in(0,90,45):
            for amp in(.8,1.6):
                for hz in(2,4): o.append(dict(k='scrub',ang=ang,amp=amp,hz=hz,rep=r,seed=sd,id=f'{pre}S_{ang}_{amp}_{hz}_{r}',label=f"來回刷{ang}度±{amp}R每秒{hz}次"))
        for rad in(.5,1,1.6):
            for rps in(1,2.5):
                for fr in('mid','edge'): o.append({'k':'stir','rad':rad,'rps':rps,'from':fr,'sg':1 if r%2==0 else -1,'rep':r,'seed':sd,'id':f'{pre}C_{rad}_{rps}_{fr}_{r}','label':f"繞圈攪5秒半徑{rad}R每秒{rps}圈"+('(邊緣起)' if fr=='edge' else '(中間起)')})
        for d in('U','L','R','UR','UL'):
            for g in('center','near'):
                for x in(['c'] if d=='U' else ['c','o']): o.append(dict(k='fling',dir=d,grab=g,dist=2.5,x0=x,rep=r,seed=sd,id=f'{pre}F_{d}_{g}_{x}_{r}',label=GN[g]+DN[d]+'甩出去'+('(從對面)' if x=='o' else '')))
        for d in('R','L','U','D'):
            for s in('slow','fast'):
                for g in('center','edge'): o.append(dict(k='wall',dir=d,sp=s,grab=g,rep=r,seed=sd,id=f'{pre}W_{d}_{s}_{g}_{r}',label='拉著撞'+dict(R='右牆',L='左牆',U='上緣',D='窗台')[d]+'再貼著滑'+('快' if s=='fast' else '慢')+('(抓中間)' if g=='center' else '(抓邊)')))
        for md in('same','rand'):
            for s in('slow','fast'):
                for ds in(1.5,3): o.append(dict(k='yoyo',mode=md,sp=s,dist=ds,rep=r,seed=sd,id=f'{pre}Y_{md}_{s}_{ds}_{r}',label=f"連續拉放6次{ds}R"+('快' if s=='fast' else '慢')+('(同方向)' if md=='same' else '(亂方向)')))
    return o
def fuzz(n,pre='',s0=1000): return [dict(k='fuzz',seed=s0+i,rep=i,id=f'{pre}Z_{s0+i}',label=f'亂捏第{i+1}組') for i in range(n)]
if __name__=='__main__':
    al=pulls(['U','D','L','R','UR','UL','DR'],[1.5,3,4.5,6,'edge'],['slow','fast'],['center','near','far','regrab'],3)
    ot=others(3);fz=fuzz(30)
    random.seed(5)
    for n,c in(('taro_pull',al),('taro_other',ot),('taro_fuzz',fz)):
        random.shuffle(c);json.dump(c,open(A+f'cells_{n}.json','w',encoding='utf-8'),ensure_ascii=False);print(n,len(c))
