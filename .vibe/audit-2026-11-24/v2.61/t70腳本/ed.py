p='C:/Users/fcharlie/AppData/Local/Temp/claude/667dbbd50c5b7948/c03762d8-d9d7-48d6-842c-b409d5d2cab2/scratchpad/t70/t70.js'
s=open(p,encoding='utf-8').read()
def R(a,b):
    global s
    assert s.count(a)==1,(s.count(a),a[:60]); s=s.replace(a,b)
R("  // 對照：同一批皮 0（v2.60 的外框畫法）要裂 6 組以上，證明量得到（補量 12 到 15）。回家力道：網頁自己的值用來擋，手機的值（KPIOS）只記錄。\n  // 數字每次差幾組（物理裡有不吃種子的計時）。預設跑短版；先設 window.T70LONG = 1 跑長版：隨手拉 300 次，手機力道也跑隨手拉。\n",
"  // 對照：同一批的前 20 組改皮 0（v2.60 的外框畫法）要裂 2 組以上，證明量得到（40 組補量裂 12 到 15）。回家力道：網頁自己的值用來擋，手機的值（KPIOS）只記錄。\n  // 數字每次差幾組（物理裡有不吃種子的計時）。預設跑短版，約 8 分鐘；先設 window.T70LONG = 1 跑長版，約 40 分鐘：對照和手機力道也跑滿 40 組，隨手拉 300 次，手機力道隨手拉 100 次。只想快看一眼：window.T70N = 隨手拉次數。\n")
R("worst.push({ k: 'pull', dir: 'R', d: 99, seed: 31175 + k * 1000 }, { k: 'pull', dir: 'DR', d: 3, seed: 31175 + k * 1000 }, { k: 'opp', seed: 31201 + k * 1000 }, { k: 'pull', dir: 'L', d: 99, seed: 31101 + k * 1000 });",
"worst.push({ id: 'R' + k, k: 'pull', dir: 'R', d: 99, seed: 31175 + k * 1000 }, { id: 'DR' + k, k: 'pull', dir: 'DR', d: 3, seed: 31175 + k * 1000 }, { id: 'O' + k, k: 'opp', seed: 31201 + k * 1000 }, { id: 'L' + k, k: 'pull', dir: 'L', d: 99, seed: 31101 + k * 1000 });")
R("({ k: 'rnd', seed: 45000 + k })","({ id: 'N' + k, k: 'rnd', seed: 45000 + k })")
R("popMax: 0, skin: null };","popMax: 0, skin: null, who: '' };")
R("if (o.split || o.hole || o.pop) q.brk++;","if (o.split || o.hole || o.pop) { q.brk++; q.who += ' ' + c.id + (o.split ? '裂' : '') + (o.hole ? '洞' : '') + (o.pop ? '突' : ''); }")
R("const nr = long ? 300 : window.T70N || 60;\n      await batch('old', worst, OLD, 0);","const nr = long ? 300 : window.T70N || 20, few = long ? worst : worst.slice(0, 20);\n      await batch('old', few, OLD, 0);")
R("await batch('defP', worst, DEF, 1); await batch('allP', worst, ALL, 1);\n      if (long) { await batch('defRP', casual(nr), DEF, 1); await batch('allRP', casual(nr), ALL, 1); }",
"await batch('defP', long ? worst : worst.slice(0, 12), DEF, 1); await batch('allP', long ? worst : worst.slice(0, 12), ALL, 1);\n      if (long) { await batch('defRP', casual(100), DEF, 1); await batch('allRP', casual(100), ALL, 1); }")
R("r.sec.all = Math","r.sec.total = Math")
R("r.old.split >= 6 &&","r.old.split >= (long ? 6 : 2) &&")
open(p,'w',encoding='utf-8',newline='\n').write(s)
