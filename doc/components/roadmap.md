# Components roadmap

What `fossui` ships today, what is being built next, and what is planned. This
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
- [x] **Toggle** : a two-state pressable button, standard or outline.
- [x] **Toggle group** : a set of toggles, single or multiple selection.
- [x] **Slider** : pick a value from a range.
- [x] **Select** : single or multiple choice from a dropdown.
- [x] **Combobox and autocomplete** : filterable select, single or multi.
- [x] **Number field** : numeric input with steppers, clamped to a range.
- [x] **OTP field** : segmented one-time-code entry.
- [x] **Calendar** : month grid with single, multiple, or range selection.
- [x] **Date picker** : date selection from a field, in a bottom sheet or a
  centered dialog.

### Layout and surfaces

- [x] **Card** : surface container with the package elevation.
- [x] **Separator** : thin divider.
- [x] **Tabs** : tabbed panels, horizontal or vertical.
- [x] **Accordion** : expandable, stacked sections, single or multiple open.

### Feedback and status

- [x] **Spinner** : a themed loading indicator, also used inside Button.
- [x] **Progress** : determinate progress bar.
- [x] **Skeleton** : a loading placeholder, box or circle, with a shimmer.
- [x] **Meter** : static gauge for a bounded value.
- [x] **Badge** : small status or count pill.
- [x] **Avatar** : image with an initials fallback.
- [x] **Alert** : inline status message.

### Overlays

- [x] **Popover** : floating panel anchored to a trigger.
- [x] **Dialog** : modal dialog over a dimmed scrim.
- [x] **Alert dialog** : non-dismissible confirm dialog.
- [x] **Drawer** : panel that slides in from an edge.
- [x] **Tooltip** : anchored hint on hover or focus.
- [x] **Toast** : transient notifications with a queue.

## Planned

Next up, in no fixed order. Each clears the same bar as everything above before it
ships.

### Forms and inputs

- [ ] **Chip** : selectable, dismissible chip or tag.
- [ ] **Time picker** : time-of-day selection, pairs with Date picker.
- [ ] **Rating** : star rating input and display.

### Layout and surfaces

- [ ] **List tile** : list row with leading, title, subtitle, and trailing slots.
- [ ] **Empty state** : icon, message, and action for an empty view.
- [ ] **Stepper** : multi-step progress and step-through flows.
- [ ] **Timeline** : vertical sequence of events.
- [ ] **Scroll area** : scrolling region with a styled scrollbar.
- [ ] **Avatar group** : overlapping stack of avatars.
- [ ] **Resizable** : draggable split panels, stacked on small screens.

### Navigation

- [ ] **Breadcrumb** : path trail for nested navigation.
- [ ] **Pagination** : page controls with previous, next, and page numbers.
- [ ] **Bottom navigation bar** : primary tab bar for top-level sections.
- [ ] **Menubar** : application menu bar, collapses on small screens.
- [ ] **Navigation menu** : grouped navigation with flyout panels.

### Overlays

- [ ] **Context menu** : long-press or secondary-click menu.
- [ ] **Hover card** : preview card shown on hover or long-press.

### Feedback and status

- [ ] **Kbd** : keyboard key label.

New components are added as real needs come in. Need one sooner? Open an issue and
say so.

## Beyond the core: fossui_plus

Bigger composed pieces do not live here: data tables, charts, dashboards, auth
forms, schedulers, and the like. They ship in a separate package, `fossui_plus`,
built on these same atoms so they inherit the theme and retheme with your app. It
is pre-development; follow it at [github.com/fossui/plus](https://github.com/fossui/plus).

## How the order is decided

Components are built in dependency order, not alphabetical order. A layer has to
exist before anything that builds on it: tokens before any component, simple
controls before overlays, overlays before the data-heavy widgets that compose
them. Button came first because it exercises the whole pipeline once (token
reads, the variant API, interactive state, golden tests, and the catalog entry),
which makes every component after it faster to add.

Have a component you need sooner? Open an issue and say so. The order above is a
plan, not a contract.
