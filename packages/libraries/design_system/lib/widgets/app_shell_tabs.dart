// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/color.dart';
import 'package:design_system/theme/spacing.dart';
import 'package:design_system/widgets/app_shell.dart';

/// One action of the shell's account menu.
@immutable
class AppShellAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Drawn in the error colour: signing out.
  final bool destructive;

  const AppShellAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });
}

/// The shell with its sections as tabs: a bar across the top of a wide
/// viewport, a bar along the bottom of a narrow one.
class AppShellTabsFrame extends StatelessWidget {
  final String brand;
  final List<AppShellItem> items;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final List<AppShellAction> accountMenu;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final bool isMobile;
  final Widget child;

  const AppShellTabsFrame({
    super.key,
    required this.brand,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    required this.accountMenu,
    required this.actions,
    required this.floatingActionButton,
    required this.isMobile,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButton: floatingActionButton,
      // The bar is the scaffold's own, so a snackbar rises above it and the
      // keyboard covers it instead of lifting it over the page.
      bottomNavigationBar: isMobile
          ? SafeArea(top: false, child: _BottomTabs(frame: this))
          : null,
      // The whole frame keeps clear of the system bars, so no screen has to.
      body: SafeArea(
        child: Column(
          children: [
            if (!isMobile) _TopTabs(frame: this),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  List<Widget> _tabs({required bool compact}) => [
        for (final item in items)
          AppShellTab(
            label: item.label,
            shortLabel: item.shortLabel,
            icon: item.icon,
            selected: item.id == selectedId,
            compact: compact,
            onTap: () => onSelect(item.id),
          ),
      ];
}

class _TopTabs extends StatelessWidget {
  static const double _height = 56;

  final AppShellTabsFrame frame;

  const _TopTabs({required this.frame});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Text(frame.brand, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: frame._tabs(compact: false)),
            ),
          ),
          ...frame.actions,
          if (frame.accountMenu.isNotEmpty)
            AppShellAccountButton(actions: frame.accountMenu),
        ],
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  final AppShellTabsFrame frame;

  const _BottomTabs({required this.frame});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          for (final tab in frame._tabs(compact: true)) Expanded(child: tab),
          if (frame.accountMenu.isNotEmpty)
            Expanded(
              child: AppShellAccountButton(
                actions: frame.accountMenu,
                compact: true,
              ),
            ),
        ],
      ),
    );
  }
}

/// One section of the shell, as a tab. [compact] is the bottom bar's form:
/// the icon over [shortLabel]; a screen reader hears [label] either way.
class AppShellTab extends StatelessWidget {
  static const double _topHeight = 56;
  static const double _bottomHeight = 56;
  static const double _underline = 2;

  final String label;
  final String? shortLabel;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const AppShellTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.shortLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final foreground = selected ? colors.textPrimary : colors.textSecondary;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: ExcludeSemantics(
          child: compact
              ? _compact(foreground)
              : _wide(foreground, colors.textPrimary),
        ),
      ),
    );
  }

  Widget _wide(Color foreground, Color underline) {
    return Container(
      height: _topHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: _underline,
            color: selected ? underline : Colors.transparent,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 6),
          Text(label, maxLines: 1, style: _labelStyle(foreground, 14)),
        ],
      ),
    );
  }

  Widget _compact(Color foreground) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _bottomHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: foreground),
          Text(
            shortLabel ?? label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _labelStyle(foreground, 12),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle(Color color, double size) => TextStyle(
        color: color,
        fontSize: size,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      );
}

/// Opens the account's actions: who is signed in, signing out.
class AppShellAccountButton extends StatelessWidget {
  static const String tooltip = 'บัญชี';

  final List<AppShellAction> actions;
  final bool compact;

  const AppShellAccountButton({
    super.key,
    required this.actions,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PopupMenuButton<AppShellAction>(
      tooltip: tooltip,
      onSelected: (action) => action.onTap(),
      itemBuilder: (context) => [
        for (final action in actions)
          _AccountMenuItem(value: action, child: _item(action, colors)),
      ],
      child: Semantics(
        button: true,
        child: compact ? _compactFace(colors) : _wideFace(colors),
      ),
    );
  }

  Widget _item(AppShellAction action, AppColors colors) {
    final color = action.destructive ? CustomColor.error : colors.textPrimary;
    return Row(
      children: [
        Icon(action.icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(action.label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }

  Widget _wideFace(AppColors colors) => SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.account_circle_outlined, color: colors.textPrimary),
      );

  Widget _compactFace(AppColors colors) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 22,
              color: colors.textSecondary,
            ),
            // The button already says its name through the tooltip.
            ExcludeSemantics(
              child: Text(
                tooltip,
                maxLines: 1,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ),
          ],
        ),
      );
}

/// An account action read as a plain button. Flutter web writes a
/// menuitem's name as an aria-label only, which a find by text in the page
/// (an end-to-end driver's) cannot read; a button's name it writes as text.
class _AccountMenuItem extends PopupMenuItem<AppShellAction> {
  const _AccountMenuItem({super.value, required super.child});

  @override
  PopupMenuItemState<AppShellAction, _AccountMenuItem> createState() =>
      _AccountMenuItemState();
}

class _AccountMenuItemState
    extends PopupMenuItemState<AppShellAction, _AccountMenuItem> {
  @override
  Widget buildSemantics({required Widget child}) =>
      Semantics(enabled: widget.enabled, button: true, child: child);
}
