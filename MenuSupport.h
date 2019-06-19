#import <UIKit/UIKit.h>

@protocol MSMenuItem <NSObject>
/// Selector that will be sent to the target when menu item is pressed
@property (nonnull, nonatomic, readonly, assign) SEL action;
/// Selector that will be sent to the target to query whether menu item is valid
@property (nonnull, nonatomic, readonly, assign) SEL canPerform;
/// Localized title of the menu item
@property (nonnull, nonatomic, readwrite, retain) NSString *title;
/// Image that will be used to display the menu item
@property (nullable, nonatomic, readwrite, retain) UIImage *image;
@end

// Plugin Registration function
@interface UIMenuController (MenuSupport)
/// Useful method for show any view.
+ (nullable UIWindow *)frontmostWindow;
/// - action: will be sent to the target when the menu item has been pressed
/// - title: localized title of the menu item
/// - canPerform: will be sent to the target when the menu is about to be shown and we need to know if the menu item is valid
- (nonnull id<MSMenuItem>)ms_registerAction:(nonnull SEL)action title:(nonnull NSString *)title canPerform:(nonnull SEL)canPerform;
@end

@interface UIResponder (MenuSupport)
/// full text in the selectable view.
- (nullable NSString *)ms_textualRepresentation;
/// selected text; return nil if no selection.
- (nullable NSString *)ms_selectedTextualRepresentation;
@end

