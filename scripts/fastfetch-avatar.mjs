// Regenerate (requires rsvg-convert):
//   node scripts/fastfetch-avatar.mjs > fastfetch/.config/fastfetch/avatar.png
// Optional wake level: 0 (off) to 1 (awake), default 0.6.
import { execFileSync } from "node:child_process";

const wake = Number(process.argv[2] ?? 0.6);
const P = {
  base: "#232136", surface: "#2a273f", overlay: "#393552", text: "#e0def4",
  gold: "#f6c177", rose: "#ea9a97", hlLow: "#2a283e", hlMed: "#44415a", hlHigh: "#56526e",
};
const size = 864;
const glow = 0.25 + 0.75 * wake;

const lens = (cx, rotation) => `
  <g transform="translate(${cx} 0) rotate(${rotation})">
    <path d="M-105 -25 Q-98 -87 -37 -98 L48 -91 Q98 -85 106 -39 L98 36 Q90 76 49 80 L-40 77 Q-100 69 -105 12 Z"
      fill="url(#metal)" stroke="${P.hlHigh}" stroke-width="6"/>
    <path d="M-88 -22 Q-81 -69 -35 -77 L42 -73 Q79 -68 85 -33 L78 28 Q72 56 44 59 L-39 57 Q-84 49 -88 9 Z"
      fill="#15131f" stroke="${P.base}" stroke-width="5"/>
    <circle cy="-6" r="57" fill="${P.hlLow}" stroke="${P.hlMed}" stroke-width="5"/>
    <circle cy="-6" r="45" fill="url(#lamp)" opacity="${glow}"/>
    <circle cy="-6" r="23" fill="${P.base}"/>
    <ellipse cx="-14" cy="-22" rx="13" ry="9" transform="rotate(-28 -14 -22)" fill="#fff6e4" opacity="${glow}"/>
    <circle cx="16" cy="10" r="5" fill="${P.gold}" opacity="${glow}"/>
    <path d="M-73 -41 Q-65 -57 -48 -61" fill="none" stroke="${P.text}" stroke-opacity="0.28" stroke-width="5" stroke-linecap="round"/>
  </g>`;

const track = (x) => `
  <g transform="translate(${x} 0)">
    <path d="M49 501 H88 Q109 501 119 538 L155 653 Q173 722 104 737 H40 Q-28 730 -12 672 L22 533 Q30 501 49 501 Z"
      fill="${P.base}" stroke="${P.hlHigh}" stroke-width="6"/>
    <path d="M56 519 H83 Q99 519 108 551 L139 656 Q154 703 106 717 H44 Q-4 711 8 672 L39 551 Q46 519 56 519 Z"
      fill="${P.overlay}" stroke="${P.hlMed}" stroke-width="5"/>
    ${[[70, 562, 17], [58, 606, 21], [42, 664, 27], [103, 664, 27]].map(([cx, cy, r]) => `
      <circle cx="${cx}" cy="${cy}" r="${r}" fill="${P.base}" stroke="${P.hlHigh}" stroke-width="4"/>
      <circle cx="${cx}" cy="${cy}" r="${r * 0.4}" fill="${P.hlMed}"/>`).join("")}
    <path d="M30 530 h15 M18 570 h15 M8 610 h15 M-2 651 h15 M-13 692 l18 -2 M12 725 l10 -13 M48 737 v-18 M88 737 v-18 M124 729 l-7 -16 M151 706 l-12 -9"
      fill="none" stroke="${P.hlHigh}" stroke-width="5" stroke-linecap="round"/>
  </g>`;

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
<title>WALL-E</title>
<defs>
  <radialGradient id="lamp" cx="40%" cy="32%" r="65%">
    <stop stop-color="#ffe9c4"/>
    <stop offset="0.48" stop-color="${P.gold}"/>
    <stop offset="1" stop-color="#b9783a"/>
  </radialGradient>
  <linearGradient id="metal" x2="0" y2="1">
    <stop stop-color="${P.hlHigh}"/>
    <stop offset="0.48" stop-color="${P.overlay}"/>
    <stop offset="1" stop-color="${P.surface}"/>
  </linearGradient>
  <linearGradient id="paint" x2="0" y2="1">
    <stop stop-color="${P.gold}"/>
    <stop offset="1" stop-color="#b9783a"/>
  </linearGradient>
  <radialGradient id="shadow">
    <stop stop-color="${P.base}" stop-opacity="0.8"/>
    <stop offset="1" stop-color="${P.base}" stop-opacity="0"/>
  </radialGradient>
