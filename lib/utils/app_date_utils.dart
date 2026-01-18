import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  /// Safely converts Timestamp or DateTime to local DateTime.
  static DateTime getDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toLocal();
    } else if (timestamp is DateTime) {
      return timestamp.toLocal();
    }
    return DateTime.now();
  }

  /// Formats date as 'EEEE, MMMM d, yyyy' (e.g., Monday, January 1, 2023).
  static String formatFullDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  /// Formats time as 'h:mm a' (e.g., 5:30 PM).
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Formats date as 'MMMM yyyy' (e.g., January 2023).
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Formats date as 'MMM d, yyyy' (e.g., Jan 1, 2023).
  static String formatMediumDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Formats date as 'MMM' (e.g., Jan).
  static String formatShortMonth(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  /// Formats date as 'yyyy-MM-dd' (e.g., 2023-01-01).
  static String formatIsoDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Formats date as 'E' (e.g., Mon).
  static String formatShortWeekday(DateTime date) {
    return DateFormat('E').format(date);
  }
}
