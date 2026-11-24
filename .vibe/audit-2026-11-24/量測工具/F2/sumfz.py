import sys,json,collections
sys.stdout.reconfigure(encoding='utf-8')
import numpy as np
def load(f): return json.load(open(f))
def summ(f,verbose=True):
    O=load(f);rows=[(o['seed'],r) for o in O for r in o['rows']]
    n=len(rows);S=lambda k:np.array([r.get(k,0) or 0 for _,r in rows],float)
    ns=S('ns');nr=S('nr');hs=S('hs');hr=S('hr');lost=S('lost');Ar=S('Ar');gain=S('gain');rx=S('ringX');inv=S('inv');eo=S('eyeOut');ec=S('eyeC');sp=S('spk')
    big2=np.array([ (r['pieces'][1] if len(r['pieces'])>1 else 0) for _,r in rows],float)
    R={'file':f,'trials':len(O),'rows':n,
     'skin>=2pieces %':100*np.mean(ns>1),'second piece>=20px %':100*np.mean(big2>=20),'2nd>=200px %':100*np.mean(big2>=200),
     'raw>=2pieces %':100*np.mean(nr>1),'skin holes %':100*np.mean(hs>0),'raw holes %':100*np.mean(hr>0),
     'lost%% mean':100*np.mean(lost/Ar),'lost%% max':100*np.max(lost/Ar),'gain%% max':100*np.max(gain/Ar),
     'ringX %':100*np.mean(rx>0),'inv %':100*np.mean(inv>0),'spikes>75deg %':100*np.mean(sp>0),'eye any out %':100*np.mean(eo>0),'eye centre out %':100*np.mean(ec>0),
     'trials skin broken>=20':len({s for s,r in rows if len(r['pieces'])>1 and r['pieces'][1]>=20}),'trials holes':len({s for s,r in rows if r['hs']>0}),'trials eye centre out':len({s for s,r in rows if (r.get('eyeC') or 0)>0})}
    # 補點那一格的輪廓跳動 vs 前後
    jr=[];jn=[]
    for o in O:
        rr=o['rows']
        for i in range(1,len(rr)-1):
            if rr[i].get('rm') and 'disp' in rr[i]:
                df=rr[i]['f']-rr[i-1]['f']
                jr.append((rr[i]['disp']/max(1,df),o['seed'],rr[i]['f'],rr[i-1]['disp']/max(1,rr[i-1]['f']-(rr[i-2]['f'] if i>1 else rr[i-1]['f']-2)) if 'disp' in rr[i-1] else 0,rr[i+1]['disp']/max(1,rr[i+1]['f']-rr[i]['f'])))
    R['remesh frames']=len(jr)
    if jr:
        a=np.array([x[0] for x in jr]);b=np.array([(x[3]+x[4])/2 for x in jr]);R['remesh disp px/frame mean']=a.mean();R['neighbours disp mean']=b.mean();R['remesh disp max']=a.max()
    if verbose:
        for k,v in R.items(): print('  ',k,(round(v,3) if isinstance(v,float) else v))
        # 最糟的幾幀
        bad=sorted([(r['pieces'][1],s,r['f'],r['ph'],r['pieces'],r['nr'],r['ringX'],r['inv']) for s,r in rows if len(r['pieces'])>1],reverse=True)[:8]
        print('   worst broken',bad)
        bh=sorted([(r['hsA'],s,r['f'],r['ph'],r['hs'],r['hr'],r['ringX'],r['inv']) for s,r in rows if r['hs']>0],reverse=True)[:8]
        print('   worst holes',bh)
        be=sorted([(r['eyeOut'],r['eyeC'],s,r['f'],r['ph']) for s,r in rows if (r.get('eyeOut') or 0)>0],reverse=True)[:8]
        print('   worst eyes',be)
        bl=sorted([(round(100*r['lost']/r['Ar'],2),s,r['f'],r['ph'],r['ns']) for s,r in rows],reverse=True)[:6]
        print('   worst lost',bl)
        if jr: print('   worst remesh',[tuple(round(y,1) for y in x) for x in sorted(jr,reverse=True)[:6]])
    return R
if __name__=='__main__':
    for f in sys.argv[1:]: print(f);summ(f)
