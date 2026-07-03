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

### Forms and inputs

- [x] **Button** : variants, sizes, leading and trailing icon slots, a loading
  state, an icon-only form, and an optional controller for driving loading and
  disabled imperatively.
- [x] **Text field** : single-line and multi-line input from one widget.
- [x] **Checkbox** : on/off control, with a group for related options.
- [x] **Radio group** : single choice from a set.
- [x] **Switch** : toggle control.
- [x] **Slider** : pick a value from a range.
- [x] **Select** : single or multiple choice from a dropdown.
- [x] **Combobox and autocomplete** : filterable select, single or multi.

### Layout and surfaces

- [x] **Card** : surface container with the package elevation.
- [x] **Separator** : thin divider.
- [x] **Tabs** : tabbed panels, horizontal or vertical.

### Feedback and status

- [x] **Spinner** : a themed loading indicator, also used inside Button.
- [x] **Progress** : determinate progress bar.
- [x] **Badge** : small status or count pill.
- [x] **Avatar** : image with an initials fallback.
- [x] **Alert** : inline status message.

### Overlays

- [x] **Dialog** : modal dialog over a dimmed scrim.
- [x] **Alert dialog** : non-dismissible confirm dialog.
- [x] **Drawer** : panel that slides in from an edge.
- [x] **Tooltip** : anchored hint on hover or focus.
- [x] **Toast** : transient notifications with a queue.

## Planned

The overlay and focus-management layer already ships under the dialogs, drawer,
tooltip, and toast above, so what is left builds on top of it.

- [ ] **Label** : text label that pairs with a form control.
- [ ] **Skeleton** : shimmer placeholder for loading content.
- [ ] **Popover** : floating panel anchored to a trigger.
- [ ] **Accordion and collapsible** : expandable sections.
- [ ] **Calendar and date picker** : date selection.
- [ ] **Table and pagination** : tabular data.
- [ ] **Number field** : numeric input with steppers.
- [ ] **One-time-code field** : segmented code entry.

## How the order is decided

Components are built in dependency order, not alphabetical order. A layer has to
exist before anything that builds on it: tokens before any component, simple
controls before overlays, overlays before the data-heavy widgets that compose
them. Button came first because it exercises the whole pipeline once (token
reads, the variant API, interactive state, golden tests, and the catalog entry),
which makes every component after it faster to add.

Have a component you need sooner? Open an issue and say so. The order above is a
plan, not a contract.
