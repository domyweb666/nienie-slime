import json,sys,math
sys.stdout.reconfigure(encoding='utf-8')
o=json.load(open('e2c.json',encoding='utf-8'))
MM=0.16565
def de(a,b): return math.dist(a,b)
for bg in ['day']:
    n=o[bg+'.neutral']; print(bg,'neutral w %.1f h %.1f mm per %.2f pp %.2fpt(%.2fmm) ppW %.2f'%(n['w']*MM,n['h']*MM,n['per'] or 0,n['pp'],n['pp']*MM,n['ppW']),'rgb',n['rgb'],n['rgbTop'],n['tint'])
    for k,v in o.items():
        if not k.startswith(bg+'.'): continue
        print('  %-10s dw %+.2fmm (%+.1f%%) dh %+.2fmm (%+.1f%%) A %+.1f%% per %.2fs pp %.2fmm(%.2fx) eye open %.2f wide %.2f %s | rgb %s dE %.1f | top %s dE %.1f'%(k.split('.')[1],(v['w']-n['w'])*MM,(v['w']/n['w']-1)*100,(v['h']-n['h'])*MM,(v['h']/n['h']-1)*100,(v['A']/n['A']-1)*100,v['per'] or 0,v['pp']*MM,v['pp']/max(.01,n['pp']),v['open'],v['wide'],v['mode'],v['rgb'],de(v['lab'],n['lab']),v['rgbTop'],de(v['labTop'],n['labTop'])))
print(o['R'],o['eye'], 'eye half w mm',o['eye']['ew']*MM,'half h',o['eye']['eh']*MM)
