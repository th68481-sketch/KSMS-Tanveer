
/// Route path constants.
abstract final class Routes {
  static const welcome = '/welcome';
  static const signIn = '/signin';
  static const requestAccess = '/request-access';
  static const statusCheck = '/status';
  static const mfaSetup = '/mfa-setup';
  static const pending = '/pending';
  static const noAccess = '/no-access';
  static const dashboard = '/dash';

  static const adminApprovals = '/admin/approvals';
  static const adminTenants = '/admin/tenants';
  static const govRegistry = '/gov/registry';

  static const students = '/school/students';
  static String studentProfile(String id) => '/school/students/$id';
  static const admissions = '/school/admissions';
  static const academics = '/school/academics';
  static const assignments = '/school/assignments';
  static const timetable = '/school/timetable';
  static const homework = '/school/homework';
  static const attendance = '/school/attendance';
  static const attendanceSync = '/school/attendance/sync';
  static const finance = '/school/finance';
  static const feeCounter = '/school/finance/counter';
  static const reconciliation = '/school/finance/reconciliation';
  static const grants = '/school/grants';
  static const budgets = '/school/budgets';
  static const expenses = '/school/expenses';
  static const hr = '/school/hr';
  static const staffAttendance = '/school/hr/staff-attendance';
  static const leave = '/school/hr/leave';
  static const payroll = '/school/hr/payroll';
  static const library = '/school/library';
  static const transport = '/school/transport';
  static const inventory = '/school/inventory';
  static const notices = '/school/notices';
  static const notifications = '/notifications';
  static const exams = '/school/exams';
  static String examMarks(String examId) => '/school/exams/$examId/marks';
  static String examReview(String examId) => '/school/exams/$examId/review';
  static String examReportCards(String examId) => '/school/exams/$examId/report-cards';
  static const reports = '/reports';
  static const audit = '/audit';
  static const settings = '/settings';
  static const portal = '/portal';
  static const profile = '/profile';
}
