# 音量相對關係：捏的聲音（照 Swift 的音量公式）對自己的環境音，分 1/3 八度比
import json,sys,os
import numpy as np, soundfile as sf
from scipy.signal import butter,sosfilt,resample_poly,welch
sys.stdout.reconfigure(encoding='utf-8')
RES=r'E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/ios/NieNie/Resources'
W=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'wav')
m=json.load(open(os.path.join(RES,'manifest.json'),encoding='utf-8'))
SR=48000
def load(f):
    x,sr=sf.read(f); x=x if x.ndim==1 else x.mean(1)
    if sr!=SR: x=resample_poly(x,SR,sr) if sr!=44100 else resample_poly(x,160,147)
    return x
def lp(x,fc): return sosfilt(butter(2,min(fc,20000),'low',fs=SR,output='sos'),x)
def db(v): return 20*np.log10(np.maximum(v,1e-12))
def rms(x): return np.sqrt((x**2).mean())
# 手機喇叭近似：350 Hz 以下 4 階高通（只是近似，真機要量）
spk=butter(4,350,'high',fs=SR,output='sos')
cen=[400,500,630,800,1000,1250,1600,2000,2500,3150,4000,5000,6300,8000]
def bands(x):
    f,p=welch(x,SR,nperseg=4096)
    o=[]
    for c in cen:
        a,b=c*2**(-1/6),c*2**(1/6); s=(f>=a)&(f<b); o.append(10*np.log10(p[s].sum()*(f[1]-f[0])+1e-20))
    return np.array(o)
bed=load(os.path.join(W,'amb-rain-bed.wav'))[SR:SR*61]
AMB=0.25*1.6; DUCK=0.6; MASTER=0.9
b0=bed*AMB; b1=bed*AMB*DUCK
print('rain bed file rms %.1f dBFS; played %.1f; ducked while held %.1f (speaker band >350Hz: %.1f)'%(db(rms(bed)),db(rms(b0)),db(rms(b1)),db(rms(sosfilt(spk,b1)))))
B=bands(sosfilt(spk,b1))
def cmp(name,x):
    y=sosfilt(spk,x); d=bands(y)-B
    print('%-34s rms %.1f dBFS | 喇叭段比雨聲 %+.1f dB | 最有利 1/3 八度 %+.1f dB @%d Hz'%(name,db(rms(x)),db(rms(y))-db(rms(sosfilt(spk,b1))),d.max(),cen[int(d.argmax())]))
Rpt=106.1
rub=[load(os.path.join(RES,f)) for f in m['rub']['loop']]; pull=[load(os.path.join(RES,f)) for f in m['pull']['loop']]
cat=lambda L:np.concatenate(L)
for v in (30,60,120,240,400,600):
    n=min(1,v/Rpt/5); lv=0.7*n
    cmp('揉 %d 點/秒 (%.1f cm/s) 音量 %.3f'%(v,v/60.4,lv),lp(cat(rub),1400+2600*n)*lv*MASTER)
def pg(st,v): return (0.12+0.18*(1-np.exp(-max(0,st-0.6)/4)))*np.clip((st-0.2)/0.4,0,1)+0.88*min(1,v/2.5)
for st,v in ((0.3,0.2),(0.6,0.3),(1,0.5),(1,1),(1.5,2.5),(3,2.5),(2,0)):
    g=0.6*min(1,pg(st,v)); cmp('拉絲 st=%.1fR v=%.1fR/s (%d pt/s) 音量 %.3f'%(st,v,v*Rpt,g),lp(cat(pull),1000+7000*(1-np.exp(-st/5)))*g*MASTER)
