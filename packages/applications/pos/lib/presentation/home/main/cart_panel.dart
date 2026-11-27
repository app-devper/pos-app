// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/ext/number_ext.dart';
import 'package:design_system/theme/app_colors.dart';
import 'package:design_system/theme/radius.dart';
import 'package:design_system/theme/text_styles.dart';
import 'package:design_system/widgets/app_card.dart';

// Project imports:
import 'package:pos/domain/model/customer/customer.dart';
import 'package:pos/presentation/home/main/cart_widget.dart';

/// The cart column of the selling screen: which cart is open, its lines as
/// cards, the sale's customer and controlled-drug details, the totals, and
/// the one button that takes payment.
///
/// It draws what it is given: the selling page owns the cart and what each
/// tap does.
class CartPanel extends StatelessWidget {
  /// The net total's amount, for a test to read what the cart prints.
  static const Key netTotalKey = Key('cart-net-total');

  static const double _gutter = 12;
  static const double _lineGap = 6;
  static const double _payHeight = 64;

  /// The open cart, counted from 1.
  final int cartNumber;
  final int lineCount;
  final IndexedWidgetBuilder lineBuilder;
  final double total;

  /// The sale's customer; null until one is chosen.
  final Customer? customer;

  /// What the controlled-drug details say; null when none are given.
  final String? complianceSummary;

  /// The phone's button for the product picker, which is not on its screen.
  final bool showSearchButton;
  final VoidCallback onOpenProducts;
  final VoidCallback onChooseCustomer;
  final VoidCallback onRemoveCustomer;
  final VoidCallback onCompliance;
  final VoidCallback onPay;

  const CartPanel({
    super.key,
    required this.cartNumber,
    required this.lineCount,
    required this.lineBuilder,
    required this.total,
    required this.customer,
    required this.complianceSummary,
    required this.onOpenProducts,
    required this.onChooseCustomer,
    required this.onRemoveCustomer,
    required this.onCompliance,
    required this.onPay,
    this.showSearchButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const Divider(height: 1),
        _columnTitles(context),
        Expanded(child: _lines()),
        Padding(
          padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, _gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppCard(
                padding: EdgeInsets.zero,
                child: CartCustomerTile(
                  customer: customer,
                  onChoose: onChooseCustomer,
                  onRemove: onRemoveCustomer,
                ),
              ),
              const SizedBox(height: _lineGap),
              AppCard(padding: EdgeInsets.zero, child: _complianceTile()),
              const SizedBox(height: 8),
              _CartTotalRow(label: 'ราคาเฉพาะสินค้า', value: _money(total)),
              const _CartTotalRow(label: 'ส่วนลด (%)', value: '-'),
              _CartTotalRow(
                label: 'ยอดรวมสุทธิ',
                value: _money(total),
                valueKey: netTotalKey,
                emphasised: true,
              ),
              const SizedBox(height: 8),
              _payButton(context),
            ],
          ),
        ),
      ],
    );
  }

  static String _money(double amount) => '฿${formatDouble(amount)}';

  Widget _header() {
    return Row(children: [
      if (showSearchButton) ...[
        const SizedBox(width: 4),
        CartSearchButton(onPressed: onOpenProducts),
      ],
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          // A header node of its own: on the web a text merged into a
          // node with children is not written into the page.
          child: Semantics(
            container: true,
            header: true,
            child: Text(
              'ตะกร้าสินค้า #$cartNumber',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    ]);
  }

  /// What each part of a line is: รายการ, จำนวน, ราคา.
  Widget _columnTitles(BuildContext context) {
    final style = TextStyle(
      fontSize: 12,
      height: 1.4,
      color: AppColors.of(context).textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(_gutter + 12, 8, _gutter + 12, 4),
      child: Row(
        children: [
          Expanded(child: Text('รายการ', style: style)),
          SizedBox(
            width: 100,
            child: Text('จำนวน', textAlign: TextAlign.center, style: style),
          ),
          SizedBox(
            width: 100,
            child: Text('ราคา', textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }

  Widget _lines() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, _gutter),
      itemCount: lineCount,
      separatorBuilder: (_, __) => const SizedBox(height: _lineGap),
      itemBuilder: (context, index) => AppCard(
        padding: EdgeInsets.zero,
        child: lineBuilder(context, index),
      ),
    );
  }

  Widget _complianceTile() {
    final summary = complianceSummary;
    return Builder(builder: (context) {
      final colors = AppColors.of(context);
      return ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: colors.surfaceSunken,
          foregroundColor: colors.textPrimary,
          child: const Icon(Icons.medical_information_outlined, size: 20),
        ),
        title: const Text('ข้อมูลยาควบคุม', style: TextStyle(fontSize: 15)),
        subtitle: Text(
          summary == null ? 'ไม่บังคับ ระบุเมื่อจำเป็น' : 'ระบุแล้ว: $summary',
          style: const TextStyle(fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onCompliance,
      );
    });
  }

  Widget _payButton(BuildContext context) {
    final colors = AppColors.of(context);
    final empty = lineCount == 0;
    return ElevatedButton(
      onPressed: empty ? null : onPay,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primaryFill,
        foregroundColor: colors.onPrimaryFill,
        disabledBackgroundColor: colors.surfaceSunken,
        disabledForegroundColor: colors.textSecondary,
        minimumSize: const Size(double.infinity, _payHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            empty ? "เลือกสินค้าเพื่อเริ่มขาย" : "ชำระเงิน ($lineCount รายการ)",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            _money(total),
            style: AppText.money(const TextStyle(
              height: 1.4,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            )),
          ),
        ],
      ),
    );
  }
}

/// One of the cart's totals, read as one line: its label, then its amount.
class _CartTotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Key? valueKey;
  final bool emphasised;

  const _CartTotalRow({
    required this.label,
    required this.value,
    this.valueKey,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final style = TextStyle(
      fontSize: emphasised ? 18 : 14,
      fontWeight: emphasised ? FontWeight.bold : FontWeight.normal,
      color: emphasised ? colors.textPrimary : colors.textSecondary,
    );
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            const SizedBox(width: 8),
            Text(value, key: valueKey, style: AppText.money(style)),
          ],
        ),
      ),
    );
  }
}
