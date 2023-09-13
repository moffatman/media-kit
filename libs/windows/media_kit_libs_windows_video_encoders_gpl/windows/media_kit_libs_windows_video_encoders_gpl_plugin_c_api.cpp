#include "include/media_kit_libs_windows_video/media_kit_libs_windows_video_encoders_gpl_plugin_c_api.h"

#include <iostream>

#include <flutter/plugin_registrar_windows.h>

void MediaKitLibsWindowsVideoEncodersGPLPluginCApiRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  std::cout << "package:media_kit_libs_windows_video_encoders_gpl registered." << std::endl;
}
