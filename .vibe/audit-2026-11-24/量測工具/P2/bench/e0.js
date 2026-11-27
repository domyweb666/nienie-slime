const o={R,W,H,DPR,N,nb:bnd.length,curMat,SLIME:SLIMES[SLIME].name,view:{...VIEW},sill:mat.sill,eyes:mat.eyes,intro:mat.intro,introSwim:mat.introSwim,limbs:mat.limbs,bodySize:mat.bodySize,tremble:mat.tremble,struggle:mat.struggle,shake:mat.shake,SILLg:SILL.g?{l:SILL.g.l,r:SILL.g.r,bx:SILL.g.bx,fl:SILL.g.fl}:null,tr:IMP.tr,t,lsKeys:Object.keys(localStorage)};
o.clampL=sillClampX(-999);o.clampR=sillClampX(9999);
return o;
