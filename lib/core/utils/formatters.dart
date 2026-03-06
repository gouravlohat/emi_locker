import 'package:intl/intl.dart';

abstract class AppFormatters {
  static final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static final _shortDateFmt = DateFormat('dd MMM');
  static final _monthYearFmt = DateFormat('MMM yyyy');

  static String currency(num amount) => _currencyFmt.format(amount);
  static String date(DateTime dt) => _dateFmt.format(dt);
  static String dateTime(DateTime dt) => _dateTimeFmt.format(dt);
  static String shortDate(DateTime dt) => _shortDateFmt.format(dt);
  static String monthYear(DateTime dt) => _monthYearFmt.format(dt);

  static String daysRemaining(DateTime dueDate) {
    final diff = dueDate.difference(DateTime.now()).inDays;
    if (diff < 0) return '${diff.abs()} days overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return '1 day left';
    return '$diff days left';
  }

  static String percentage(double value) => '${(value * 100).toStringAsFixed(1)}%';

  static String compact(num amount) {
    if (amount >= 10000000) return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toString();
  }

  static String imei(String raw) {
    if (raw.length != 15) return raw;
    return '${raw.substring(0, 2)}-${raw.substring(2, 8)}-${raw.substring(8, 14)}-${raw.substring(14)}';
  }

  static String maskedPhone(String phone) {
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 2)}****${phone.substring(phone.length - 4)}';
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(dt);
  }
}
