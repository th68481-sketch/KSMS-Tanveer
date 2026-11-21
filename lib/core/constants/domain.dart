/// Domain vocabulary mirroring the PostgreSQL schema (string-backed enums).

enum TenantType { private, government }

extension TenantTypeX on TenantType {
  String get value => name.toUpperCase();
  static TenantType from(String v) =>
      v == 'GOVERNMENT' ? TenantType.government : TenantType.private;
}

enum AccessRequestKind { schoolRegistration, staffAccess }

extension AccessRequestKindX on AccessRequestKind {
  String get value => switch (this) {
        AccessRequestKind.schoolRegistration => 'SCHOOL_REGISTRATION',
        AccessRequestKind.staffAccess => 'STAFF_ACCESS',
      };
  static AccessRequestKind from(String v) => v == 'STAFF_ACCESS'
      ? AccessRequestKind.staffAccess
      : AccessRequestKind.schoolRegistration;
}

enum AccessRequestState {
  requested,
  pendingReview,
  needsInformation,
  approved,
  rejected;

  static AccessRequestState from(String v) => switch (v) {
        'PENDING_REVIEW' => pendingReview,
        'NEEDS_INFORMATION' => needsInformation,
        'APPROVED' => approved,
        'REJECTED' => rejected,
        _ => requested,
      };
}

enum MembershipState { invited, active, suspended, expired }

extension MembershipStateX on MembershipState {
  String get value => name.toUpperCase();
  static MembershipState from(String v) =>
      MembershipState.values.firstWhere((e) => e.value == v,
          orElse: () => MembershipState.invited);
}

enum UserRole {
  platformSuperAdmin('platform_super_admin'),
  governmentAuthorityAdmin('government_authority_admin'),
  tenantAdmin('tenant_admin'),
  principal('principal'),
  vicePrincipal('vice_principal'),
  registrar('registrar'),
  accountant('accountant'),
  teacher('teacher'),
  hrOfficer('hr_officer'),
  opsOfficer('ops_officer'),
  parent('parent'),
  student('student'),
  auditor('auditor');

  const UserRole(this.key);
  final String key;

  static UserRole? from(String key) {
    for (final r in UserRole.values) {
      if (r.key == key) return r;
    }
    return null;
  }
}

/// Permission keys — must mirror `public.permissions` seeds exactly.
abstract final class Permissions {
  static const requestsReviewPlatform = 'requests.review.platform';
  static const requestsReviewGovernment = 'requests.review.government';
  static const tenantsManage = 'tenants.manage';
  static const govRegistryRead = 'gov.registry.read';
  static const govReportsRead = 'gov.reports.read';
  static const schoolSettingsManage = 'school.settings.manage';
  static const campusManage = 'campus.manage';
  static const staffApprove = 'staff.approve';
  static const studentsRead = 'students.read';
  static const studentsWrite = 'students.write';
  static const studentsMerge = 'students.merge';
  static const admissionsWrite = 'admissions.write';
  static const guardiansWrite = 'guardians.write';
  static const academicsManage = 'academics.manage';
  static const assignmentsManage = 'assignments.manage';
  static const timetableManage = 'timetable.manage';
  static const homeworkRead = 'homework.read';
  static const homeworkWrite = 'homework.write';
  static const attendanceMark = 'attendance.mark';
  static const attendanceCorrect = 'attendance.correct';
  static const attendanceRead = 'attendance.read';
  static const examsManage = 'exams.manage';
  static const marksEnter = 'marks.enter';
  static const marksReview = 'marks.review';
  static const marksApprove = 'marks.approve';
  static const resultsPublish = 'results.publish';
  static const financePrivateView = 'finance.private.view';
  static const financeCollect = 'finance.collect';
  static const financeReverse = 'finance.reverse';
  static const financeDiscountApprove = 'finance.discount.approve';
  static const financeGovView = 'finance.gov.view';
  static const financeGovExpenseRequest = 'finance.gov.expense.request';
  static const financeGovExpenseApprove = 'finance.gov.expense.approve';
  static const hrManage = 'hr.manage';
  static const leaveApprove = 'leave.approve';
  static const payrollManage = 'payroll.manage';
  static const libraryManage = 'library.manage';
  static const transportManage = 'transport.manage';
  static const inventoryManage = 'inventory.manage';
  static const noticesCompose = 'notices.compose';
  static const notificationsRead = 'notifications.read';
  static const reportsExport = 'reports.export';
  static const auditRead = 'audit.read';
  static const settingsRead = 'settings.read';

