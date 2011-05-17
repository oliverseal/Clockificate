//
//  ColorableStatusItem.m
//  Clockificate
//
//  Created by Oliver Wilkerson on 4/20/11.
//  Copyright 2011 Oliver Wilkerson. All rights reserved.
//

#import "ColorableStatusItem.h"

#define STATUSITEMVIEW_PADDINGWIDTH  6
#define STATUSITEMVIEW_PADDINGHEIGHT 3
#define STATUSITEMVIEW_BINARYPADDINGHEIGHT 6
#define STATUSITEMVIEW_BINARYCOLUMNSPACING 2
#define STATUSITEMVIEW_BINARYDOTSPACING 4
#define M_FULLRADIUS (M_PI/2)

@implementation ColorableStatusItem

@synthesize statusItem;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        statusItem = nil;
        title = @"";
		binaryClockImage = nil;
        isMenuVisible = NO;
		asBinary = NO;
    }
    return self;
}

- (void)dealloc {
    [statusItem release];
    [title release];
    [super dealloc];
}

- (void)mouseDown:(NSEvent *)event {
    [[self menu] setDelegate:self];
    [statusItem popUpStatusItemMenu:[self menu]];
    [self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)event {
    // Treat right-click just like left-click
    [self mouseDown:event];
}

- (void)menuWillOpen:(NSMenu *)menu {
    isMenuVisible = YES;
    [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
    isMenuVisible = NO;
    [menu setDelegate:nil];    
    [self setNeedsDisplay:YES];
}

- (NSColor *)titleForegroundColor {
    if (isMenuVisible) {
        return [NSColor whiteColor];
    }
    else {
        return (titleColor == nil)?[NSColor blackColor]:titleColor;
    }    
}

- (NSColor *)titleForegroundAltColor {
    if (isMenuVisible) {
        return [NSColor grayColor];
    }
    else {
        return (alphaedTitleColor == nil)?[NSColor grayColor]:alphaedTitleColor;
    }    
}

- (void)setTitleForegroundColor:(NSColor *)color {
	if (color == nil) {
		titleColor = [NSColor blackColor];
	}
	else {
		titleColor = color;
	}
	//This happens when there are no preferences set yet, or if someone somehow picks a color that cocoa just doesn't understand for some reason (don't ask)
	@try {
		CGFloat red,green,blue,alpha;
		[titleColor getRed:&red green:&green blue:&blue alpha:&alpha];
		alphaedTitleColor = [[NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha/3] retain];
		//NSLog(@"r%f, g:%f, b:%f, a:%f", red, green, blue, alpha);
	}
	@catch (id exc)  {
		alphaedTitleColor = [NSColor grayColor];
	}

}

- (void)setBinary:(BOOL)toBinary {
	asBinary = toBinary;
}

- (NSDictionary *)titleAttributes {
    // Use default menu bar font size
    NSFont *font = [NSFont menuBarFontOfSize:0];
	
    NSColor *foregroundColor = [self titleForegroundColor];
	
    return [NSDictionary dictionaryWithObjectsAndKeys:
            font,            NSFontAttributeName,
            foregroundColor, NSForegroundColorAttributeName,
            nil];
}

- (NSRect)titleBoundingRect {
    return [title boundingRectWithSize:NSMakeSize(1e100, 1e100)
                               options:0
                            attributes:[self titleAttributes]];
}

- (void)setTitle:(NSString *)newTitle {
    if (![title isEqual:newTitle]) {
        [newTitle retain];
        [title release];
        title = newTitle;
		
        // Update status item size (which will also update this view's bounds)
        NSRect titleBounds = [self titleBoundingRect];
        int newWidth = titleBounds.size.width + (2 * STATUSITEMVIEW_PADDINGWIDTH);
        [statusItem setLength:newWidth];
		
        [self setNeedsDisplay:YES];
    }
}

- (void)drawRect:(NSRect)rect {
    // Draw status bar background, highlighted if menu is showing
    [statusItem drawStatusBarBackgroundInRect:[self bounds]
                                withHighlight:isMenuVisible];
	
    // Draw title string
    NSPoint origin = NSMakePoint(STATUSITEMVIEW_PADDINGWIDTH,
                                 STATUSITEMVIEW_PADDINGHEIGHT);
	
	if (!asBinary)
		[title drawAtPoint:origin withAttributes:[self titleAttributes]];
	else
		[binaryClockImage drawAtPoint:origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
}

- (NSString *)title {
    return title;
}

- (void)setTitleToBinary:(NSDate *)time {
	int newWidth = 50;
	[statusItem setLength:newWidth];
	
	NSImage *currentImage = [[[NSImage alloc] initWithSize:NSMakeSize(50, 20)] autorelease];
	
	// Dear Open-Source Community, do you know of a more efficient way to get this in Objective-C? Email me.
	NSInteger hour = [[time dateWithCalendarFormat:nil timeZone:nil] hourOfDay];
	NSInteger min = [[time dateWithCalendarFormat:nil timeZone:nil] minuteOfHour];
	NSInteger sec = [[time dateWithCalendarFormat:nil timeZone:nil] secondOfMinute];
	
	BOOL isPM = hour >= 12;
	// In my clock, I don't allow 24 hour clocks -- yet :) so we have am/pm
	[self drawBits:currentImage digit:(isPM)?1:0 centerX: 4 mask: 1];
	// See above.
	hour = hour > 12 ? hour - 12 : hour;
	[self drawBits:currentImage digit:hour centerX:8 mask:4];
	
	// Divide these by 10. Each digit of the clock can have a column this way.
	// You can make 8 bit columns, but no one like reading them. 4 bit is how this clock works.
	// Note that floor is required here. You don't want ceil.
	NSInteger minDeca = floor(min / 10);
	[self drawBits:currentImage digit:minDeca centerX:14 mask:3];
	NSInteger minDigi = min % 10;
	[self drawBits:currentImage digit:minDigi centerX:18 mask:4];
	
	NSInteger secDeca = floor(sec / 10);
	[self drawBits:currentImage digit:secDeca centerX:24 mask:3];
	NSInteger secDigi = sec % 10;
	[self drawBits:currentImage digit:secDigi centerX:28 mask:4];
	
	[binaryClockImage release];
	[currentImage retain];
	binaryClockImage = currentImage;
	[self setNeedsDisplay:YES];
}

- (void)drawBits:(NSImage *)image digit:(NSInteger)digit centerX:(NSInteger)centerX mask:(NSInteger)mask {
	if (mask == 0)
		mask = 4;
	
	[image lockFocus];
	// We loop for each bit. Typically there are 4 bits in the clock. 8 4 2 1, but this function allows for masking in the cases where the number just don't get higher than 7
	// ... but no 0 masks. That's just silly. 
	NSInteger i = mask-1;
	for(i; i >= 0; i--)
	{
		//Is this bit supposed to be on?
		if( (1 << i) & digit) {
			[[self titleForegroundColor] set];
		}
		//nope, let's hide this.
		else {
			[[self titleForegroundAltColor] set];
		}
			
		NSPoint center = {centerX/1, STATUSITEMVIEW_BINARYPADDINGHEIGHT + (STATUSITEMVIEW_BINARYDOTSPACING * i) - STATUSITEMVIEW_BINARYCOLUMNSPACING};
		NSBezierPath* circle = [[[NSBezierPath alloc] init] autorelease];
		[circle moveToPoint:center];
		[circle appendBezierPathWithArcWithCenter:center radius:1 startAngle:0 endAngle:M_FULLRADIUS clockwise:YES];
		
		[circle closePath];
		[circle setLineWidth: 0.0];
		[circle fill];
	}
	[image unlockFocus];
}

@end