</defs>

<ellipse cx="432" cy="724" rx="347" ry="53" fill="url(#shadow)"/>
${track(137)}
${track(589)}

<!-- Wall-E's boxy compactor and the inset front door. -->
<g stroke="${P.base}" stroke-width="7" stroke-linejoin="round">
  <path d="M266 501 L314 446 H577 L615 501 L587 541 H303 Z" fill="${P.gold}"/>
  <path d="M266 501 H615 V674 Q615 686 603 686 H279 Q266 686 266 673 Z" fill="url(#paint)"/>
  <rect x="296" y="521" width="288" height="119" rx="11" fill="${P.overlay}"/>
  <path d="M319 544 H561 V598 L538 618 H342 L319 598 Z" fill="url(#metal)"/>
</g>
<path d="M335 555 H545 M342 600 H538" fill="none" stroke="${P.hlHigh}" stroke-width="4" stroke-linecap="round"/>
<rect x="317" y="648" width="247" height="25" rx="6" fill="${P.base}"/>
<text x="328" y="666" font-family="sans-serif" font-weight="bold" font-size="17" letter-spacing="3" fill="${P.text}">WALL<tspan fill="${P.rose}">·E</tspan></text>
<path d="M514 660 h5 m6 0 h5 m6 0 h5 m6 0 h5" stroke="${P.gold}" stroke-width="4" stroke-linecap="round" opacity="${glow}"/>

<!-- Hinged arms and two-finger grippers. -->
<g stroke-linecap="round" stroke-linejoin="round">
  <path d="M272 501 L235 541 L213 590 M607 505 L649 548 L671 590" fill="none" stroke="${P.base}" stroke-width="39"/>
  <path d="M272 501 L235 541 L213 590 M607 505 L649 548 L671 590" fill="none" stroke="url(#paint)" stroke-width="25"/>
  <path d="M214 583 L179 591 L171 622 L195 635 L199 611 L218 609 L222 632 L245 622 L239 592 Z M671 583 L646 592 L640 622 L663 632 L667 609 L686 611 L690 635 L714 622 L706 591 Z"
    fill="url(#metal)" stroke="${P.hlHigh}" stroke-width="5"/>
  <circle cx="235" cy="541" r="9" fill="${P.hlMed}"/>
  <circle cx="649" cy="548" r="9" fill="${P.hlMed}"/>
</g>

<!-- Tall articulated neck and separate binocular housings. -->
<ellipse cx="432" cy="465" rx="62" ry="16" fill="${P.hlMed}" stroke="${P.base}" stroke-width="5"/>
<path d="M411 458 L393 395 L418 ${240 + (1 - wake) * 30} H458 L436 395 L454 460 Z"
  fill="url(#metal)" stroke="${P.hlHigh}" stroke-width="6" stroke-linejoin="round"/>
<circle cx="416" cy="395" r="15" fill="${P.base}" stroke="${P.hlHigh}" stroke-width="5"/>
<circle cx="416" cy="395" r="5" fill="${P.gold}"/>
<g transform="translate(432 ${233 + (1 - wake) * 30}) rotate(${-3 - (1 - wake) * 6})">
  <rect x="-63" y="-31" width="126" height="58" rx="18" fill="${P.base}" stroke="${P.hlHigh}" stroke-width="6"/>
  ${lens(-121, -9)}
  ${lens(121, 9)}
</g>
</svg>
`;

execFileSync("rsvg-convert", { input: svg, stdio: ["pipe", "inherit", "inherit"] });
