//
//  TwitterReflectorDishAppDelegate.h
//  TwitterReflectorDish
//
//  Created by wolf on 9/24/09.
//  Copyright 2009 Red Shed Software Company. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#define JRLogOverrideNSLog 1
#import "JRLog.h"
#import "MGTwitterEngine.h"

@interface TwitterReflectorDishAppDelegate : NSObject <JRLogLogger> {
    IBOutlet    NSTextView      *logView;
                MGTwitterEngine *twitterEngine;
                int32_t         lastDirectMessageID;
                NSTimeInterval  pollInterval;
                NSMutableSet    *seenDirectMessageIDs;
}

@end
