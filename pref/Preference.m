#import <Preferences/Preferences.h>
#import "../define.h"
#import <notify.h>
#import <UIKit/UIKit.h>

#define LOG_PATH @"/var/mobile/Library/Safari/menusupport.pref.log"
#import <DLog.h>

@interface PSSpecifier (Add)
@property (nonatomic) SEL buttonAction;
@end

@interface MSRootListController : PSListController
@property (nonatomic, strong) NSMutableDictionary *pref;
@end

@implementation MSRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        self.pref = [[NSDictionary dictionaryWithContentsOfFile:PREF_PATH] mutableCopy];

        NSMutableArray *specs = [[self loadSpecifiersFromPlistName:@"Root" target:self] mutableCopy];
        // dynamic PSSpecifier from Plugins.
        NSArray *subpaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:PLUGINS_DIR_PATH error:NULL];
        for (NSString *item in subpaths) {
            NSString *ext = item.pathExtension;
            NSString *filename = item.lastPathComponent.stringByDeletingPathExtension;
            if ([ext isEqualToString:@"bundle"]) {
                NSString *path = [NSString stringWithFormat:@"%@%@", PLUGINS_DIR_PATH, item];
                NSBundle *bundle = [NSBundle bundleWithPath:path];
                PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:filename target:self set:NULL get:NULL detail:bundle.principalClass cell:PSLinkCell edit:Nil];
                [specs addObject:spec];
            } else if ([ext isEqualToString:@"dylib"]) {
                PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:filename target:self set:@selector(setterForDylib:specifier:) get:@selector(getterForDylib:) detail:Nil cell:PSSwitchCell edit:Nil];
                [specs addObject:spec];
            }
        }
        // buttons
        PSSpecifier *g = [PSSpecifier emptyGroupSpecifier];
        [g setProperty:@"Author: @r_plus" forKey:@"footerText"];
        [specs addObject:g];

        PSSpecifier *github = [PSSpecifier preferenceSpecifierNamed:@"SourceCode" target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
        github.buttonAction = @selector(github:);
        [specs addObject:github];

        PSSpecifier *donation = [PSSpecifier preferenceSpecifierNamed:@"Donate to @r_plus" target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
        donation.buttonAction = @selector(donation:);
        [specs addObject:donation];

        PSSpecifier *license = [PSSpecifier preferenceSpecifierNamed:@"License" target:self set:NULL get:NULL detail:NSClassFromString(@"MenuSupportLicenseViewController") cell:PSLinkCell edit:Nil];
        [specs addObject:license];

        _specifiers = specs;
    }

    return _specifiers;
}

// MARK: - Button

- (void)github:(id)specifier
{
    NSURL *URL = [NSURL URLWithString:@"https://github.com/r-plus/MenuSupport"];
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
}

- (void)donation:(id)specifier
{
    NSURL *URL = [NSURL URLWithString:@"https://paypal.me/rplus"];
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
}

// MARK: - Setter/Getter

- (NSNumber *)getterForDylib:(PSSpecifier *)specifier
{
    NSString *key = [NSString stringWithFormat:@"%@-%@", PLUGIN_ENABLED_PREFIX, specifier.name];
    id existEnabled = self.pref[key];
    return existEnabled ? existEnabled : @YES;
}

- (void)setterForDylib:(id)value specifier:(PSSpecifier *)specifier
{
    NSString *key = [NSString stringWithFormat:@"%@-%@", PLUGIN_ENABLED_PREFIX, specifier.name];
    [self setterForCfprefsd:value key:key postNotification:(NSString *)kNotificationName];
}

- (void)setterForCfprefsd:(id)value specifier:(PSSpecifier *)specifier
{
    CFStringRef preferenceKey = (CFStringRef)[specifier propertyForKey:@"key"];
    NSString *settingsChangeNotification = [specifier propertyForKey:@"PostNotification"];
    [self setterForCfprefsd:value key:(NSString *)preferenceKey postNotification:settingsChangeNotification];
}

- (void)setterForCfprefsd:(id)value key:(NSString *)preferenceKey postNotification:(NSString *)settingsChangeNotification
{
    CFStringRef appID = CFSTR("jp.r-plus.MenuSupport");
    // daemon
    CFPreferencesSetAppValue((CFStringRef)preferenceKey, value, appID);
    CFPreferencesAppSynchronize(appID);
    // writetofile
    [self.pref setObject:value forKey:(NSString *)preferenceKey];
    [self.pref writeToFile:PREF_PATH atomically:YES];
    // notify
    if (settingsChangeNotification)
        notify_post([settingsChangeNotification UTF8String]);
}

@end

__attribute__((visibility("hidden")))
@interface MenuSupportLicenseViewController: PSListController
@end

@implementation MenuSupportLicenseViewController
- (id)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"License" target:self] retain];
    }
    return _specifiers;
}
@end
