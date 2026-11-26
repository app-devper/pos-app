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

/// The height the phone layout needs at its roomy sizes. With less (most
/// phones) it tightens — closer gaps, lower boxes, the keypad as tall as what
/// is left — so the keypad's last row is not under the pay button.
const _roomyPhoneHeight = 712.0;

/// What the tightened phone layout takes besides its keypad: the method row,
/// the amounts, one row of quick-cash chips and the pay button.
const _tightRestHeight = 314.0;

/// The keypad's height: four rows of at least a finger's target, at most the
/// roomy 250 px.
const _keypadMinHeight = 204.0;
const _keypadMaxHeight = 250.0;

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
    return LayoutBuilder(builder: (context, constraints) {
      final tight = Responsive.isMobile(context) &&
          constraints.maxHeight < _roomyPhoneHeight;
      final gap = tight ? _tightGap : _roomyGap;
      final keypadHeight = tight
          ? (constraints.maxHeight - _tightRestHeight)
              .clamp(_keypadMinHeight, _keypadMaxHeight)
          : _keypadMaxHeight;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, gap, 16, 0),
              child: _buildBody(tight: tight, keypadHeight: keypadHeight),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, gap, 16, tight ? 12 : 16),
            child: _buildPayButton(tight: tight),
          ),
        ],
      );
    });
  }

  static const _roomyGap = 16.0;
  static const _tightGap = 8.0;

  Widget _buildBody({required bool tight, required double keypadHeight}) {
    // On a phone the method is chosen first, in a row under the title where
    // it is seen; on a wide screen it stays beside the keypad.
    final narrow = Responsive.isMobile(context);
    final gap = SizedBox(height: tight ? _tightGap : _roomyGap);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (narrow) ...[
          _buildPaymentOptionsRow(tight: tight),
          gap,
        ],
        _buildInputSection(
            Languages.of(context).amountReceived, _getNumberFormat(_number),
            tight: tight),
        gap,
        Row(
          children: [
            Expanded(
              child: _buildAmountBox(Languages.of(context).amountDue,
                  "฿${formatDouble(widget.amount)}",
                  tight: tight),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAmountBox(Languages.of(context).change,
                  _change > 0 ? "฿${formatDouble(_change)}" : "",
                  tight: tight),
            ),
          ],
        ),
        if (_typeMode == "Cash") ...[
          gap,
          QuickCashChips(
              total: widget.amount,
              onSelected: _receiveQuickCash,
              singleRow: tight),
        ],
        gap,
        if (narrow)
          _buildKeypad(keypadHeight)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(flex: 1, child: _buildPaymentOptions()),
              const SizedBox(width: 16),
              Flexible(flex: 2, child: _buildKeypad(keypadHeight)),
            ],
          ),
      ],
    );
  }

  Widget _buildKeypad(double height) {
    return SizedBox(
      height: height,
      child: InputNumber(
        key: ValueKey(_keypadGeneration),
        onDone: (_) => _pay(),
        onChange: _calculate,
      ),
    );
  }

  /// The phone's method choice: the two options side by side.
  Widget _buildPaymentOptionsRow({required bool tight}) {
    final height = tight ? _tightOptionHeight : _compactOptionHeight;
    return Row(
      children: [
        Expanded(
          child: _buildPaymentOption(
            Languages.of(context).cash,
            iconData: Icons.money,
            compactHeight: height,
            isSelected: _typeMode == "Cash",
            onTap: () => _selectMethod("Cash"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPaymentOption(
            Languages.of(context).promptPay,
            iconData: Icons.qr_code_2,
            compactHeight: height,
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

  Widget _buildPayButton({required bool tight}) {
    return ElevatedButton(
      onPressed: _pay,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        minimumSize: Size(double.infinity, tight ? 56 : 64),
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

  Widget _buildInputSection(String title, String amount,
      {required bool tight}) {
    final received = (!_isInput && amount.isEmpty)
        ? Text("฿${formatDouble(widget.amount)}",
            style: AppText.money(TextStyle(
                fontSize: 24,
                color: AppColors.of(context).textSecondary,
                fontWeight: FontWeight.bold)))
        : Text("฿$amount",
            style: AppText.money(
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
    final label = Text(title,
        style:
            TextStyle(fontSize: tight ? 16 : 20, fontWeight: FontWeight.bold));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: tight ? 6 : 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      // Tightened, the title and the amount share one line.
      child: tight
          ? Row(
              children: [
                label,
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: received,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [label, received],
            ),
    );
  }

  static const _amountBoxHeight = 80.0;

  /// A sunken box naming an amount: the amount due, or the change ([amount]
  /// empty when there is none).
  Widget _buildAmountBox(String title, String amount, {required bool tight}) {
    return Container(
      // Roomy: at least 80 px; either way taller when a larger system text
      // size needs it.
      constraints: BoxConstraints(minHeight: tight ? 0 : _amountBoxHeight),
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: tight ? 4 : 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceSunken,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: tight ? 13 : 16,
                  color: AppColors.of(context).textSecondary)),
          // One line, shrunk to the box on a narrow phone, never wrapped.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amount,
                style: AppText.money(TextStyle(
                    fontSize: tight ? 20 : 24,
                    color: AppColors.of(context).textPrimary,
                    fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }

  /// A method option: a tall card beside the keypad, or, with a
  /// [compactHeight], a row that high (icon, name, check mark) on a phone. The check mark marks the
  /// selected one, besides its border.
  Widget _buildPaymentOption(String title,
      {required IconData iconData,
      bool isSelected = false,
      double? compactHeight,
      Function()? onTap}) {
    // A screen reader hears a button, and which method is chosen; the
    // check icon alone said it only to the eye.
    return Semantics(
      button: true,
      selected: isSelected,
      child: compactHeight != null
          ? _buildCompactOption(title,
              height: compactHeight,
              iconData: iconData,
              isSelected: isSelected,
              onTap: onTap)
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

  /// The tightened row: still a finger's target.
  static const _tightOptionHeight = 48.0;

  Widget _buildCompactOption(String title,
      {required double height,
      required IconData iconData,
      required bool isSelected,
      Function()? onTap}) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: () => onTap?.call(),
      child: Container(
        height: height,
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
