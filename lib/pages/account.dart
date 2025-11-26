import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login.dart';

/// Account Page with Modern Aesthetic
///
/// Displays comprehensive user profile information in a visually appealing layout
/// with sections for personal info, account status, preferences, and statistics.
class AccountPage extends StatefulWidget {
  final bool isDarkMode;
  final bool isTraditionalChinese;
  final VoidCallback onThemeChanged;
  final VoidCallback onLanguageChanged;
  final bool isLoggedIn;
  final ValueChanged<bool> onLoginStateChanged;

  const AccountPage({
    required this.isDarkMode,
    required this.isTraditionalChinese,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.isLoggedIn,
    required this.onLoginStateChanged,
    super.key,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _hasAttemptedLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileIfNeeded();
    });
  }

  /// Loads user profile if not already loaded
  Future<void> _loadProfileIfNeeded() async {
    if (!mounted) return;
    if (!widget.isLoggedIn) return;
    if (_hasAttemptedLoad) return;

    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();

    if (authService.uid != null) {
      setState(() {
        _hasAttemptedLoad = true;
      });
      userService.getUserProfile(authService.uid!);
    }
  }

  /// Formats DateTime for display
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return widget.isTraditionalChinese ? '不適用' : 'N/A';
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime.toLocal());
  }

  /// Builds section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds info row within a card
  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds status badge
  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds statistics card
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Localised strings
    final personalInfoTitle = widget.isTraditionalChinese ? '個人資料' : 'Personal Information';
    final accountStatusTitle = widget.isTraditionalChinese ? '帳戶狀態' : 'Account Status';
    final preferencesTitle = widget.isTraditionalChinese ? '偏好設定' : 'Preferences';
    final statisticsTitle = widget.isTraditionalChinese ? '統計資料' : 'Statistics';
    final actionsTitle = widget.isTraditionalChinese ? '操作' : 'Actions';

    final uidLabel = widget.isTraditionalChinese ? '使用者ID' : 'User ID';
    final emailLabel = widget.isTraditionalChinese ? '電郵' : 'Email';
    final displayNameLabel = widget.isTraditionalChinese ? '顯示名稱' : 'Display Name';
    final phoneLabel = widget.isTraditionalChinese ? '電話' : 'Phone Number';
    final accountTypeLabel = widget.isTraditionalChinese ? '帳戶類型' : 'Account Type';
    final bioLabel = widget.isTraditionalChinese ? '個人簡介' : 'Bio';

    final verifiedLabel = widget.isTraditionalChinese ? '已驗證' : 'Verified';
    final notVerifiedLabel = widget.isTraditionalChinese ? '未驗證' : 'Not Verified';

    final createdAtLabel = widget.isTraditionalChinese ? '建立日期' : 'Created';
    final modifiedAtLabel = widget.isTraditionalChinese ? '修改日期' : 'Modified';
    final lastLoginLabel = widget.isTraditionalChinese ? '上次登入' : 'Last Login';
    final loginCountLabel = widget.isTraditionalChinese ? '登入次數' : 'Login Count';

    final editProfileLabel = widget.isTraditionalChinese ? '編輯個人資料' : 'Edit Profile';
    final logoutLabel = widget.isTraditionalChinese ? '登出' : 'Logout';

    final loginPrompt = widget.isTraditionalChinese ? '請先登入' : 'Please log in';
    final loginButtonLabel = widget.isTraditionalChinese ? '登入' : 'Login';
    final loadingMessage = widget.isTraditionalChinese ? '載入中...' : 'Loading...';
    final noProfileMessage = widget.isTraditionalChinese ? '沒有找到使用者資料' : 'No profile found';
    final retryLabel = widget.isTraditionalChinese ? '重試' : 'Retry';

    // Early return if not logged in
    if (!widget.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_circle,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loginPrompt,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoginPage(
                            isTraditionalChinese: widget.isTraditionalChinese,
                            isDarkMode: widget.isDarkMode,
                            onThemeChanged: widget.onThemeChanged,
                            onLanguageChanged: widget.onLanguageChanged,
                            onSkip: () => Navigator.of(context).pop(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: Text(loginButtonLabel),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Consumer<UserService>(
      builder: (context, userService, _) {
        // Loading state
        if (userService.isLoading && !_hasAttemptedLoad) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (userService.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userService.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasAttemptedLoad = false;
                      });
                      _loadProfileIfNeeded();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(retryLabel),
                  ),
                ],
              ),
            ),
          );
        }

        final user = userService.currentProfile;

        // No profile state
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    noProfileMessage,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasAttemptedLoad = false;
                      });
                      _loadProfileIfNeeded();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(retryLabel),
                  ),
                ],
              ),
            ),
          );
        }

        // Display profile
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile header with avatar and name
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                            ? NetworkImage(user.photoURL!)
                            : null,
                        backgroundColor: Colors.white,
                        child: user.photoURL == null || user.photoURL!.isEmpty
                            ? Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Display name
                    Text(
                      user.displayName ?? emailLabel,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Email verification badge
                    _buildStatusBadge(
                      user.emailVerified ? verifiedLabel : notVerifiedLabel,
                      user.emailVerified ? Colors.green : Colors.orange,
                      user.emailVerified ? Icons.verified : Icons.warning,
                    ),
                  ],
                ),
              ),

              // Statistics cards
              _buildSectionHeader(statisticsTitle, Icons.analytics),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildStatCard(
                      loginCountLabel,
                      '${user.loginCount ?? 0}',
                      Icons.login,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      widget.isTraditionalChinese ? '帳戶天數' : 'Days Active',
                      user.createdAt != null
                          ? '${DateTime.now().difference(user.createdAt!).inDays}'
                          : '0',
                      Icons.calendar_today,
                      Colors.purple,
                    ),
                  ],
                ),
              ),

              // Personal information section
              _buildSectionHeader(personalInfoTitle, Icons.person),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInfoRow(uidLabel, user.uid, icon: Icons.fingerprint),
                    const Divider(height: 1),
                    _buildInfoRow(emailLabel, user.email ?? 'N/A', icon: Icons.email),
                    if (user.displayName != null) ...[
                      const Divider(height: 1),
                      _buildInfoRow(displayNameLabel, user.displayName!, icon: Icons.badge),
                    ],
                    if (user.phoneNumber != null) ...[
                      const Divider(height: 1),
                      _buildInfoRow(phoneLabel, user.phoneNumber!, icon: Icons.phone),
                    ],
                    if (user.type != null) ...[
                      const Divider(height: 1),
                      _buildInfoRow(accountTypeLabel, user.type!, icon: Icons.category),
                    ],
                    if (user.bio != null) ...[
                      const Divider(height: 1),
                      _buildInfoRow(bioLabel, user.bio!, icon: Icons.description),
                    ],
                  ],
                ),
              ),

              // Account status section
              _buildSectionHeader(accountStatusTitle, Icons.info),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      createdAtLabel,
                      _formatDateTime(user.createdAt),
                      icon: Icons.event,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      modifiedAtLabel,
                      _formatDateTime(user.modifiedAt),
                      icon: Icons.update,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      lastLoginLabel,
                      _formatDateTime(user.lastLoginAt),
                      icon: Icons.access_time,
                    ),
                  ],
                ),
              ),

              // Preferences section
              if (user.preferences != null && user.preferences!.isNotEmpty) ...[
                _buildSectionHeader(preferencesTitle, Icons.settings),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: user.preferences!.entries.map((entry) {
                      final isLast = entry.key == user.preferences!.keys.last;
                      return Column(
                        children: [
                          _buildInfoRow(
                            entry.key,
                            entry.value.toString(),
                            icon: Icons.tune,
                          ),
                          if (!isLast) const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Actions section
              _buildSectionHeader(actionsTitle, Icons.touch_app),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.isTraditionalChinese
                                  ? '編輯功能即將推出'
                                  : 'Edit feature coming soon',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(editProfileLabel),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              widget.isTraditionalChinese ? '確認登出' : 'Confirm Logout',
                            ),
                            content: Text(
                              widget.isTraditionalChinese
                                  ? '您確定要登出嗎？'
                                  : 'Are you sure you want to logout?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  widget.isTraditionalChinese ? '取消' : 'Cancel',
                                ),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onLoginStateChanged(false);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                ),
                                child: Text(logoutLabel),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(logoutLabel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade700),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}