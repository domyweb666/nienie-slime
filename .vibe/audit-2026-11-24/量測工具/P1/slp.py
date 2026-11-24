import json,sys,glob,os
sys.stdout.reconfigure(encoding='utf-8')
tot={}
for f in sorted(glob.glob('../data/own-*.json')):
    d=json.load(open(f,encoding='utf-8'));a=[e for e in d['E'] if e['k']=='act' and e['kind'] not in('rhythm','hover')];b=[e for e in d['E'] if e['k']=='act' and e['kind'] in('rhythm','hover')]
    print(os.path.basename(f),'碰身體時在睡',sum(1 for x in a if x['slp']),'/',len(a),'；空白處時在睡',sum(1 for x in b if x['slp']),'/',len(b),'被嚇醒聲',sum(1 for e in d['E'] if e['k']=='snd' and e['s']=='voice.startle'))
