# Component quality checklist

The definition of done for a `fossui` component. Every component clears this
before it is marked shipped on the [roadmap](roadmap.md), from a one-line
separator to a full date picker. A simple component does not skip boxes. Most are
trivial for it, but each one is checked off deliberately rather than assumed.

Use this as your guide when contributing a component. Copy the short block at the
bottom into the pull request and tick it as you go.

## 1. Design and API

- [ ] Variants and sizes are enums (`FossXVariant`, `FossXSize`), passed as named
  parameters.
- [ ] The states it supports are decided up front: which of default, hover,
  pressed, focused, disabled, selected, error, and loading apply.
- [ ] Both controlled and uncontrolled use work where they make sense: a
  `value` plus `onChanged`, or an optional controller.
- [ ] A single `FossXStyle` object is the per-instance escape hatch. A named
  constructor is added only for a genuinely distinct shape (for example
  `FossButton.icon`).
- [ ] Icon slots accept any `Widget`, so any icon set works. The package takes no
  icon dependency.

## 2. Theming

- [ ] Every value is read through `context.fossTheme`. No hardcoded color, size,
  radius, spacing, duration, or text style.
- [ ] Light and dark both resolve, and the theme animates between them.
- [ ] Style precedence holds: the widget `style` argument wins over the theme,
  and the theme wins over the built-in default.
- [ ] No per-instance token properties on the constructor (`color:`,
  `borderRadius:`, `padding:`). Restyle through the theme, not the widget.

## 3. State matrix

- [ ] Every state the component claims renders and is visually distinct:
  default, and whichever of hover, pressed, focused, disabled, selected, error,
  and loading apply.
- [ ] In a list or group, at most one item is highlighted at a time; selection
  follows the component (single or multiple).
- [ ] Disabled blocks interaction and reads as disabled to assistive technology.
- [ ] Error recolors the affected surface and announces its message.
- [ ] Open, close, and value transitions run on the motion tokens and collapse
  under the reduced-motion preference.

## 4. Accessibility

- [ ] Correct semantics: role, label, hint, value, and flags, with an explicit
  label for icon-only controls.
- [ ] Full keyboard support: activation, tab order, arrow and escape keys where
  the role calls for them, and a visible focus ring.
- [ ] Meets the platform guidelines: tap target size, labeled targets, and text
  contrast.
- [ ] Layout survives a text scale of 2.0x.
- [ ] Right-to-left layout is correct.
- [ ] Reduced-motion preference is honored.

## 5. Responsiveness

- [ ] Respects incoming constraints. No hardcoded width or height assumptions.
- [ ] No overflow from narrow to wide. Long text wraps or truncates on purpose.
- [ ] Verified at small and large sizes, across text scales, in both text
  directions.

## 6. Tests

- [ ] Unit tests for any logic: style resolution, controller behavior, value
  math.
- [ ] Widget tests for interaction and the semantics tree.
- [ ] Golden tests for the look across themes, text direction, and text scale.
- [ ] Accessibility assertions for tap target, labeling, and contrast.
- [ ] Coverage reported.

## 7. Docs

- [ ] A documentation comment on every public member, each with a short summary
  and a runnable example.
- [ ] A companion showcase page that exercises the variants, sizes, states, and
  themes. This lives in the separate showcase project, not in the package.
- [ ] The dartdoc preview, docs, and playground links follow the mechanical
  convention so they stay derivable from the name: preview images at
  `fossui.org/components/<slug>/overview/{light,dark}.png`, docs at
  `fossui.org/docs/components/<slug>`, playground at
  `play.fossui.org/#/?path=components/<folder>/<class-lower>/playground`. The
  `<slug>` is the class name minus the `Foss` prefix, kebab-cased; the playground
  is keyed on the component's primary class. Do not invent a new path shape.
- [ ] Once a component ships, its URLs are frozen: never move or rename one. Add a
  new asset path rather than changing a published one.
- [ ] Public API added after the `0.1.0` baseline carries `@FossSince('<version>')`
  on the class. API that shipped in `0.1.0` stays unannotated; the baseline is
  implicit.

## 8. Gate

- [ ] Static analysis is clean and the code is formatted.
- [ ] Public names are `Foss`-prefixed; internals are not exported.

## The checklist (copy into a pull request)

```
Component: ____

Design + API
[ ] variant + size enums, supported states
[ ] controlled + uncontrolled where sensible, FossXStyle, Widget? icon slots

Theming
[ ] context.fossTheme, no literals
[ ] light + dark + animated
[ ] style precedence; no per-instance token props

State matrix
[ ] every claimed state renders and is distinct
[ ] one active highlight (selection per component); disabled blocks + announces; error recolors + announces
[ ] transitions on motion tokens; collapse under reduced motion

Accessibility
[ ] semantics role/label/flags; label on icon-only
[ ] keyboard + focus traversal + visible ring
[ ] tap target + labeled + contrast guidelines
[ ] text scale 2.0x; right-to-left; reduced motion

Responsiveness
[ ] respects constraints, no overflow, deliberate long-text
[ ] small + large sizes, text scales, both directions

Tests
[ ] unit / widget (+ semantics) / golden / accessibility
[ ] coverage reported

Docs
[ ] documentation comment on every public member
[ ] companion showcase page (separate project)
[ ] preview/docs/playground URLs follow the mechanical slug convention (frozen once shipped)
[ ] @FossSince on public API added after 0.1.0 (baseline stays unannotated)

Gate
[ ] analysis clean, formatted, prefixed names
```
