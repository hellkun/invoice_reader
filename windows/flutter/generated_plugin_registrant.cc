//
//  Generated file. Do not edit.
//

#include "generated_plugin_registrant.h"

#include <file_saver/file_saver_plugin.h>
#include <file_selector_windows/file_selector_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FileSaverPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSaverPlugin"));
  FileSelectorPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSelectorPlugin"));
}
