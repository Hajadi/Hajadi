import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/card_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/payment_labels.dart';
import '../../../core/widgets/card_brand_mark.dart';
import '../../../core/widgets/common.dart';
import '../../../models/invoice.dart';
import '../../../models/job_request.dart';
import '../../../services/payment_service.dart';
import '../../../viewmodels/payment_view_model.dart';
import '../../../viewmodels/session_view_model.dart';

/// Checkout for one invoice: MonCash, NatCash, Visa/Mastercard or cash.
Future<void> showPaymentSheet(
  BuildContext context, {
  required Invoice invoice,
  List<PaymentMethod>? allowedMethods,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _PaymentSheet(
          invoice: invoice,
          allowedMethods: allowedMethods ?? PaymentMethod.values,
        ),
      ),
    );

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.invoice, required this.allowedMethods});

  final Invoice invoice;
  final List<PaymentMethod> allowedMethods;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late PaymentMethod _method = widget.allowedMethods.contains(widget.invoice.method)
      ? widget.invoice.method
      : widget.allowedMethods.first;

  late final TextEditingController _phone = TextEditingController(
    text: context.read<SessionViewModel>().user?.phone ?? '',
  );
  final TextEditingController _cardNumber = TextEditingController();
  final TextEditingController _cardExpiry = TextEditingController();
  final TextEditingController _cardCvc = TextEditingController();
  final TextEditingController _cardHolder = TextEditingController();

  bool _busy = false;

  CardBrand get _brand => CardUtils.brandOf(_cardNumber.text);

  CardDetails get _card => CardDetails(
        number: _cardNumber.text,
        expiry: _cardExpiry.text,
        cvc: _cardCvc.text,
        holder: _cardHolder.text,
      );

  @override
  void dispose() {
    _phone.dispose();
    _cardNumber.dispose();
    _cardExpiry.dispose();
    _cardCvc.dispose();
    _cardHolder.dispose();
    super.dispose();
  }

  /// Blocks the pay button until the form is actually payable, so a decline
  /// costs a round trip only when the card itself is the problem.
  bool get _canSubmit {
    if (_busy) {
      return false;
    }
    if (_method == PaymentMethod.card) {
      return _card.validate() == null;
    }
    if (_method.needsPayerPhone) {
      return _phone.text.trim().length >= 8;
    }
    return true;
  }

  Future<void> _submit() async {
    final Strings s = context.l10n;
    final PaymentViewModel payments = context.read<PaymentViewModel>();

    setState(() => _busy = true);
    final PaymentIntent? intent = await payments.pay(
      invoice: widget.invoice,
      method: _method,
      payerPhone: _phone.text.trim(),
      card: _method == PaymentMethod.card ? _card : null,
    );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);

    if (intent == null) {
      // The view-model mapped the failure to a catalog key.
      showAppSnackBar(
        context,
        context.l10nRaw.raw(payments.errorKey ?? 'paymentFailed'),
        error: true,
      );
      return;
    }

    // A hosted checkout page or a 3-D Secure challenge finishes the payment
    // outside the app; the provider webhook is what marks the invoice paid.
    final String? redirect = intent.redirectUrl;
    if (redirect != null && redirect.isNotEmpty) {
      await launchUrl(
        Uri.parse(redirect),
        mode: LaunchMode.externalApplication,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    Navigator.of(context).pop();
    showAppSnackBar(
      context,
      _method == PaymentMethod.cash ? s.requestSentBody : s.paymentSuccess,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final String localeCode = Localizations.localeOf(context).languageCode;
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(s.payWith, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  children: <Widget>[
                    _Line(
                      label: s.subtotal,
                      value:
                          Formatters.money(widget.invoice.subtotal, localeCode),
                    ),
                    _Line(
                      label: s.serviceFee,
                      value: Formatters.money(
                        widget.invoice.serviceFee,
                        localeCode,
                      ),
                    ),
                    const Divider(),
                    _Line(
                      label: s.total,
                      value: Formatters.money(widget.invoice.total, localeCode),
                      strong: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final PaymentMethod method in widget.allowedMethods)
                    ChoiceChip(
                      avatar: Icon(method.icon, size: 16),
                      label: Text(method.label(s)),
                      selected: _method == method,
                      onSelected: (_) => setState(() => _method = method),
                    ),
                ],
              ),
              if (_method == PaymentMethod.card) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        s.acceptedCards,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const AcceptedCardBrands(),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _CardForm(
                  number: _cardNumber,
                  expiry: _cardExpiry,
                  cvc: _cardCvc,
                  holder: _cardHolder,
                  brand: _brand,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.lock_outline_rounded, size: 14),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        s.cardSecureNote,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              if (_method.needsPayerPhone) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: s.phoneForPayment,
                    prefixIcon: const Icon(Icons.smartphone_rounded),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              BusyButton(
                label: _method == PaymentMethod.cash ? s.confirm : s.payNow,
                busy: _busy,
                onPressed: _canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Number, expiry, security code and cardholder name, with the detected brand
/// shown as the number is typed.
class _CardForm extends StatelessWidget {
  const _CardForm({
    required this.number,
    required this.expiry,
    required this.cvc,
    required this.holder,
    required this.brand,
    required this.onChanged,
  });

  final TextEditingController number;
  final TextEditingController expiry;
  final TextEditingController cvc;
  final TextEditingController holder;
  final CardBrand brand;
  final VoidCallback onChanged;

  /// Shows a validation message only once the field is long enough to judge,
  /// so the form does not shout at someone mid-keystroke.
  String? _errorFor(BuildContext context, String? key, bool ready) =>
      ready && key != null ? context.l10nRaw.raw(key) : null;

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final String digits = CardUtils.digitsOf(number.text);
    final int maxDigits = CardUtils.expectedLength(brand);

    return Column(
      children: <Widget>[
        TextField(
          controller: number,
          keyboardType: TextInputType.number,
          autofillHints: const <String>[AutofillHints.creditCardNumber],
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
            _CardNumberFormatter(),
          ],
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: s.cardNumber,
            hintText: '4242 4242 4242 4242',
            prefixIcon: const Icon(Icons.credit_card_rounded),
            suffixIcon: brand == CardBrand.unknown
                ? null
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 12,
                    ),
                    child: CardBrandMark(brand: brand),
                  ),
            suffixIconConstraints: const BoxConstraints(minWidth: 56),
            errorText: _errorFor(
              context,
              CardUtils.validateNumber(number.text),
              digits.length >= maxDigits,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: expiry,
                keyboardType: TextInputType.number,
                autofillHints: const <String>[
                  AutofillHints.creditCardExpirationDate,
                ],
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryFormatter(),
                ],
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  labelText: s.cardExpiry,
                  hintText: '09/28',
                  errorText: _errorFor(
                    context,
                    CardUtils.validateExpiry(expiry.text),
                    CardUtils.digitsOf(expiry.text).length == 4,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: cvc,
                keyboardType: TextInputType.number,
                obscureText: true,
                autofillHints: const <String>[
                  AutofillHints.creditCardSecurityCode,
                ],
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(CardUtils.cvcLength(brand)),
                ],
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  labelText: s.cardCvc,
                  errorText: _errorFor(
                    context,
                    CardUtils.validateCvc(cvc.text, brand),
                    CardUtils.digitsOf(cvc.text).length >=
                        CardUtils.cvcLength(brand),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: holder,
          textCapitalization: TextCapitalization.characters,
          autofillHints: const <String>[AutofillHints.creditCardName],
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: s.cardHolder,
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
        ),
      ],
    );
  }
}

/// Groups digits as they are typed: `4242 4242 4242 4242`.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String formatted = CardUtils.formatNumber(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Inserts the slash in `MM/YY`.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String formatted = CardUtils.formatExpiry(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: strong
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: strong
                ? theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
