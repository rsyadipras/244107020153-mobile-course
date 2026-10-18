import 'dart:io';

import 'package:dio/dio.dart';

// REFRACTORING: Pemetaan error jaringan dipusatkan agar UI tidak perlu memahami status DioException atau detail koneksi.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    if (error.response?.statusCode == 401) {
      return 'Sesi berakhir. Silakan login kembali.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Koneksi terlalu lama. Periksa jaringan Anda.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    return 'Terjadi kesalahan saat menghubungi server.';
  }

  if (error is SocketException) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
  }

  return error.toString().replaceFirst('Exception: ', '');
}
