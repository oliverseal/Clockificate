//
//  ClockificateAppDelegate.h
//  Clockificate
//
//  Created by Oliver Wilkerson on 4/20/11.
//  Copyright 2011 Oliver Wilkerson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ColorableStatusItem.h";
#import "AboutClockificateWindow.h";

@interface ClockificateAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
	ColorableStatusItem *statusItemView;
	NSDateFormatter *dateFormatter;
	NSTimer *dateTimer; 
	NSTimeInterval dateTimerSecond;
	NSColor *currentColor;
	NSModalSession colorPanelSession;
	BOOL isOSX105;
	
	NSModalSession aboutPanelSession;
	IBOutlet AboutClockificateWindow *aboutPanel;
}
@property (assign) IBOutlet NSWindow *window;
- (IBAction)promptForTextColor:(id)sender;
- (IBAction)openAboutWindow:(id)sender;
@end
