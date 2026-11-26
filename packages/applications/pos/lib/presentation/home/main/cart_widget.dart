// Flutter imports:
import 'package:flutter/material.dart';
import 'package:design_system/theme/app_colors.dart';

// Package imports:
import 'package:common/core/ext/number_ext.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/presentation/core/readable_tile.dart';

class ProductItem extends StatelessWidget {
  final String name;
  final double price;
  final int quantity;
  final String unit;
  final String barcode;
  final Function onTap;

  const ProductItem({
    super.key,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.barcode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = quantity > 0;
    return Card(
      elevation: 0,
      color: available
          ? AppColors.of(context).surfaceRaised
          : AppColors.of(context).surfaceSunken,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.of(context).border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap.call(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).textPrimary)),
              const Spacer(),
              Text(available ? 'คงเหลือ $quantity $unit' : 'สินค้าหมด',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: available
                          ? AppColors.of(context).textSecondary
                          : Theme.of(context).colorScheme.error)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: Text('฿${formatDouble(price)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: AppColors.of(context).textPrimary))),
                Flexible(
                    child: Text('/ $unit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.of(context).textSecondary))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class CartItem extends StatelessWidget {
  final int index;
  final bool active;
  final bool haveOrder;
  final Function onTap;

  const CartItem({
    super.key,
    required this.index,
    required this.active,
    required this.haveOrder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppColors.of(context).textPrimary : Colors.transparent;
    final background =
        active ? AppColors.of(context).sidebarSelected : Colors.transparent;
    return InkWell(
      onTap: () {
        onTap.call();
      },
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 60,
              color: background,
              child: Stack(
                children: [
                  Center(
                      child: Text(
                    index.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                  haveOrder
                      ? Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          ),
          Container(height: 60, width: 3, color: color),
        ],
      ),
    );
  }
}

class CartOrderItem extends StatelessWidget {
  final String title;
  final int quantity;
  final double price;
  final String unit;
  final String priceDetail;
  final double discount;
  final bool allowOversell;
  final Function onRemove;
  final Function onAdd;
  final Function onEdit;
  final Function onEditPrice;
  final Function onToggleOversell;

  const CartOrderItem({
    super.key,
    required this.title,
    required this.quantity,
    required this.price,
    required this.unit,
    required this.discount,
    required this.priceDetail,
    required this.allowOversell,
    required this.onRemove,
    required this.onAdd,
    required this.onEdit,
    required this.onEditPrice,
    required this.onToggleOversell,
  });

  @override
  Widget build(BuildContext context) {
    getPriceDiscount() {
      if (discount > 0) {
        return SizedBox(
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '฿${formatDouble(price * quantity)}',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  fontSize: 10,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
              Text(
                '฿${formatDouble((price * quantity) - (discount * quantity))}',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }
      return SizedBox(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '฿${formatDouble(price * quantity)}',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            Text(
              priceDetail,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < _wideMinWidth) {
        return _buildNarrow(context, getPriceDiscount());
      }
      return _buildWide(context, getPriceDiscount());
    });
  }

  /// A cart wide enough for the controls and the price beside the name.
  Widget _buildWide(BuildContext context, Widget price) {
    final tile = ReadableTile(
      label: _label(),
      onTap: () {
        onEditPrice.call();
      },
      dense: true,
      visualDensity: const VisualDensity(vertical: -3),
      title: Text(
        title,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        unit,
        style: TextStyle(
          color: AppColors.of(context).textSecondary,
          fontSize: 14,
        ),
      ),
      trailing: SizedBox(
        width: _controlsWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ..._controls(context),
            const SizedBox(width: 4),
            // Read in the line's own node.
            ExcludeSemantics(child: price),
          ],
        ),
      ),
    );

    return Column(
      children: [
        tile,
        const Divider(
          height: 1,
        ),
      ],
    );
  }

  /// The width of the quantity controls and the price, side by side.
  static const _controlsWidth = 288.0;

  /// The narrowest line that keeps the controls beside the name: the
  /// controls, the tile's 40 px of padding and 112 px for the name (440 px;
  /// every cart the app builds today, 309-400 px, is narrower).
  static const _wideMinWidth = _controlsWidth + 40 + 112;

  /// A narrow cart (a phone's, a tablet's or the desktop's panel): the
  /// name, unit and price on the first row, the quantity controls on a row
  /// of their own under them.
  Widget _buildNarrow(BuildContext context, Widget price) {
    return Column(
      children: [
        ReadableTile(
          label: _label(),
          onTap: () {
            onEditPrice.call();
          },
          dense: true,
          visualDensity: const VisualDensity(vertical: -3),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            unit,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 14,
            ),
          ),
          // Read in the line's own node.
          trailing: ExcludeSemantics(child: price),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _controls(context),
          ),
        ),
        const Divider(
          height: 1,
        ),
      ],
    );
  }

  /// The line's oversell switch, one less, its quantity and one more.
  List<Widget> _controls(BuildContext context) => [
        SizedBox(
          width: 36,
          height: 36,
          child: Tooltip(
            message: allowOversell
                ? Languages.of(context).oversellAllowed(title)
                : Languages.of(context).allowOversell(title),
            child: InkResponse(
              onTap: () {
                onToggleOversell.call();
              },
              child: Ink(
                decoration: ShapeDecoration(
                  color: allowOversell
                      ? Colors.orange[50]
                      : AppColors.of(context).surfaceSunken,
                  shape: CircleBorder(),
                ),
                child: Icon(
                  allowOversell
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: allowOversell
                      ? Colors.orange
                      : AppColors.of(context).textSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 36,
          height: 36,
          child: _named(
            Languages.of(context).oneLess(title),
            InkResponse(
              onTap: () {
                onRemove.call();
              },
              child: Ink(
                decoration: ShapeDecoration(
                  color: Colors.red[50],
                  shape: const CircleBorder(),
                ),
                child: const Icon(
                  Icons.remove,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () {
            onEdit.call();
          },
          child: Container(
            width: 50,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              '${quantity}x',
              // The line's own node reads the quantity; the button
              // says what it does, to which line.
              semanticsLabel: Languages.of(context).changeQuantity(title),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 36,
          height: 36,
          child: _named(
            Languages.of(context).oneMore(title),
            InkResponse(
              onTap: () {
                onAdd.call();
              },
              child: Ink(
                decoration: ShapeDecoration(
                  color: AppColors.of(context).surfaceSunken,
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  Icons.add,
                  color: AppColors.of(context).textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ];

  /// What the line reads: quantity, product, unit and amount to pay, then
  /// the full amount when discounted, or else the price's kind.
  String _label() {
    final full = '฿${formatDouble(price * quantity)}';
    if (discount <= 0) return '${quantity}x $title $unit $full $priceDetail';
    final paid = '฿${formatDouble((price - discount) * quantity)}';
    return '${quantity}x $title $unit $paid ลดจาก $full';
  }

  /// A round icon button of the line, named for a screen reader.
  static Widget _named(String label, Widget button) =>
      Semantics(button: true, label: label, child: button);
}

/// Opens the product picker on a narrow (phone) layout, where the product grid
/// is not on the selling screen itself.
class CartSearchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CartSearchButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: IconButton(
        tooltip: Languages.of(context).chooseProduct,
        padding: const EdgeInsets.all(0),
        splashRadius: 20,
        onPressed: onPressed,
        icon: Icon(
          Icons.search,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Takes the chosen customer off the sale. Its tooltip names the customer: on
/// the web the tile's own title does not reach the semantics tree.
class CartCustomerRemoveButton extends StatelessWidget {
  final String customerName;
  final VoidCallback onPressed;

  const CartCustomerRemoveButton({
    super.key,
    required this.customerName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: Languages.of(context).removeCustomer(customerName),
      splashRadius: 16,
      onPressed: onPressed,
      color: Colors.red,
      icon: const Icon(Icons.close, size: 24),
    );
  }
}

/// The sale's customer: none yet (tap to choose one), or the chosen one's
/// name and code with a button that takes them off the sale.
class CartCustomerTile extends StatelessWidget {
  final Customer? customer;
  final VoidCallback onChoose;
  final VoidCallback onRemove;

  const CartCustomerTile({
    super.key,
    required this.customer,
    required this.onChoose,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final chosen = customer;
    final title = chosen == null ? 'ข้อมูลลูกค้า' : chosen.name;
    final subtitle = chosen == null ? 'เลือกลูกค้า' : chosen.code;
    return ReadableTile(
      label: '$title\n$subtitle',
      leading: const CircleAvatar(
        radius: 20,
        child: Icon(Icons.person),
      ),
      title: Text(title, style: const TextStyle(fontSize: 18)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
      trailing: chosen == null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : CartCustomerRemoveButton(
              customerName: chosen.name,
              onPressed: onRemove,
            ),
      onTap: onChoose,
    );
  }
}
