import 'dart:html' as html;

void openFile(String tableName) {
  final String url = 'https://192.168.18.108:8080/downloadExcel/$tableName';
  final html.AnchorElement anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    ..download = '$tableName.xlsx'
    ..click();
}

Future<String> getLocalPath(String filename) async {
  // On web, we don't download files to a local path but trigger a download directly
  // This function can return a temporary path or URL
  return 'downloads/$filename';
}
