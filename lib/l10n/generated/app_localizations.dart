import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KSMS'**
  String get appName;

  /// No description provided for @common_signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get common_signIn;

  /// No description provided for @common_signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get common_signOut;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @common_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get common_filter;

  /// No description provided for @common_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get common_actions;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get common_view;

  /// No description provided for @common_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get common_create;

  /// No description provided for @common_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get common_submit;

  /// No description provided for @common_noData.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get common_noData;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get common_error;

  /// No description provided for @common_offlineHint.
  ///
  /// In en, this message translates to:
  /// **'Connection issue — tap retry; offline work is queued safely'**
  String get common_offlineHint;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get common_from;

  /// No description provided for @common_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get common_to;

  /// No description provided for @common_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get common_date;

  /// No description provided for @common_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get common_status;

  /// No description provided for @common_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get common_name;

  /// No description provided for @common_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get common_phone;

  /// No description provided for @common_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get common_email;

  /// No description provided for @common_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get common_city;

  /// No description provided for @common_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get common_notes;

  /// No description provided for @common_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get common_reason;

  /// No description provided for @common_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get common_amount;

  /// No description provided for @common_method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get common_method;

  /// No description provided for @common_print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get common_print;

  /// No description provided for @common_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get common_export;

  /// No description provided for @common_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// No description provided for @common_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get common_today;

  /// No description provided for @common_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get common_none;

  /// No description provided for @common_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get common_required;

  /// No description provided for @common_selectHint.
  ///
  /// In en, this message translates to:
  /// **'Select…'**
  String get common_selectHint;

  /// No description provided for @common_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get common_refresh;

  /// No description provided for @common_upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get common_upload;

  /// No description provided for @common_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get common_download;

  /// No description provided for @nav_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get nav_dashboard;

  /// No description provided for @nav_portal.
  ///
  /// In en, this message translates to:
  /// **'My Portal'**
  String get nav_portal;

  /// No description provided for @nav_approvals.
  ///
  /// In en, this message translates to:
  /// **'Approval Queue'**
  String get nav_approvals;

  /// No description provided for @nav_tenants.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get nav_tenants;

  /// No description provided for @nav_registry.
  ///
  /// In en, this message translates to:
  /// **'School Registry'**
  String get nav_registry;

  /// No description provided for @nav_students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get nav_students;

  /// No description provided for @nav_admissions.
  ///
  /// In en, this message translates to:
  /// **'Admissions'**
  String get nav_admissions;

  /// No description provided for @nav_academics.
  ///
  /// In en, this message translates to:
  /// **'Academic Setup'**
  String get nav_academics;

  /// No description provided for @nav_assignments.
  ///
  /// In en, this message translates to:
  /// **'Teacher Assignments'**
  String get nav_assignments;

  /// No description provided for @nav_timetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get nav_timetable;

  /// No description provided for @nav_homework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get nav_homework;

  /// No description provided for @nav_exams.
  ///
  /// In en, this message translates to:
  /// **'Exams & Marks'**
  String get nav_exams;

  /// No description provided for @nav_attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get nav_attendance;

  /// No description provided for @nav_feeManagement.
  ///
  /// In en, this message translates to:
  /// **'Fee Management'**
  String get nav_feeManagement;

  /// No description provided for @nav_feeCounter.
  ///
  /// In en, this message translates to:
  /// **'Fee Counter'**
  String get nav_feeCounter;

  /// No description provided for @nav_reconciliation.
  ///
  /// In en, this message translates to:
  /// **'Daily Reconciliation'**
  String get nav_reconciliation;

  /// No description provided for @nav_grants.
  ///
  /// In en, this message translates to:
  /// **'Grants'**
  String get nav_grants;

  /// No description provided for @nav_budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get nav_budgets;

  /// No description provided for @nav_expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get nav_expenses;

  /// No description provided for @nav_hr.
  ///
  /// In en, this message translates to:
  /// **'Staff Directory'**
  String get nav_hr;

  /// No description provided for @nav_staffAttendance.
  ///
  /// In en, this message translates to:
  /// **'Staff Attendance'**
  String get nav_staffAttendance;

  /// No description provided for @nav_leave.
  ///
  /// In en, this message translates to:
  /// **'Leave Requests'**
  String get nav_leave;

  /// No description provided for @nav_payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get nav_payroll;

  /// No description provided for @nav_library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get nav_library;

  /// No description provided for @nav_transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get nav_transport;

  /// No description provided for @nav_inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get nav_inventory;

  /// No description provided for @nav_notices.
  ///
  /// In en, this message translates to:
  /// **'Notice Board'**
  String get nav_notices;

  /// No description provided for @nav_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports & Exports'**
  String get nav_reports;

  /// No description provided for @nav_audit.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get nav_audit;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @nav_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get nav_notifications;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @sec_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get sec_overview;

  /// No description provided for @sec_access.
  ///
  /// In en, this message translates to:
  /// **'Access & Tenancy'**
  String get sec_access;

  /// No description provided for @sec_students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get sec_students;

  /// No description provided for @sec_academics.
  ///
  /// In en, this message translates to:
  /// **'Academics'**
  String get sec_academics;

  /// No description provided for @sec_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get sec_finance;

  /// No description provided for @sec_people.
  ///
  /// In en, this message translates to:
  /// **'People & Operations'**
  String get sec_people;

  /// No description provided for @sec_system.
  ///
  /// In en, this message translates to:
  /// **'Communication & System'**
  String get sec_system;

  /// No description provided for @auth_welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to KSMS'**
  String get auth_welcomeTitle;

  /// No description provided for @auth_welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Karachi School Management System — one platform for private and government schools, across every campus.'**
  String get auth_welcomeSubtitle;

  /// No description provided for @auth_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_emailLabel;

  /// No description provided for @auth_passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_passwordLabel;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get auth_forgotPassword;

  /// No description provided for @auth_requestAccess.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get auth_requestAccess;

  /// No description provided for @auth_checkStatus.
  ///
  /// In en, this message translates to:
  /// **'Check request status'**
  String get auth_checkStatus;

  /// No description provided for @auth_signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Check your email and password.'**
  String get auth_signInFailed;

  /// No description provided for @auth_resetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get auth_resetSent;

  /// No description provided for @req_schoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Register a school'**
  String get req_schoolTitle;

  /// No description provided for @req_staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Request staff access'**
  String get req_staffTitle;

  /// No description provided for @req_institutionName.
  ///
  /// In en, this message translates to:
  /// **'Institution name'**
  String get req_institutionName;

  /// No description provided for @req_institutionType.
  ///
  /// In en, this message translates to:
  /// **'Institution type'**
  String get req_institutionType;

  /// No description provided for @req_campusName.
  ///
  /// In en, this message translates to:
  /// **'Campus name'**
  String get req_campusName;

  /// No description provided for @req_semisCode.
  ///
  /// In en, this message translates to:
  /// **'SEMIS code (government schools)'**
  String get req_semisCode;

  /// No description provided for @req_requesterName.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get req_requesterName;

  /// No description provided for @req_requesterEmail.
  ///
  /// In en, this message translates to:
  /// **'Your email'**
  String get req_requesterEmail;

  /// No description provided for @req_requesterPhone.
  ///
  /// In en, this message translates to:
  /// **'Your phone'**
  String get req_requesterPhone;

  /// No description provided for @req_requestedRole.
  ///
  /// In en, this message translates to:
  /// **'Requested role'**
  String get req_requestedRole;

  /// No description provided for @req_evidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence documents'**
  String get req_evidence;

  /// No description provided for @req_addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get req_addFiles;

  /// No description provided for @req_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get req_submit;

  /// No description provided for @req_submitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get req_submitted;

  /// No description provided for @req_reference.
  ///
  /// In en, this message translates to:
  /// **'Request reference'**
  String get req_reference;

  /// No description provided for @req_referenceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the reference code from your request confirmation'**
  String get req_referenceHint;

  /// No description provided for @req_statusTitle.
  ///
  /// In en, this message translates to:
  /// **'Request status'**
  String get req_statusTitle;

  /// No description provided for @req_selectSchool.
  ///
  /// In en, this message translates to:
  /// **'Select school'**
  String get req_selectSchool;

  /// No description provided for @req_selectCampus.
  ///
  /// In en, this message translates to:
  /// **'Select campus'**
  String get req_selectCampus;

  /// No description provided for @pending_title.
  ///
  /// In en, this message translates to:
  /// **'Your request is under review'**
  String get pending_title;

  /// No description provided for @pending_body.
  ///
  /// In en, this message translates to:
  /// **'A Platform Admin or the relevant Government Authority will review your request. You will receive an email with an activation link once approved.'**
  String get pending_body;

  /// No description provided for @mfa_title.
  ///
  /// In en, this message translates to:
  /// **'Secure your account with MFA'**
  String get mfa_title;

  /// No description provided for @mfa_body.
  ///
  /// In en, this message translates to:
  /// **'Your role requires two-factor authentication. Scan the QR code or enter the secret into your authenticator app, then verify a code to finish setup.'**
  String get mfa_body;

  /// No description provided for @mfa_secret.
  ///
  /// In en, this message translates to:
  /// **'Secret key'**
  String get mfa_secret;

  /// No description provided for @mfa_code.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get mfa_code;

  /// No description provided for @mfa_verify.
  ///
  /// In en, this message translates to:
  /// **'Verify & activate'**
  String get mfa_verify;

  /// No description provided for @mfa_done.
  ///
  /// In en, this message translates to:
  /// **'MFA activated'**
  String get mfa_done;

  /// No description provided for @role_platform_super_admin.
  ///
  /// In en, this message translates to:
  /// **'Platform Super Admin'**
  String get role_platform_super_admin;

  /// No description provided for @role_government_authority_admin.
  ///
  /// In en, this message translates to:
  /// **'Government Authority Admin'**
  String get role_government_authority_admin;

  /// No description provided for @role_tenant_admin.
  ///
  /// In en, this message translates to:
  /// **'School Owner / Admin'**
  String get role_tenant_admin;

  /// No description provided for @role_principal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get role_principal;

  /// No description provided for @role_vice_principal.
  ///
  /// In en, this message translates to:
  /// **'Vice Principal / Coordinator'**
  String get role_vice_principal;

  /// No description provided for @role_registrar.
  ///
  /// In en, this message translates to:
  /// **'Registrar / Admissions'**
  String get role_registrar;

  /// No description provided for @role_accountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant / Cashier'**
  String get role_accountant;

  /// No description provided for @role_teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get role_teacher;

  /// No description provided for @role_hr_officer.
  ///
  /// In en, this message translates to:
  /// **'HR / Payroll'**
  String get role_hr_officer;

  /// No description provided for @role_ops_officer.
  ///
  /// In en, this message translates to:
  /// **'Library / Transport / Inventory'**
  String get role_ops_officer;

  /// No description provided for @role_parent.
  ///
  /// In en, this message translates to:
  /// **'Parent / Guardian'**
  String get role_parent;

  /// No description provided for @role_student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get role_student;

  /// No description provided for @role_auditor.
  ///
  /// In en, this message translates to:
  /// **'Auditor / Inspector'**
  String get role_auditor;

  /// No description provided for @appr_title.
  ///
  /// In en, this message translates to:
  /// **'Approval Queue'**
  String get appr_title;

  /// No description provided for @appr_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get appr_approve;

  /// No description provided for @appr_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get appr_reject;

  /// No description provided for @appr_requestInfo.
  ///
  /// In en, this message translates to:
  /// **'Request information'**
  String get appr_requestInfo;

  /// No description provided for @appr_reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is mandatory for every decision'**
  String get appr_reasonRequired;

  /// No description provided for @appr_details.
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get appr_details;

  /// No description provided for @appr_kind_school.
  ///
  /// In en, this message translates to:
  /// **'School registration'**
  String get appr_kind_school;

  /// No description provided for @appr_kind_staff.
  ///
  /// In en, this message translates to:
  /// **'Staff access'**
  String get appr_kind_staff;

  /// No description provided for @appr_provisioned.
  ///
  /// In en, this message translates to:
  /// **'Organization provisioned and invitation sent'**
  String get appr_provisioned;

  /// No description provided for @appr_membershipCreated.
  ///
  /// In en, this message translates to:
  /// **'Staff access granted and member notified'**
  String get appr_membershipCreated;

  /// No description provided for @dash_studentsActive.
  ///
  /// In en, this message translates to:
  /// **'Active students'**
  String get dash_studentsActive;

  /// No description provided for @dash_staffActive.
  ///
  /// In en, this message translates to:
  /// **'Active staff'**
  String get dash_staffActive;

  /// No description provided for @dash_attendanceToday.
  ///
  /// In en, this message translates to:
  /// **'Attendance today'**
  String get dash_attendanceToday;

  /// No description provided for @dash_feesDue.
  ///
  /// In en, this message translates to:
  /// **'Fees due'**
  String get dash_feesDue;

  /// No description provided for @dash_pendingLeaves.
  ///
  /// In en, this message translates to:
  /// **'Pending leaves'**
  String get dash_pendingLeaves;

  /// No description provided for @dash_pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get dash_pendingRequests;

  /// No description provided for @dash_tenantsTotal.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get dash_tenantsTotal;

  /// No description provided for @dash_privateSchools.
  ///
  /// In en, this message translates to:
  /// **'Private schools'**
  String get dash_privateSchools;

  /// No description provided for @dash_govSchools.
  ///
  /// In en, this message translates to:
  /// **'Government schools'**
  String get dash_govSchools;

  /// No description provided for @dash_campuses.
  ///
  /// In en, this message translates to:
  /// **'Campuses'**
  String get dash_campuses;

  /// No description provided for @dash_suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get dash_suspended;

  /// No description provided for @dash_grantsActive.
  ///
  /// In en, this message translates to:
  /// **'Active grants'**
  String get dash_grantsActive;

  /// No description provided for @dash_budgetRemaining.
  ///
  /// In en, this message translates to:
  /// **'Budget remaining'**
  String get dash_budgetRemaining;

  /// No description provided for @dash_recentAudit.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dash_recentAudit;

  /// No description provided for @dash_quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dash_quickActions;

  /// No description provided for @dash_schoolsInJurisdiction.
  ///
  /// In en, this message translates to:
  /// **'Schools in your jurisdiction'**
  String get dash_schoolsInJurisdiction;

  /// No description provided for @students_title.
  ///
  /// In en, this message translates to:
  /// **'Student Directory'**
  String get students_title;

  /// No description provided for @students_admissionNo.
  ///
  /// In en, this message translates to:
  /// **'Admission No.'**
  String get students_admissionNo;

  /// No description provided for @students_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get students_gender;

  /// No description provided for @students_dob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get students_dob;

  /// No description provided for @students_class.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get students_class;

  /// No description provided for @students_section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get students_section;

  /// No description provided for @students_roll.
  ///
  /// In en, this message translates to:
  /// **'Roll No.'**
  String get students_roll;

  /// No description provided for @students_new.
  ///
  /// In en, this message translates to:
  /// **'New student'**
  String get students_new;

  /// No description provided for @students_merge.
  ///
  /// In en, this message translates to:
  /// **'Merge duplicates'**
  String get students_merge;

  /// No description provided for @students_mergeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Merge the duplicate record into this student? Guardians, enrollments and finance follow the kept record.'**
  String get students_mergeConfirm;

  /// No description provided for @students_duplicates.
  ///
  /// In en, this message translates to:
  /// **'Potential duplicates'**
  String get students_duplicates;

  /// No description provided for @students_360.
  ///
  /// In en, this message translates to:
  /// **'Student 360°'**
  String get students_360;

  /// No description provided for @students_enrollments.
  ///
  /// In en, this message translates to:
  /// **'Enrollment history'**
  String get students_enrollments;

  /// No description provided for @students_attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get students_attendance;

  /// No description provided for @students_fees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get students_fees;

  /// No description provided for @students_documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get students_documents;

  /// No description provided for @students_results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get students_results;

  /// No description provided for @students_promote.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get students_promote;

  /// No description provided for @students_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get students_transfer;

  /// No description provided for @students_withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get students_withdraw;

  /// No description provided for @students_leavingCert.
  ///
  /// In en, this message translates to:
  /// **'Leaving certificate'**
  String get students_leavingCert;

  /// No description provided for @students_certNo.
  ///
  /// In en, this message translates to:
  /// **'Certificate No.'**
  String get students_certNo;

  /// No description provided for @students_guardians.
  ///
  /// In en, this message translates to:
  /// **'Guardians'**
  String get students_guardians;

  /// No description provided for @students_addGuardian.
  ///
  /// In en, this message translates to:
  /// **'Link guardian'**
  String get students_addGuardian;

  /// No description provided for @students_primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get students_primary;

  /// No description provided for @students_canPickup.
  ///
  /// In en, this message translates to:
  /// **'Can pick up'**
  String get students_canPickup;

  /// No description provided for @students_portalAccess.
  ///
  /// In en, this message translates to:
  /// **'Portal access'**
  String get students_portalAccess;

  /// No description provided for @students_verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get students_verified;

  /// No description provided for @students_relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get students_relationship;

  /// No description provided for @adm_title.
  ///
  /// In en, this message translates to:
  /// **'Admission Pipeline'**
  String get adm_title;

  /// No description provided for @adm_stage_enquiry.
  ///
  /// In en, this message translates to:
  /// **'Enquiry'**
  String get adm_stage_enquiry;

  /// No description provided for @adm_stage_applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get adm_stage_applied;

  /// No description provided for @adm_stage_documents.
  ///
  /// In en, this message translates to:
  /// **'Documents pending'**
  String get adm_stage_documents;

  /// No description provided for @adm_stage_review.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get adm_stage_review;

  /// No description provided for @adm_stage_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get adm_stage_approved;

  /// No description provided for @adm_stage_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adm_stage_rejected;

  /// No description provided for @adm_stage_enrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get adm_stage_enrolled;

  /// No description provided for @adm_stage_withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get adm_stage_withdrawn;

  /// No description provided for @adm_new.
  ///
  /// In en, this message translates to:
  /// **'New enquiry / application'**
  String get adm_new;

  /// No description provided for @adm_advance.
  ///
  /// In en, this message translates to:
  /// **'Advance stage'**
  String get adm_advance;

  /// No description provided for @adm_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve application'**
  String get adm_approve;

  /// No description provided for @adm_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adm_reject;

  /// No description provided for @adm_finalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize enrollment'**
  String get adm_finalize;

  /// No description provided for @adm_finalizeHint.
  ///
  /// In en, this message translates to:
  /// **'Creates the student record, first enrollment and guardian link'**
  String get adm_finalizeHint;

  /// No description provided for @adm_applicationNo.
  ///
  /// In en, this message translates to:
  /// **'Application No.'**
  String get adm_applicationNo;

  /// No description provided for @adm_applicantName.
  ///
  /// In en, this message translates to:
  /// **'Applicant name'**
  String get adm_applicantName;

  /// No description provided for @adm_applicantDob.
  ///
  /// In en, this message translates to:
  /// **'Applicant date of birth'**
  String get adm_applicantDob;

  /// No description provided for @adm_applicantGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get adm_applicantGender;

  /// No description provided for @adm_guardianName.
  ///
  /// In en, this message translates to:
  /// **'Guardian name'**
  String get adm_guardianName;

  /// No description provided for @adm_guardianPhone.
  ///
  /// In en, this message translates to:
  /// **'Guardian phone'**
  String get adm_guardianPhone;

  /// No description provided for @adm_guardianCnic.
  ///
  /// In en, this message translates to:
  /// **'Guardian CNIC'**
  String get adm_guardianCnic;

  /// No description provided for @adm_checklist.
  ///
  /// In en, this message translates to:
  /// **'Document checklist'**
  String get adm_checklist;

  /// No description provided for @adm_enrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrollment created'**
  String get adm_enrolled;

  /// No description provided for @acad_years.
  ///
  /// In en, this message translates to:
  /// **'Academic years'**
  String get acad_years;

  /// No description provided for @acad_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get acad_terms;

  /// No description provided for @acad_classes.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get acad_classes;

  /// No description provided for @acad_sections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get acad_sections;

  /// No description provided for @acad_subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get acad_subjects;

  /// No description provided for @acad_holidays.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get acad_holidays;

  /// No description provided for @acad_scales.
  ///
  /// In en, this message translates to:
  /// **'Grading scales'**
  String get acad_scales;

  /// No description provided for @acad_addYear.
  ///
  /// In en, this message translates to:
  /// **'Add academic year'**
  String get acad_addYear;

  /// No description provided for @acad_addTerm.
  ///
  /// In en, this message translates to:
  /// **'Add term'**
  String get acad_addTerm;

  /// No description provided for @acad_addClass.
  ///
  /// In en, this message translates to:
  /// **'Add class'**
  String get acad_addClass;

  /// No description provided for @acad_addSection.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get acad_addSection;

  /// No description provided for @acad_addSubject.
  ///
  /// In en, this message translates to:
  /// **'Add subject'**
  String get acad_addSubject;

  /// No description provided for @acad_addHoliday.
  ///
  /// In en, this message translates to:
  /// **'Add holiday'**
  String get acad_addHoliday;

  /// No description provided for @acad_addScale.
  ///
  /// In en, this message translates to:
  /// **'Add grading scale'**
  String get acad_addScale;

  /// No description provided for @acad_setCurrent.
  ///
  /// In en, this message translates to:
  /// **'Set as current'**
  String get acad_setCurrent;

  /// No description provided for @acad_numericLevel.
  ///
  /// In en, this message translates to:
  /// **'Numeric level'**
  String get acad_numericLevel;

  /// No description provided for @acad_capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get acad_capacity;

  /// No description provided for @acad_isElective.
  ///
  /// In en, this message translates to:
  /// **'Elective'**
  String get acad_isElective;

  /// No description provided for @acad_code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get acad_code;

  /// No description provided for @acad_boundsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. min 80 = A, min 60 = B (highest first)'**
  String get acad_boundsHint;

  /// No description provided for @assign_title.
  ///
  /// In en, this message translates to:
  /// **'Teacher Assignments'**
  String get assign_title;

  /// No description provided for @assign_teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get assign_teacher;

  /// No description provided for @assign_subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get assign_subject;

  /// No description provided for @assign_weeklyPeriods.
  ///
  /// In en, this message translates to:
  /// **'Weekly periods'**
  String get assign_weeklyPeriods;

  /// No description provided for @assign_new.
  ///
  /// In en, this message translates to:
  /// **'Add assignment'**
  String get assign_new;

  /// No description provided for @assign_anyTerm.
  ///
  /// In en, this message translates to:
  /// **'Whole year'**
  String get assign_anyTerm;

  /// No description provided for @tt_title.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get tt_title;

  /// No description provided for @tt_day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get tt_day;

  /// No description provided for @tt_period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get tt_period;

  /// No description provided for @tt_room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get tt_room;

  /// No description provided for @tt_add.
  ///
  /// In en, this message translates to:
  /// **'Add slot'**
  String get tt_add;

  /// No description provided for @tt_conflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict: {message}'**
  String tt_conflict(String message);

  /// No description provided for @tt_autoArrange.
  ///
  /// In en, this message translates to:
  /// **'Auto-arrange week'**
  String get tt_autoArrange;

  /// No description provided for @tt_autoHint.
  ///
  /// In en, this message translates to:
  /// **'Greedy builder places each teacher assignment into the first free period, avoiding teacher, room and section clashes.'**
  String get tt_autoHint;

  /// No description provided for @tt_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear week'**
  String get tt_clear;

  /// No description provided for @tt_teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get tt_teacher;

  /// No description provided for @tt_subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get tt_subject;

  /// No description provided for @hw_title.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get hw_title;

  /// No description provided for @hw_dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due on'**
  String get hw_dueOn;

  /// No description provided for @hw_assignedOn.
  ///
  /// In en, this message translates to:
  /// **'Assigned on'**
  String get hw_assignedOn;

  /// No description provided for @hw_publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get hw_publish;

  /// No description provided for @hw_published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get hw_published;

  /// No description provided for @hw_draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get hw_draft;

  /// No description provided for @hw_new.
  ///
  /// In en, this message translates to:
  /// **'New homework'**
  String get hw_new;

  /// No description provided for @hw_attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get hw_attachments;

  /// No description provided for @att_title.
  ///
  /// In en, this message translates to:
  /// **'Attendance Workspace'**
  String get att_title;

  /// No description provided for @att_mark.
  ///
  /// In en, this message translates to:
  /// **'Mark attendance'**
  String get att_mark;

  /// No description provided for @att_allPresent.
  ///
  /// In en, this message translates to:
  /// **'All present'**
  String get att_allPresent;

  /// No description provided for @att_save.
  ///
  /// In en, this message translates to:
  /// **'Save attendance'**
  String get att_save;

  /// No description provided for @att_locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get att_locked;

  /// No description provided for @att_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get att_approved;

  /// No description provided for @att_lock.
  ///
  /// In en, this message translates to:
  /// **'Lock session'**
  String get att_lock;

  /// No description provided for @att_approveSession.
  ///
  /// In en, this message translates to:
  /// **'Approve session'**
  String get att_approveSession;

  /// No description provided for @att_correctionReason.
  ///
  /// In en, this message translates to:
  /// **'Correction reason (required for locked sessions)'**
  String get att_correctionReason;

  /// No description provided for @att_offlineQueued.
  ///
  /// In en, this message translates to:
  /// **'No connection — saved to encrypted offline queue'**
  String get att_offlineQueued;

  /// No description provided for @att_conflicts.
  ///
  /// In en, this message translates to:
  /// **'Sync conflicts'**
  String get att_conflicts;

  /// No description provided for @att_keepServer.
  ///
  /// In en, this message translates to:
  /// **'Keep server value'**
  String get att_keepServer;

  /// No description provided for @att_forceLocal.
  ///
  /// In en, this message translates to:
  /// **'Apply my values'**
  String get att_forceLocal;

  /// No description provided for @att_forceReason.
  ///
  /// In en, this message translates to:
  /// **'Override reason'**
  String get att_forceReason;

  /// No description provided for @att_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get att_history;

  /// No description provided for @att_summary.
  ///
  /// In en, this message translates to:
  /// **'Monthly summary'**
  String get att_summary;

  /// No description provided for @att_present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get att_present;

  /// No description provided for @att_absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get att_absent;

  /// No description provided for @att_late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get att_late;

  /// No description provided for @att_leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get att_leave;

  /// No description provided for @att_excused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get att_excused;

  /// No description provided for @att_sessionKind.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get att_sessionKind;

  /// No description provided for @att_noStudents.
  ///
  /// In en, this message translates to:
  /// **'No active students in this section'**
  String get att_noStudents;

  /// No description provided for @exam_title.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get exam_title;

  /// No description provided for @exam_new.
  ///
  /// In en, this message translates to:
  /// **'New exam'**
  String get exam_new;

  /// No description provided for @exam_name.
  ///
  /// In en, this message translates to:
  /// **'Exam name'**
  String get exam_name;

  /// No description provided for @exam_kind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get exam_kind;

  /// No description provided for @exam_subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects & marks'**
  String get exam_subjects;

  /// No description provided for @exam_addSubject.
  ///
  /// In en, this message translates to:
  /// **'Add subject paper'**
  String get exam_addSubject;

  /// No description provided for @exam_maxMarks.
  ///
  /// In en, this message translates to:
  /// **'Max marks'**
  String get exam_maxMarks;

  /// No description provided for @exam_passing.
  ///
  /// In en, this message translates to:
  /// **'Passing marks'**
  String get exam_passing;

  /// No description provided for @exam_weightage.
  ///
  /// In en, this message translates to:
  /// **'Weightage %'**
  String get exam_weightage;

  /// No description provided for @exam_examDate.
  ///
  /// In en, this message translates to:
  /// **'Exam date'**
  String get exam_examDate;

  /// No description provided for @exam_marksEntry.
  ///
  /// In en, this message translates to:
  /// **'Marks entry'**
  String get exam_marksEntry;

  /// No description provided for @exam_review.
  ///
  /// In en, this message translates to:
  /// **'Review & approval'**
  String get exam_review;

  /// No description provided for @exam_submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get exam_submitReview;

  /// No description provided for @exam_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve marks'**
  String get exam_approve;

  /// No description provided for @exam_publish.
  ///
  /// In en, this message translates to:
  /// **'Publish results'**
  String get exam_publish;

  /// No description provided for @exam_publishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Publish results? Approved marks become visible to parents and students and marks are locked.'**
  String get exam_publishConfirm;

  /// No description provided for @exam_reportCards.
  ///
  /// In en, this message translates to:
  /// **'Report cards'**
  String get exam_reportCards;

  /// No description provided for @exam_obtained.
  ///
  /// In en, this message translates to:
  /// **'Obtained'**
  String get exam_obtained;

  /// No description provided for @exam_grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get exam_grade;

  /// No description provided for @exam_remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get exam_remarks;

  /// No description provided for @exam_saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get exam_saveDraft;

  /// No description provided for @exam_amend.
  ///
  /// In en, this message translates to:
  /// **'Amend published mark'**
  String get exam_amend;

  /// No description provided for @exam_amendReason.
  ///
  /// In en, this message translates to:
  /// **'Amendment reason'**
  String get exam_amendReason;

  /// No description provided for @exam_classSummary.
  ///
  /// In en, this message translates to:
  /// **'Class summary'**
  String get exam_classSummary;

  /// No description provided for @exam_rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get exam_rank;

  /// No description provided for @exam_percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get exam_percentage;

  /// No description provided for @fin_heads.
  ///
  /// In en, this message translates to:
  /// **'Fee heads'**
  String get fin_heads;

  /// No description provided for @fin_plans.
  ///
  /// In en, this message translates to:
  /// **'Fee plans'**
  String get fin_plans;

  /// No description provided for @fin_discounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts & waivers'**
  String get fin_discounts;

  /// No description provided for @fin_invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get fin_invoices;

  /// No description provided for @fin_addHead.
  ///
  /// In en, this message translates to:
  /// **'Add fee head'**
  String get fin_addHead;

  /// No description provided for @fin_addPlan.
  ///
  /// In en, this message translates to:
  /// **'Add fee plan'**
  String get fin_addPlan;

  /// No description provided for @fin_addItem.
  ///
  /// In en, this message translates to:
  /// **'Add plan item'**
  String get fin_addItem;

  /// No description provided for @fin_headCode.
  ///
  /// In en, this message translates to:
  /// **'Head code'**
  String get fin_headCode;

  /// No description provided for @fin_recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get fin_recurring;

  /// No description provided for @fin_defaultAmount.
  ///
  /// In en, this message translates to:
  /// **'Default amount'**
  String get fin_defaultAmount;

  /// No description provided for @fin_frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get fin_frequency;

  /// No description provided for @fin_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get fin_monthly;

  /// No description provided for @fin_termly.
  ///
  /// In en, this message translates to:
  /// **'Termly'**
  String get fin_termly;

  /// No description provided for @fin_annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get fin_annual;

  /// No description provided for @fin_oneTime.
  ///
  /// In en, this message translates to:
  /// **'One time'**
  String get fin_oneTime;

  /// No description provided for @fin_effectiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Effective from'**
  String get fin_effectiveFrom;

  /// No description provided for @fin_generateInvoices.
  ///
  /// In en, this message translates to:
  /// **'Generate invoices'**
  String get fin_generateInvoices;

  /// No description provided for @fin_generateHint.
  ///
  /// In en, this message translates to:
  /// **'Creates invoices for active students of the selected class for the given period'**
  String get fin_generateHint;

  /// No description provided for @fin_billingPeriod.
  ///
  /// In en, this message translates to:
  /// **'Billing period (e.g. 2026-01)'**
  String get fin_billingPeriod;

  /// No description provided for @fin_dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get fin_dueDate;

  /// No description provided for @fin_invoiceNo.
  ///
  /// In en, this message translates to:
  /// **'Invoice No.'**
  String get fin_invoiceNo;

  /// No description provided for @fin_gross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get fin_gross;

  /// No description provided for @fin_discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get fin_discount;

  /// No description provided for @fin_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get fin_paid;

  /// No description provided for @fin_balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get fin_balance;

  /// No description provided for @fin_collect.
  ///
  /// In en, this message translates to:
  /// **'Collect payment'**
  String get fin_collect;

  /// No description provided for @fin_referenceNo.
  ///
  /// In en, this message translates to:
  /// **'Reference No.'**
  String get fin_referenceNo;

  /// No description provided for @fin_receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get fin_receipt;

  /// No description provided for @fin_printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print receipt'**
  String get fin_printReceipt;

  /// No description provided for @fin_reversal.
  ///
  /// In en, this message translates to:
  /// **'Reverse / refund'**
  String get fin_reversal;

  /// No description provided for @fin_reversalReason.
  ///
  /// In en, this message translates to:
  /// **'Reversal reason'**
  String get fin_reversalReason;

  /// No description provided for @fin_reversed.
  ///
  /// In en, this message translates to:
  /// **'Payment reversed'**
  String get fin_reversed;

  /// No description provided for @fin_collected.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get fin_collected;

  /// No description provided for @fin_discountApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get fin_discountApprove;

  /// No description provided for @fin_discountReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get fin_discountReject;

  /// No description provided for @fin_kind_sibling.
  ///
  /// In en, this message translates to:
  /// **'Sibling'**
  String get fin_kind_sibling;

  /// No description provided for @fin_kind_scholarship.
  ///
  /// In en, this message translates to:
  /// **'Scholarship'**
  String get fin_kind_scholarship;

  /// No description provided for @fin_kind_waiver.
  ///
  /// In en, this message translates to:
  /// **'Waiver'**
  String get fin_kind_waiver;

  /// No description provided for @fin_kind_staffChild.
  ///
  /// In en, this message translates to:
  /// **'Staff child'**
  String get fin_kind_staffChild;

  /// No description provided for @fin_kind_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get fin_kind_other;

  /// No description provided for @fin_validFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get fin_validFrom;

  /// No description provided for @fin_validTo.
  ///
  /// In en, this message translates to:
  /// **'Valid to'**
  String get fin_validTo;

  /// No description provided for @fin_daySummary.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get fin_daySummary;

  /// No description provided for @fin_collectedToday.
  ///
  /// In en, this message translates to:
  /// **'Collected today'**
  String get fin_collectedToday;

  /// No description provided for @fin_method_cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get fin_method_cash;

  /// No description provided for @fin_method_bank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get fin_method_bank;

  /// No description provided for @fin_method_cheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get fin_method_cheque;

  /// No description provided for @fin_method_digital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get fin_method_digital;

  /// No description provided for @fin_selectStudent.
  ///
  /// In en, this message translates to:
  /// **'Select student'**
  String get fin_selectStudent;

  /// No description provided for @fin_addDiscount.
  ///
  /// In en, this message translates to:
  /// **'New discount / waiver'**
  String get fin_addDiscount;

  /// No description provided for @gov_grants.
  ///
  /// In en, this message translates to:
  /// **'Grants & funds'**
  String get gov_grants;

  /// No description provided for @gov_newGrant.
  ///
  /// In en, this message translates to:
  /// **'Record grant'**
  String get gov_newGrant;

  /// No description provided for @gov_source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get gov_source;

  /// No description provided for @gov_fiscalYear.
  ///
  /// In en, this message translates to:
  /// **'Fiscal year'**
  String get gov_fiscalYear;

  /// No description provided for @gov_budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get gov_budgets;

  /// No description provided for @gov_newBudget.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get gov_newBudget;

  /// No description provided for @gov_allocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get gov_allocated;

  /// No description provided for @gov_committed.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get gov_committed;

  /// No description provided for @gov_remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get gov_remaining;

  /// No description provided for @gov_expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get gov_expenses;

  /// No description provided for @gov_newExpense.
  ///
  /// In en, this message translates to:
  /// **'Request expense'**
  String get gov_newExpense;

  /// No description provided for @gov_expenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense title'**
  String get gov_expenseTitle;

  /// No description provided for @gov_evidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get gov_evidence;

  /// No description provided for @gov_submitExpense.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval'**
  String get gov_submitExpense;

  /// No description provided for @gov_reviewExpense.
  ///
  /// In en, this message translates to:
  /// **'Move to review'**
  String get gov_reviewExpense;

  /// No description provided for @gov_approveExpense.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get gov_approveExpense;

  /// No description provided for @gov_rejectExpense.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get gov_rejectExpense;

  /// No description provided for @gov_markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get gov_markPaid;

  /// No description provided for @gov_paidReference.
  ///
  /// In en, this message translates to:
  /// **'Payment reference'**
  String get gov_paidReference;

  /// No description provided for @gov_chain.
  ///
  /// In en, this message translates to:
  /// **'Approval chain'**
  String get gov_chain;

  /// No description provided for @hr_title.
  ///
  /// In en, this message translates to:
  /// **'Staff Directory'**
  String get hr_title;

  /// No description provided for @hr_newStaff.
  ///
  /// In en, this message translates to:
  /// **'Add staff member'**
  String get hr_newStaff;

  /// No description provided for @hr_employeeCode.
  ///
  /// In en, this message translates to:
  /// **'Employee code'**
  String get hr_employeeCode;

  /// No description provided for @hr_designation.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get hr_designation;

  /// No description provided for @hr_qualification.
  ///
  /// In en, this message translates to:
  /// **'Qualification'**
  String get hr_qualification;

  /// No description provided for @hr_joinedOn.
  ///
  /// In en, this message translates to:
  /// **'Joined on'**
  String get hr_joinedOn;

  /// No description provided for @hr_baseSalary.
  ///
  /// In en, this message translates to:
  /// **'Base salary'**
  String get hr_baseSalary;

  /// No description provided for @hr_attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Attendance'**
  String get hr_attendanceTitle;

  /// No description provided for @hr_markStaff.
  ///
  /// In en, this message translates to:
  /// **'Save staff attendance'**
  String get hr_markStaff;

  /// No description provided for @hr_checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get hr_checkIn;

  /// No description provided for @hr_checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get hr_checkOut;

  /// No description provided for @hr_halfDay.
  ///
  /// In en, this message translates to:
  /// **'Half day'**
  String get hr_halfDay;

  /// No description provided for @leave_title.
  ///
  /// In en, this message translates to:
  /// **'Leave Requests'**
  String get leave_title;

  /// No description provided for @leave_new.
  ///
  /// In en, this message translates to:
  /// **'Apply for leave'**
  String get leave_new;

  /// No description provided for @leave_kind.
  ///
  /// In en, this message translates to:
  /// **'Leave kind'**
  String get leave_kind;

  /// No description provided for @leave_from.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get leave_from;

  /// No description provided for @leave_to.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get leave_to;

  /// No description provided for @payroll_title.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll_title;

  /// No description provided for @payroll_newRun.
  ///
  /// In en, this message translates to:
  /// **'New payroll run'**
  String get payroll_newRun;

  /// No description provided for @payroll_period.
  ///
  /// In en, this message translates to:
  /// **'Period (e.g. 2026-01)'**
  String get payroll_period;

  /// No description provided for @payroll_items.
  ///
  /// In en, this message translates to:
  /// **'Run items'**
  String get payroll_items;

  /// No description provided for @payroll_basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get payroll_basic;

  /// No description provided for @payroll_allowances.
  ///
  /// In en, this message translates to:
  /// **'Allowances'**
  String get payroll_allowances;

  /// No description provided for @payroll_deductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get payroll_deductions;

  /// No description provided for @payroll_net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get payroll_net;

  /// No description provided for @payroll_addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get payroll_addItem;

  /// No description provided for @payroll_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve run'**
  String get payroll_approve;

  /// No description provided for @payroll_markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get payroll_markPaid;

  /// No description provided for @lib_title.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get lib_title;

  /// No description provided for @lib_newItem.
  ///
  /// In en, this message translates to:
  /// **'Add book'**
  String get lib_newItem;

  /// No description provided for @lib_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get lib_author;

  /// No description provided for @lib_isbn.
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get lib_isbn;

  /// No description provided for @lib_copiesTotal.
  ///
  /// In en, this message translates to:
  /// **'Total copies'**
  String get lib_copiesTotal;

  /// No description provided for @lib_copiesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get lib_copiesAvailable;

  /// No description provided for @lib_issueLoan.
  ///
  /// In en, this message translates to:
  /// **'Issue loan'**
  String get lib_issueLoan;

  /// No description provided for @lib_returnLoan.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get lib_returnLoan;

  /// No description provided for @lib_fine.
  ///
  /// In en, this message translates to:
  /// **'Fine'**
  String get lib_fine;

  /// No description provided for @lib_borrower.
  ///
  /// In en, this message translates to:
  /// **'Borrower'**
  String get lib_borrower;

  /// No description provided for @tr_title.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get tr_title;

  /// No description provided for @tr_newRoute.
  ///
  /// In en, this message translates to:
  /// **'Add route'**
  String get tr_newRoute;

  /// No description provided for @tr_vehicleNo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle No.'**
  String get tr_vehicleNo;

  /// No description provided for @tr_driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get tr_driver;

  /// No description provided for @tr_capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get tr_capacity;

  /// No description provided for @tr_monthlyFee.
  ///
  /// In en, this message translates to:
  /// **'Monthly fee'**
  String get tr_monthlyFee;

  /// No description provided for @tr_assign.
  ///
  /// In en, this message translates to:
  /// **'Assign student'**
  String get tr_assign;

  /// No description provided for @tr_pickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Pickup point'**
  String get tr_pickupPoint;

  /// No description provided for @inv_title.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inv_title;

  /// No description provided for @inv_tag.
  ///
  /// In en, this message translates to:
  /// **'Asset tag'**
  String get inv_tag;

  /// No description provided for @inv_quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inv_quantity;

  /// No description provided for @inv_condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get inv_condition;

  /// No description provided for @inv_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get inv_location;

  /// No description provided for @inv_acquiredOn.
  ///
  /// In en, this message translates to:
  /// **'Acquired on'**
  String get inv_acquiredOn;

  /// No description provided for @inv_maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get inv_maintenance;

  /// No description provided for @inv_raiseRequest.
  ///
  /// In en, this message translates to:
  /// **'Raise request'**
  String get inv_raiseRequest;

  /// No description provided for @notices_title.
  ///
  /// In en, this message translates to:
  /// **'Notice Board'**
  String get notices_title;

  /// No description provided for @notices_new.
  ///
  /// In en, this message translates to:
  /// **'New notice'**
  String get notices_new;

  /// No description provided for @notices_titleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get notices_titleEn;

  /// No description provided for @notices_titleUr.
  ///
  /// In en, this message translates to:
  /// **'Title (اردو)'**
  String get notices_titleUr;

  /// No description provided for @notices_bodyEn.
  ///
  /// In en, this message translates to:
  /// **'Body (English)'**
  String get notices_bodyEn;

  /// No description provided for @notices_bodyUr.
  ///
  /// In en, this message translates to:
  /// **'Body (اردو)'**
  String get notices_bodyUr;

  /// No description provided for @notices_audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get notices_audience;

  /// No description provided for @notices_allMembers.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get notices_allMembers;

  /// No description provided for @notices_channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get notices_channels;

  /// No description provided for @notices_expires.
  ///
  /// In en, this message translates to:
  /// **'Expires on'**
  String get notices_expires;

  /// No description provided for @notices_publish.
  ///
  /// In en, this message translates to:
  /// **'Publish notice'**
  String get notices_publish;

  /// No description provided for @notices_recipients.
  ///
  /// In en, this message translates to:
  /// **'{count} recipients'**
  String notices_recipients(int count);

  /// No description provided for @notif_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notif_title;

  /// No description provided for @notif_markAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notif_markAll;

  /// No description provided for @rep_title.
  ///
  /// In en, this message translates to:
  /// **'Reports & Export Center'**
  String get rep_title;

  /// No description provided for @rep_dataset.
  ///
  /// In en, this message translates to:
  /// **'Dataset'**
  String get rep_dataset;

  /// No description provided for @rep_format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get rep_format;

  /// No description provided for @rep_generate.
  ///
  /// In en, this message translates to:
  /// **'Generate export'**
  String get rep_generate;

  /// No description provided for @rep_logged.
  ///
  /// In en, this message translates to:
  /// **'Export recorded in audit log'**
  String get rep_logged;

  /// No description provided for @rep_studentsList.
  ///
  /// In en, this message translates to:
  /// **'Students list'**
  String get rep_studentsList;

  /// No description provided for @rep_attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance summary'**
  String get rep_attendance;

  /// No description provided for @rep_fees.
  ///
  /// In en, this message translates to:
  /// **'Fee collection'**
  String get rep_fees;

  /// No description provided for @rep_examResults.
  ///
  /// In en, this message translates to:
  /// **'Exam results'**
  String get rep_examResults;

  /// No description provided for @rep_semis.
  ///
  /// In en, this message translates to:
  /// **'SEMIS (government)'**
  String get rep_semis;

  /// No description provided for @rep_audit.
  ///
  /// In en, this message translates to:
  /// **'Audit trail'**
  String get rep_audit;

  /// No description provided for @audit_title.
  ///
  /// In en, this message translates to:
  /// **'Audit Log Viewer'**
  String get audit_title;

  /// No description provided for @audit_actor.
  ///
  /// In en, this message translates to:
  /// **'Actor'**
  String get audit_actor;

  /// No description provided for @audit_action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get audit_action;

  /// No description provided for @audit_entity.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get audit_entity;

  /// No description provided for @audit_when.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get audit_when;

  /// No description provided for @audit_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get audit_details;

  /// No description provided for @set_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get set_title;

  /// No description provided for @set_organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get set_organization;

  /// No description provided for @set_campuses.
  ///
  /// In en, this message translates to:
  /// **'Campuses'**
  String get set_campuses;

  /// No description provided for @set_addCampus.
  ///
  /// In en, this message translates to:
  /// **'Add campus'**
  String get set_addCampus;

  /// No description provided for @set_campusCode.
  ///
  /// In en, this message translates to:
  /// **'Campus code'**
  String get set_campusCode;

  /// No description provided for @set_timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get set_timezone;

  /// No description provided for @set_isMain.
  ///
  /// In en, this message translates to:
  /// **'Main campus'**
  String get set_isMain;

  /// No description provided for @set_rolesMatrix.
  ///
  /// In en, this message translates to:
  /// **'Role & permission matrix'**
  String get set_rolesMatrix;

  /// No description provided for @set_attStatuses.
  ///
  /// In en, this message translates to:
  /// **'Attendance statuses'**
  String get set_attStatuses;

  /// No description provided for @set_attStatusesHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated subset of PRESENT, ABSENT, LATE, LEAVE, EXCUSED'**
  String get set_attStatusesHint;

  /// No description provided for @set_semis.
  ///
  /// In en, this message translates to:
  /// **'SEMIS code'**
  String get set_semis;

  /// No description provided for @set_district.
  ///
  /// In en, this message translates to:
  /// **'Government district'**
  String get set_district;

  /// No description provided for @set_province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get set_province;

  /// No description provided for @set_suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend organization'**
  String get set_suspend;

  /// No description provided for @set_activate.
  ///
  /// In en, this message translates to:
  /// **'Activate organization'**
  String get set_activate;

  /// No description provided for @set_danger.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get set_danger;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @profile_fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profile_fullName;

  /// No description provided for @profile_locale.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profile_locale;

  /// No description provided for @profile_mfa.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get profile_mfa;

  /// No description provided for @profile_mfaOn.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get profile_mfaOn;

  /// No description provided for @profile_mfaOff.
  ///
  /// In en, this message translates to:
  /// **'Not enabled'**
  String get profile_mfaOff;

  /// No description provided for @portal_title.
  ///
  /// In en, this message translates to:
  /// **'My Portal'**
  String get portal_title;

  /// No description provided for @portal_children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get portal_children;

  /// No description provided for @portal_attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get portal_attendance;

  /// No description provided for @portal_homework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get portal_homework;

  /// No description provided for @portal_results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get portal_results;

  /// No description provided for @portal_fees.
  ///
  /// In en, this message translates to:
  /// **'Fee status'**
  String get portal_fees;

  /// No description provided for @portal_timetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get portal_timetable;

  /// No description provided for @portal_notices.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get portal_notices;

  /// No description provided for @portal_dueAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get portal_dueAmount;

  /// No description provided for @portal_attendanceRate.
  ///
  /// In en, this message translates to:
  /// **'Attendance rate'**
  String get portal_attendanceRate;

  /// No description provided for @portal_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming homework'**
  String get portal_upcoming;

  /// No description provided for @err_forbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission for this action'**
  String get err_forbidden;

  /// No description provided for @err_generic.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get err_generic;

  /// No description provided for @common_backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get common_backToSignIn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
