import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware dates (uses [Localizations.localeOf]).
abstract final class LocaleDates {
  static String yMd(BuildContext context, DateTime d) =>
      DateFormat.yMd(Localizations.localeOf(context).toString()).format(d);

  static String yMMMd(BuildContext context, DateTime d) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(d);

  /// Month + day, compact (charts, small labels).
  static String mdShort(BuildContext context, DateTime d) =>
      DateFormat('MMM d', Localizations.localeOf(context).toString()).format(d);

  /// e.g. community post timestamp
  static String dMMMHm(BuildContext context, DateTime d) =>
      DateFormat('d MMM, HH:mm', Localizations.localeOf(context).toString()).format(d);
}
