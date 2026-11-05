// Renders design/mascots/svg/*.svg to PNGs with Chromium (Playwright).
//
//   node design/mascots/render.mjs                -> writes PNGs into the shared asset catalog
//   node design/mascots/render.mjs --sheet out.png -> writes a contact sheet for review
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
// Playwright is resolved from the global install (CommonJS resolution honours NODE_PATH).
const { chromium } = createRequire(import.meta.url)('playwright');
const svgDir = path.join(here, 'svg');
const repo = path.resolve(here, '..', '..');
const catalog = path.join(repo, 'Shared', 'MascotArt.xcassets');

const args = process.argv.slice(2);
const sheetIdx = args.indexOf('--sheet');

const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 1 });

async function renderSVG(svgText, size, file) {
  const html = `<html><body style="margin:0;background:transparent">
    <img id="i" src="data:image/svg+xml;base64,${Buffer.from(svgText).toString('base64')}" width="${size}" height="${size}" style="display:block"/>
  </body></html>`;
  await page.setViewportSize({ width: size, height: size });
  await page.setContent(html);
  await page.waitForFunction(() => document.getElementById('i').complete);
  await page.screenshot({ path: file, omitBackground: true, clip: { x: 0, y: 0, width: size, height: size } });
}

if (args.includes('--icons')) {
  const iconDir = path.join(here, 'icons');
  const iosSet = path.join(repo, 'App', 'Assets.xcassets', 'AppIcon.appiconset');
  const macSet = path.join(repo, 'Mac', 'Assets.xcassets', 'AppIcon.appiconset');
  fs.mkdirSync(iosSet, { recursive: true });
  fs.mkdirSync(macSet, { recursive: true });
  const light = fs.readFileSync(path.join(iconDir, 'icon_light.svg'), 'utf8');
  const dark = fs.readFileSync(path.join(iconDir, 'icon_dark.svg'), 'utf8');
  const mac = fs.readFileSync(path.join(iconDir, 'icon_mac.svg'), 'utf8');
  await renderSVG(light, 1024, path.join(iosSet, 'AppIcon.png'));
  await renderSVG(dark, 1024, path.join(iosSet, 'AppIcon-Dark.png'));
  fs.writeFileSync(
    path.join(iosSet, 'Contents.json'),
    JSON.stringify(
      {
        images: [
          { filename: 'AppIcon.png', idiom: 'universal', platform: 'ios', size: '1024x1024' },
          {
            appearances: [{ appearance: 'luminosity', value: 'dark' }],
            filename: 'AppIcon-Dark.png',
            idiom: 'universal',
            platform: 'ios',
            size: '1024x1024',
          },
        ],
        info: { author: 'xcode', version: 1 },
      },
      null,
      2,
    ) + '\n',
  );
  const images = [];
  for (const pt of [16, 32, 128, 256, 512]) {
    for (const scale of [1, 2]) {
      const px = pt * scale;
      const file = `mac_${pt}@${scale}x.png`;
      await renderSVG(mac, px, path.join(macSet, file));
      images.push({ filename: file, idiom: 'mac', scale: `${scale}x`, size: `${pt}x${pt}` });
    }
  }
  fs.writeFileSync(path.join(macSet, 'Contents.json'), JSON.stringify({ images, info: { author: 'xcode', version: 1 } }, null, 2) + '\n');
  console.log('icons rendered');
} else if (sheetIdx >= 0) {
  const out = args[sheetIdx + 1];
  const files = args.slice(sheetIdx + 2);
  const cells = files
    .map((f) => {
      const data = fs.readFileSync(f);
      const mime = f.endsWith('.png') ? 'image/png' : 'image/svg+xml';
      return `<div class="c"><img src="data:${mime};base64,${data.toString('base64')}"/><span>${path.basename(f)}</span></div>`;
    })
    .join('');
  const cols = Math.min(files.length, Number(process.env.COLS || 7));
  const w = Number(process.env.W || 220);
  const html = `<html><body style="margin:0;background:#FBF8F4;font:12px -apple-system,Helvetica;--w:${w}px">
    <style>.g{display:grid;grid-template-columns:repeat(${cols},var(--w,220px));gap:8px;padding:12px}
    .c{display:flex;flex-direction:column;align-items:center}.c img{width:var(--w,220px);height:var(--w,220px);object-fit:contain}</style>
    <div class="g">${cells}</div></body></html>`;
  const rows = Math.ceil(files.length / cols);
  await page.setViewportSize({ width: cols * (w + 8) + 24, height: rows * (w + 30) + 24 });
  await page.setContent(html);
  await page.waitForTimeout(200);
  await page.screenshot({ path: out, fullPage: true });
  console.log('sheet ->', out);
} else {
  const svgs = fs.readdirSync(svgDir).filter((f) => f.endsWith('.svg') && !f.includes('_preview'));
  for (const f of svgs) {
    const name = f.replace('.svg', '');
    const isAvatar = name.endsWith('_avatar');
    const size = isAvatar ? 240 : 768;
    const setDir = path.join(catalog, `${name}.imageset`);
    fs.mkdirSync(setDir, { recursive: true });
    await renderSVG(fs.readFileSync(path.join(svgDir, f), 'utf8'), size, path.join(setDir, `${name}.png`));
    fs.writeFileSync(
      path.join(setDir, 'Contents.json'),
      JSON.stringify(
        { images: [{ filename: `${name}.png`, idiom: 'universal' }], info: { author: 'xcode', version: 1 } },
        null,
        2,
      ) + '\n',
    );
  }
  fs.writeFileSync(path.join(catalog, 'Contents.json'), JSON.stringify({ info: { author: 'xcode', version: 1 } }, null, 2) + '\n');
  console.log(`rendered ${svgs.length} images into ${catalog}`);
}
await browser.close();
