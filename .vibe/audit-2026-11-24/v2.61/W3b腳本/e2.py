W='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web/index.html'
s=open(W,encoding='utf-8',newline='').read()
def rep(a,b,n=1):
    global s
    assert s.count(a)==n,(s.count(a),a[:60]);s=s.replace(a,b)
rep("selfWake:0,zAt:.5,jA:1,jS:1,slp:false};","selfWake:0,zAt:.5,jA:1,jS:1,slp:false,ojT:-9};")
rep("homeAt:t,zAt:.5,jA:1,jS:1,slp:false})}","homeAt:t,zAt:.5,jA:1,jS:1,slp:false,ojT:-9})}")
rep("function brainPick(canGo){const B=BRAIN,n=()=>(brnd()-.5)*.16,","function brainPick(canGo){const B=BRAIN,na=mat.greetLook>=.5&&t<B.ojT?OPENJ.n:.16,n=()=>(brnd()-.5)*na,")
rep("B.z=.15+.3*r();B.q=.05+.65*r();B.e=.05+.65*r();B.s=.4*r()*IMP.tr}   // 打開（換隻、離開十分鐘回來）時四個需求的起點加亂數：開頭三件事不再每次一樣","B.z=.15+.3*r();B.q=.05+.65*r();B.e=.15+.7*r();B.s=.4*r()*IMP.tr;B.ojT=t+OPENJ.s}   // 打開（換隻、離開十分鐘回來）時四個需求的起點加亂數，剛打開 OPENJ.s 秒挑事情時每一項多加一點亂數（平常 0.16）：開頭三件事不再每次一樣。只加起點不夠：好奇漲得快、想動漲得慢，第二件以後照樣都是探\r\nconst OPENJ={s:40,n:.8};")
open(W,'w',encoding='utf-8',newline='').write(s)
