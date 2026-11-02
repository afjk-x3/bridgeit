// The one BridgeIt bridge, as board markup for every state.
const fs = require('node:fs');

const C = {
  navy: '#183870', teal: '#309090', light: '#80C0A8', orange: '#D88858', sky: '#E6F5FF',
  deck: '#5B6472', deckTop: '#8A93A0', stone: '#6F7F9E', water: '#56B9D6', white: '#FFFFFF',
  car: '#3A8FDB', hair: '#5A3825', skin: '#F4C7A1', right: '#22C55E', note: '#FFF6EC',
};
const ALLOWED = Object.values(C).map((c) => c.toUpperCase());

// Sentence piers stand under the deck span, clear of the tower footings.
const PIER_X = { 1: 122, 2: 268 };
const NOR_X = 195;

function car(x, y, scale = 1) {
  return `<g transform="translate(${x} ${y}) scale(${scale})" stroke="${C.navy}" stroke-width="2.5">
      <path d="M2 22 Q0 14 8 13 L18 4 Q20 2 24 2 H42 Q46 2 49 5 L56 13 Q63 14 63 22 V25 H2Z" fill="${C.car}"></path>
      <path d="M20 6 H31 V13 H13Z M34 6 H44 L51 13 H34Z" fill="${C.sky}" stroke-width="2"></path>
      <g stroke="${C.navy}" stroke-width="0.6"><path d="M35.5 13.5 Q36 10.6 40 10.6 Q44 10.6 44.5 13.5Z" fill="${C.teal}"></path><circle cx="40" cy="8.6" r="3.2" fill="${C.hair}"></circle><circle cx="40.6" cy="8.9" r="2.4" fill="${C.skin}"></circle></g>
      <circle cx="15" cy="26" r="6" fill="${C.navy}"></circle><circle cx="50" cy="26" r="6" fill="${C.navy}"></circle>
    </g>`;
}

// Two lines at most: about 17 characters of 15 px bold fit in a 150 px slab.
function wrap(text, max = 17) {
  const lines = [''];
  for (const word of text.split(' ')) {
    const line = lines[lines.length - 1];
    if (line && (line + ' ' + word).length > max && lines.length < 2) lines.push(word);
    else lines[lines.length - 1] = line ? `${line} ${word}` : word;
  }
  return lines;
}

function clause(text, cx) {
  const lines = wrap(text);
  const top = 147 - (lines.length - 1) * 9 + 5;
  return lines
    .map((l, i) => `<text x="${cx}" y="${top + i * 18}" font-size="15" fill="${C.white}">${l}</text>`)
    .join('');
}

function pier(n, word, cx, h, width = 48) {
  const tag = word ? `${n} · ${word}` : '';
  const plaque = Math.max(width, tag.length * 7.8 + 12);
  return `<rect data-pier="${n}" x="${cx - width / 2}" y="194" width="${width}" height="${h - 194}" fill="${C.stone}" stroke="${C.navy}" stroke-width="3"></rect>${
    tag
      ? `<rect x="${cx - plaque / 2}" y="200" width="${plaque}" height="20" rx="4" fill="${C.navy}"></rect><text x="${cx}" y="215" font-size="13" fill="${C.white}">${tag}</text>`
      : ''
  }`;
}

// Zig-zags above and below the joint; half length once one pier is in.
function wobble(half) {
  const len = half ? 3 : 6;
  const zig = (x, y) => {
    let d = `M${x} ${y}`;
    for (let i = 1; i <= len; i++) d += ` l4 ${i % 2 ? -4 : 4}`;
    return d;
  };
  const d = [zig(132, 102), zig(236, 102), zig(132, 204), zig(236, 204)].join(' ');
  return `<g id="wobble" fill="none" stroke="${C.navy}" stroke-width="2" stroke-linecap="round"><path d="${d}"></path></g>${
    half ? `<text x="282" y="104" font-size="14" fill="${C.navy}">½</text>` : ''
  }`;
}

