//
//  AppDelegate.m
//  AppScreen
//
//  Created by Nelson on 2017/11/14.
//  Copyright © 2017年 Nelson. All rights reserved.
//

#import "AppDelegate.h"
#import "Settings.h"
#import "AsyncTask.h"
#import "FNHUD.h"
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
    
//    NSArray * screens = [NSScreen screens];
//    NSLog(@"--%@",screens);
//    for (NSScreen * screen in screens) {
//
////        NSWindow * desktopWindow = [[NSWindow alloc] initWithContentRect:screen.frame styleMask:NSWindowStyleMaskFullSizeContentView backing:NSBackingStoreBuffered defer:YES screen:screen];
////        NSLog(@"--%@",desktopWindow);
////        window.contentViewController
//        [FNHUD showSuccess:@"拷贝成功" inView:[NSApplication sharedApplication].windows[0].contentView];
////        [desktopWindow makeKeyAndOrderFront:nil];
//    }
    
    
    
    
    
    
    
//    return;
    NSMenu * menu = [[NSMenu alloc]init];
    NSArray * windows = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    windowInfoDictionary = [NSMutableDictionary dictionary];
    for (NSDictionary * runApp in windows) {
        NSString* windowOwner = [runApp objectForKey:(NSString *)kCGWindowOwnerName];
        NSInteger onscreen = [[runApp objectForKey:(NSString *)kCGWindowIsOnscreen] integerValue];
        NSInteger windowID = [[runApp objectForKey:(NSString *)kCGWindowNumber] integerValue];
        NSString * windowName = [runApp objectForKey:(NSString *)kCGWindowName];
        NSString * windowPID = [NSString stringWithFormat:@"%@",[runApp objectForKey:(NSString *)kCGWindowOwnerPID]];
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[runApp objectForKey:(NSString*)kCGWindowBounds], &bounds);
        
        if (onscreen == 1 && bounds.size.height != 22 && bounds.size.height != 46 && ![windowOwner isEqualToString:@"Dock"] && ![windowName isEqualToString:@"Dock"]) {
            [windowInfoDictionary setValue:runApp forKey:[NSString stringWithFormat:@"%ld",(long)windowID]];
            NSString * itemTitle;
            if (windowName.length > 0) {
                itemTitle = [windowOwner stringByAppendingFormat:@" - %@",windowName];
            }else{
                itemTitle = windowOwner;
            }
            NSMenuItem * item = [[NSMenuItem alloc]initWithTitle:itemTitle action:@selector(takeScreenshot:) keyEquivalent:@""];
            NSString * appPath = [NSString stringWithFormat:@"/Applications/%@.app",windowOwner];
            if (![[NSFileManager defaultManager] fileExistsAtPath:appPath]) {
                NSString * taskString = [self luanchArguments:@[@"-A"] grepArguments:@[@"-w",windowPID]];
                appPath = [@"/" stringByAppendingString:[[taskString componentsSeparatedByString:@"/Contents"].firstObject componentsSeparatedByString:@" /"].lastObject];
            }
            NSImage * icon = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
            [icon setSize:CGSizeMake(25, 25)];
            [item setImage:icon];
            item.tag = windowID;
            [menu addItem:item];
        }
    }
    [menu addItem:[NSMenuItem separatorItem]];
    
    //拷贝到粘贴板
    BOOL copyEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"COPYITEM"];
    NSMenuItem * pasteboardItem = [[NSMenuItem alloc]initWithTitle:@"拷贝到粘贴板" action:@selector(pasteboardAction) keyEquivalent:@""];
    [pasteboardItem setState:copyEnabled];
    [menu addItem:pasteboardItem];
    
    //保存截图到桌面
    BOOL saveEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"SAVEITEM"];
    NSMenuItem * saveItem = [[NSMenuItem alloc]initWithTitle:@"保存截图到桌面" action:@selector(saveScreenshotsAction) keyEquivalent:@""];
    [saveItem setState:saveEnabled];
    [menu addItem:saveItem];
    
    //Start at Login
    NSMenuItem* startAtLogin =
    [[NSMenuItem alloc] initWithTitle:@"Start at Login" action:@selector(handleStartAtLogin:) keyEquivalent:@""];
    
    BOOL isStartAtLoginEnabled = [Settings isStartAtLoginEnabled];
    [startAtLogin setState:isStartAtLoginEnabled];
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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SAVEITEM"]) {
        BOOL isWrite = [data writeToFile: screenshotPath atomically:NO];
        NSLog(@"保存截图到桌面-%d",isWrite);
    }
    CGImageRelease(image);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"COPYITEM"]) {
        NSPasteboard * pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        NSPasteboardItem * pasteboardItem = [[NSPasteboardItem alloc]init];
        [pasteboardItem setData:data forType:NSPasteboardTypePNG];
        BOOL isCopy = [pasteboard writeObjects:@[pasteboardItem]];
        NSLog(@"粘贴板-%d",isCopy);
    }
}

-(NSString *)luanchArguments:(NSArray *)lArguments grepArguments:(NSArray *)gArguments{
    NSTask *psTask = [[NSTask alloc] init];
    NSTask *grepTask = [[NSTask alloc] init];
    
    [psTask setLaunchPath: @"/bin/ps"];
    [grepTask setLaunchPath: @"/usr/bin/grep"];
    
    [psTask setArguments:lArguments];
    [grepTask setArguments:gArguments];
    
    /* ps ==> grep */
    NSPipe *pipeBetween = [NSPipe pipe];
    [psTask setStandardOutput: pipeBetween];
    [grepTask setStandardInput: pipeBetween];
    
    /* grep ==> me */
    NSPipe *pipeToMe = [NSPipe pipe];
    [grepTask setStandardOutput: pipeToMe];
    
    NSFileHandle *grepOutput = [pipeToMe fileHandleForReading];
    
    [psTask launch];
    [grepTask launch];
    
    NSData *data = [grepOutput readDataToEndOfFile];
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

-(void)pasteboardAction{
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"COPYITEM"] forKey:@"COPYITEM"];
}

-(void)saveScreenshotsAction{
    [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:@"SAVEITEM"] forKey:@"SAVEITEM"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
