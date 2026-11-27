. "$(dirname "$0")/lib.sh"; PORT=8995
run c_mix.json m_def1 '{}' "$N" 4
run c_mix.json m_w1_1 '{}' "$W1" 4
run c_mix.json m_def2 '{}' "$N" 4
run c_mix.json m_w1_2 '{}' "$W1" 4
run c_mix.json m_def3 '{}' "$N" 4
run c_mix.json m_A5 "$A5" "$N" 4
run c_mix.json m_v260 '{}' "$O" 4
run c_mix.json m_all "$ALL" "$N" 4
run c_mix.json m_A3 "$A3" "$N" 4
run c_mix.json m_A4 "$A4" "$N" 4
run c_mix1000.json ms1_def '{}' "$N" 4
run c_mix1000.json ms1_w1 '{}' "$W1" 4
echo QG >> out/q.log
