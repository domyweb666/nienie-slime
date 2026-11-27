// 把設計畫布的窗景（*.dc.html）抽成網頁原型用的 SVG：只留 <svg> 那一段，洞（{{n}}、{{d}}、{{red}}、{{rib}}、{{win}}）原樣留著，由 prototype/web/windows.js 填。
// 用法：node tools/extract-windows.mjs <畫布 project 資料夾> ［輸出資料夾，預設 prototype/web/scene/win］
// 畫布檔案用 Artifact 工具 read 下來：https://claude.ai/artifact/VbfSsySMxR3YApgGyx8Ut5 的 project/*.dc.html
// 只認得下面列的標籤和屬性；畫布多用了別的就直接停，免得網頁那邊默默少畫。
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const IDS = ['Shancheng', 'Dingceng', 'Daotian', 'Tiandeng', 'Yinghua', 'Haibian', 'Yinxing', 'Xueye', 'Jingyu', 'Yueqiu', 'Yundao', 'Baobing'];
const TAGS = new Set('svg defs lineargradient radialgradient stop clippath g rect path circle ellipse use animate animatetransform'.split(' '));
const ATTRS = new Set('viewbox role aria-label style id x y x1 y1 x2 y2 cx cy r rx ry width height d offset stop-color stop-opacity fill stroke stroke-width stroke-linecap stroke-linejoin stroke-dasharray opacity transform href clip-path attributename type values keytimes keysplines calcmode dur begin from to repeatcount'.split(' '));
const [src, out = join(dirname(fileURLToPath(import.meta.url)), '..', 'prototype', 'web', 'scene', 'win')] = process.argv.slice(2);
mkdirSync(out, { recursive: true });
for (const id of IDS) {
  const m = /<svg[\s\S]*?<\/svg>/.exec(readFileSync(join(src, id + '.dc.html'), 'utf8'));
  if (!m) throw new Error(id + ' 沒有 <svg>');
  for (const t of m[0].matchAll(/<([A-Za-z]+)([^>]*)>/g)) {
    if (!TAGS.has(t[1].toLowerCase())) throw new Error(`${id}：不認得的標籤 ${t[1]}`);
    for (const a of t[2].matchAll(/([\w:-]+)="/g)) if (!ATTRS.has(a[1].toLowerCase())) throw new Error(`${id}：不認得的屬性 ${a[1]}`);
  }
  const svg = m[0].replace(/<svg[^>]*>/, '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 828">').replace(/\r/g, '').replace(/\n{2,}/g, '\n') + '\n';
  writeFileSync(join(out, id + '.svg'), svg);
  console.log(id, svg.length);
}
