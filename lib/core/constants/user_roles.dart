/// Role definitions and permission helpers for the admin moderation system.
///
/// Roles:
///   - `super_admin`   – full access including admin management
///   - `question_admin` – can review reports, see source metadata
///   - `user`           – standard app user
enum UserRole {
  superAdmin,
  questionAdmin,
  user;

  String get value {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.questionAdmin:
        return 'question_admin';
      case UserRole.user:
        return 'user';
    }
  }

  String get displayLabel {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.questionAdmin:
        return 'Question Admin';
      case UserRole.user:
        return 'User';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'question_admin':
        return UserRole.questionAdmin;
      default:
        return UserRole.user;
    }
  }
}

/// Computed permissions derived from a user's role.
class UserPermissions {
  const UserPermissions({
    this.canViewReports = false,
    this.canViewQuestionSource = false,
    this.canManageAdmins = false,
    this.canModerateReports = false,
  });

  final bool canViewReports;
  final bool canViewQuestionSource;
  final bool canManageAdmins;
  final bool canModerateReports;

  /// Derive permissions from a [UserRole].
  factory UserPermissions.fromRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const UserPermissions(
          canViewReports: true,
          canViewQuestionSource: true,
          canManageAdmins: true,
          canModerateReports: true,
        );
      case UserRole.questionAdmin:
        return const UserPermissions(
          canViewReports: true,
          canViewQuestionSource: true,
          canManageAdmins: false,
          canModerateReports: true,
        );
      case UserRole.user:
        return const UserPermissions(
          canViewReports: false,
          canViewQuestionSource: false,
          canManageAdmins: false,
          canModerateReports: false,
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'canViewReports': canViewReports,
      'canViewQuestionSource': canViewQuestionSource,
      'canManageAdmins': canManageAdmins,
      'canModerateReports': canModerateReports,
    };
  }

  factory UserPermissions.fromMap(Map<String, dynamic> data) {
    return UserPermissions(
      canViewReports: data['canViewReports'] as bool? ?? false,
      canViewQuestionSource: data['canViewQuestionSource'] as bool? ?? false,
      canManageAdmins: data['canManageAdmins'] as bool? ?? false,
      canModerateReports: data['canModerateReports'] as bool? ?? false,
    );
  }
}
