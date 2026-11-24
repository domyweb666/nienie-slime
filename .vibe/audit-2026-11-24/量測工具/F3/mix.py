# 按、放手的三層合起來：從 play() 到「聽得到」與「主能量」多少毫秒（照 Swift 的 gain、rate、lowpass、air 延遲、每幀才放 pending）
import json,sys,os
import numpy as np, soundfile as sf
from scipy.signal import butter,sosfilt,resample_poly
sys.stdout.reconfigure(encoding='utf-8')
rng=np.random.default_rng(7)
RES=r'E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/ios/NieNie/Resources'
W=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'wav')
m=json.load(open(os.path.join(RES,'manifest.json'),encoding='utf-8'))
SR=48000
def load(f):
    x,sr=sf.read(f); x=x if x.ndim==1 else x.mean(1)
    return x if sr==SR else resample_poly(x,160,147)
B={(k,l):[load(os.path.join(RES,f)) for f in m[k][l]] for k in('press','release') for l in m[k]}
def lp(x,fc): return sosfilt(butter(2,min(fc,20000),'low',fs=SR,output='sos'),x)
spk=butter(4,350,'high',fs=SR,output='sos')
N=int(.6*SR)
def put(o,x,rate,g,fc,delay):
    n=int(len(x)/rate); y=np.interp(np.arange(n)*rate,np.arange(len(x)),x); y=lp(y,fc)*g
    a=int(delay*SR); b=min(len(o),a+n); o[a:b]+=y[:b-a]
def press(i,frame=1/120,only=None):
    o=np.zeros(N); L=[]
    J=lambda:1+rng.uniform(-.08,.08)
    if i>.3: L.append(('body',.9*i**1.2,(1.06-.14*i)*J(),2600,0))
    L.append(('wet',.45+.45*i,J(),1600+3400*i,0))
    if rng.random()<.35+.6*i:
        d=rng.uniform(.015,.045); d=np.ceil((d+rng.uniform(0,frame))/frame)*frame   # 排進 pending，下一個 tick 才放
        L.append(('air',.25+.45*i,rng.uniform(.9,1.15)*J(),6000,d))
    for l,g,r,fc,d in L:
        if only and l not in only: continue
        put(o,B[('press',l)][rng.integers(len(B[('press',l)]))],r,g,fc,d)
    return o*.9
def release(s,only=None):
    o=np.zeros(N); J=lambda:1+rng.uniform(-.08,.08)
    L=[('air',.55+.45*s,(1.08-.14*s)*J(),7000),('wet',.25+.6*s,J(),1800+4200*s)]
    if s>.2: L.append(('body',.85*s**1.3,(1.05-.1*s)*J(),2400))
    for l,g,r,fc in L:
        if only and l not in only: continue
        put(o,B[('release',l)][rng.integers(len(B[('release',l)]))],r,g,fc,0)
    return o*.9
def st(x,win=.005,hop=.001):
    w=int(win*SR);h=int(hop*SR);c=np.concatenate([[0],np.cumsum(x**2)]);e=np.arange(h,len(x)+1,h);a=np.maximum(0,e-w)
    return np.sqrt((c[e]-c[a])/w), e/SR*1000
bed=sosfilt(spk,load(os.path.join(W,'amb-rain-bed.wav'))[SR:SR*61]*.4)
bedst,_=st(bed); BL=np.sqrt((bedst**2).mean()); BP=np.percentile(bedst,95)
print('雨聲（喇叭頻段、沒壓低）短時均方 %.1f dBFS，95 百分位 %.1f'%(20*np.log10(BL),20*np.log10(BP)))
def stat(fn,label,n=400):
    A={k:[] for k in('aud','m6','pk','e50','first50','pkdb','late')}
    for _ in range(n):
        x=sosfilt(spk,fn()); e,t=st(x); pk=e.max()
        A['aud'].append(t[np.argmax(e>BP)] if (e>BP).any() else np.nan)
        A['m6'].append(t[np.argmax(e>pk/2)]); A['pk'].append(t[e.argmax()])
        c=np.cumsum(x**2)/np.sum(x**2); A['e50'].append(np.searchsorted(c,.5)/SR*1000)
        A['first50'].append(c[int(.05*SR)]); A['pkdb'].append(20*np.log10(pk)); A['late'].append(t[e.argmax()]>60)
    q=lambda k,p:np.nanpercentile(A[k],p)
    print('%-28s 蓋過雨聲 %4.0f/%4.0f/%4.0f ms (沒蓋過 %2.0f%%) | 到−6dB %4.0f/%4.0f | 最大聲 %4.0f/%4.0f/%4.0f ms | 能量一半 %4.0f/%4.0f | 前50ms能量占 %2.0f%% | 最大聲在60ms後 %2.0f%% | 峰 %.1f dBFS'%(label,q('aud',10),q('aud',50),q('aud',90),100*np.isnan(A['aud']).mean(),q('m6',50),q('m6',90),q('pk',10),q('pk',50),q('pk',90),q('e50',50),q('e50',90),100*np.median(A['first50']),100*np.mean(A['late']),q('pkdb',50)))
for i in (.3,.5,.6,.7): stat(lambda:press(i),'按 i=%.1f 三層'%i)
stat(lambda:press(.6,only=('wet',)),'按 i=0.6 只有濕聲')
stat(lambda:press(.6,only=('body',)),'按 i=0.6 只有份量')
for s in (0,.3,.6,1): stat(lambda:release(s),'放手 s=%.1f 全部'%s)
