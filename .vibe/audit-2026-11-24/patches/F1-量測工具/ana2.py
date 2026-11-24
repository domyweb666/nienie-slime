# 彙整表：每列一類手勢
import sys,json,collections
sys.path.insert(0,'C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/415881cf-6a7b-41c2-85af-00bf46311a7d/scratchpad/audit/F1/tool')
from ana import load,g,tot,mx,mn,A
def P(r,ph): return r['ph'].get(ph) or {}
def rec(r):
    o={}
    o['split']=tot(r,'cFr');o['hole']=tot(r,'hFr');o['pop']=tot(r,'popN');o['brk']=1 if o['split'] or o['hole'] or o['pop'] else 0
    for ph in('pull','hold','rel'):
        q=P(r,ph);o['s_'+ph]=q.get('cFr',0);o['h_'+ph]=q.get('hFr',0);o['p_'+ph]=q.get('popN',0);o['x_'+ph]=q.get('xFr',0)
    h=P(r,'hold');l=P(r,'rel');u=P(r,'pull')
    o['xFr']=tot(r,'xFr');o['xMax']=mx(r,'xMax');o['xRun']=max(q.get('xRun',0) for q in r['ph'].values())
    o['xd']=tot(r,'xdFr')
    o['fl']=mx(r,'flMax');o['flFr']=tot(r,'flFr');o['sh']=tot(r,'shFr');o['shMin']=mn(r,'shMin');o['nk']=mn(r,'neck',.25);o['nkFr']=tot(r,'neckFr')
    o['jh']=h.get('jSum',0)/h['jN'] if h.get('jN') else None;o['jhm']=h.get('jMax',0) if h.get('jN') else None
    o['flick']=h.get('flick',0)/h['flickN'] if h.get('flickN') else None
    o['set']=r['rel']['settle'];o['j34']=r['rel']['j34'];o['j34m']=r['rel']['j34max']
    o['lagP']=u.get('lagMax',0);o['lagH']=h.get('lagEnd') if h else None;o['gapP']=u.get('gapMax',0);o['gapH']=h.get('gapEnd') if h else None
    o['grow']=(h['len1']-h['len0']) if h.get('fr',0)>=60 and h.get('len0') else None
    o['vmax']=l.get('vmax',0);o['off']=mx(r,'off');o['offR']=l.get('off',0);o['offFr']=tot(r,'offFr')
    o['xEnd']=l.get('xEnd',0);o['flEnd']=l.get('flEnd',0);o['shEnd']=l.get('shEnd',0);o['nan']=tot(r,'nan')
    o['eyeFr']=tot(r,'eyeFr');o['eyeJN']=tot(r,'eyeJN');o['eyeJ']=mx(r,'eyeJ')
    o['ms']=tot(r,'msSum')/max(1,tot(r,'fr'));o['msMax']=mx(r,'msMax');o['remN']=tot(r,'remN');o['remMs']=mx(r,'remMs');o['er']=tot(r,'erFr');o['erMax']=mx(r,'erMax');o['str']=mx(r,'str')
    return o
def av(a): a=[x for x in a if x is not None]; return sum(a)/len(a) if a else 0
def mxx(a): a=[x for x in a if x is not None]; return max(a) if a else 0
def line(nm,rs):
    if not rs: return
    Q=[rec(r) for r in rs];n=len(Q);c=lambda k:sum(1 for q in Q if q[k]);
    print(f"{nm:<22}n{n:4d}|破{c('brk'):4d}({100*c('brk')//n:3d}%) 裂{c('split'):3d} 洞{c('hole'):3d} 變{c('pop'):3d}|自交{c('xFr'):4d} 最長{mxx([q['xRun'] for q in Q])/60:4.1f}s 尾{c('xEnd'):2d}|翻面最多{mxx([q['fl'] for q in Q]):3d}|尖角{c('sh'):3d}|細脖{c('nkFr'):3d}|按住跳{av([q['jh'] for q in Q]):5.2f}/{mxx([q['jhm'] for q in Q]):4.0f} >3點:{sum(1 for q in Q if q['jh'] and q['jh']>3):3d}|長{av([q['grow'] for q in Q]):5.2f}/{mxx([q['grow'] for q in Q]):4.1f}|放手抖{av([q['set'] for q in Q]):4.2f}s 滿4s{sum(1 for q in Q if q['set']>=3.9):3d} 末秒{av([q['j34'] for q in Q]):4.2f}|甩{av([q['vmax'] for q in Q]):4.0f}/{mxx([q['vmax'] for q in Q]):4.0f}R/s|出畫面>3成{c('offFr'):3d}|落後拉{av([q['lagP'] for q in Q]):4.2f}/{mxx([q['lagP'] for q in Q]):4.2f} 按住{av([q['lagH'] for q in Q]):4.2f}/{mxx([q['lagH'] for q in Q]):4.2f} 可見{av([q['gapH'] for q in Q]):4.2f}/{mxx([q['gapH'] for q in Q]):4.2f}|眼跳{c('eyeJN'):3d} 眼外{c('eyeFr'):2d}|NaN{c('nan')}")
if __name__=='__main__':
    R,E,SK=load(sys.argv[1]);print('有效',len(R),'錯',len(E),'跳過',len(SK))
    for e in E[:3]: print(e['id'],e['err'][:200])
    mode=sys.argv[2] if len(sys.argv)>2 else 'all'
    line('全部',R)
    ks=['pull','opp','rot','pinch','three','scrub','stir','fling','wall','yoyo','fuzz','idle']
    if mode=='all':
        for k in ks: line(k,[r for r in R if r['c']['k']==k])
    if mode=='pull':
        pl=[r for r in R if r['c']['k']=='pull']
        for key in('grab','dir','dist','sp','x0'):
            print('--',key)
            for v in sorted({str(r['c'][key]) for r in pl}): line(v,[r for r in pl if str(r['c'][key])==v])
    if mode=='pull2':
        pl=[r for r in R if r['c']['k']=='pull']
        for gr in('near','regrab','center','far'):
            for ds in('1.5','3','4.5','6','edge'): line(gr+' '+ds,[r for r in pl if r['c']['grab']==gr and str(r['c']['dist'])==ds])
    if mode=='other':
        for k,keys in(('opp',('ang','dist','sp','from')),('rot',('nf','grow','sp')),('three',('dist','sp')),('scrub',('ang','amp','hz')),('stir',('rad','rps','from')),('wall',('dir','sp','grab')),('yoyo',('mode','sp','dist')),('fling',('dir','grab')),('pinch',('ang','sp'))):
            rr=[r for r in R if r['c']['k']==k]
            for key in keys:
                for v in sorted({str(r['c'].get(key)) for r in rr}): line(f'{k} {key}={v}',[r for r in rr if str(r['c'].get(key))==v])
