import sys, json, itertools
import numpy as np
sys.stdout.reconfigure(encoding='utf-8'); sys.argv=['x']
from onset import load, env, m
def mel(sr,n,nb=24,lo=200,hi=12000):
    f=np.fft.rfftfreq(n,1/sr); M=lambda h:2595*np.log10(1+h/700); pts=700*(10**(np.linspace(M(lo),M(hi),nb+2)/2595)-1)
    B=np.zeros((nb,len(f)))
    for i in range(nb):
        a,b,c=pts[i:i+3]; B[i]=np.clip(np.minimum((f-a)/(b-a),(c-f)/(c-b)),0,None)
    return B
def feat(f):
    sr,x=load(f); e=env(x,sr); o=np.argmax(e>e.max()*10**(-26/20)); x=x[max(0,o-int(.002*sr)):]
    n=int(.025*sr); h=int(.0125*sr); B=mel(sr,n); w=np.hanning(n); fr=[]
    for i in range(0,max(1,len(x)-n),h):
        X=np.abs(np.fft.rfft(x[i:i+n]*w))**2; fr.append(10*np.log10(B@X+1e-9))
    F=np.array(fr); return F
def dist(a,b):
    n=min(len(a),len(b)); A=a[:n]-a[:n].max(); Bq=b[:n]-b[:n].max(); A=np.maximum(A,-45); Bq=np.maximum(Bq,-45); return float(np.sqrt(np.mean((A-Bq)**2)))
rows=[]
for k,v in m.items():
    if not isinstance(v,dict): continue
    for l,fs in v.items():
        if len(fs)<3: continue
        F=[feat(f) for f in fs]; D=[dist(a,b) for a,b in itertools.combinations(F,2)]
        rows.append((k+'.'+l,len(fs),min(D),np.median(D),max(D),100/len(fs)))
print('layer          n | closest pair dB | median pair dB | farthest | P(same as previous) %')
for r in rows: print('%-14s %2d | %5.1f | %5.1f | %5.1f | %4.1f'%r)
