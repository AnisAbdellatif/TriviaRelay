/// What the app asks of the platform it runs on, with no plugin for it: the
/// share sheet, and the address it was opened at.
library;

export 'platform_io.dart' if (dart.library.js_interop) 'platform_web.dart';
