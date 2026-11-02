// Writes the finished-bridge art from bridge.js, the source of the
// Wireframes v3 Bridge sheet. Run from the repo root:
//   node tool/bridge_art/make_assets.js
const fs = require('node:fs');
const path = require('node:path');
const { bridgeSvg } = require('./bridge');

const scenes = path.join(__dirname, '..', '..', 'assets', 'images', 'scenes');

// The low bridge as a standalone SVG file (flutter_svg needs the namespace).
function strip(car) {
  return bridgeSvg({ state: 'finished', low: true, car })
    .replace(
      /^<svg aria-hidden="true" width="390" height="210" viewBox="0 0 390 210">/,
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 390 210">',
    )
    .trim() + '\n';
}

fs.writeFileSync(path.join(scenes, 'bridge_strip.svg'), strip('middle'));
fs.writeFileSync(path.join(scenes, 'bridge_strip_crossed.svg'), strip('right'));

