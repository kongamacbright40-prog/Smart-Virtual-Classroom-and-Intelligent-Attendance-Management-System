import 'package:flutter_test/flutter_test.dart';
import 'package:smart_class/core/utils/date_utils.dart';
import 'package:smart_class/core/utils/formatters.dart';
import 'package:smart_class/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('alex.rivers@campus.edu'), isNull);
    });

    test('institutional email domain', () {
      expect(
        Validators.institutionalEmail('a@gmail.com', ['@campus.edu']),
        isNotNull,
      );
      expect(
        Validators.institutionalEmail('a@campus.edu', ['@campus.edu']),
        isNull,
      );
      // Defaults to the ICT University domain.
      expect(
        Validators.institutionalEmail(' Ngono.Marie@ICTUniversity.edu.cm '),
        isNull,
      );
      expect(Validators.institutionalEmail('a@ictuniversity.com'), isNotNull);
      expect(
        Validators.institutionalEmail('a@sub.ictuniversity.edu.cm'),
        isNotNull,
      );
    });

    test('full name needs two names of letters only', () {
      expect(Validators.fullName(''), 'Full name is required');
      expect(Validators.fullName('Ngono'), isNotNull);
      expect(Validators.fullName('Ngono M'), isNotNull);
      expect(Validators.fullName('Ngono 2'), isNotNull);
      expect(Validators.fullName('Ngono M@rie'), isNotNull);
      expect(Validators.fullName('Ngono Marie.'), isNotNull);
      expect(Validators.fullName('Ngono Marie'), isNull);
      expect(Validators.fullName('  Konga   Mac-Bright '), isNull);
      expect(Validators.fullName("Chloé O'Neil Éboué"), isNull);
      expect(Validators.fullName('Jean -Paul'), isNotNull);
    });

    test('identifier accepts emails and any existing ID format', () {
      expect(Validators.identifier(''), isNotNull);
      expect(Validators.identifier('ab'), isNotNull);
      expect(Validators.identifier('bad id'), isNotNull);
      expect(Validators.identifier('x@'), isNotNull);
      expect(Validators.identifier('ICTU20251181'), isNull);
      expect(Validators.identifier('ictu20251181'), isNull);
      expect(Validators.identifier('x@y.edu'), isNull);
      // Accounts created before the ICTU format can still sign in.
      expect(Validators.identifier('ICT20251181'), isNull);
      expect(Validators.identifier('UNI12345'), isNull);
      expect(Validators.identifier('ADM-001'), isNull);
    });

    test('password and new password rules', () {
      // Signing in only needs a password, so older accounts keep working.
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('abc'), isNull);
      // New passwords: 8+ chars with upper, lower, digit and special.
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.newPassword('Ab1!'), isNotNull);
      expect(Validators.newPassword('alllowercase1!'), isNotNull);
      expect(Validators.newPassword('ALLUPPERCASE1!'), isNotNull);
      expect(Validators.newPassword('NoDigits!!'), isNotNull);
      expect(Validators.newPassword('NoSpecial123'), isNotNull);
      expect(Validators.newPassword('Secure123!'), isNull);
      expect(Validators.confirmPassword('a', 'b'), isNotNull);
      expect(Validators.confirmPassword('Secure123', 'Secure123'), isNull);
    });

    test('password strength scoring', () {
      expect(Validators.passwordStrength('').score, 0);
      final strong = Validators.passwordStrength('Secure123!');
      expect(strong.score, PasswordStrength.total);
      expect(strong.isValid, isTrue);
      expect(strong.label, 'Strong');
      expect(Validators.passwordStrength('Secure123').label, 'Fair');
      expect(Validators.passwordStrength('abc').label, 'Weak');
    });

    test('phone', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('', isRequired: false), isNull);
      expect(Validators.phone('+234 803 456 7890'), isNull);
      expect(Validators.phone('12ab'), isNotNull);
    });

    test('institutional IDs', () {
      expect(Validators.studentId('ICTU20249148'), isNull);
      expect(Validators.studentId('ictu20251181'), isNull);
      expect(Validators.studentId(' ICTU20233736 '), isNull);
      expect(Validators.studentId('123'), isNotNull);
      expect(Validators.studentId('ICTU2023373'), isNotNull);
      expect(Validators.studentId('ICTU202337361'), isNotNull);
      expect(Validators.studentId('ICTU30233736'), isNotNull);
      expect(Validators.studentId('ICT-1'), isNotNull);
      expect(Validators.studentId('  '), 'Student matricule is required');
      expect(Validators.staffId('ICTU20183736'), isNull);
      expect(Validators.staffId('FAC-2018-042'), isNotNull);
      expect(Validators.staffId('LEC002'), isNotNull);
      expect(Validators.staffId(''), isNotNull);
      expect(Validators.adminId('ADM-001'), isNull);
      expect(Validators.adminId('ADM-9021-SYS'), isNull);
      expect(Validators.adminId('admin'), isNotNull);
    });

    test('course fields', () {
      expect(Validators.courseCode('CS-301'), isNull);
      expect(Validators.courseCode('MTH1221'), isNull);
      expect(Validators.courseCode('301'), isNotNull);
      expect(Validators.courseTitle('AI'), isNotNull);
      expect(Validators.courseTitle('Data Structures'), isNull);
      expect(Validators.credits('0'), isNotNull);
      expect(Validators.credits('4'), isNull);
      expect(Validators.credits('x'), isNotNull);
    });

    test('class scheduling fields', () {
      final now = DateTime(2026, 9, 25, 12);
      expect(Validators.classDate(null, now: now), isNotNull);
      expect(Validators.classDate(DateTime(2026, 9, 24), now: now), isNotNull);
      expect(Validators.classDate(DateTime(2026, 9, 25, 8), now: now), isNull);
      expect(Validators.classTimeRange(600, 590), isNotNull);
      expect(Validators.classTimeRange(600, 605), isNotNull);
      expect(Validators.classTimeRange(600, 690), isNull);
      expect(Validators.time24h('25:00'), isNotNull);
      expect(Validators.time24h('09:30'), isNull);
    });

    test('question creation fields', () {
      expect(Validators.questionText('Hi'), isNotNull);
      expect(Validators.questionText('What is O(log n)?'), isNull);
      expect(Validators.questionOptions(['A'], 0), isNotNull);
      expect(Validators.questionOptions(['A', ''], 0), isNotNull);
      expect(Validators.questionOptions(['A', 'a'], 0), isNotNull);
      expect(Validators.questionOptions(['A', 'B'], null), isNotNull);
      expect(Validators.questionOptions(['A', 'B'], 1), isNull);
    });

    test('recovery code', () {
      expect(Validators.recoveryCode('12'), isNotNull);
      expect(Validators.recoveryCode('12a4'), isNotNull);
      expect(Validators.recoveryCode('8429'), isNull);
    });
  });

  group('Formatters', () {
    final d = DateTime(2026, 10, 26, 14, 5);

    test('time and dates', () {
      expect(Formatters.time(d), '2:05 PM');
      expect(Formatters.time(DateTime(2026, 1, 1, 0, 0)), '12:00 AM');
      expect(Formatters.timeFromHhmm('09:30'), '9:30 AM');
      expect(Formatters.date(d), 'Oct 26, 2026');
      expect(Formatters.shortDate(d), 'Mon, Oct 26');
    });

    test('relative labels', () {
      final now = DateTime(2026, 10, 26, 9);
      expect(Formatters.relativeDay(d, now: now), 'Today, 2:05 PM');
      expect(
        Formatters.relativeDay(d.add(const Duration(days: 1)), now: now),
        'Tomorrow, 2:05 PM',
      );
      expect(
        Formatters.timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5m ago',
      );
      expect(Formatters.timeAgo(now, now: now), 'Just now');
    });

    test('durations, numbers and initials', () {
      expect(Formatters.duration(const Duration(minutes: 85)), '1h 25m');
      expect(Formatters.duration(const Duration(minutes: 45)), '45m');
      expect(Formatters.countdown(const Duration(seconds: 42)), '00:42');
      expect(Formatters.compactNumber(1420), '1,420');
      expect(Formatters.compactNumber(3400000), '3.4M');
      expect(Formatters.initials('Prof. Kwame Mensah'), 'KM');
      expect(Formatters.initials('Amina'), 'A');
      expect(Formatters.percent(94.456, decimals: 1), '94.5%');
    });
  });

  group('AppDateUtils', () {
    test('week helpers', () {
      final thu = DateTime(2026, 9, 24);
      expect(AppDateUtils.startOfWeek(thu), DateTime(2026, 9, 21));
      expect(AppDateUtils.weekDays(thu).length, 7);
      expect(AppDateUtils.parseMinutes('10:30'), 630);
      expect(AppDateUtils.parseMinutes('bad'), isNull);
      expect(AppDateUtils.minutesToHhmm(630), '10:30');
      expect(AppDateUtils.combine(thu, '08:15'), DateTime(2026, 9, 24, 8, 15));
    });
  });
}
