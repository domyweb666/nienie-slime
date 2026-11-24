# 一次性小聲音（細絲、小泡）對自己的雨聲：短時峰值（5 ms、喇叭頻段）；再看 loop 的短時 95 百分位（上一支只比長時平均）
import sys,os,json
import numpy as np, soundfile as sf
from scipy.signal import butter,sosfilt,resample_poly
sys.stdout.reconfigure(encoding='utf-8')
RES=r'E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/ios/NieNie/Resources'; W=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'wav')
m=json.load(open(os.path.join(RES,'manifest.json'),encoding='utf-8')); SR=48000
def load(f):
    x,sr=sf.read(f); x=x if x.ndim==1 else x.mean(1); return x if sr==SR else resample_poly(x,160,147)
spk=butter(4,350,'high',fs=SR,output='sos'); lp=lambda x,fc:sosfilt(butter(2,fc,'low',fs=SR,output='sos'),x)
def st(x,w=240,h=48):
    c=np.concatenate([[0],np.cumsum(x**2)]);e=np.arange(w,len(x)+1,h); return np.sqrt((c[e]-c[e-w])/w)
db=lambda v:20*np.log10(np.maximum(v,1e-12))
def band(x,a,b): return sosfilt(butter(3,[a,b],'band',fs=SR,output='sos'),x)
bed=load(os.path.join(W,'amb-rain-bed.wav'))[SR:SR*61]*.4*.6; B=st(sosfilt(spk,bed)); p95=db(np.percentile(B,95)); p50=db(np.median(B))
print('雨聲（抓著、壓到六成）短時：中位 %.1f、95 百分位 %.1f dBFS'%(p50,p95))
for (k,l,g,fc) in (('pull','strand',.12,9000),('pull','strand',.3,9000),('settle','bubble',.2,6000),('settle','bubble',.35,6000)):
    v=[]
    for f in m[k][l]: v.append(db(st(sosfilt(spk,np.pad(lp(load(os.path.join(RES,f)),fc),(300,300)))*g*.9).max()))
    v=np.array(v); print('%s.%s 音量 %.2f：峰 %.1f（%.1f 到 %.1f）dBFS，比雨聲 95 百分位 %+.1f dB，%d/%d 段蓋得過'%(k,l,g,np.median(v),v.min(),v.max(),np.median(v)-p95,(v>p95).sum(),len(v)))
for nm,k,lv,fc in (('揉 60 點/秒','rub',.079,1694),('揉 120 點/秒','rub',.158,1988),('揉 240 點/秒','rub',.317,2576),('揉 400 點/秒','rub',.528,3361),('揉 600 點/秒','rub',.7,4000),('拉 106 點/秒 st1R','pull',.293,2269),('拉 265 點/秒 st1.5R','pull',.6,2814)):
    x=np.concatenate([load(os.path.join(RES,f)) for f in m[k]['loop']]); s=st(sosfilt(spk,lp(x,fc))*lv*.9)
    print('%-18s 短時 95 百分位 %.1f dBFS 比雨聲 95 百分位 %+.1f dB；超過雨聲 95 百分位的時間 %.1f%%'%(nm,db(np.percentile(s,95)),db(np.percentile(s,95))-p95,100*(db(s)>p95).mean()))
