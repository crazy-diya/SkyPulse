import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  static String formatDay(DateTime dateTime) {
    return DateFormat('EEEE').format(dateTime);
  }

  static String formatShortDay(DateTime dateTime) {
    return DateFormat('EEE').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, HH:mm').format(dateTime);
  }

  static String formatFullDateTime(DateTime dateTime) {
    return DateFormat('EEEE, MMM dd, yyyy HH:mm').format(dateTime);
  }
}

