import 'dart:ui';

import 'package:intl/intl.dart';

String formatDate(DateTime date) => DateFormat('dd-MM-yy').format(date);

DateTime parseDate(date) => DateTime.parse(date);

