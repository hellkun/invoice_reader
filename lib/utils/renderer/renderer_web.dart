import 'dart:js' as js;

bool get isCanvasKitRenderer {
  var r = js.context['flutterCanvasKit'];
  return r != null;
}