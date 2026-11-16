// Generates the app icon without any image library: a dark gradient square
// with a terminal prompt mark (">_" ), written as a PNG through node:zlib.
// Usage: node tools/make-icon.mjs [size]
import zlib from 'node:zlib';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const size = Number(process.argv[2] || 1024);
const here = path.dirname(fileURLToPath(import.meta.url));
const out = path.join(here, '..', 'App', 'Assets.xcassets', 'AppIcon.appiconset', 'AppIcon-1024.png');

const px = Buffer.alloc(size * size * 4);

const lerp = (a, b, t) => a + (b - a) * t;
const smooth = (edge0, edge1, x) => {
  const t = Math.min(1, Math.max(0, (x - edge0) / (edge1 - edge0)));
  return t * t * (3 - 2 * t);
};
// distance from point to a segment
function segmentDistance(px_, py, ax, ay, bx, by) {
  const vx = bx - ax;
  const vy = by - ay;
  const wx = px_ - ax;
  const wy = py - ay;
  const len = vx * vx + vy * vy;
  const t = len === 0 ? 0 : Math.min(1, Math.max(0, (wx * vx + wy * vy) / len));
  const dx = px_ - (ax + vx * t);
  const dy = py - (ay + vy * t);
  return Math.sqrt(dx * dx + dy * dy);
}

const s = size / 1024;
const chevron = [
  [300 * s, 360 * s, 470 * s, 512 * s],
  [470 * s, 512 * s, 300 * s, 664 * s],
];
const underscore = [520 * s, 664 * s, 720 * s, 664 * s];
const stroke = 46 * s;

for (let y = 0; y < size; y += 1) {
  for (let x = 0; x < size; x += 1) {
    const t = (x / size) * 0.55 + (y / size) * 0.45;
    let r = lerp(24, 74, t);
    let g = lerp(30, 58, t);
    let b = lerp(52, 152, t);

    // soft radial highlight in the top-left
    const dx = x / size - 0.22;
    const dy = y / size - 0.18;
    const glow = Math.max(0, 1 - Math.sqrt(dx * dx + dy * dy) / 0.55);
    r += 30 * glow;
    g += 34 * glow;
    b += 60 * glow;

    let alpha = 255;

    // mark
    let d = Infinity;
    for (const [ax, ay, bx, by] of chevron) d = Math.min(d, segmentDistance(x, y, ax, ay, bx, by));
    d = Math.min(d, segmentDistance(x, y, underscore[0], underscore[1], underscore[2], underscore[3]));
    const coverage = 1 - smooth(stroke - 1.5 * s, stroke + 1.5 * s, d);
    if (coverage > 0) {
      r = lerp(r, 255, coverage);
      g = lerp(g, 255, coverage);
      b = lerp(b, 255, coverage);
    }

    const i = (y * size + x) * 4;
    px[i] = Math.round(r);
    px[i + 1] = Math.round(g);
    px[i + 2] = Math.round(b);
    px[i + 3] = alpha;
  }
}

// PNG encode: filter byte 0 per scanline, RGBA8
const raw = Buffer.alloc((size * 4 + 1) * size);
for (let y = 0; y < size; y += 1) {
  raw[y * (size * 4 + 1)] = 0;
  px.copy(raw, y * (size * 4 + 1) + 1, y * size * 4, (y + 1) * size * 4);
}

const crcTable = new Int32Array(256);
for (let n = 0; n < 256; n += 1) {
  let c = n;
  for (let k = 0; k < 8; k += 1) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  crcTable[n] = c;
}
const crc32 = (buf) => {
  let c = 0xffffffff;
  for (const byte of buf) c = crcTable[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};
const chunk = (type, data) => {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
};

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(size, 0);
ihdr.writeUInt32BE(size, 4);
ihdr[8] = 8; // bit depth
ihdr[9] = 6; // RGBA
const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk('IHDR', ihdr),
  chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
  chunk('IEND', Buffer.alloc(0)),
]);

fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, png);
console.log(`wrote ${out} (${size}×${size}, ${(png.length / 1024).toFixed(1)} KB)`);
