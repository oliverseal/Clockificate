#import <Cocoa/Cocoa.h>

//Many thanks to Kris Johnson for his post on this stuff: http://undefinedvalue.com/2009/07/07/adding-custom-view-nsstatusitem
@interface ColorableStatusItem : NSView {
	NSStatusItem *statusItem;
	NSString *title;
	NSImage *binaryClockImage;
	BOOL isMenuVisible;
	NSColor *titleColor;
	NSColor *alphaedTitleColor;
	BOOL asBinary;
}
@property (retain, nonatomic) NSStatusItem *statusItem;
@property (retain, nonatomic) NSString *title;

- (void)setImage:(NSImage*)newClockImage;
@end
