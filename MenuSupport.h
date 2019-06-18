#import <UIKit/UIKit.h>

@protocol MSMenuItem <NSObject>
/// Selector that will be sent to the target when menu item is pressed
@property (nonatomic, readonly, assign) SEL action;
/// Selector that will be sent to the target to query whether menu item is valid
@property (nonatomic, readonly, assign) SEL canPerform;
/// Localized title of the menu item
@property (nonatomic, readwrite, retain) NSString *title;
/// Image that will be used to display the menu item
@property (nonatomic, readwrite, retain) UIImage *image;
@end

// Plugin Registration function
@interface UIMenuController (MenuSupport)
/// - action: will be sent to the target when the menu item has been pressed
/// - title: localized title of the menu item
/// - canPerform: will be sent to the target when the menu is about to be shown and we need to know if the menu item is valid
- (id<MSMenuItem>)ms_registerAction:(SEL)action title:(NSString *)title canPerform:(SEL)canPerform;
@end

@interface UIResponder (MenuSupport)
/// full text in the selectable view.
- (NSString *)ms_textualRepresentation;
/// selected text; return nil if no selection.
- (NSString *)ms_selectedTextualRepresentation;
@end

