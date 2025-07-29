import 'package:intl/intl.dart';

class DateUtils {
  // Format date for display
  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    return DateFormat(format).format(date);
  }

  // Format time for display
  static String formatTime(DateTime time, {String format = 'hh:mm a'}) {
    return DateFormat(format).format(time);
  }

  // Format date and time for display
  static String formatDateTime(DateTime dateTime, {String format = 'MMM dd, yyyy hh:mm a'}) {
    return DateFormat(format).format(dateTime);
  }

  // Get relative time (e.g., "2 hours ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
           date.month == yesterday.month &&
           date.day == yesterday.day;
  }

  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // Get start of week
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }

  // Get end of week
  static DateTime endOfWeek(DateTime date) {
    final daysFromSunday = 7 - date.weekday;
    return date.add(Duration(days: daysFromSunday));
  }

  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // Get days in month
  static int daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  // Get age from date of birth
  static int calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  // Get week number
  static int getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = date.difference(startOfYear).inDays;
    return ((daysSinceStart + startOfYear.weekday - 1) / 7).ceil();
  }

  // Get month name
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  // Get day name
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  // Get short day name
  static String getShortDayName(DateTime date) {
    return DateFormat('E').format(date);
  }

  // Parse date from string
  static DateTime? parseDate(String dateString, {String format = 'yyyy-MM-dd'}) {
    try {
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Get date range for last N days
  static List<DateTime> getDateRange(int days) {
    final now = DateTime.now();
    final List<DateTime> dates = [];
    
    for (int i = days - 1; i >= 0; i--) {
      dates.add(now.subtract(Duration(days: i)));
    }
    
    return dates;
  }

  // Get date range for last N weeks
  static List<DateTime> getWeekRange(int weeks) {
    final now = DateTime.now();
    final List<DateTime> dates = [];
    
    for (int i = weeks - 1; i >= 0; i--) {
      dates.add(now.subtract(Duration(days: i * 7)));
    }
    
    return dates;
  }

  // Get date range for last N months
  static List<DateTime> getMonthRange(int months) {
    final now = DateTime.now();
    final List<DateTime> dates = [];
    
    for (int i = months - 1; i >= 0; i--) {
      dates.add(DateTime(now.year, now.month - i, 1));
    }
    
    return dates;
  }
} 