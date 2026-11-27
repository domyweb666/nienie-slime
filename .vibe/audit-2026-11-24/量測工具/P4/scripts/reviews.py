import json,sys,re,time,urllib.request
sys.stdout.reconfigure(encoding='utf-8')
CATS={
 'ads':r'\bads?\b|\badds\b|advert|commercial',
 'lag_freeze_crash':r'\blag|laggy|freez|froze|glitch|crash|\bslow\b|black screen|(does|do|did)n.?t load|won.?t load|kick(s|ed)? me out|\bstuck\b',
 'sound':r'\bsounds?\b|\baudio\b|\bnoise',
 'haptic':r'vibrat|haptic',
 'realism_texture':r'realis|feels? real|not real|fake|look(s)? like real|\btexture',
 'stretch_tear':r'stretch|\brip(s|ped)?\b|\btear(s|ing)?\b|\bbreaks?\b|\bholes?\b|\bpull',
 'boring_repetitive':r'boring|\bbored\b|repetit|gets? old|nothing to do|same thing|no point|pointless',
 'same_feel':r'all the same|feel(s)? the same|same texture|same slime|look(s)? the same|sound(s)? the same',
 'relax_satisfy':r'satisf|relax|calm|stress|anxi|sooth|asmr',
 'more_content':r'(more|new|add) (slime|charm|texture|color|colour|item|cat|adventure|outfit|toy)',
 'feel_response':r'respon(d|s)|react|touch',
 'guilt_sad':r'guilt|feel bad|sad|lonely',
 'alive_pet':r'alive|real pet|like a pet|personality|love(s)? me|friend|companion',
}
def get(app,page,cc='us'):
    u=f'https://itunes.apple.com/{cc}/rss/customerreviews/page={page}/id={app}/sortby=mostrecent/json'
    for k in range(2):
        try:
            return json.loads(urllib.request.urlopen(urllib.request.Request(u,headers={'User-Agent':'Mozilla/5.0'}),timeout=30).read())
        except Exception as e:
            time.sleep(1)
    return {}
def load(app,cc='us',pages=10):
    R=[]
    for p in range(1,pages+1):
        d=get(app,p,cc).get('feed',{}).get('entry',[])
        if isinstance(d,dict): d=[d]
        n=0
        for e in d:
            if 'im:rating' in e:
                R.append((int(e['im:rating']['label']),e['title']['label'],e['content']['label'],e.get('updated',{}).get('label','')[:10])); n+=1
        if n==0: break
        time.sleep(.25)
    return R
if __name__=='__main__':
    tot={}
    for spec in sys.argv[1:]:
        app,name=spec.split(':',1)
        R=load(app)
        if not R: print(name,'no reviews'); continue
        lo=[r for r in R if r[0]<=2]; n=len(R)
        dates=sorted(r[3] for r in R)
        print(f'## {name} n={n} mean={sum(r[0] for r in R)/n:.2f} low(1-2)={len(lo)} {dates[0]}..{dates[-1]}')
        row=[]
        for c,p in CATS.items():
            rx=re.compile(p,re.I)
            a=sum(1 for r in R if rx.search(r[1]+' '+r[2])); b=sum(1 for r in lo if rx.search(r[1]+' '+r[2]))
            row.append(f'{c} {a}({100*a/n:.0f}%)/low {b}({100*b/max(1,len(lo)):.0f}%)')
            t=tot.setdefault(c,[0,0]); t[0]+=a; t[1]+=b
        tot.setdefault('_n',[0,0]); tot['_n'][0]+=n; tot['_n'][1]+=len(lo)
        print('  '+'; '.join(row))
    print('## TOTAL',tot)
