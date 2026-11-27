// 開場：大腦關（等於現在手機版的邏輯）對大腦開，很熟
const out=[];
for(const br of [0,1])for(const tr of [.6,.9])for(let sd=1;sd<=6;sd++){fresh(sd*17+3,{brain:br,mood:br,brMem:br,decoReact:br},{tr,settle:0});let eye=null,greet=null,hello=null;steps(35*60,i=>{const s=i/60;if(EYE.user>t&&eye==null)eye=r2(s);if(E4.on&&greet==null)greet=r2(s)});const h=LOG.find(q=>q[1]==='voice.hello');out.push({br,tr,sd,eye,greet,hello:h?h[0]:null})}
return out;
