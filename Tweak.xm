#import "MenuSupport.h"
#import "define.h"
#import <WebKit/WebKit.h>

#define LOG_PATH @"/var/mobile/Library/Safari/menusupport.log"
#import <DLog.h>

static NSDictionary *pref;
static BOOL enabled = YES;;
static BOOL useImage = YES;
static BOOL isFirstLoad = YES;

// interfaces {{{
@interface _UICalloutBarSystemButtonDescription : NSObject
//// (int)type on iOS 12.
// +title=コピー, 1
// +title=選択, 1
// +title=すべてを選択, 1
// +title=ペースト, 1
// +title=削除, 1
// +title=置き換える…, 2
// +title=简⇄繁, 2
// +title=描画を挿入, 1
// +image=<UIImage: 0x2809ec620> size {26, 12} orientation 0 scale 3.000000, 0
// +title=lookup調べる, 0
// +title=define調べる, 0
// +title=ユーザ辞書…, 0
// +title=読み上げ, 5
// +title=読み上げ…, 5
// +title=一時停止, 5
// +title=共有…, 0
+ (id)buttonDescriptionWithImage:(UIImage *)arg1 action:(SEL)arg2 type:(int)arg3;
+ (id)buttonDescriptionWithTitle:(NSString *)arg1 action:(SEL)arg2 type:(int)arg3;
- (id)initWithTitle:(id)arg1 orImage:(id)arg2 action:(SEL)arg3 type:(int)arg4;
@property (nonatomic, readonly) SEL action;
@end

@interface UICalloutBar
+ (void)_releaseSharedInstance;
@end

@interface WKContentView
- (NSString *)selectedText;
@end

@interface WKWebView()
- (WKContentView *)_currentContentView;
@end

@interface UIWebDocumentView<UITextInput>
@end

@interface UIWebView()
- (UIWebDocumentView *)_documentView;
@end

@interface UIPeripheralHost : NSObject
+ (UIPeripheralHost *)activeInstance; // iOS 7+
+ (UIPeripheralHost *)sharedInstance; // iOS 4-6
@property (nonatomic) int currentState;
@end

@interface UIWindow()
+ (NSArray *)allWindowsIncludingInternalWindows:(BOOL)arg1 onlyVisibleWindows:(BOOL)arg2;
@end
// }}}

// MARK: - Private Class

@interface MSMenuPlugin : NSObject <MSMenuItem> // {{{
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) SEL canPerform;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, readonly, assign) BOOL isEnabled;
@property (nonatomic, readonly, assign) NSString *actionString;
@end

@implementation MSMenuPlugin
- (id)initWithAction:(SEL)action title:(NSString *)title canPerform:(SEL)canPerform
{
    self = [super init];
    if (self) {
        self.action = action;
        self.title = title;
        self.canPerform = canPerform;
        self.filename = nil;
    }
    return self;
}

- (NSString *)actionString
{
    return NSStringFromSelector(self.action);
}

- (BOOL)isEnabled
{
    NSString *key = [NSString stringWithFormat:@"%@-%@", PLUGIN_ENABLED_PREFIX, self.filename];
    id obj = pref[key];
    return obj ? [obj boolValue] : YES;
}

- (_UICalloutBarSystemButtonDescription *)buttonDescription
{
    int type = 1;
    _UICalloutBarSystemButtonDescription *desc;
    if (useImage && self.image) {
        desc = [%c(_UICalloutBarSystemButtonDescription) buttonDescriptionWithImage:self.image action:self.action type:type];
    } else {
        desc = [%c(_UICalloutBarSystemButtonDescription) buttonDescriptionWithTitle:self.title action:self.action type:type];
    }
    return desc;
}
@end
// }}}
@interface MSMenuPluginManager : NSObject // {{{
// TODO: maybe should use NSMutableSet instead
@property (nonatomic, strong) NSMutableArray<MSMenuPlugin *> *plugins;
+ (MSMenuPluginManager *)sharedInstance;
@end

@implementation MSMenuPluginManager
static MSMenuPluginManager *sharedInstance = nil;

+ (MSMenuPluginManager *)sharedInstance
{
    if (!sharedInstance) {
         sharedInstance = [MSMenuPluginManager new];
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.plugins = [NSMutableArray array];
    }
    return self;
}
@end
// }}}

// MARK: - Public API

@implementation UIMenuController (MenuSupport) // {{{
/// Plugin registration function
- (id<MSMenuItem>)ms_registerAction:(SEL)action title:(NSString *)title canPerform:(SEL)canPerform
{
    DLog(@"registed: %@, %@, %@", title, NSStringFromSelector(action), NSStringFromSelector(canPerform));
    MSMenuPluginManager *m = [MSMenuPluginManager sharedInstance];
    MSMenuPlugin *p = [[MSMenuPlugin alloc] initWithAction:action title:title canPerform:canPerform];
    [m.plugins addObject:p];
    return p;
}

