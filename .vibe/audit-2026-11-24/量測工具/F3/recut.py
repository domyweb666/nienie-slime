# 可行性：同一批 ElevenLabs 原始檔，加一條「最大聲要在前 30 毫秒」的條件，還剩幾顆；多剪幾毫秒頭就好的有幾段（只讀，不寫專案）
import os,sys,subprocess
import numpy as np
from scipy.signal import butter,sosfiltfilt
sys.stdout.reconfigure(encoding='utf-8')
SR=44100; EL=r'E:/捏捏史萊姆/素材/elevenlabs/slime/_opus'
def load(p):
    r=subprocess.run(['ffmpeg','-v','error','-i',p,'-f','f32le','-ac','1','-ar',str(SR),'-'],capture_output=True,check=True)
    return np.frombuffer(r.stdout,dtype=np.float32).astype(np.float64)
db=lambda x:20*np.log10(np.maximum(x,1e-12))
def env(x,hop_s=.005):
    h=int(hop_s*SR);n=len(x)//h; return db(np.sqrt((x[:n*h].reshape(n,h)**2).mean(1))),h
def onsets(x,thr,gap):
    e,h=env(x);k=int(.25/.005);fl=e.max()-45;o=[];i=0
    while i<len(e):
        lo,hi=max(0,i-k),min(len(e),i+k);loc=np.median(e[lo:hi])
        if e[i]>fl and e[i]-loc>thr and e[i]==e[max(0,i-4):i+5].max(): o.append((i*h,e[i]-loc)); i+=int(gap/.005)
        else: i+=1
    return o
def st(x):
    w=int(.004*SR);h=int(.0005*SR);c=np.concatenate([[0],np.cumsum(x**2)]);n=np.arange(0,len(x),h);a=np.maximum(0,n-w//2);b=np.minimum(len(x),n+w//2+1)
    return np.sqrt((c[b]-c[a])/(b-a)), n/SR*1000
def hp(x,f): return sosfiltfilt(butter(4,f,'hp',fs=SR,output='sos'),x)
def test(name,keys,length,thr,gap,need,band=None,lim=30):
    tot=ok=0; e50=[]
    for k in keys:
        x=load(os.path.join(EL,k+'.opus')); xx=hp(x,band) if band else x
        for p,s in onsets(xx,thr,gap):
            tot+=1; seg=xx[max(0,p-int(.01*SR)):p+int(length*SR)]; e,t=st(seg); pk=t[e.argmax()]
            if pk<=lim: ok+=1; c=np.cumsum(seg**2); e50.append(np.searchsorted(c/c[-1],.5)/SR*1000)
    print('%-14s 候選 %3d 顆，最大聲在前 %d ms 的 %3d 顆（要 %d 顆），這些的能量一半時間中位數 %.0f ms'%(name,tot,lim,ok,need,np.median(e50) if e50 else float('nan')))
E=lambda k:['%s-%d'%(k,i) for i in range(1,5)]
test('press.wet',E('press'),.35,6,.2,8); test('press.wet 放寬門檻4dB 間隔.12',E('press'),.35,4,.12,8)
test('release.wet',E('release'),.28,6,.15,8); test('release.wet 放寬',E('release'),.28,4,.1,8)
test('release.air',E('release'),.12,8,.1,8,band=2000); test('pull.strand',E('strand'),.1,7,.06,10)
test('voice.poke',E('as-poke'),.3,6,.3,6)
# 撕開、黏上、拔開、吞：現在的檔，從「主能量開始」往前留 12 ms 重切，還剩多長
import soundfile as sf
RES=r'E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/ios/NieNie/Resources'
for pre in('ai-voice-tear','ai-fx-cling','ai-fx-unstick','ai-voice-gulp','ai-voice-protest','ai-voice-startle','ai-voice-poke'):
    for f in sorted(os.listdir(RES)):
        if f.startswith(pre) and f.endswith('.wav'):
            x,sr=sf.read(os.path.join(RES,f)); e,t=st(x) if sr==SR else (None,None); d=db(e/e.max()); t6=t[np.argmax(d>=-6)]; pk=t[e.argmax()]
            print('%-24s 長 %4.0f ms 主能量(-6dB)在 %4.0f ms 最大聲 %4.0f ms；從主能量往後還有 %4.0f ms'%(f,len(x)/sr*1000,t6,pk,len(x)/sr*1000-t6))
