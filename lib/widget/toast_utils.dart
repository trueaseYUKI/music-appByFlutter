// lib/utils/toast_utils.dart
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    toastification.show(
      context: context,
      title: const Text('成功'),
      description: Text(message),
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  static void showError(BuildContext context, String message) {
    toastification.show(
      context: context,
      title: const Text('错误'),
      description: Text(message),
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  static void showInfo(BuildContext context, String message) {
    toastification.show(
      context: context,
      title: const Text('提示'),
      description: Text(message),
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  static void showWarning(BuildContext context, String message) {
    toastification.show(
      context: context,
      title: const Text('警告'),
      description: Text(message),
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}