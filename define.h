#import <rootless.h>

#define PLUGINS_DIR_PATH ROOT_PATH_NS(@"/Library/MenuSupport/Plugins/")
#define PREF_PATH @"/var/mobile/Library/Preferences/jp.r-plus.MenuSupport.plist"
#define PLUGIN_ENABLED_PREFIX @"MSPluginEnabled"

static CFStringRef const kNotificationName = CFSTR("jp.r-plus.MenuSupport.settingschanged");
