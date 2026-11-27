import sys, os, json, base64
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE)
from boot import *
import numpy as np
from scipy.signal import lfilter
def kw(x):
    b1,a1=[1.53512485958697,-2.69169618940638,1.19839281085285],[1.0,-1.69065929318241,0.73248077421585]
    b2,a2=[1.0,-2.0,1.0],[1.0,-1.99004745483398,0.99007225036621]
    return lfilter(b2,a2,lfilter(b1,a1,x))
def lufs(x): y=kw(x); return -0.691+10*np.log10(np.mean(y*y)+1e-14)
srv=serve(9931)
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=CH,headless=True,args=['--mute-audio'])
    pg=b.new_context().new_page(); pg.goto('http://127.0.0.1:9931/sfx/manifest.json'); pg.set_default_timeout(0)
    for f in ['amb-rain-bed.m4a','amb-fire-bed.m4a','amb-noise-pink-bed.m4a','bgm-lofi-loop.m4a']:
        r=pg.evaluate('''async(f)=>{const c=new OfflineAudioContext(1,48000,48000);const ab=await (await fetch('/sfx/'+f)).arrayBuffer();const b=await c.decodeAudioData(ab);const n=Math.min(b.length,48000*40),o=new Float32Array(n);for(let ch=0;ch<b.numberOfChannels;ch++){const d=b.getChannelData(ch);for(let i=0;i<n;i++)o[i]+=d[i+48000*5]/b.numberOfChannels}const u=new Uint8Array(o.buffer);let s='';for(let i=0;i<u.length;i+=0x8000)s+=String.fromCharCode.apply(null,u.subarray(i,i+0x8000));return{n:b.numberOfChannels,d:b.duration,sr:b.sampleRate,pcm:btoa(s)}}''',f)
        x=np.frombuffer(base64.b64decode(r['pcm']),dtype=np.float32).astype(float)
        print(f,'dur %.1f ch %d'%(r['d'],r['n']),'file LUFS(mono) %.1f rms %.1f'%(lufs(x),20*np.log10(np.sqrt(np.mean(x**2)))),'| in app: free %.1f, held(x0.6) %.1f LUFS'%(lufs(x)+20*np.log10(.4 if 'lofi' not in f else .25),lufs(x)+20*np.log10((.4 if 'lofi' not in f else .25)*.6)))
    b.close()
srv.shutdown()
