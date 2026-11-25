// Flutter imports:
import 'package:flutter/material.dart';

/// A [ListTile] whose texts reach assistive technology as one node of their
/// own, [label], with the row's buttons as separate nodes beside it.
///
/// A plain ListTile merges its texts into the node that also holds its
/// trailing or leading buttons. Flutter web writes such a node, one with
/// children, as an `aria-label` only, not as text, and ARIA does not allow a
/// name on a plain group, so the texts are lost on the web. Here the title
/// carries [label] (and the row's tap, [onTap]) as a leaf node, and the
/// visible title and subtitle are left out of the semantics; the caller
/// leaves out any other text it puts in [leading] or [trailing].
///
/// It looks and taps as the ListTile it wraps: the row's tap is an
/// [InkWell] around the tile, kept out of the semantics, since the label
/// node offers it.
class ReadableTile extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool? dense;
  final VisualDensity? visualDensity;

  const ReadableTile({
    super.key,
    required this.label,
    required this.title,
    this.onTap,
    this.leading,
    this.subtitle,
    this.trailing,
    this.dense,
    this.visualDensity,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      dense: dense,
      visualDensity: visualDensity,
      leading: leading,
      title: Semantics(
        container: true,
        label: label,
        button: onTap != null,
        onTap: onTap,
        excludeSemantics: true,
        child: title,
      ),
      subtitle: subtitle == null ? null : ExcludeSemantics(child: subtitle),
      trailing: trailing,
    );
    final tap = onTap;
    if (tap == null) return tile;
    return InkWell(onTap: tap, excludeFromSemantics: true, child: tile);
  }
}
