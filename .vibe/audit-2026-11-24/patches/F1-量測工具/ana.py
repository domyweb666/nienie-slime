# ana.py out.json [--by grab|dir|dist|sp|k] 彙整
import sys,json,glob,collections,statistics as st
sys.stdout.reconfigure(encoding='utf-8')
A='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/'
def load(p):
    R=[]
    if p.endswith('.json'): R=json.load(open(p,encoding='utf-8'))
    else:
        for f in glob.glob(p+'.*.jsonl'):
            for l in open(f,encoding='utf-8'):
                try:R.append(json.loads(l))
                except: pass
    return [r for r in R if not r.get('err') and not (r.get('info') or {}).get('skip')],[r for r in R if r.get('err')],[r for r in R if (r.get('info') or {}).get('skip')]
PH=('pull','hold','rel')
def g(r,ph,k,d=0): return (r['ph'].get(ph) or {}).get(k,d)
def tot(r,k): return sum(g(r,p,k) for p in r['ph'])
def mx(r,k): return max(g(r,p,k) for p in r['ph'])
def mn(r,k,d=1e9): return min((r['ph'][p].get(k,d) for p in r['ph']),default=d)
def flags(r):
    f={}
    f['split']=tot(r,'cFr'); f['hole']=tot(r,'hFr'); f['pop']=tot(r,'popN')
    f['xFr']=tot(r,'xFr'); f['flFr']=tot(r,'flFr'); f['shFr']=tot(r,'shFr'); f['nkFr']=tot(r,'neckFr')
    f['nan']=tot(r,'nan'); f['eye']=tot(r,'eyeFr'); f['er']=tot(r,'erFr')
    return f
def row(name,rs):
    n=len(rs)
    if not n: return
    F=[flags(r) for r in rs]
    brk=sum(1 for f in F if f['split'] or f['hole'] or f['pop'])
    def pc(k): return sum(1 for f in F if f[k])
    H=[g(r,'hold','jSum')/max(1,g(r,'hold','jN')) for r in rs if g(r,'hold','jN')]
    HM=[g(r,'hold','jMax') for r in rs if g(r,'hold','jN')]
    S=[r['rel']['settle'] for r in rs]
    J=[r['rel']['j34'] for r in rs]
    L=[g(r,'pull','lagMax') for r in rs]; LE=[g(r,'hold','lagEnd') for r in rs if 'hold' in r['ph']]
    GE=[g(r,'hold','gapEnd') for r in rs if 'hold' in r['ph']]
    ms=sum(tot(r,'msSum') for r in rs)/max(1,sum(tot(r,'fr') for r in rs)); msx=max(mx(r,'msMax') for r in rs)
    av=lambda a: sum(a)/len(a) if a else 0
    print(f"{name:<26} n{n:4d} 看得到破 {brk:3d} (裂{pc('split')} 洞{pc('hole')} 突變{pc('pop')}) 自交{pc('xFr')} 翻面{pc('flFr')} 尖角{pc('shFr')} 細脖{pc('nkFr')} 吃掉{pc('er')} 眼外{pc('eye')} NaN{pc('nan')} | 按住跳 均{av(H):.2f} 最大{max(HM) if HM else 0:.1f} | 放手抖 均{av(S):.2f}s 滿4s:{sum(1 for s in S if s>=3.9)} 末秒{av(J):.2f} | 落後拉{av(L):.2f}/{max(L) if L else 0:.2f} 按住{av(LE):.2f}/{max(LE) if LE else 0:.2f} 可見{av(GE):.2f}/{max(GE) if GE else 0:.2f} | ms {ms:.1f}/{msx:.0f}")
if __name__=='__main__':
    R,E,SK=load(sys.argv[1]);print('有效',len(R),'錯',len(E),'跳過',len(SK))
    row('全部',R)
    for key in (sys.argv[2].split(',') if len(sys.argv)>2 else ['sp','grab','dir','dist']):
        print('--',key)
        vs=sorted({str(r['c'].get(key)) for r in R})
        for v in vs: row(v,[r for r in R if str(r['c'].get(key))==v])
