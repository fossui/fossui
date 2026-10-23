part of 'foss_menu.dart';

/// What a [FossMenuItem] renders as. Kept private: the kind is chosen by the
/// constructor a caller picks, never passed in.
enum _MenuItemKind { item, separator, label }

/// One entry in a [FossMenu]: an action row, a divider, or a group heading.
///
/// This is data passed to [FossMenu.items], not a widget, so the menu owns the
/// row metrics, the colors, and the highlight. One list carries all three
/// kinds, so a caller never passes a parallel structure to place a divider.
///
/// An action row is the default constructor. [onSelected] null leaves the row
/// visible, at full strength, and doing nothing, which is how a "coming soon"
/// entry is expressed; `enabled: false` dims it and takes it out of the
/// keyboard walk. Use [FossMenuItem.separator] for a divider and
/// [FossMenuItem.label] for a heading above a group.
///
/// ```dart
/// const items = [
///   FossMenuItem.label('Actions'),
///   FossMenuItem(label: 'New file', shortcut: 'Ctrl N'),
///   FossMenuItem.separator(),
///   FossMenuItem(label: 'Delete', destructive: true),
/// ];
/// ```
@immutable
@FossSince('0.1.3')
class FossMenuItem {
  /// Creates an action row showing [label].
  const FossMenuItem({
    required this.label,
    this.icon,
    this.shortcut,
    this.onSelected,
    this.enabled = true,
    this.destructive = false,
    this.inset = false,
  }) : _kind = _MenuItemKind.item;

  /// Creates a divider between two groups of rows. It takes no input and is
  /// skipped by the keyboard walk.
  const FossMenuItem.separator()
    : label = '',
      icon = null,
      shortcut = null,
      onSelected = null,
      enabled = true,
      destructive = false,
      inset = false,
      _kind = _MenuItemKind.separator;

  /// Creates a heading above a group of rows, showing [label]. It is announced
  /// with the menu but takes no input.
  const FossMenuItem.label(this.label, {this.inset = false})
    : icon = null,
      shortcut = null,
      onSelected = null,
      enabled = true,
      destructive = false,
      _kind = _MenuItemKind.label;

  /// The row's text, and the name it announces. Empty on a separator.
  final String label;

  /// A glyph at the start of the row, sized and colored by the menu. Any
  /// widget; no icon dependency.
  final Widget? icon;

  /// The key combination shown at the end of the row, such as `Ctrl N`.
  ///
  /// Display only: the menu never binds it. An app that wants the combination
  /// to work registers it itself.
  final String? shortcut;

  /// Called when the row is selected by a tap, `Enter`, or `Space`. Null
  /// leaves the row inert: it stays at full strength, keeps its place in the
  /// keyboard walk, and selecting it does nothing.
  final VoidCallback? onSelected;

  /// Whether the row accepts input. False dims it to 64% and skips it in the
  /// keyboard walk.
  final bool enabled;

  /// Whether the row reads as a destructive action, which colors its text and
  /// glyph accordingly.
  final bool destructive;

  /// Whether the row starts past the glyph column, so its text lines up with
  /// the rows that carry an [icon].
  final bool inset;

  final _MenuItemKind _kind;

  /// Whether this renders as an action row, which reports the menu-item role
  /// whether or not it is enabled.
  bool get _isRow => _kind == _MenuItemKind.item;

  /// Whether the row can take a selection: an action row that is enabled. An
  /// inert row qualifies, and selecting it does nothing.
  bool get _selectable => _isRow && enabled;
}
