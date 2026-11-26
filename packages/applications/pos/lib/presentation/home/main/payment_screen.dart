// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:common/core/ext/number_ext.dart';
import 'package:design_system/widgets/dialogs.dart';
import 'package:design_system/theme/text_styles.dart';
import 'package:design_system/widgets/input_number.dart';
import 'package:design_system/widgets/responsive.dart';
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
          title: Languages.of(dialogContext).paymentTitle,
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
    // On a phone the method is chosen first, in a row under the title where
    // it is seen; on a wide screen it stays beside the keypad.
    final narrow = Responsive.isMobile(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (narrow) ...[
          _buildPaymentOptionsRow(),
          const SizedBox(height: 16),
        ],
        _buildInputSection(
            Languages.of(context).amountReceived, _getNumberFormat(_number)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAmountSection(Languages.of(context).amountDue,
                  "฿${formatDouble(widget.amount)}"),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAmountChange(Languages.of(context).change, _change),
            ),
          ],
        ),
        if (_typeMode == "Cash") ...[
          const SizedBox(height: 16),
          QuickCashChips(total: widget.amount, onSelected: _receiveQuickCash),
        ],
        const SizedBox(height: 16),
        if (narrow)
          _buildKeypad()
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(flex: 1, child: _buildPaymentOptions()),
              const SizedBox(width: 16),
              Flexible(flex: 2, child: _buildKeypad()),
            ],
          ),
      ],
    );
  }

  Widget _buildKeypad() {
    return SizedBox(
      height: 250,
      child: InputNumber(
        key: ValueKey(_keypadGeneration),
        onDone: (_) => _pay(),
        onChange: _calculate,
      ),
    );
  }

  /// The phone's method choice: the two options side by side.
  Widget _buildPaymentOptionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildPaymentOption(
            Languages.of(context).cash,
            iconData: Icons.money,
            compact: true,
            isSelected: _typeMode == "Cash",
            onTap: () => _selectMethod("Cash"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPaymentOption(
            Languages.of(context).promptPay,
            iconData: Icons.qr_code_2,
            compact: true,
            isSelected: _isPromptPay,
            onTap: () => _selectMethod("PromptPay"),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        _buildPaymentOption(
          Languages.of(context).cash,
          iconData: Icons.money,
          isSelected: _typeMode == "Cash",
          onTap: () => _selectMethod("Cash"),
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          Languages.of(context).promptPay,
          iconData: Icons.qr_code_2,
          isSelected: _typeMode == "PromptPay",
          onTap: () => _selectMethod("PromptPay"),
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

  bool get _isPromptPay => _typeMode == "PromptPay";

  /// Changes the method to [type], starting from an empty entry: a PromptPay
  /// payment is for exactly the total, with nothing tendered and no change,
  /// and cash chosen again starts afresh rather than with what was entered
  /// before.
  void _selectMethod(String type) {
    if (type == _typeMode) return;
    setState(() {
      _typeMode = type;
      _number = "";
      _change = 0;
      _isInput = false;
      _keypadGeneration++;
    });
  }

  /// Pays the amount due when nothing was entered (and always for
  /// PromptPay), else the amount entered when it covers the amount due;
  /// anything short is refused.
  void _pay() {
    if (_isPromptPay || !_isInput) {
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
    // PromptPay takes no tender: what is keyed in changes nothing.
    if (_isPromptPay) return;
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
    if (_isPromptPay) {
      return _oneLine(Text(
          strings.payByPromptPay("฿${formatDouble(widget.amount)}"),
          style: AppText.money(_payLabelStyle)));
    }
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
        style: AppText.money(_payLabelStyle)));
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
            style: AppText.money(TextStyle(
                fontSize: 24,
                color: AppColors.of(context).textSecondary,
                fontWeight: FontWeight.bold)));
      }
      return Text("฿$amount",
          style: AppText.money(
              const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
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
                style: AppText.money(TextStyle(
                    fontSize: 24,
                    color: AppColors.of(context).textPrimary,
                    fontWeight: FontWeight.bold))),
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
                style: AppText.money(TextStyle(
                    fontSize: 24,
                    color: AppColors.of(context).textPrimary,
                    fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }

  /// A method option: a tall card beside the keypad, or, [compact], a
  /// 56 px row (icon, name, check mark) on a phone. The check mark marks the
  /// selected one, besides its border.
  Widget _buildPaymentOption(String title,
      {required IconData iconData,
      bool isSelected = false,
      bool compact = false,
      Function()? onTap}) {
    // A screen reader hears a button, and which method is chosen; the
    // check icon alone said it only to the eye.
    return Semantics(
      button: true,
      selected: isSelected,
      child: compact
          ? _buildCompactOption(title,
              iconData: iconData, isSelected: isSelected, onTap: onTap)
          : _buildWideOption(title,
              iconData: iconData, isSelected: isSelected, onTap: onTap),
    );
  }

  Widget _buildWideOption(String title,
      {required IconData iconData,
      required bool isSelected,
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
          ],
        ),
      ),
    );
  }

  static const _compactOptionHeight = 56.0;

  Widget _buildCompactOption(String title,
      {required IconData iconData,
      required bool isSelected,
      Function()? onTap}) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: () => onTap?.call(),
      child: Container(
        height: _compactOptionHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? colors.textPrimary : colors.border, width: 2),
        ),
        child: Row(
          children: [
            Icon(iconData, color: colors.textPrimary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? colors.textPrimary : colors.border,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
