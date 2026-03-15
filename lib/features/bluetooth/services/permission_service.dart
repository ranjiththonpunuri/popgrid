import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:popgrid/core/theme/app_colors.dart';

class PermissionService {
  PermissionService._();

  /// Returns true if all required Bluetooth/location permissions are granted.
  static Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
        Permission.nearbyWifiDevices,
      ].request();

      return statuses.values.every(
        (s) => s.isGranted || s.isLimited,
      );
    } else if (Platform.isIOS) {
      final btStatus = await Permission.bluetooth.request();
      return btStatus.isGranted || btStatus.isLimited;
    }
    return false;
  }

  /// Check if permissions are already granted without requesting.
  static Future<bool> hasBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.isGranted;
      final advertise = await Permission.bluetoothAdvertise.isGranted;
      final connect = await Permission.bluetoothConnect.isGranted;
      final location = await Permission.locationWhenInUse.isGranted;
      return scan && advertise && connect && location;
    } else if (Platform.isIOS) {
      return await Permission.bluetooth.isGranted;
    }
    return false;
  }

  /// Shows explanation dialog, then requests permissions.
  /// Returns true if all granted.
  static Future<bool> requestWithExplanation(BuildContext context) async {
    final alreadyGranted = await hasBluetoothPermissions();
    if (alreadyGranted) return true;

    if (!context.mounted) return false;

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.player1.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bluetooth,
                color: AppColors.player1,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                'Permissions Needed',
                style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                      color: AppColors.neonGreen,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'PopGrid needs Bluetooth and Location access to discover '
                'and connect with nearby players.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Location is only used for Bluetooth discovery — '
                'we never track your location.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      fontSize: 8,
                      color: AppColors.disabledText,
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.player1.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.player1.withValues(alpha: 0.6),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Allow',
                          style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                                fontSize: 10,
                                color: AppColors.player1,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldRequest != true) return false;

    final granted = await requestBluetoothPermissions();

    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permissions denied. Enable them in Settings to use Bluetooth.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 9,
                  color: AppColors.textPrimary,
                ),
          ),
          backgroundColor: AppColors.surfaceLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Settings',
            textColor: AppColors.player1,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }

    return granted;
  }
}
