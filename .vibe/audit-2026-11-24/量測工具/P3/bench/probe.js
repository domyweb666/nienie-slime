(async()=>{window.requestAnimationFrame=()=>0;await new Promise(r=>setTimeout(r,80));
IMPSV.noSave=true;WALK.noSave=true;
return {R,W,H,N,mat:{brain:mat.brain,mood:mat.mood,eyes:mat.eyes,brMem:mat.brMem,strokeV:mat.strokeV,rubSpeed:mat.rubSpeed,sill:mat.sill,deco:mat.deco,decoReal:mat.decoReal,life2:mat.life2,flinchAmp:mat.flinchAmp,jellyT:mat.jellyT,breathT:mat.breathT,sleepAfter:mat.sleepAfter},SLIME:SLIMES[SLIME].name,view:VIEW,camz:CAM.z}})()
