import 'dart:html' as html;
import 'dart:typed_data';

String? createVideoUrl(Uint8List videoBytes) {
  final blob = html.Blob([videoBytes], 'video/mp4');
  return html.Url.createObjectUrl(blob);
}

void revokeVideoUrl(String url) {
  html.Url.revokeObjectUrl(url);
}