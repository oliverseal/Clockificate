//
//  ClockificateAppDelegate.m
//  Clockificate
//
//  Created by Oliver Wilkerson on 4/20/11.
//  Copyright 2011 Oliver Wilkerson. All rights reserved.
//

#import "ClockificateAppDelegate.h"
#import "AboutClockificateWindow.h"

#define PREFSKEY_DEFAULTCOLOR @"DefaultColor.Color"
//TODO: Actually implement a date format
#define PREFSKEY_DEFAULTTIMEFORMAT @"DefaultTimeFormat"
#define PREFSKEY_DEFAULTTOBINARY @"DefaultToBinary"

@implementation ClockificateAppDelegate

@synthesize window;

- (void)dealloc {
    [statusItem release];
    [currentColor release];
	[window release];
	[statusMenu release];
	[statusItemView release];
	[dateFormatter release];
	[dateTimer release]; 
	[currentColor release];
	
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
}

- (void)awakeFromNib {
	SInt32 systemVersion = 0;
	OSStatus status = Gestalt(gestaltSystemVersion, &systemVersion);
	if (status != noErr) {
		[self release];
		return nil;
	}
	isOSX105 = systemVersion >= 0x1030;
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	// App's loaded, let's set the color based on the prefs
	currentColor = [NSColor blackColor];
	NSData* defaultColorData = [defaults dataForKey:PREFSKEY_DEFAULTCOLOR];
	if (defaultColorData != nil) {
		currentColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:defaultColorData];
		if (currentColor == nil)
			currentColor = [NSColor blackColor];
		else
			// CurrentColor will now be an autorelease: let's stop that
			[currentColor retain];
	}
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"h:mm:ss a"];
	dateTimerSecond = 1.0;
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [statusItem setHighlightMode:YES];
	
	statusItemView = [[ColorableStatusItem alloc] init];
	[statusItemView retain];
	statusItemView.statusItem = statusItem;
	[statusItemView setMenu:statusMenu];
	[statusItemView setToolTip:NSLocalizedString(@"Clockificate",
												 @"Status Item Tooltip")];
	[statusItem setView:statusItemView];
	
	dateTimer = [[NSTimer scheduledTimerWithTimeInterval:dateTimerSecond target:self selector:@selector(updateTime) userInfo:nil repeats:YES] retain];
	
	if (isOSX105) {					
		[[NSRunLoop currentRunLoop] addTimer:dateTimer forMode:NSEventTrackingRunLoopMode];
	}
	
	[statusItemView setTitleForegroundColor:currentColor];
	// Show the app name for the first second. Just so the user a) knows it loaded and b) can see the color and width
	// This could be removed without offending anyone, I think.
	[statusItemView setTitle:@"Clockificate"];	
	
	[defaults release];
}

- (void)updateTime {
	BOOL showAsBinary = [[NSUserDefaults standardUserDefaults] boolForKey:PREFSKEY_DEFAULTTOBINARY];
	NSDate *date = [NSDate date];
	NSString *time = [dateFormatter stringFromDate:date];
	if (!showAsBinary) {
		[statusItemView setBinary:NO];
		[statusItemView setTitle:time];
	}
	else {
		[statusItemView setBinary:YES];
		[statusItemView setTitleToBinary:date];
	}

}

- (IBAction)promptForTextColor:(id)sender {
	NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
	colorPanelSession = [NSApp beginModalSessionForWindow:colorPanel];
	
	[colorPanel orderFront:sender];
	[colorPanel setDelegate:self];
	[colorPanel setTarget:self];
	[colorPanel setAction:@selector(changeColor:)];
	[colorPanel setAction:@selector(windowWillClose:)];
	[colorPanel setContinuous:YES];
	
}

- (void)changeColor:(id)sender {
	currentColor = [[NSColorPanel sharedColorPanel] color];
	[statusItemView setTitleForegroundColor:currentColor];
}

- (void)windowWillClose:(id)sender {
	// This feels sloppy...
	if ([[sender object] isEqualTo:aboutPanel]) {
		[NSApp endModalSession:aboutPanelSession];
		[aboutPanel setDelegate:nil];
	}
	else
	{
		currentColor = (NSColor*)[[NSColorPanel sharedColorPanel] color];
		[[NSColorPanel sharedColorPanel] setDelegate:nil];
		NSData *defaultColorData = [NSArchiver archivedDataWithRootObject:currentColor];
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:defaultColorData forKey:PREFSKEY_DEFAULTCOLOR];
		[defaults synchronize];		[NSApp endModalSession:colorPanelSession];
	}
}

- (IBAction)openAboutWindow:(id)sender {
	if (aboutPanel == nil) {
		return nil;
	}
	
	aboutPanelSession = [NSApp beginModalSessionForWindow:aboutPanel];
	[NSApp runModalSession:aboutPanelSession];
	[aboutPanel setDelegate:self];
	[aboutPanel makeKeyAndOrderFront:sender];
}
@end

