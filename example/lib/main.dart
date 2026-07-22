import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

void main() => runApp(const ExampleApp());

/// Entry point for the fossui example.
///
/// Registers the light and dark themes, then shows a component gallery grouped
/// into tabs. The app bar toggles the theme so every component can be seen in
/// both modes.
class ExampleApp extends StatefulWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _mode = ThemeMode.dark;

  void _toggleTheme() => setState(
    () => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fossui example',
      debugShowCheckedModeBanner: false,
      theme: FossThemeData.light.toThemeData(),
      darkTheme: FossThemeData.dark.toThemeData(),
      themeMode: _mode,
      home: _Home(isDark: _mode == ThemeMode.dark, onToggleTheme: _toggleTheme),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.isDark, required this.onToggleTheme});

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('fossui'),
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            tooltip: isDark ? 'Switch to light' : 'Switch to dark',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      // A FossToaster ancestor is required for showFossToast to find a host.
      body: const FossToaster(
        child: FossTabs(
          initialValue: 'controls',
          tabs: [
            FossTab(value: 'controls', label: 'Controls', content: _Controls()),
            FossTab(value: 'inputs', label: 'Inputs', content: _Inputs()),
            FossTab(value: 'feedback', label: 'Feedback', content: _Feedback()),
            FossTab(value: 'layout', label: 'Layout', content: _Layout()),
          ],
        ),
      ),
    );
  }
}

/// Wraps a titled section: a muted label above its content.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.fossTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: t.typography.xs.medium.copyWith(
            color: t.colors.mutedForeground,
          ),
        ),
        SizedBox(height: t.spacing(3)),
        child,
      ],
    );
  }
}

/// A vertically scrolling list of sections with consistent padding and gaps.
class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.fossTheme.spacing;
    return ListView(
      padding: spacing.all(5),
      children: [
        for (final child in children) ...[child, SizedBox(height: spacing(6))],
      ],
    );
  }
}

class _Controls extends StatefulWidget {
  const _Controls();

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  bool _notify = true;
  bool _terms = false;
  String _plan = 'pro';
  double _volume = 40;
  bool _bold = false;
  String? _align = 'left';

