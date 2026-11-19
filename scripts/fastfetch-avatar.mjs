// Draws the fastfetch avatar: a lantern-headed robot caught while it boots, its lamps
// warming to the gold of the greeting's title. Rose Pine Moon colors, transparent ground.
// Regenerate with:
//   node scripts/fastfetch-avatar.mjs | rsvg-convert -o fastfetch/.config/fastfetch/avatar.png
// The optional argument sets how far it has woken, 0 (off) to 1 (awake); the greeting uses 0.6.
const wake = Number(process.argv[2] ?? 0.6);
const P = {
  base: "#232136", surface: "#2a273f", overlay: "#393552", text: "#e0def4",
  gold: "#f6c177", rose: "#ea9a97", hlLow: "#2a283e", hlMed: "#44415a", hlHigh: "#56526e",
};
const S = 864, cx = S / 2;
// The head is still rising: lower and tilted forward while waking, level when awake.
const lift = (1 - wake) * 26;
const tilt = (1 - wake) * 4;
// Shutters over the lamps open as it wakes.
const shut = 0.55 * (1 - wake);
const glow = 0.25 + 0.75 * wake;

const eye = (x, y) => {
  const r = 46, cover = r * 2 * shut;
  return `
    <circle cx="${x}" cy="${y}" r="${r + 10}" fill="${P.hlLow}" stroke="${P.hlMed}" stroke-width="4"/>
    <circle cx="${x}" cy="${y}" r="${r}" fill="url(#lamp)" opacity="${glow}"/>
    <circle cx="${x}" cy="${y}" r="${r * 0.42}" fill="#fff6e4" opacity="${0.35 + 0.65 * wake}" filter="url(#soft)"/>
    <clipPath id="c${x}"><circle cx="${x}" cy="${y}" r="${r + 1}"/></clipPath>
    <g clip-path="url(#c${x})">
      <rect x="${x - r - 2}" y="${y - r - 2}" width="${2 * r + 4}" height="${cover + 2}" fill="${P.surface}"/>
      <rect x="${x - r - 2}" y="${y - r + cover - 3}" width="${2 * r + 4}" height="3" fill="${P.hlHigh}"/>
    </g>`;
};

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">
<defs>
  <radialGradient id="lamp" cx="50%" cy="55%" r="50%">
    <stop offset="0" stop-color="#ffe9c4"/>
    <stop offset="0.45" stop-color="${P.gold}"/>
    <stop offset="1" stop-color="#b9783a"/>
  </radialGradient>
  <radialGradient id="halo" cx="50%" cy="50%" r="50%">
    <stop offset="0" stop-color="${P.gold}" stop-opacity="${0.55 * glow}"/>
    <stop offset="1" stop-color="${P.gold}" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="headFill" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="${P.hlHigh}"/>
    <stop offset="0.18" stop-color="${P.overlay}"/>
    <stop offset="1" stop-color="${P.surface}"/>
  </linearGradient>
  <linearGradient id="bodyFill" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="${P.overlay}"/>
    <stop offset="1" stop-color="${P.base}"/>
  </linearGradient>
  <linearGradient id="warmUnder" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="${P.gold}" stop-opacity="${0.22 * glow}"/>
    <stop offset="1" stop-color="${P.gold}" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="fadeOut" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0.72" stop-color="#fff"/>
    <stop offset="1" stop-color="#000"/>
  </linearGradient>
  <mask id="vignette"><rect width="${S}" height="${S}" fill="url(#fadeOut)"/></mask>
  <clipPath id="headClip"><rect x="212" y="250" width="440" height="310" rx="64"/></clipPath>
  <filter id="soft" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="6"/></filter>
  <filter id="bloom" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="28"/></filter>
</defs>

