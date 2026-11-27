P='E:/捏捏史萊姆/nienie-slime/prototype/web/_wt/prototype/web/index.html'
s=open(P,encoding='utf-8',newline='').read().replace('\r\n','\n')
B=chr(92)
for a,b in (("w='\n這一批","w='"+B+"n這一批"),("t.replace('\n#nienie-feel',w+'\n#nienie-feel')","t.replace('"+B+"n#nienie-feel',w+'"+B+"n#nienie-feel')")):
    print(s.count(a)); s=s.replace(a,b)
i=s.index('/#nienie-feel',s.index('deskImport=txt=>'));print(s[i:i+40])
open(P,'w',encoding='utf-8',newline='').write(s.replace('\n','\r\n'))
e=open('eq.py',encoding='utf-8').read()
e=e.replace("pg=cx.new_page();","cx.add_init_script(INI);pg=cx.new_page();",1)
e=e.replace('def sess','INI="""(()=>{let a=12345;window.__NOW=1e6;Math.random=()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296};performance.now=()=>window.__NOW;Date.now=()=>1.7e12+window.__NOW;window.requestAnimationFrame=()=>0;window.setInterval=()=>0})()"""\ndef sess',1)
e=e.replace("let NOW=1e6;performance.now=()=>NOW;Date.now=()=>1.7e12+NOW;","").replace("NOW+=1000/60","__NOW+=1000/60")
open('eq.py','w',encoding='utf-8').write(e)
