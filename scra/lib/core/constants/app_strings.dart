/// Shared user-facing strings. Screen-specific copy from the Stitch designs
/// lives next to the screen that uses it; strings reused across features
/// belong here.
abstract final class AppStrings {
  static const String appName = 'Smart Class';
  static const String suiteName = 'EduVerse Suite';
  static const String tagline =
      'Intelligent Virtual Classroom & Attendance Management';

  // Generic actions
  static const String next = 'Next';
  static const String back = 'Back';
  static const String skip = 'Skip';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String saveChanges = 'Save Changes';
  static const String retry = 'Retry';
  static const String close = 'Close';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String viewAll = 'View All';
  static const String search = 'Search';
  static const String logout = 'Log Out';
  static const String signIn = 'Sign In';
  static const String backToLogin = 'Back to Login';

  // States
  static const String loading = 'Loading...';
  static const String nothingHere = 'Nothing here yet';
  static const String somethingWentWrong = 'Something went wrong';
  static const String noConnection =
      'Unable to reach the campus server. Check your connection and try again.';
  static const String sessionExpired =
      'Your session has expired. Please sign in again.';
  static const String accessDenied =
      'You do not have permission to open this section.';

  // Roles
  static const String student = 'Student';
  static const String lecturer = 'Lecturer';
  static const String admin = 'Admin';

  // Logout
  static const String logoutTitle = 'Log out of Smart Class?';
  static const String logoutMessage =
      'You will need to sign in again with your institutional credentials.';
}