+ (nullable UIWindow *)frontmostWindow
{
    // workaround for iOS 9+ SafariViewController.
    // if showInView:UIRemoteKeyboardWindow or UITextEffectsWindow, nothing happen.
    // It only change keyboard window, so later timing keyboard windows will be top, its already appeared.
    UIPeripheralHost *peripheral = [UIPeripheralHost respondsToSelector:@selector(activeInstance)] ? [UIPeripheralHost activeInstance] : [UIPeripheralHost sharedInstance];
    //// NOTE: state 3 is not showing keyboard or floating position keyboard(include split).
    ////       state 1 is showing keyboard.
    BOOL isShowingKeyboard = peripheral.currentState == 1 ? YES : NO;
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleIdentifier isEqualToString:@"com.apple.SafariViewService"]) {
        if (!isShowingKeyboard) {
            // non keyboard showing. "_UIHostedWindow"
            return [UIApplication sharedApplication].keyWindow;
        }
    }

    UIWindow *keyboardWindow = nil;
    for (UIWindow *window in [UIWindow allWindowsIncludingInternalWindows:YES onlyVisibleWindows:YES]) {
        if ([window isKindOfClass:%c(UIRemoteKeyboardWindow)]) {
            // since iOS 9
            keyboardWindow = window;
            break;
        } else if ([window isKindOfClass:%c(UITextEffectsWindow)]) {
            keyboardWindow = window;
        }
    }
    return keyboardWindow;
}
@end
// }}}
// functions for textualRepresentation {{{
static NSString *FullText(id<UITextInput> view)
{
    UITextRange *r = [view textRangeFromPosition:view.beginningOfDocument toPosition:view.endOfDocument];
    return [view textInRange:r];
}
static NSString *SelectedText(id<UITextInput> view)
{
    UITextRange *r = view.selectedTextRange;
    if (r) {
        if (r.isEmpty) {
            return nil;
        } else {
            return [view textInRange:r];
        }
    } else {
        return nil;
    }
}
static NSString *Invoke(UIResponder *self, NSString *(*function)(id<UITextInput> view))
{
    NSString *result = nil;
    if ([self isKindOfClass:%c(UIWebView)]) {
        // UIWebView (tested on Byline)
        id<UITextInput> v = [(UIWebView *)self _documentView];
        result = (*function)(v);
        DLog(@"UIWebView: %@", result);
    } else if ([self isKindOfClass:%c(WKWebView)]) {
        // WKWebView (tested on Safari - Normal webpage and GitHub comment form)
        result = [[(WKWebView *)self _currentContentView] selectedText];
        DLog(@"WKWebView: %@", result);
    } else if ([self isKindOfClass:%c(WKContentView)]) {
        // WKContentView (from doc)
        result = [(WKContentView *)self selectedText];
        DLog(@"WKContentView: %@", result);
    } else if ([self respondsToSelector:@selector(textInRange:)] && [self respondsToSelector:@selector(selectedTextRange)]) {
        // UITextInput (tested on MobileNotes)
        id<UITextInput> v = (id<UITextInput>)self;
        result = (*function)(v);
        DLog(@"UITextInput: %@", result);
    }
    return result;
}
// }}}
@implementation UIResponder (MenuSupport) // {{{
- (NSString *)ms_textualRepresentation
{
    return Invoke(self, FullText);
}
- (NSString *)ms_selectedTextualRepresentation
{
    return Invoke(self, SelectedText);
}
@end
// }}}

// MARK: - Hook

