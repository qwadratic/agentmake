# polish-pass

Pretty layer over app-shell styles. Integration: add after style.css in index.html:

```html
<link rel="stylesheet" href="../polish-pass/polish.css">
```

Covers: animated gradient bg (@keyframes gradient-shift), card hover
(transition/transform), tabular-nums on clock digits, transform-only entry
animation (rise-in — never animates opacity, content visible at first paint),
contrast-boosted card bg/border/headings, single-column stack under 700px
(@media), prefers-reduced-motion block disabling animations.