  static const all = [
    requestsReviewPlatform, requestsReviewGovernment, tenantsManage,
    govRegistryRead, govReportsRead, schoolSettingsManage, campusManage,
    staffApprove, studentsRead, studentsWrite, studentsMerge, admissionsWrite,
    guardiansWrite, academicsManage, assignmentsManage, timetableManage,
    homeworkRead, homeworkWrite, attendanceMark, attendanceCorrect,
    attendanceRead, examsManage, marksEnter, marksReview, marksApprove,
    resultsPublish, financePrivateView, financeCollect, financeReverse,
    financeDiscountApprove, financeGovView, financeGovExpenseRequest,
    financeGovExpenseApprove, hrManage, leaveApprove, payrollManage,
    libraryManage, transportManage, inventoryManage, noticesCompose,
    notificationsRead, reportsExport, auditRead, settingsRead,
  ];
}

enum StudentStatus { active, promoted, transferred, withdrawn, graduated, alumnus, left }

extension StudentStatusX on StudentStatus {
  String get value => name.toUpperCase();
  static StudentStatus from(String v) =>
      StudentStatus.values.firstWhere((e) => e.value == v, orElse: () => StudentStatus.active);
}

enum AdmissionStage { enquiry, applied, documentsPending, underReview, approved, rejected, enrolled, withdrawn }

extension AdmissionStageX on AdmissionStage {
  String get value => switch (this) {
        AdmissionStage.enquiry => 'ENQUIRY',
        AdmissionStage.applied => 'APPLIED',
        AdmissionStage.documentsPending => 'DOCUMENTS_PENDING',
        AdmissionStage.underReview => 'UNDER_REVIEW',
        AdmissionStage.approved => 'APPROVED',
        AdmissionStage.rejected => 'REJECTED',
        AdmissionStage.enrolled => 'ENROLLED',
        AdmissionStage.withdrawn => 'WITHDRAWN',
      };
  static AdmissionStage from(String v) =>
      AdmissionStage.values.firstWhere((e) => e.value == v, orElse: () => AdmissionStage.enquiry);
}

enum AttendanceStatus { present, absent, late, leave, excused }

extension AttendanceStatusX on AttendanceStatus {
  String get value => name.toUpperCase();
  static AttendanceStatus? from(String v) {
    for (final s in AttendanceStatus.values) {
      if (s.value == v) return s;
    }
    return null;
  }
}

enum SessionKind { morning, afternoon, custom }

extension SessionKindX on SessionKind {
  String get value => name.toUpperCase();
}

enum SessionState { open, locked, approved }

enum PaymentMethod { cash, bankTransfer, cheque, digital }

extension PaymentMethodX on PaymentMethod {
  String get value => switch (this) {
        PaymentMethod.cash => 'CASH',
        PaymentMethod.bankTransfer => 'BANK_TRANSFER',
        PaymentMethod.cheque => 'CHEQUE',
        PaymentMethod.digital => 'DIGITAL',
      };
  static PaymentMethod from(String v) => switch (v) {
        'BANK_TRANSFER' => PaymentMethod.bankTransfer,
        'CHEQUE' => PaymentMethod.cheque,
        'DIGITAL' => PaymentMethod.digital,
        _ => PaymentMethod.cash,
      };
}

enum InvoiceStatus { draft, issued, partiallyPaid, paid, voided }

enum MarkState { draft, reviewed, approved, published }

enum ExamKind { unit, midterm, finalExam, custom }

extension ExamKindX on ExamKind {
  String get value => switch (this) {
        ExamKind.unit => 'UNIT',
        ExamKind.midterm => 'MIDTERM',
        ExamKind.finalExam => 'FINAL',
        ExamKind.custom => 'CUSTOM',
      };
}

enum ExpenseState { submitted, underReview, approved, rejected, paid }

enum LeaveKind { sick, casual, annual, unpaid, other }

enum HomeworkStatus { draft, published }

enum Gender { male, female, other }

extension GenderX on Gender {
  String get value => name.toUpperCase();
  static Gender from(String v) => switch (v) {
        'FEMALE' => Gender.female,
        'OTHER' => Gender.other,
        _ => Gender.male,
      };
}

/// Roles that must enroll MFA before reaching any dashboard (mirrors seeds).
const mfaRequiredRoles = <String>{
  'platform_super_admin', 'government_authority_admin', 'tenant_admin', 'principal',
};
