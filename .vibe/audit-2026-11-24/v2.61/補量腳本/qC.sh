. "$(dirname "$0")/lib.sh"; export PYTHONIOENCODING=utf-8
x(){ [ -f out/$3 ] && return; python x.py "$1" 8996 $2 out/$3 "$4" >> out/qC.log 2>&1; echo $(date +%T) $3 >> out/qC.log; }
x "$N" e2.js e2_taro.json '{"sl":[2],"cf":["def","A3","A4","A5","all","def_r0","A5_r0","all_r0"],"seeds":3}'
x "$O" e2.js e2_v260.json '{"sl":[2,1,5,7],"cf":["def"],"seeds":3}'
x "$N" e2.js e2_oth.json '{"sl":[1,5,7],"cf":["def","A3","A4","A5","all"],"seeds":2}'
x "$N" e6.js e6_taro.json '{"sl":[2],"cf":["def","A3","A4","A5","all","def_r0"],"seeds":2,"tw":[[0.5,0.3]]}'
x "$N" e6.js e6_taro00.json '{"sl":[2],"cf":["def"],"seeds":1,"tw":[[0,0]]}'
x "$O" e6.js e6_v260.json '{"sl":[2],"cf":["def"],"seeds":2,"tw":[[0.5,0.3]]}'
x "$N" e6.js e6_oth.json '{"sl":[1,5,7],"cf":["def","all"],"seeds":1,"tw":[[0.5,0.3]]}'
x "$N" e5.js e5_taro.json '{"sl":[2],"cf":["def","A3","A4","A5","all"],"seeds":2}'
x "$O" e5.js e5_v260.json '{"sl":[2],"cf":["def"],"seeds":1}'
x "$N" e5.js e5_oth.json '{"sl":[1,5,7],"cf":["def","all"],"seeds":1}'
echo QC >> out/qC.log
