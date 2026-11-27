. "$(dirname "$0")/lib.sh"; export PYTHONIOENCODING=utf-8; PORT=8997
run c_rnd.json rd_all_2 "$ALL" "$N" 3
run c_rnd.json rd_A5_2 "$A5" "$N" 3
run c_rnd.json rd_v260_2 "{}" "$O" 3
x(){ [ -f out/$3 ] && return; python x.py "$1" $5 $2 out/$3 "$4" >> out/qE.log 2>&1; }
x "$N" e6b.js e6b_def.json '{"sl":[2],"cf":["def"],"seeds":3,"tw":[[0.5,0.3],[0,0]]}' 8995 &
x "$N" e6b.js e6b_r0A5.json '{"sl":[2],"cf":["def_r0","A5"],"seeds":3,"tw":[[0.5,0.3]]}' 8997 &
x "$O" e6b.js e6b_v260.json '{"sl":[2],"cf":["def"],"seeds":3,"tw":[[0.5,0.3]]}' 8999 &
wait
x "$N" e6b.js e6b_A34all.json '{"sl":[2],"cf":["A3","A4","all"],"seeds":2,"tw":[[0.5,0.3]]}' 8995 &
x "$N" e5b.js e5b_def.json '{"sl":[2],"cf":["def"],"seeds":2}' 8997 &
x "$O" e5b.js e5b_v260.json '{"sl":[2],"cf":["def"],"seeds":1}' 8999 &
wait
x "$N" e5b.js e5b_A4.json '{"sl":[2],"cf":["A4","all"],"seeds":1}' 8995
echo QF >> out/q.log
