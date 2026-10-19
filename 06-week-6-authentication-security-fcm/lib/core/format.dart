/// Fungsi murni untuk formatting tanggal agar dapat diuji tanpa BuildContext
String formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