function low(opts) {
  const at = { left: 16, middle: 160, right: 300 }[opts.car];
  return `<svg aria-hidden="true" width="390" height="210" viewBox="0 0 390 210">
    <path d="M0 150 Q90 120 180 140 Q270 116 390 138 V180 H0Z" fill="${C.light}" stroke="${C.navy}" stroke-width="2"></path>
    <rect y="168" width="390" height="42" fill="${C.water}"></rect>
    <path d="M93 22 Q195 104 297 22 M93 22 Q50 70 0 90 M297 22 Q340 70 390 90" fill="none" stroke="${C.navy}" stroke-width="3"></path>
    <path d="M120 52 V104 M146 72 V104 M172 84 V104 M218 84 V104 M244 72 V104 M270 52 V104 M40 72 V104 M350 72 V104" stroke="${C.navy}" stroke-width="1.5"></path>
    <path d="M0 104 H390" stroke="${C.navy}" stroke-width="3"></path>
    <rect x="135" y="136" width="30" height="62" fill="${C.stone}" stroke="${C.navy}" stroke-width="3"></rect>
    <rect x="225" y="136" width="30" height="62" fill="${C.stone}" stroke="${C.navy}" stroke-width="3"></rect>
    <rect y="110" width="390" height="14" fill="${C.deckTop}" stroke="${C.navy}" stroke-width="3"></rect>
    <rect y="124" width="390" height="12" fill="${C.deck}" stroke="${C.navy}" stroke-width="2"></rect>
    <rect x="80" y="18" width="26" height="150" fill="${C.orange}" stroke="${C.navy}" stroke-width="3"></rect>
    <rect x="284" y="18" width="26" height="150" fill="${C.orange}" stroke="${C.navy}" stroke-width="3"></rect>
    <path d="M80 44 L106 70 M106 44 L80 70 M284 44 L310 70 M310 44 L284 70" stroke="${C.navy}" stroke-width="2"></path>
    <rect x="76" y="14" width="34" height="7" fill="${C.navy}"></rect>
    <rect x="280" y="14" width="34" height="7" fill="${C.navy}"></rect>
    ${at === undefined ? '' : car(at, 80)}
  </svg>`;
}

function full(opts) {
  const H = 232;
  const broken = opts.state === 'broken';
  const finished = opts.state === 'finished';
  const deck = broken
    ? `<path d="M0 118 H150 L144 134 L152 150 L144 166 L150 176 H0Z M390 118 H240 L246 134 L238 150 L246 166 L240 176 H390Z" fill="${C.deck}" stroke="${C.navy}" stroke-width="2"></path>
      <path d="M0 176 H150 L146 194 H0Z M240 176 L244 194 H390 V176Z" fill="${C.deck}" stroke="${C.navy}" stroke-width="2"></path>
      <g fill="${C.deck}" stroke="${C.navy}" stroke-width="2"><path d="M168 204 l14 -4 l4 10 l-14 4Z"></path><path d="M206 214 l12 2 l-2 10 l-12 -2Z"></path></g>
      <path d="M160 226 q10 -10 20 0 M200 230 q10 -10 20 0" fill="none" stroke="${C.white}" stroke-width="3" stroke-linecap="round"></path>`
    : `<rect x="0" y="118" width="390" height="58" fill="${C.deck}" stroke="${C.navy}" stroke-width="2"></rect>
      <path d="M0 176 H390 V194 H0Z" fill="${C.deck}" stroke="${C.navy}" stroke-width="2"></path>`;
  const cable = broken
    ? `M72 10 Q120 100 150 108 M318 10 Q270 100 240 108`
    : `M72 10 Q195 112 318 10`;
  const piers = (() => {
    if (finished) return pier(1, '', PIER_X[1], H) + pier(2, '', PIER_X[2], H);
    if (opts.state === 'nor') return pier(1, opts.piers[0].word, NOR_X, H, 64);
    return (opts.piers || []).map((p) => pier(p.n, p.word, PIER_X[p.n], H)).join('');
  })();
  const shake = opts.state === 'shaking' ? wobble(false) : opts.state === 'onePier' ? wobble(true) : '';
  const cracks = opts.state === 'shaking'
    ? `<path d="M144 120 l-6 10 l5 6 M246 120 l6 10 l-5 6" fill="none" stroke="${C.navy}" stroke-width="2"></path>`
    : '';
  const at = { left: 6, middle: 150, right: 300 }[opts.car];
  const label = opts.state === 'finished'
    ? 'The finished bridge'
    : `${opts.left}, ${opts.piece && opts.piece.tone === 'right' ? opts.piece.text.slice(2) : '_____'} ${opts.right}`;
  const svg = `<svg role="img" aria-label="${label}" style="position: absolute; left: 0; top: 0" width="390" height="${H}" viewBox="0 0 390 ${H}">
    <g fill="${C.white}"><ellipse cx="190" cy="30" rx="28" ry="9"></ellipse><ellipse cx="206" cy="24" rx="16" ry="8"></ellipse></g>
    <path d="M0 170 Q80 140 160 160 Q240 136 320 158 Q360 146 390 160 V200 H0Z" fill="${C.light}" stroke="${C.navy}" stroke-width="2"></path>
    <rect y="196" width="390" height="${H - 196}" fill="${C.water}"></rect>
    <path d="M0 96 H30 L38 ${H} H0Z M390 96 H360 L352 ${H} H390Z" fill="${C.stone}" stroke="${C.navy}" stroke-width="3"></path>
    <path d="M0 92 H32 V100 H0Z M390 92 H358 V100 H390Z" fill="${C.light}" stroke="${C.navy}" stroke-width="2"></path>
    <path d="${cable} M72 10 Q40 70 0 92 M318 10 Q350 70 390 92" fill="none" stroke="${C.navy}" stroke-width="3"></path>
    <path d="M96 28 V118 M116 40 V118 M136 49 V118 M254 49 V118 M274 40 V118 M294 28 V118 M40 64 V118 M350 64 V118" stroke="${C.navy}" stroke-width="1.5"></path>
    <path d="${broken ? 'M0 108 H150 M240 108 H390' : 'M0 108 H390'}" stroke="${C.navy}" stroke-width="3"></path>
    <rect x="58" y="6" width="28" height="190" fill="${C.orange}" stroke="${C.navy}" stroke-width="3"></rect>
    <rect x="304" y="6" width="28" height="190" fill="${C.orange}" stroke="${C.navy}" stroke-width="3"></rect>
    <path d="M58 40 L86 70 M86 40 L58 70 M304 40 L332 70 M332 40 L304 70" stroke="${C.navy}" stroke-width="2"></path>
    <rect x="54" y="2" width="36" height="8" fill="${C.navy}"></rect>
    <rect x="300" y="2" width="36" height="8" fill="${C.navy}"></rect>
    ${deck}
    <rect x="50" y="194" width="44" height="${H - 194}" fill="${C.stone}" stroke="${C.navy}" stroke-width="3"></rect>
    <rect x="296" y="194" width="44" height="${H - 194}" fill="${C.stone}" stroke="${C.navy}" stroke-width="3"></rect>
    ${piers}
    ${cracks}${shake}
    ${opts.left ? clause(opts.left, 75) + clause(opts.right, 315) : ''}
    ${at === undefined ? '' : car(at, 79, 1.3)}
  </svg>`;
  return svg.replace(/(<text )/g, '$1font-family="Nunito, sans-serif" font-weight="800" text-anchor="middle" ');
}

