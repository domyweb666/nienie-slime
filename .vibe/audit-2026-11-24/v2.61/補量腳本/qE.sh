. "$(dirname "$0")/lib.sh"; export PYTHONIOENCODING=utf-8
x(){ [ -f out/$3 ] && return; python x.py "$1" $5 $2 out/$3 "$4" >> out/qE.log 2>&1; }
x "$N" e6b.js e6b_def.json '{"sl":[2],"cf":["def"],"seeds":3,"tw":[[0.5,0.3],[0,0]]}' 8995 &
x "$N" e6b.js e6b_r0A5.json '{"sl":[2],"cf":["def_r0","A5"],"seeds":3,"tw":[[0.5,0.3]]}' 8996 &
x "$O" e6b.js e6b_v260.json '{"sl":[2],"cf":["def"],"seeds":3,"tw":[[0.5,0.3]]}' 8997 &
x "$N" e6b.js e6b_A34all.json '{"sl":[2],"cf":["A3","A4","all"],"seeds":2,"tw":[[0.5,0.3]]}' 8998 &
wait
x "$N" e5b.js e5b_def.json '{"sl":[2],"cf":["def"],"seeds":2}' 8995 &
x "$N" e5b.js e5b_A4.json '{"sl":[2],"cf":["A4","all"],"seeds":1}' 8996 &
x "$O" e5b.js e5b_v260.json '{"sl":[2],"cf":["def"],"seeds":1}' 8997 &
wait; echo QE >> out/q.log
