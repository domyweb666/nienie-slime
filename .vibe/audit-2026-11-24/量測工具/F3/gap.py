# 靜默空窗：照 Swift 的公式（SlimeRig 的 tick/grain/pull 事件、SlimeController 的連續震動、SlimeAudio 的 loop 音量）套網頁物理的軌跡
import sys,os,json,math,random
sys.stdout.reconfigure(encoding='utf-8')
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE)
from vis import evaljs
js=open(os.path.join(HERE,'gap.js'),encoding='utf-8').read()
DT=1/120
S=[]
for v in (0,): S.append(dict(name='長按不動',n=int(6/DT),wait=10**9,v=0,ox=0))
for v in (30,60,120,240,400): S.append(dict(name='揉圈 %d'%v,n=int(6/DT),wait=24,v=v,circle=24))
for v in (20,40,80,160,300,600): S.append(dict(name='邊緣往上拉 %d'%v,n=int(min(6,320/v+1.5)/DT),wait=24,v=v,dir=[0,-1],edge=1,stop=320))
r=evaljs(js,dict(jobs=S,over=dict(life2=0,emo=0,life=0,wriggle=0,morph=0,pods=0,jelly=0,drift=0,wander=0,brain=0)))
def drive(x,seed=1):
    rnd=random.Random(seed); R=x['R']; rows=x['rows']
    ev=[(0,'震','按下 0.50'),(0,'聲','按下')]; speedC=0;travel=0;tickAt=0;tickNext=0;tickLast=-9;gi=0;far=False;step=0;cont=False;contOn=[];lastx,lasty=rows[0][1],rows[0][2]; stv=0;st0=0
    ax,ay=rows[0][1],rows[0][2]; GT=[.06,.13,.21,.30];GG=[.8,.6,.42,.28]; vs=0
    aud=[]; contStart=None
    for (t,ex,ey,mode,st,cg,raw,rs,_) in rows:
        d=math.hypot(ex-lastx,ey-lasty); lastx,lasty=ex,ey; kv=1-math.exp(-DT/.03)
        travel+=d; speedC+=(d/DT-speedC)*kv
        if math.hypot(ex-ax,ey-ay)>0.15*R: far=True
        pullK=min(1,st/2);tense=1-.6*pullK
        if tickNext<=0: tickNext=12*tense; tickAt=travel
        if travel-tickAt>=tickNext and speedC>R*.1 and t-tickLast>=1/20:
            tickAt=travel; tickNext=12*tense*(.7+.6*rnd.random()); tickLast=t; g=min(1,max(speedC/(R*3),.5*pullK)); ev.append((t,'震','顆粒 %.2f'%(.15+.2*g)))
        if not far and gi<4 and t-tickLast>=1/20 and t>=GT[gi]:
            ev.append((t,'震','沉 %.2f'%(.08+.22*GG[gi]))); gi+=1; tickLast=t
        s=int(math.floor(st*2.5))
        if s>step and st>.35: ev.append((t,'聲','拉絲一根'))
        step=max(step,s)
        sx=max(0,st-.3); tn=min(1,.8*(1-math.exp(-sx/4.5))+.45*min(1,cg/.8)*(.4+.6*rs)); tnr=min(1,.8*(1-math.exp(-sx/4.5))+.45*min(1,raw/.8)*(.4+.6*rs))
        lv=.55*(.18+.82*tn) if tn>.02 else 0
        if lv>=.03 and not cont: cont=True; ev.append((t,'震','連續開 %.2f'%lv)); contStart=t
        if lv<.008 and cont and t-contStart>.12: cont=False; ev.append((t,'震','連續關'))
        vr=abs(st-st0)/DT; st0=st; stv+=(vr-stv)*(1-math.exp(-DT/.06))
        pg=.6*min(1,max(0,(.12+.18*(1-math.exp(-max(0,st-.6)/4)))*min(1,max(0,(st-.2)/.4))+.88*min(1,stv/2.5))) if st>.2 else 0
        duck=min(1,max(0,1-(st-.3)/.7)); rub=min(1,speedC/R/5)*.7*duck
        rate=((2+16*(1-math.exp(-st/4)))*(.25+.75*min(1,stv/2.5))) if st>.4 else 0
        if rnd.random()<rate*DT: ev.append((t,'聲','細絲'))
        aud.append((t,rub,pg,tn,tnr,lv))
    return ev,aud
def gaps(times,end):
    ts=sorted(times)+[end]; g=max((b-a,a,b) for a,b in zip(ts,ts[1:])) if len(ts)>1 else (end,0,end); return g
for x in r:
    ev,aud=drive(x); end=aud[-1][0]
    hv=[e[0] for e in ev if e[1]=='震']; au=[e[0] for e in ev if e[1]=='聲']
    # 連續震動開著的時段不算空窗
    contT=[a[0] for a in aud if a[5]>0]; hv2=sorted(hv+contT); gh=gaps(hv2,end); ga=gaps(au,end)
    first_c=contT[0] if contT else None; mx=max(a[1] for a in aud); mp=max(a[2] for a in aud)
    firstraw=next((a[0] for a in aud if a[4]>.02),None)
    strands=[e[0] for e in ev if e[2] in('拉絲一根','細絲')]
    ticks=[e[0] for e in ev if e[2].startswith('顆粒')]
    print('%-14s %.1fs | 震動事件 %2d 顆粒 %2d 首顆 %s 最長無震動 %.2fs (%.2f→%.2f) 連續震動始 %s（改用真手指 %s）| 拉絲首根 %s 最長無一次性聲 %.2fs (%.2f→%.2f)| 揉音量最大 %.3f 拉絲音量最大 %.3f'%(x['name'],end,len(hv),len(ticks),'%.2f'%ticks[0] if ticks else '無',gh[0],gh[1],gh[2],'%.2f'%first_c if first_c else '無','%.2f'%firstraw if firstraw else '無','%.2f'%strands[0] if strands else '無',ga[0],ga[1],ga[2],mx,mp))
json.dump(r,open(os.path.join(HERE,'gap.json'),'w'))
