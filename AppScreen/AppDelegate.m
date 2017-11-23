//
//  AppDelegate.m
//  AppScreen
//
//  Created by Nelson on 2017/11/14.
//  Copyright © 2017年 Nelson. All rights reserved.
//

#import "AppDelegate.h"
#import "Settings.h"
@interface AppDelegate (){
    NSStatusItem * statusItem;
    NSMutableDictionary * windowInfoDictionary;
}

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage * icon = [NSImage imageNamed:@"screen"];
    [icon setSize:CGSizeMake(20, 20)];
    [statusItem.button setImage:icon];
    statusItem.action = @selector(presentApplicationMenu);
    [statusItem setToolTip:@"screen shot"];
    
    //hide dock icon
    //Info.plist add key "Application is agent (UIElement)" return "YES"
    
}

-(void)presentApplicationMenu{
    NSMenu * menu = [[NSMenu alloc]init];
    NSArray * windows = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    windowInfoDictionary = [NSMutableDictionary dictionary];
    for (NSDictionary * runApp in windows) {
        NSString* windowOwner = [runApp objectForKey:(NSString *)kCGWindowOwnerName];
        NSInteger onscreen = [[runApp objectForKey:(NSString *)kCGWindowIsOnscreen] integerValue];
        NSInteger windowID = [[runApp objectForKey:(NSString *)kCGWindowNumber] integerValue];
        NSString * windowName = [runApp objectForKey:(NSString *)kCGWindowName];
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[runApp objectForKey:(NSString*)kCGWindowBounds], &bounds);
        
        if (onscreen == 1 && bounds.size.height != 22 && bounds.size.height != 46 && ![windowOwner isEqualToString:@"Dock"]) {
            [windowInfoDictionary setValue:runApp forKey:[NSString stringWithFormat:@"%ld",(long)windowID]];
            NSString * itemTitle;
            if (windowName.length > 0) {
                itemTitle = [windowOwner stringByAppendingFormat:@" - %@",windowName];
            }else{
                itemTitle = windowOwner;
            }
            NSMenuItem * item = [[NSMenuItem alloc]initWithTitle:itemTitle action:@selector(takeScreenshot:) keyEquivalent:@""];
            NSString * appPath = [NSString stringWithFormat:@"/Applications/%@.app",windowOwner];
            if ([windowOwner isEqualToString:@"Simulator"]) {
                appPath = @"/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app";
            }else if ([windowOwner isEqualToString:@"Finder"]){
                appPath = @"/System/Library/CoreServices/Finder.app";
            }
            NSImage * icon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
            [icon setSize:CGSizeMake(25, 25)];
            [item setImage:icon];
            item.tag = windowID;
            [menu addItem:item];
        }
    }
    [menu addItem:[NSMenuItem separatorItem]];
    
    //Start at Login
    NSMenuItem* startAtLogin =
    [[NSMenuItem alloc] initWithTitle:@"Start at Login" action:@selector(handleStartAtLogin:) keyEquivalent:@""];
    
    BOOL isStartAtLoginEnabled = [Settings isStartAtLoginEnabled];
    if (isStartAtLoginEnabled){
        [startAtLogin setState:NSOnState];
    }else{
        [startAtLogin setState:NSOffState];
    }
    [startAtLogin setRepresentedObject:@(isStartAtLoginEnabled)];
    [menu addItem:startAtLogin];
    
    //Quit
    NSMenuItem* quit = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(exitApp:) keyEquivalent:@"Q"];
    [menu addItem:quit];
    [statusItem popUpStatusItemMenu:menu];
}

- (void) handleStartAtLogin:(id)sender
{
    BOOL isEnabled = [[sender representedObject] boolValue];
    
    [Settings setStartAtLoginEnabled:!isEnabled];
    
    [sender setRepresentedObject:@(!isEnabled)];
    
    if (isEnabled){
        [sender setState:NSOffState];
    }else{
        [sender setState:NSOnState];
    }
}


- (void) exitApp:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

-(void)takeScreenshot:(NSMenuItem *)item{
    NSInteger windowID = item.tag;
    NSDictionary * infoDictionary = windowInfoDictionary[[NSString stringWithFormat:@"%ld",windowID]];
    NSLog(@"--%@",infoDictionary);
    NSString *dateComponents = @"YYYY-MM-dd HH:mm:ss";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setDateFormat:dateComponents];
    
    NSDate *date = [NSDate date];
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    NSString* screenshotPath =
    [NSString stringWithFormat:@"%@/Desktop/%@.png", NSHomeDirectory(), [infoDictionary[(NSString *)kCGWindowOwnerName] stringByAppendingFormat:@" - %@",dateString]];
    
    CGRect bounds;
    CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[infoDictionary objectForKey:(NSString*)kCGWindowBounds], &bounds);
    
    CGImageRef image = CGWindowListCreateImage(bounds, kCGWindowListOptionIncludingWindow, (int)windowID, kCGWindowImageDefault);
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
    
    NSData *data = [bitmap representationUsingType: NSPNGFileType properties:@{}];
    [data writeToFile: screenshotPath atomically:NO];
    
    CGImageRelease(image);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
