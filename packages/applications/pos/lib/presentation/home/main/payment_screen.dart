// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/ext/number_ext.dart';
import 'package:design_system/widgets/dialogs.dart';
import 'package:design_system/widgets/input_number.dart';
import 'package:design_system/widgets/title_bar.dart';

// Project imports:
import 'package:design_system/theme/app_colors.dart';
import 'package:pos/domain/model/sale/money.dart';
import 'package:pos/localizations/language/languages.dart';
import 'package:pos/presentation/home/main/quick_cash_chips.dart';

/// The most the payment dialog grows to fit its content (it is never above
/// 90% of the screen; below that its content scrolls).
const paymentDialogMaxHeight = 720.0;

/// The cart's ชำระเงิน dialog: a title bar over the [PaymentScreen], as tall
/// as its content.
void showPaymentDialog(
  BuildContext context, {
  Key? alertKey,
  required double amount,
  required Function(double, String) onCompleted,
  required Function onError,
}) {
  showCenterDialog(
    context: context,
    alertKey: alertKey,
    maxHeight: paymentDialogMaxHeight,
    builder: (dialogContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TitleBar(
          title: "ชำระเงิน",
          onBack: () {
            Navigator.pop(dialogContext);
          },
        ),
        const Divider(height: 1),
        Flexible(
          child: PaymentScreen(
            amount: amount,
            onCompleted: onCompleted,
            onError: onError,
          ),
        ),
      ],
    ),
  );
}

class PaymentScreen extends StatefulWidget {
  final double amount;
  final Function(double, String) onCompleted;
  final Function onError;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.onCompleted,
    required this.onError,
  });

  @override
  State createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _typeMode = "Cash";
  String _number = "";
  double _change = 0;
  bool _isInput = false;

  /// Bumped when a quick-cash chip sets the amount, so the keypad forgets
  /// what was typed before it and the next key starts a new amount.
  int _keypadGeneration = 0;

  @override
  Widget build(BuildContext context) {
    // The pay button stays at the foot; above it the amounts, chips and
    // keypad are sized by their content and, where the dialog is lower than
    // that (a small phone, a phone held sideways), they scroll rather than
    // squeezing the amounts out of their boxes.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildBody(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildPayButton(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInputSection('ยอดรับเงินรวม', _getNumberFormat(_number)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAmountSection(
                  'ยอดที่ต้องชำระ', "฿${formatDouble(widget.amount)}"),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAmountChange("เงินทอน", _change),
            ),
          ],
        ),
        if (_typeMode == "Cash") ...[
          const SizedBox(height: 16),
          QuickCashChips(total: widget.amount, onSelected: _receiveQuickCash),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(flex: 1, child: _buildPaymentOptions()),
            const SizedBox(width: 16),
            Flexible(
              flex: 2,
              child: SizedBox(
                height: 250,
                child: InputNumber(
                  key: ValueKey(_keypadGeneration),
                  onDone: (_) => _pay(),
                  onChange: _calculate,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        _buildPaymentOption(
          "เงินสด",
          iconData: Icons.money,
          isSelected: _typeMode == "Cash",
          onTap: () => setState(() => _typeMode = "Cash"),
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          "พร้อมเพย์",
          iconData: Icons.qr_code_2,
          isSelected: _typeMode == "PromptPay",
          onTap: () => setState(() => _typeMode = "PromptPay"),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: _pay,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: _payButtonLabel(),
    );
  }

  /// Pays the amount due when nothing was entered, else the amount entered
  /// when it covers the amount due; anything short is refused.
  void _pay() {
    if (!_isInput) {
      widget.onCompleted(widget.amount, _typeMode);
    } else if (_change >= 0) {
      widget.onCompleted(double.parse(_number), _typeMode);
    } else {
      widget.onError();
    }
  }

  /// A quick-cash chip: receives [amount], a whole number of baht.
  void _receiveQuickCash(double amount) {
    setState(() => _keypadGeneration++);
    _calculate(amount.toInt().toString());
  }

  void _calculate(String value) {
    setState(() {
      _isInput = true;
      _number = value;
      if (value.isEmpty || value == "." || value == "0") {
        _change = 0 - widget.amount;
      } else {
        // pos-api's rule, so the till never offers a tender it would refuse.
        final tendered = double.parse(value);
        final tender = Tender.of(tendered, widget.amount);
        _change = tender.covers
            ? tender.change
            : roundMoney(tendered - widget.amount);
      }
    });
  }

  static const _payLabelStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

  /// The pay button's label, centred, each line kept on one line (shrunk to
  /// fit rather than wrapped). Paid exactly, it reads รับชำระพอดี over a
  /// smaller ไม่มีเงินทอน, and is named as one phrase.
  Widget _payButtonLabel() {
    final strings = Languages.of(context);
    if (_change == 0) {
      return Semantics(
        label: strings.exactPaymentName,
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _oneLine(Text(strings.exactPayment, style: _payLabelStyle)),
            _oneLine(Text(strings.exactPaymentNoChange,
                style: const TextStyle(fontSize: 14))),
          ],
        ),
      );
    }
    if (_change < 0) {
      return _oneLine(Text(strings.enterAmountReceived, style: _payLabelStyle));
    }
    return _oneLine(Text(strings.payWithChange("฿${formatDouble(_change)}"),
        style: _payLabelStyle
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()])));
  }

  static Widget _oneLine(Text text) => FittedBox(
        fit: BoxFit.scaleDown,
        child: text,
      );

  String _getNumberFormat(String value) {
    if (value.isEmpty) {
      return "";
    }
    if (value == ".") {
      return ".";
    }
    if (value.contains('.')) {
      final split = value.split('.');
      if (split[0] == "") {
        return '.${split[1]}';
      } else {
        return '${formatDecimal(double.parse(split[0]))}.${split[1]}';
      }
    }
    return formatDecimal(double.parse(value));
  }

  Widget _buildInputSection(String title, String amount) {
    getAmount() {
      if (!_isInput && amount.isEmpty) {
        return Text("฿${formatDouble(widget.amount)}",
            style: TextStyle(
                fontSize: 24,
                color: AppColors.of(context).textSecondary,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()]));
      }
      return Text("฿$amount",
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()]));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          getAmount(),
        ],
      ),
    );
  }

  static const _amountBoxHeight = 80.0;

  Widget _buildAmountSection(String title, String amount) {
    return Container(
      // At least 80 px, taller when a larger system text size needs it.
      constraints: const BoxConstraints(minHeight: _amountBoxHeight),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceSunken,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16, color: AppColors.of(context).textSecondary)),
          // One line, shrunk to the box on a narrow phone, never wrapped.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amount,
                style: TextStyle(
                    fontSize: 24,
                    color: AppColors.of(context).textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChange(String title, double change) {
    getChange() {
      if (change <= 0) {
        return "";
      }
      return "฿${formatDouble(change)}";
    }

    return Container(
      // At least 80 px, taller when a larger system text size needs it.
      constraints: const BoxConstraints(minHeight: _amountBoxHeight),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceSunken,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16, color: AppColors.of(context).textSecondary)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(getChange(),
                style: TextStyle(
                    fontSize: 24,
                    color: AppColors.of(context).textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title,
      {required IconData iconData,
      String? amount,
      bool isSelected = false,
      Function()? onTap}) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
      },
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.of(context).surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? AppColors.of(context).textPrimary
                  : AppColors.of(context).border,
              width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(iconData,
                    color: AppColors.of(context).textPrimary, size: 20),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected
                      ? AppColors.of(context).textPrimary
                      : AppColors.of(context).border,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        color: AppColors.of(context).textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            if (amount != null)
              Text(amount, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