// menu injection
%hook UICalloutBar // {{{
- (void)updateAvailableButtons
{
    if (!enabled || !isFirstLoad) { return %orig; }

    isFirstLoad = NO;

    // load plugins
    MSMenuPluginManager *m = [MSMenuPluginManager sharedInstance];
    NSArray *subpaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:PLUGINS_DIR_PATH error:NULL];
    for (NSString *item in subpaths) {
        NSString *ext = item.pathExtension;
        NSString *filename = item.lastPathComponent.stringByDeletingPathExtension;
        NSUInteger bfCount = m.plugins.count;
        if ([ext isEqualToString:@"bundle"]) {
            NSString *path = [NSString stringWithFormat:@"%@%@", PLUGINS_DIR_PATH, item];
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            if (!bundle.isLoaded) {
                NSError *e = nil;
                BOOL result = [bundle loadAndReturnError:&e];
                DLog(@"loaded bundle: %@, %d, %@", bundle, result, e);
                // FIXME: more robust way to assign filename to plugin model instance.
                NSUInteger afCount = m.plugins.count;
                if (result && bfCount + 1 == afCount) {
                    m.plugins.lastObject.filename = filename;
                } else {
                    NSLog(@"MenuSupport bundle loading error: %@", e);
                }
            }
        } else if ([ext isEqualToString:@"dylib"]) {
            NSString *path = [NSString stringWithFormat:@"%@%@", PLUGINS_DIR_PATH, item];
            const char *filepath = path.UTF8String;
            DLog(@"loading dylib: %@", path);
            void *handle = dlopen(filepath, RTLD_LAZY);
            // FIXME: more robust way to assign filename to plugin model instance.
            NSUInteger afCount = m.plugins.count;
            if (handle && bfCount + 1 == afCount) {
                m.plugins.lastObject.filename = filename;
            } else {
                NSLog(@"MenuSupport dylib open error.");
            }
        }
    }

    // add model from registered plugins
    NSMutableArray *a = MSHookIvar<NSMutableArray*>(self, "m_systemButtonDescriptions");
    for (MSMenuPlugin *plugin in m.plugins) {
        _UICalloutBarSystemButtonDescription *desc = [plugin buttonDescription];
        [a addObject:desc];
        DLog(@"added buttonDescription: %@", plugin.title);
    }

    %orig;
}
%end // }}}
// menu visible/invisible when appear
%hook UIResponder // {{{
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    MSMenuPluginManager *m = [MSMenuPluginManager sharedInstance];
    for (MSMenuPlugin *plugin in m.plugins) {
        if (action == plugin.action) {
            if (!enabled) { return NO; }
            if (![self respondsToSelector:plugin.canPerform]) {
                DLog(@"NoSelector: %@, %@", self, sender);
                return NO;
            }
            if (!plugin.isEnabled) {
                DLog(@"Disabled: %@, %@", self, sender);
                return NO;
            }
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
                [[self class] instanceMethodSignatureForSelector:plugin.canPerform]];
            [invocation setSelector:plugin.canPerform];
            [invocation setTarget:self];
            [invocation invoke];
            BOOL returnValue;
            [invocation getReturnValue:&returnValue];
            DLog(@"canPerform: %d", returnValue);
            return returnValue;
        }
    }

    return %orig;
}
%end // }}}
// stock system menu iconable
%hook _UICalloutBarSystemButtonDescription // {{{
+ (id)buttonDescriptionWithTitle:(NSString *)title action:(SEL)action type:(int)type
{
    if (!useImage || !enabled) { return %orig; }

    NSString *a = NSStringFromSelector(action);
    UIImage *img = nil;
    if ([a isEqualToString:@"cut:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/Cut.png"];
    } else if ([a isEqualToString:@"copy:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/Copy.png"];
    } else if ([a isEqualToString:@"select:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/Select.png"];
    } else if ([a isEqualToString:@"selectAll:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/SelectAll.png"];
    } else if ([a isEqualToString:@"paste:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/Paste.png"];
    } else if ([a isEqualToString:@"delete:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/Delete.png"];
    } else if ([a isEqualToString:@"_promptForReplace:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/Replace.png"];
    } else if ([a isEqualToString:@"_lookup:"] || [a isEqualToString:@"_define:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/Define.png"];
    } else if ([a isEqualToString:@"_addShortcut:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/UserShortcut.png"];
    } else if ([a isEqualToString:@"_accessibilitySpeak:"] || [a isEqualToString:@"_accessibilitySpeakLanguageSelection:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/Speak.png"];
    } else if ([a isEqualToString:@"_accessibilityPauseSpeaking:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/Pause.png"];
    } else if ([a isEqualToString:@"_share:"]) {
        img = [UIImage imageWithContentsOfFile:PLUGINS_DIR_PATH @"/Share.png"];
    }
    // _transliterateChinese and _insertDrawing are not support yet.
    if (img) {
        return [self buttonDescriptionWithImage:img action:action type:type];
    }
    return %orig;
}
%end // }}}

// MARK: - Constractor

// constractor / load settings {{{
static void LoadSettings()
{
    DLog(@"LoadSettings...");
    pref = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    id existEnabled = [pref objectForKey:@"Enabled"];
    enabled = existEnabled ? [existEnabled boolValue] : YES;
    id existUseImage = [pref objectForKey:@"UseImage"];
    useImage = existUseImage ? [existUseImage boolValue] : YES;

    // to reset style.
    if ([%c(UICalloutBar) respondsToSelector:@selector(_releaseSharedInstance)]) {
        [%c(UICalloutBar) _releaseSharedInstance];
        // to re-register plugin description.
        isFirstLoad = YES;
    }
}
static void ChangeNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    LoadSettings();
}

%ctor {
    @autoreleasepool {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, ChangeNotification, kNotificationName, NULL, CFNotificationSuspensionBehaviorCoalesce);
        LoadSettings();
    }
}
// }}}

