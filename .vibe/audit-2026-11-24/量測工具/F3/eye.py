import sys,os
sys.stdout.reconfigure(encoding='utf-8')
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE)
from vis import evaljs
r=evaljs(open(os.path.join(HERE,'eye.js'),encoding='utf-8').read(),{},port=8977)
for x in r:
    rows=x['rows']; z=next((q[0] for q in rows if q[2]>=0),None); f=next((q[0] for q in rows if q[1]>=196),None)
    print('lag',x['lag'],'手指越過中線 %s ms，視線越過中線 %s ms，差 %s ms；模式 %s；手指到終點 %d ms；視線到 0.9×終值 %s ms'%(f,z,None if z is None or f is None else z-f,rows[0][3],x['reach'],next((q[0] for q in rows if q[2]>=.9*rows[-1][2]),None)), '起點視線 %.2f 終點 %.2f'%(rows[0][2],rows[-1][2]))
