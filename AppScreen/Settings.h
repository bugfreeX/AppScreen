//
//  Settings.h
//  AppScreen
//
//  Created by Nelson on 2017/11/14.
//  Copyright © 2017年 Nelson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject
+ (void) setStartAtLoginEnabled:(BOOL)isEnabled;
+ (BOOL) isStartAtLoginEnabled;

@end
