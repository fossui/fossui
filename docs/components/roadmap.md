# Components roadmap

What `foss_ui` ships today, what is being built next, and what is planned. This
page is the single place to check whether a component exists yet, so you do not
have to read the changelog or grep the source.

Status legend:

- `[x]` shipped and stable
- `[~]` in progress
- `[ ]` planned, not started

Every component marked `[x]` clears the same bar before it ships: themed tokens,
light and dark, full keyboard and screen-reader support, text-scale and
right-to-left layout, and three layers of tests. That bar is written down in
[checklist.md](checklist.md).

## Available now

- [x] **Button** : variants, sizes, leading and trailing icon slots, a loading
  state, an icon-only form, and an optional controller for driving loading and
  disabled imperatively.
- [x] **Spinner** : a themed loading indicator, also used inside Button.

## Next

The current focus is the rest of the form and layout foundations. These have no
dependencies on overlays or focus traps, so they land first.

- [ ] **Label** : text label that pairs with a form control.
- [ ] **Input** : single-line text field.
- [ ] **Textarea** : multi-line text field.
- [ ] **Separator** : thin divider.
- [ ] **Badge** : small status or count pill.
- [ ] **Avatar** : image with an initials fallback.
- [ ] **Card** : surface container with the package elevation.
- [ ] **Skeleton** : shimmer placeholder for loading content.
- [ ] **Checkbox** : on/off control.
- [ ] **Switch** : toggle control.
- [ ] **Radio group** : single choice from a set.

## Planned

### Overlays and composites

Built on an overlay and focus-management layer that lands with this group.

- [ ] Tooltip
- [ ] Popover
- [ ] Dialog and alert dialog
- [ ] Sheet
- [ ] Tabs
- [ ] Accordion and collapsible
- [ ] Toast
- [ ] Alert
- [ ] Select

### Data and advanced

- [ ] Slider
- [ ] Progress
- [ ] Calendar and date picker
- [ ] Combobox and autocomplete
- [ ] Table and pagination
- [ ] Number field
- [ ] One-time-code field

## How the order is decided

Components are built in dependency order, not alphabetical order. A layer has to
exist before anything that builds on it: tokens before any component, simple
controls before overlays, overlays before the data-heavy widgets that compose
them. Button came first because it exercises the whole pipeline once (token
reads, the variant API, interactive state, golden tests, and the catalog entry),
which makes every component after it faster to add.

Have a component you need sooner? Open an issue and say so. The order above is a
plan, not a contract.