  Future<void> _confirmDelete() => showFossDialog<void>(
    context: context,
    builder: (context) => FossDialog(
      title: const Text('Delete project'),
      description: const Text('This cannot be undone.'),
      actions: [
        FossButton(
          variant: FossButtonVariant.ghost,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FossButton(
          variant: FossButtonVariant.destructive,
          onPressed: () => Navigator.pop(context),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  void _saved() => showFossToast(
    context,
    const FossToast(
      variant: FossToastVariant.success,
      title: Text('Changes saved'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final spacing = context.fossTheme.spacing;
    return _Page(
      children: [
        _Section(
          label: 'Buttons',
          child: Wrap(
            spacing: spacing(3),
            runSpacing: spacing(3),
            children: [
              FossButton(onPressed: _saved, child: const Text('Primary')),
              FossButton(
                variant: FossButtonVariant.secondary,
                onPressed: () {},
                child: const Text('Secondary'),
              ),
              FossButton(
                variant: FossButtonVariant.outline,
                leading: const Icon(Icons.download_outlined, size: 16),
                onPressed: () {},
                child: const Text('Outline'),
              ),
              FossButton(
                variant: FossButtonVariant.ghost,
                onPressed: () {},
                child: const Text('Ghost'),
              ),
              FossButton(
                variant: FossButtonVariant.destructive,
                onPressed: _confirmDelete,
                child: const Text('Delete'),
              ),
            ],
          ),
        ),
        _Section(
          label: 'Switch and checkbox',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FossSwitch(
                    value: _notify,
                    onChanged: (v) => setState(() => _notify = v),
                  ),
                  SizedBox(width: spacing(3)),
                  const Text('Email notifications'),
                ],
              ),
              SizedBox(height: spacing(4)),
              FossCheckbox(
                value: _terms,
                label: 'Accept terms and conditions',
                description: 'You agree to the service agreement.',
                onChanged: (v) => setState(() => _terms = v),
              ),
            ],
          ),
        ),
        _Section(
          label: 'Radio group',
          child: FossRadioGroup<String>(
            groupValue: _plan,
            onChanged: (v) => setState(() => _plan = v),
            children: const [
              FossRadio(value: 'free', label: 'Free'),
              FossRadio(value: 'pro', label: 'Pro'),
              FossRadio(value: 'team', label: 'Team'),
            ],
          ),
        ),
        _Section(
          label: 'Slider',
          child: FossSlider(
            value: _volume,
            onChanged: (v) => setState(() => _volume = v),
          ),
        ),
        _Section(
          label: 'Toggle',
          child: FossToggle(
            pressed: _bold,
            leading: const Icon(Icons.format_bold),
            semanticLabel: 'Bold',
            onPressedChanged: (v) => setState(() => _bold = v),
            child: const Text('Bold'),
          ),
        ),
        _Section(
          label: 'Toggle group',
          child: FossToggleGroup.single(
            value: _align,
            onChanged: (v) => setState(() => _align = v),
            children: const [
              FossToggleGroupItem(
                value: 'left',
                leading: Icon(Icons.format_align_left),
                semanticLabel: 'Align left',
              ),
              FossToggleGroupItem(
                value: 'center',
                leading: Icon(Icons.format_align_center),
                semanticLabel: 'Align center',
              ),
              FossToggleGroupItem(
                value: 'right',
                leading: Icon(Icons.format_align_right),
                semanticLabel: 'Align right',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Inputs extends StatefulWidget {
  const _Inputs();

  @override
  State<_Inputs> createState() => _InputsState();
}

class _InputsState extends State<_Inputs> {
  String? _plan;
  num? _quantity = 1;
  DateTime? _date;
  String? _fruit;
  Set<String> _labels = {'design'};

  static const _fruits = <FossComboboxItem<String>>[
    FossComboboxItem(value: 'apple', label: 'Apple'),
    FossComboboxItem(value: 'banana', label: 'Banana'),
    FossComboboxItem(value: 'cherry', label: 'Cherry'),
    FossComboboxItem(value: 'mango', label: 'Mango'),
  ];

  static const _tags = <FossComboboxItem<String>>[
    FossComboboxItem(value: 'design', label: 'Design'),
    FossComboboxItem(value: 'eng', label: 'Engineering'),
    FossComboboxItem(value: 'ops', label: 'Operations'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        const _Section(
          label: 'Text field',
          child: FossTextField(
            label: 'Email',
            hintText: 'you@example.com',
            helperText: 'We never share it.',
            leading: Icon(Icons.mail_outlined, size: 18),
          ),
        ),
        const _Section(
          label: 'Password',
          child: FossTextField(
            label: 'Password',
            hintText: 'Enter a password',
            obscureText: true,
          ),
        ),
        _Section(
          label: 'Select',
          child: FossSelect<String>(
            label: 'Plan',
            placeholder: 'Choose a plan',
            value: _plan,
            onChanged: (v) => setState(() => _plan = v),
            items: const [
              FossSelectItem(value: 'free', label: 'Free'),
              FossSelectItem(value: 'pro', label: 'Pro'),
              FossSelectItem(value: 'team', label: 'Team'),
            ],
          ),
        ),
        _Section(
          label: 'Number field',
          child: FossNumberField(
            value: _quantity,
            min: 0,
            max: 10,
            onChanged: (v) => setState(() => _quantity = v),
          ),
        ),
        _Section(
          label: 'Combobox',
          child: FossCombobox<String>(
            label: 'Fruit',
            hintText: 'Search fruit',
            value: _fruit,
            items: _fruits,
            onChanged: (v) => setState(() => _fruit = v),
          ),
        ),
        const _Section(
          label: 'Autocomplete',
          child: FossAutocomplete(
            label: 'Fruit',
            hintText: 'Type to search',
            items: ['Apple', 'Banana', 'Cherry', 'Mango'],
          ),
        ),
        _Section(
          label: 'Multi combobox',
          child: FossMultiCombobox<String>(
            label: 'Tags',
            hintText: 'Add tags',
            values: _labels,
            items: _tags,
            onChanged: (v) => setState(() => _labels = v),
          ),
        ),
        _Section(
          label: 'Multi select',
          child: FossMultiSelect<String>(
            label: 'Tags',
            placeholder: 'Choose tags',
            values: _labels,
            items: const [
              FossSelectItem(value: 'design', label: 'Design'),
              FossSelectItem(value: 'eng', label: 'Engineering'),
              FossSelectItem(value: 'ops', label: 'Operations'),
            ],
            onChanged: (v) => setState(() => _labels = v),
          ),
        ),
        _Section(
          label: 'Date picker',
          child: FossDatePicker.single(
            selected: _date,
            onSelected: (d) => setState(() => _date = d),
          ),
        ),
        const _Section(label: 'One-time code', child: FossOtpField(length: 6)),
        const _Section(
          label: 'Validation',
          child: FossTextField(
            label: 'Email',
            errorText: 'Enter a valid email.',
          ),
        ),
      ],
    );
  }
}

/// A button trigger wired to a [FossPopoverController]: the enabled button
/// consumes its own tap, so it drives the popover through the controller, which
/// also lets the content close itself.
class _PopoverDemo extends StatefulWidget {
  const _PopoverDemo();

  @override
  State<_PopoverDemo> createState() => _PopoverDemoState();
}

class _PopoverDemoState extends State<_PopoverDemo> {
  final _controller = FossPopoverController();

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    return FossPopover(
      controller: _controller,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dimensions', style: theme.typography.sm.medium),
          SizedBox(height: theme.spacing(1)),
          Text(
            'Set the width and height of the panel.',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          SizedBox(height: theme.spacing(3)),
          Align(
            alignment: Alignment.centerRight,
            child: FossButton(
              size: FossButtonSize.sm,
              onPressed: _controller.close,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
      child: FossButton(
        onPressed: _controller.toggle,
        child: const Text('Open popover'),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback();

  @override
  Widget build(BuildContext context) {
    final spacing = context.fossTheme.spacing;
    return _Page(
      children: [
        _Section(
          label: 'Alerts',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FossAlert(
                variant: FossAlertVariant.info,
                title: Text('Heads up'),
                description: Text('A new version is available.'),
              ),
              SizedBox(height: spacing(3)),
              const FossAlert(
                variant: FossAlertVariant.success,
                title: Text('Payment received'),
                description: Text('Your subscription is now active.'),
              ),
            ],
          ),
        ),
        _Section(
          label: 'Badges',
          child: Wrap(
            spacing: spacing(2),
            runSpacing: spacing(2),
            children: const [
              FossBadge(label: Text('Primary')),
              FossBadge(
                label: Text('Success'),
                variant: FossBadgeVariant.success,
              ),
              FossBadge(
                label: Text('Warning'),
                variant: FossBadgeVariant.warning,
              ),
              FossBadge(label: Text('Error'), variant: FossBadgeVariant.error),
            ],
          ),
        ),
        const _Section(
          label: 'Progress',
          child: FossProgress(
            value: 0.72,
            label: 'Uploading',
            valueLabel: '72%',
          ),
        ),
        const _Section(
          label: 'Meter',
          child: FossMeter(value: 40, label: 'Storage'),
        ),
        _Section(
          label: 'Skeleton',
          child: Row(
            children: [
              const FossSkeleton.circle(size: 40),
              SizedBox(width: spacing(3)),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FossSkeleton(width: 160, height: 12),
                    SizedBox(height: 8),
                    FossSkeleton(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Section(
          label: 'Avatar, spinner, tooltip',
          child: Row(
            children: [
              const FossAvatar(fallback: Text('AB')),
              SizedBox(width: spacing(4)),
              const FossSpinner(size: 22),
              SizedBox(width: spacing(4)),
              const FossTooltip(
                message: 'More information',
                child: Icon(Icons.info_outline, size: 20),
              ),
            ],
          ),
        ),
        const _Section(label: 'Popover', child: _PopoverDemo()),
        _Section(
          label: 'Card',
          child: FossCard(
            title: const Text('Upgrade to Pro'),
            description: const Text('Unlock analytics and priority support.'),
            footer: Align(
              alignment: Alignment.centerRight,
              child: FossButton(onPressed: () {}, child: const Text('Upgrade')),
            ),
          ),
        ),
      ],
    );
  }
}

class _Layout extends StatefulWidget {
  const _Layout();

  @override
  State<_Layout> createState() => _LayoutState();
}

class _LayoutState extends State<_Layout> {
  DateTime? _day;

  Future<void> _openDrawer() => showFossDrawer<void>(
    context: context,
    builder: (context) => const FossDrawer(
      showHandle: true,
      title: Text('Details'),
      content: Text('A panel that slides up from the bottom edge.'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        const _Section(
          label: 'Text',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FossText.title('Type scale'),
              SizedBox(height: 8),
              FossText.body('Body copy in the muted foreground role.'),
            ],
          ),
        ),
        const _Section(
          label: 'Separator',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Above'),
              SizedBox(height: 12),
              FossSeparator(),
              SizedBox(height: 12),
              Text('Below'),
            ],
          ),
        ),
        const _Section(
          label: 'Accordion',
          child: FossAccordion(
            initialValue: {'a'},
            children: [
              FossAccordionItem(
                value: 'a',
                title: Text('Is it accessible?'),
                child: Text('Yes. It follows the accessibility pattern.'),
              ),
              FossAccordionItem(
                value: 'b',
                title: Text('Is it themeable?'),
                child: Text('Yes. Colors and type come from the theme.'),
              ),
            ],
          ),
        ),
        _Section(
          label: 'Calendar',
          child: FossCalendar.single(
            selected: _day,
            onSelected: (d) => setState(() => _day = d),
          ),
        ),
        _Section(
          label: 'Drawer',
          child: FossButton(
            variant: FossButtonVariant.outline,
            onPressed: _openDrawer,
            child: const Text('Open drawer'),
          ),
        ),
      ],
    );
  }
}
