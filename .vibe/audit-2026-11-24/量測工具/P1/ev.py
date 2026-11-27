import json,sys
sys.stdout.reconfigure(encoding='utf-8')
d=json.load(open(sys.argv[1],encoding='utf-8'));a=float(sys.argv[2]);b=float(sys.argv[3]);skip=set((sys.argv[4] if len(sys.argv)>4 else 'blink,sac').split(','))
for e in d['E']:
    if a<=e['t']<=b and e['k'] not in skip: print(e)
