import io, sys
sys.stdout.reconfigure(encoding='utf-8')
p='P2.md'; s=io.open(p,encoding='utf-8').read()
def rep(a,b):
    global s
    if s.count(a)!=1: print('COUNT',s.count(a),a[:50]); return
    s=s.replace(a,b)
rep("熟的速度（芋圓 trRate 0.7，其他隻更快）：","熟的速度（芋圓 trRate 0.7；仙草、蝶豆 0.5 比較慢，其他七隻 1.0 到 1.6 更快）：")
rep("| 往上拉多遠 | 現在，陌生：逃／戒／心情 | 現在，很熟 0.9：逃／戒／心情／熟 | v2.53（slide 1.5、沒有無限拉），陌生 |","| 往上拉多遠 | 現在，陌生：逃／戒／心情 | 現在，很熟 0.9：逃／戒／心情／熟 | 同一份程式把 slide 設 1.5、無限拉關（v2.53 的設定），陌生 |")
io.open(p,'w',encoding='utf-8',newline='\n').write(s)
q='P2/findings.py'; t=io.open(q,encoding='utf-8').read()
t=t.replace("按著不動7.7秒，別隻更快（2202、2097）。","按著不動7.7秒；仙草、蝶豆慢些，其他更快（2202、2097）。")
io.open(q,'w',encoding='utf-8',newline='\n').write(t)
