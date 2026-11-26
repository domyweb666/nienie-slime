# web-bench：無頭 Chrome 量網頁原型（Windows）

需要 Python 的 playwright 和本機 Chrome，腳本自己開伺服器，不用預覽伺服器。

- 只跑 selftest 其中幾項、比較參數：`python st.py <web 資料夾> --tests T65,T67 --reps 10 --procs 5 --arms '[{"pullGive":0},{}]' --out a.json`，`sum65.py a.json` 看 T65 彙整
- 前面的項目先跑完再量：加 `--warm`
- 整份 selftest 同時跑 N 次：`--full 3`（約 13 分鐘）
- 放手後的抖動（亂拉 60 組）：`cat lib.js p4.js > q4.js`，再 `--tests "" --pre q4.js --reps 60 --procs 10`；`sumr.py`、`walls.py`（黏側邊的分開看）
- 亂捏新舊比較：`python fz.py <web 資料夾>`
- 不同版本比較：`git archive <commit> prototype/web | tar -x -C <暫存資料夾>`，把 web 資料夾指過去
- 十隻猜隻代理量（v2.64 C8）：`--tests "" --pre sig.js --reps 4 --procs 4 --arms '[{},{"signature":0}]' --out sig.json`，再 `python sig.py sig.json`
- 揉的痕跡截圖（v2.64 B9 rubTrail）：`python rubshot.py <web 資料夾> <輸出資料夾> --slimes taro,honey,mint,peach`，每隻開關各截揉 3 秒、放手 0.25 秒、0.6 秒三張
- 起步跟手亂捏打結比例（v2.64 B8 startFollow）：`python b8fz.py <web 資料夾>`，40 組種子開關各跑一次，只記數字（規劃說判不出好壞）