<g mask="url(#vignette)">
  <!-- Shoulders and chest, cropped by the frame -->
  <path d="M150 864 L170 690 Q178 640 230 632 L634 632 Q686 640 694 690 L714 864 Z" fill="url(#bodyFill)" stroke="${P.hlMed}" stroke-width="4"/>
  <path d="M230 632 L634 632 Q686 640 694 690 L170 690 Q178 640 230 632 Z" fill="url(#warmUnder)"/>
  <rect x="352" y="712" width="160" height="56" rx="12" fill="${P.hlLow}" stroke="${P.hlMed}" stroke-width="3"/>
  <circle cx="392" cy="740" r="8" fill="${P.gold}" opacity="${glow}"/>
  <circle cx="392" cy="740" r="16" fill="${P.gold}" opacity="${0.35 * glow}" filter="url(#soft)"/>
  <circle cx="432" cy="740" r="8" fill="${P.hlMed}"/>
  <circle cx="472" cy="740" r="8" fill="${P.hlMed}"/>
  ${[200, 664].map((x) => `<circle cx="${x}" cy="664" r="6" fill="${P.hlHigh}"/>`).join("")}

  <!-- Neck: three ribs -->
  <g transform="translate(0 ${lift * 0.5})">
    ${[0, 1, 2].map((i) => `<rect x="${384 - i * 4}" y="${560 + i * 24}" width="${96 + i * 8}" height="20" rx="8" fill="${i % 2 ? P.hlMed : P.overlay}"/>`).join("")}
  </g>

  <!-- Head -->
  <g transform="translate(0 ${lift}) rotate(${tilt} ${cx} 560)">
    <!-- Antenna with its pilot light -->
    <rect x="${cx + 96}" y="150" width="8" height="110" rx="4" fill="${P.hlMed}"/>
    <circle cx="${cx + 100}" cy="146" r="${14 + 10 * wake}" fill="${P.rose}" opacity="${0.4 * glow}" filter="url(#soft)"/>
    <circle cx="${cx + 100}" cy="146" r="11" fill="${P.rose}" opacity="${0.3 + 0.7 * wake}"/>
    <!-- Side cans -->
    <rect x="168" y="340" width="54" height="140" rx="18" fill="${P.overlay}" stroke="${P.hlMed}" stroke-width="4"/>
    <rect x="642" y="340" width="54" height="140" rx="18" fill="${P.overlay}" stroke="${P.hlMed}" stroke-width="4"/>
    <!-- Lantern head -->
    <rect x="212" y="250" width="440" height="310" rx="64" fill="url(#headFill)" stroke="${P.hlHigh}" stroke-width="4"/>
    <!-- A dent and a patched plate -->
    <path d="M262 286 q22 10 46 2" fill="none" stroke="${P.hlLow}" stroke-width="6" stroke-linecap="round"/>
    <rect x="520" y="492" width="86" height="40" rx="6" fill="${P.hlMed}" opacity="0.7"/>
    ${[[534, 504], [592, 504], [534, 520], [592, 520]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="3.5" fill="${P.hlHigh}"/>`).join("")}
    ${[[244, 282], [620, 282], [244, 528], [620, 528]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="6" fill="${P.hlMed}"/>`).join("")}
    <!-- Mouth grille -->
    ${[0, 1, 2, 3, 4].map((i) => `<rect x="${372 + i * 26}" y="500" width="12" height="30" rx="5" fill="${P.hlLow}"/>`).join("")}
    <!-- Visor slot: dark glass, warm light spilling onto it -->
    <rect x="252" y="330" width="360" height="148" rx="74" fill="#15131f" stroke="${P.hlMed}" stroke-width="5"/>
    <ellipse cx="${cx}" cy="404" rx="210" ry="110" fill="url(#halo)" filter="url(#bloom)"/>
    ${eye(cx - 84, 404)}
    ${eye(cx + 84, 404)}
    <!-- Glass reflection -->
    <path d="M286 352 Q330 340 380 342" fill="none" stroke="${P.text}" stroke-opacity="0.22" stroke-width="7" stroke-linecap="round"/>
    <!-- Warm light falling on the lower face, kept inside the head -->
    <ellipse cx="${cx}" cy="490" rx="170" ry="40" fill="${P.gold}" opacity="${0.16 * glow}" filter="url(#bloom)" clip-path="url(#headClip)"/>
  </g>
</g>
</svg>
`;
process.stdout.write(svg);
