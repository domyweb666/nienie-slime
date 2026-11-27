 const r={eyes:mat.eyes,curMat,slime:SLIMES[SLIME].id,view:{...VIEW},brain:mat.brain,mood:mat.mood,brMem:mat.brMem,excite:mat.excite,tr:IMP.tr,R,W,H,sill:SILL.on,e4:mat.e4,intro:mat.intro,introSwim:mat.introSwim,limbs:mat.limbs};
 const p0=performance.now();steps(120);r.msPerFrame=(performance.now()-p0)/120;
 return r;
