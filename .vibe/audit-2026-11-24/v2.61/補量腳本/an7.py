import sys,os,glob;sys.path.insert(0,'tool')
from ana2 import load,rec
sys.stdout.reconfigure(encoding='utf-8')
for n in ['def','w1','all','v260','off23']+['no_'+k for k in 'rough tapSoft petSlow wakeSoft nearFast greetLook brJit bumpSoft eyeTrue snd61'.split()]:
    p=f'out/r_i7_{n}.json'
    if not os.path.exists(p): continue
    R,E,S=load(p);Q={r['id']:rec(r) for r in R};sm=[Q[f'same_{k}'] for k in range(5) if f'same_{k}' in Q];sd=[Q[f'sd_{k}'] for k in range(1,21) if f'sd_{k}' in Q]
    print(f"{n:<14} 同種子5次 洞格*2格 {[q['hole']*2 for q in sm]} 裂{[q['split'] for q in sm]} 突{[q['pop'] for q in sm]} | 另20種子 有洞{sum(1 for q in sd if q['hole'])}/{len(sd)} 洞格合計{sum(q['hole'] for q in sd)} 最久{max(q['hole'] for q in sd)} 裂{sum(1 for q in sd if q['split'])} 突{sum(1 for q in sd if q['pop'])} 破{sum(q['brk'] for q in sd)} | 洞格 {[q['hole'] for q in sd]}")
