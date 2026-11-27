# anasr.py：刺激反應分析：機率、延遲、組合
import sys, json, collections, math
import numpy as np
sys.stdout.reconfigure(encoding='utf-8')
def q(v): v=[x for x in v if x is not None]; return '%.2f'%float(np.median(v)) if v else '—'
KEYS=[('眼睛移',lambda r:r['lEye']),('眼睛開合',lambda r:r['lOpen'])]
EVK=[('縮','flinch'),('出聲','snd:voice'),('探','sniff'),('傾+','lean+'),('傾-','lean-'),('小跳','hop'),('逃','flee'),('走','gaitTo'),('甩','shake'),('節奏','echo:play'),('看你','lookYou'),('搖','wag'),('醒','wake'),('看東西','drLook'),('∩','eye:happy'),('><','eye:squeeze')]
for fn in sys.argv[1:]:
    d=json.load(open(fn,encoding='utf-8'));print('=====',fn.split('/')[-1],d['job']['ctx'],d['job'].get('o',{}))
    for s,L in d['res'].items():
        n=len(L);row=[]
        for nm,f in KEYS:
            v=[f(r) for r in L];row.append('%s %d%%@%s'%(nm,100*sum(x is not None for x in v)/n,q(v)))
        for nm,k in EVK:
            v=[]
            for r in L:
                t=[e[1] for e in r['ev'] if e[0].startswith(k)]
                v.append(t[0] if t else None)
            c=sum(x is not None for x in v)
            if c: row.append('%s %d%%@%s'%(nm,100*c/n,q(v)))
        sig=collections.Counter()
        for r in L:
            st=set()
            for e in r['ev']:
                k=e[0]
                if k in('flinch','hop','flee','shake','wake') or k.startswith('lean') or k.startswith('echo:play') or k.startswith('eye:happy') or k.startswith('eye:squ'): st.add(k)
                if k.startswith('snd:voice'): st.add(k[10:])
            sig[tuple(sorted(st))]+=1
        p=np.array(list(sig.values()))/n;top=sig.most_common(2)
        vo=collections.Counter(e[0][10:] for r in L for e in r['ev'] if e[0].startswith('snd:voice'))
        am=[e[2] for r in L for e in r['ev'] if e[0]=='flinch' and len(e)>2 and e[2]]
        print('%-9s n=%d 組合 %d 種 熵 %.2f 最多 %s ×%d｜%s｜聲 %s%s'%(s,n,len(sig),float(-(p*np.log2(p)).sum()) if len(p)>1 else 0,'+'.join(top[0][0]) or '無',top[0][1],' '.join(row),dict(vo),'｜縮幅 %.1f%%±%.1f'%(100*np.mean(am),100*np.std(am)) if am else ''))
