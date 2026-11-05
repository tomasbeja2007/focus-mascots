// Turns raw 6.9" simulator captures into App Store screenshots (1320 x 2868)
// with a headline, the screen in a rounded frame and a mascot.
//
//   node design/appstore/frame.mjs <dir with raw captures> <output dir>
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');
const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '..', '..');
const art = path.join(repo, 'Shared', 'MascotArt.xcassets');

const [, , rawDir, outDir] = process.argv;
if (!rawDir || !outDir) {
  console.error('usage: node frame.mjs <raw dir> <out dir>');
  process.exit(1);
}
fs.mkdirSync(outDir, { recursive: true });

const tints = {
  orbit: ['#DCE8F6', '#B9CFEC', '#3F74C9'],
  spark: ['#FDEBD3', '#F8D3A6', '#EC8327'],
  leaf: ['#E7F0DE', '#CFE0BF', '#5A8F4C'],
  pebble: ['#E6EAF0', '#CDD5E1', '#566377'],
  blob: ['#EDE8F9', '#D8CFF2', '#7562CC'],
};

const slides = [
  { file: 'ob-welcome', title: 'Meet your<br>Focus Crew', sub: 'Five tiny companions that help you put the phone down', mascot: 'spark', mood: 'happy' },
  { file: 'home', title: 'Focus with<br>a friend', sub: 'Pick a time, block distractions and go', mascot: 'orbit', mood: 'happy' },
  { file: 'session', title: 'Distractions<br>stay locked', sub: 'Blocked apps stay closed until your session ends', mascot: 'pebble', mood: 'focused' },
  { file: 'live-activity', title: 'Right on your<br>Lock Screen', sub: 'Live timer in the Dynamic Island, with your companion', mascot: 'orbit', mood: 'focused' },
  { file: 'blocks', title: 'Schedules that<br>run themselves', sub: 'Work, study and bedtime blocks, even when the app is closed', mascot: 'leaf', mood: 'sleepy' },
  { file: 'insights', title: 'Watch your<br>focus grow', sub: 'Streaks, weekly charts and your real screen time', mascot: 'blob', mood: 'happy' },
  { file: 'crew', title: 'Five friends,<br>one goal', sub: 'Grow your bond with every focused minute', mascot: 'spark', mood: 'excited' },
  { file: 'widgets', title: 'Widgets for<br>every screen', sub: 'Home Screen, Lock Screen and Control Center', mascot: 'blob', mood: 'excited' },
];

const dataURL = (p) => `data:image/png;base64,${fs.readFileSync(p).toString('base64')}`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1320, height: 2868 }, deviceScaleFactor: 1 });

let n = 0;
for (const s of slides) {
  const raw = path.join(rawDir, `${s.file}.png`);
  if (!fs.existsSync(raw)) {
    console.warn('missing', raw);
    continue;
  }
  n += 1;
  const [c1, c2, accent] = tints[s.mascot];
  const mascotPNG = path.join(art, `${s.mascot}_${s.mood}.imageset`, `${s.mascot}_${s.mood}.png`);
  const html = `<!doctype html><html><head>
  <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&display=block" rel="stylesheet">
  <style>
    html,body{margin:0;width:1320px;height:2868px;overflow:hidden}
    body{background:linear-gradient(170deg, ${c1} 0%, ${c2} 100%);font-family:'Nunito',sans-serif;position:relative}
    .blob{position:absolute;border-radius:50%;background:rgba(255,255,255,.35)}
    h1{position:absolute;top:150px;left:110px;right:110px;margin:0;font-size:132px;line-height:1.02;font-weight:900;color:#1E1F24;letter-spacing:-2px}
    p{position:absolute;top:455px;left:112px;right:410px;margin:0;font-size:52px;line-height:1.25;font-weight:700;color:rgba(30,31,36,.62)}
    .phone{position:absolute;top:700px;left:50%;transform:translateX(-50%);width:1000px;height:2174px;border-radius:118px;background:#111;padding:22px;box-sizing:border-box;box-shadow:0 60px 120px rgba(20,30,60,.28), 0 0 0 4px rgba(0,0,0,.05)}
    .phone img{width:100%;height:100%;border-radius:98px;display:block;object-fit:cover}
    .mascot{position:absolute;top:330px;right:40px;width:330px;height:330px}
    .accent{position:absolute;left:112px;top:118px;width:90px;height:12px;border-radius:6px;background:${accent}}
  </style></head><body>
    <div class="blob" style="width:900px;height:900px;left:-300px;top:1500px"></div>
    <div class="blob" style="width:600px;height:600px;right:-200px;top:-150px"></div>
    <div class="accent"></div>
    <h1>${s.title}</h1>
    <p>${s.sub}</p>
    <img class="mascot" src="${dataURL(mascotPNG)}">
    <div class="phone"><img src="${dataURL(raw)}"></div>
  </body></html>`;
  await page.setContent(html, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  const out = path.join(outDir, `${String(n).padStart(2, '0')}-${s.file}.png`);
  await page.screenshot({ path: out });
  console.log('framed', out);
}
await browser.close();
