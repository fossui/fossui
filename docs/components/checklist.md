# Component quality checklist

The definition of done for a `foss_ui` component. Every component clears this
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
- [ ] Controlled and uncontrolled use both work where they make sense: a
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

## 3. Accessibility

- [ ] Correct semantics: role, label, hint, value, and flags, with an explicit
  label for icon-only controls.
- [ ] Full keyboard support: activation, tab order, arrow and escape keys where
  the role calls for them, and a visible focus ring.
- [ ] Meets the platform guidelines: tap target size, labeled targets, and text
  contrast.
- [ ] Layout survives a text scale of 2.0x.
- [ ] Right-to-left layout is correct.
- [ ] Reduced-motion preference is honored.

## 4. Responsiveness

- [ ] Respects incoming constraints. No hardcoded width or height assumptions.
- [ ] No overflow from narrow to wide. Long text wraps or truncates on purpose.
- [ ] Verified at small and large sizes, across text scales, in both text
  directions.

## 5. Tests

- [ ] Unit tests for any logic: style resolution, controller behavior, value
  math.
- [ ] Widget tests for interaction and the semantics tree.
- [ ] Golden tests for the look across themes, text direction, and text scale.
- [ ] Accessibility assertions for tap target, labeling, and contrast.
- [ ] Coverage reported.

## 6. Docs

- [ ] A documentation comment on every public member, each with a short summary
  and a runnable example.
- [ ] A companion showcase page that exercises the variants, sizes, states, and
  themes. This lives in the separate showcase project, not in the package.

## 7. Gate

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

Gate
[ ] analysis clean, formatted, prefixed names
```
