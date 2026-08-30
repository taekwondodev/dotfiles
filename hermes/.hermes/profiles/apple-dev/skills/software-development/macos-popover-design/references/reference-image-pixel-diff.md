# Grounding grilling with pixel diffs of reference screenshots

When the user drops a "current" and a "desired/reference" screenshot of the same popover
(or same window, same dimensions) and describes a small layout complaint ("the scrollbar is
too close to the cards"), do NOT trust vision-model descriptions to find the delta. Two
near-identical dark screenshots come back from vision as vague and surprisingly alike;
nobody can reliably call a 5px-vs-16px gap by eye. Diff the pixels instead.

## Why vision descriptions fail here

- Both images are ~the same 426x546 dark popover, so a plain `vision_analyze` returns two
  near-identical descriptions; the model guesses the gap and is often wrong by 2x.
- The real answer is a sub-band sub-20px difference — exactly what a model free-texts about worst.

## Pixel-diff workflow

PIL/numpy may be absent (PEP 668). Bootstrap a throwaway venv:

```bash
python3 -m venv /tmp/imgvenv
/tmp/imgvenv/bin/pip install -q pillow numpy
```

Then diff grayscale arrays with a threshold:

```python
from PIL import Image
import numpy as np
load = lambda p: np.array(Image.open(p).convert('L')).astype(int)
a = load('current.png'); b = load('desired.png')
d = abs(a - b); mask = d > 20            # ignore JPEG-ish noise
rows, cols = np.where(mask)
print(mask.sum(), rows.min(), rows.max(), cols.min(), cols.max())  # WHAT/WHERE changed
colcnt = mask.sum(axis=0)                # horizontal extent of the change
```

Read the diff bounding box: if it is confined to a thin vertical band (here: rows 54-391,
cols 373-396 — a 24px stripe), the content is pixel-identical and *only* that element moved.

To locate a thin vertical element (a scrollbar track) in each image, score columns by their
fraction of mid-grey pixels across the card rows:

```python
def track(img):
    out=[]
    for c in range(int(img.shape[1]*0.7), img.shape[1]):
        seg=img[:, c]; out.append((c, float(np.mean((seg>90)&(seg<200)))))
    return sorted(out, key=lambda x:-x[1])[:5]
```

Result in this session: current scrollbar track centered ~col 378, desired ~col 391 →
a 13px separation delta, and the content/progress bars were pixel-identical in both. That
turned the frontier from "how close is too close?" into "we need ~16pt of gutter" with a
verified number.

## Setup pitfall

Prefer the venv above over mutating the system interpreter. If numpy/PIL import fails, the
usual cause is the wrong interpreter (project venv vs system) — recreate the throwaway venv.

## Carry the finding into the frontier

- State the measured delta plainly to the user ("content identical, scrollbar moves ~13px;
  current gap ~5px, target ~16px") before asking the frontier.
- Ask the options as concrete pickers (gap size, scrollbar behavior, scope) with the
  recommended default first, then STOP at the dev-cycle grilling checkpoint.