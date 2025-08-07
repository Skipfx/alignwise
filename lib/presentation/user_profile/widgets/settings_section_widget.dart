import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsSectionWidget extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Function(String, dynamic)? onSettingChanged;

  const SettingsSectionWidget({
    Key? key,
    required this.title,
    required this.items,
    this.onSettingChanged,
  }) : super(key: key);

  @override
  State<SettingsSectionWidget> createState() => _SettingsSectionWidgetState();
}

class _SettingsSectionWidgetState extends State<SettingsSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            child: Text(
              widget.title,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(3.w),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: widget.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == widget.items.length - 1;
                return _buildSettingItem(item, isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(Map<String, dynamic> item, bool isLast) {
    final String type = item["type"] as String? ?? "navigation";

    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.dividerLight,
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        leading: item["icon"] != null
            ? Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: (item["iconColor"] as Color? ?? AppTheme.primaryLight)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: item["icon"] as String,
                  color: item["iconColor"] as Color? ?? AppTheme.primaryLight,
                  size: 5.w,
                ),
              )
            : null,
        title: Text(
          item["title"] as String,
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: item["subtitle"] != null
            ? Text(
                item["subtitle"] as String,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryLight,
                ),
              )
            : null,
        trailing: _buildTrailingWidget(item, type),
        onTap: type == "navigation" ? () => _handleNavigation(item) : null,
      ),
    );
  }

  Widget _buildTrailingWidget(Map<String, dynamic> item, String type) {
    switch (type) {
      case "toggle":
        return Switch(
          value: item["value"] as bool? ?? false,
          onChanged: (value) {
            setState(() {
              item["value"] = value;
            });
            widget.onSettingChanged?.call(item["key"] as String? ?? "", value);
          },
        );
      case "selection":
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item["selectedValue"] as String? ?? "",
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(width: 2.w),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: AppTheme.textSecondaryLight,
              size: 5.w,
            ),
          ],
        );
      case "navigation":
      default:
        return CustomIconWidget(
          iconName: 'chevron_right',
          color: AppTheme.textSecondaryLight,
          size: 5.w,
        );
    }
  }

  void _handleNavigation(Map<String, dynamic> item) {
    final String? route = item["route"] as String?;
    final String? action = item["action"] as String?;

    if (route != null) {
      Navigator.pushNamed(context, route);
    } else if (action != null) {
      _handleAction(action, item);
    }
  }

  void _handleAction(String action, Map<String, dynamic> item) {
    switch (action) {
      case "logout":
        _showLogoutDialog();
        break;
      case "deleteAccount":
        _showDeleteAccountDialog();
        break;
      case "exportData":
        _handleDataExport();
        break;
      case "biometric":
        _handleBiometricSettings();
        break;
      default:
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/authentication-screen',
                  (route) => false,
                );
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Delete Account",
            style: TextStyle(color: AppTheme.errorLight),
          ),
          content: const Text(
            "This action cannot be undone. All your wellness data will be permanently deleted.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorLight,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        "Account deletion initiated. You will receive a confirmation email."),
                  ),
                );
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _handleDataExport() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Export Your Data",
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'description',
                  color: AppTheme.primaryLight,
                  size: 6.w,
                ),
                title: const Text("Export as CSV"),
                subtitle: const Text("Nutrition, fitness, and wellness data"),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text("CSV export started. Check your downloads.")),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'picture_as_pdf',
                  color: AppTheme.errorLight,
                  size: 6.w,
                ),
                title: const Text("Export as PDF"),
                subtitle: const Text("Comprehensive wellness report"),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "PDF report generated. Check your downloads.")),
                  );
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  void _handleBiometricSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Biometric Authentication"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "Enable biometric authentication for secure app access."),
              SizedBox(height: 2.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'fingerprint',
                    color: AppTheme.primaryLight,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  const Expanded(child: Text("Fingerprint")),
                  Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'face',
                    color: AppTheme.primaryLight,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  const Expanded(child: Text("Face ID")),
                  Switch(
                    value: false,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
