import sys
sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/tool')
from ana2 import load,rec,A,line,av
grp=[('center',lambda c:c['k']=='pull' and c['grab']=='center'),('far',lambda c:c['k']=='pull' and c['grab']=='far'),('near/regrab',lambda c:c['k']=='pull' and c['grab'] in('near','regrab')),('opp',lambda c:c['k']=='opp'),('three',lambda c:c['k']=='three'),('rot',lambda c:c['k']=='rot')]
def summ(nm):
    R,E,S=load(A+'abl_'+nm)
    print('==',nm,len(R))
    for gn,f in grp+[('全部',lambda c:True)]:
        Q=[rec(r) for r in R if f(r['c'])];n=len(Q)
        if not n: continue
        c=lambda k:sum(1 for q in Q if q[k])
        print(f"  {gn:<12}n{n:3d} 破{c('brk'):3d} 裂{c('split'):3d} 洞{c('hole'):3d} 變{c('pop'):3d} 自交格{sum(q['xFr'] for q in Q):5d} 翻面均{av([q['fl'] for q in Q]):4.0f} 尖角格{sum(q['sh'] for q in Q):5d} 細脖{c('nkFr'):3d} 按住跳{av([q['jh'] for q in Q]):5.2f} 長{av([q['grow'] for q in Q]):5.2f} 放手抖{av([q['set'] for q in Q]):4.2f}s 末秒{av([q['j34'] for q in Q]):4.2f} 甩{av([q['vmax'] for q in Q]):4.0f} 出畫面{c('offFr'):3d} 落後拉{av([q['lagP'] for q in Q]):4.2f} 按住{av([q['lagH'] for q in Q]):4.2f} 可見{av([q['gapH'] for q in Q]):4.2f} ms{av([q['ms'] for q in Q]):.1f}")
for nm in sys.argv[1:]: summ(nm)
