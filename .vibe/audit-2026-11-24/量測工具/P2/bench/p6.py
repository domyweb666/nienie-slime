import json,sys
sys.stdout.reconfigure(encoding='utf-8')
o=json.load(open('e6.json',encoding='utf-8'))
for r in o:
    print('tr',r['tr'],'sd',r['sd'],r['k']);print('   greet',r['ev2']['greet'],'offer',r['ev2']['offer'],'cat',r['ev2']['cat'],'nap',r['ev2']['nap'],'selfWake',r['ev2']['wakeSelf']);print('   eyeYou',r['eyeYou'],'xsd mm',r['xsdMM'],r['xmin'],r['xmax'],'topple',r['topple'],'startle',r['startle'],'voices',r['voices'],'m',r['m'],r['fx'],r['dr'])