function piece(p) {
  if (!p) return '';
  const base = 'position: absolute; left: 155px; top: 122px; width: 80px; height: 50px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-family: \'Nunito\', sans-serif; font-weight: 800; font-size: 19px;';
  if (p.tone === 'none') {
    return `<button type="button" aria-label="Gap in the bridge" style="${base} border: 3px dashed ${C.navy}; background: ${C.white}; color: ${C.navy}">?</button>`;
  }
  const look = p.tone === 'wrong'
    ? `border: 3px solid ${C.orange}; background: ${C.note}; color: ${C.navy}; transform: rotate(-5deg)`
    : `border: 3px solid ${C.right}; background: ${C.white}; color: ${C.navy}`;
  return `<div style="${base} ${look}">${p.text}</div>`;
}

function caption(lines) {
  if (!lines) return '';
  return `<ol style="margin: 0; padding: 6px 12px; list-style: none; background: ${C.navy}; color: ${C.white}; font-size: 14px; font-weight: 700; line-height: 1.3; display: flex; flex-direction: column; gap: 2px">${lines
    .map((l, i) => `<li><b style="color: ${C.light}">${i + 1}</b>&nbsp; ${l}</li>`)
    .join('')}</ol>`;
}

/** The bridge block for one board: the drawing, the piece and the caption. */
function bridgeSvg(opts) {
  if (opts.low) return low(opts);
  return `<div style="position: relative; height: 232px">${full(opts)}${piece(opts.piece)}</div>${caption(opts.caption)}`;
}

/** Rewrites only the text between the bridge markers in [file]. */
function rebuild(file, opts) {
  const text = fs.readFileSync(file, 'utf8');
  const re = /<!-- bridge -->[\s\S]*?<!-- \/bridge -->/;
  if (!re.test(text)) throw new Error(`no bridge markers in ${file}`);
  fs.writeFileSync(file, text.replace(re, () => `<!-- bridge -->${bridgeSvg(opts)}<!-- /bridge -->`));
}

module.exports = { bridgeSvg, rebuild, ALLOWED, C };
