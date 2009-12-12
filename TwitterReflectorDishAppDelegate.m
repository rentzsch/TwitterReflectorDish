#import "TwitterReflectorDishAppDelegate.h"
#import "nsenumerate.h"

@implementation TwitterReflectorDishAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [TwitterReflectorDishAppDelegate setJRLogLogger:self];
    [TwitterReflectorDishAppDelegate setClassJRLogLevel:JRLogLevel_Info];
    
    lastDirectMessageID = -1;
    
    twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
    [twitterEngine setUsername:@"YOURACCOUNT" password:@"YOURPASSWORD"];
    
    [twitterEngine getRateLimitStatus];
}

- (void)logWithLevel:(JRLogLevel)callerLevel_
			instance:(NSString*)instance_
				file:(const char*)file_
				line:(unsigned)line_
			function:(const char*)function_
			 message:(NSString*)message_
{
    [[logView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",message_]] autorelease]];
}

- (void)pollReplies:(id)z {
    assert(-1 != lastDirectMessageID);
    JRLogDebug(@"pollReplies getDirectMessagesSinceID:%d startingAtPage:0", lastDirectMessageID);
    [twitterEngine getDirectMessagesSinceID:lastDirectMessageID startingAtPage:0];
}

#pragma mark MGTwitterEngineDelegate methods


- (void)requestSucceeded:(NSString *)connectionIdentifier {
    JRLogDebug(@"Request succeeded for connectionIdentifier = %@", connectionIdentifier);
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
    JRLogWarn(@"Request failed for connectionIdentifier = %@, error = %@ (%@)", 
          connectionIdentifier, 
          [error localizedDescription], 
          [error userInfo]);
}


- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier {
    if (![messages count]) return;
    
    JRLogDebug(@"Got direct messages for %@:\r%@", connectionIdentifier, messages);
    
    if (-1 == lastDirectMessageID) {
        seenDirectMessageIDs = [[NSMutableSet alloc] init];
        nsenumerate (messages, NSDictionary, message) {
            [seenDirectMessageIDs addObject:[message objectForKey:@"id"]];
        }
        [NSTimer scheduledTimerWithTimeInterval:pollInterval target:self selector:@selector(pollReplies:) userInfo:nil repeats:YES];
    } else {
        NSMutableArray *filteredDirectMessages = [NSMutableArray array];
        nsenumerate (messages, NSDictionary, directMessage) {
            if ([seenDirectMessageIDs containsObject:[directMessage objectForKey:@"id"]]) {
                JRLogDebug(@"ignoring seen direct message %@ %@", [directMessage objectForKey:@"id"], directMessage);
            } else {
                [seenDirectMessageIDs addObject:[directMessage objectForKey:@"id"]];
                [filteredDirectMessages addObject:directMessage];
            }
        }
        nsenumerate (filteredDirectMessages, NSDictionary, directMessage) {
            NSString *echo = [NSString stringWithFormat:@"%@: %@",
                              [[directMessage objectForKey:@"sender"] objectForKey:@"screen_name"],
                              [directMessage objectForKey:@"text"]];
            JRLogInfo(@"WILL ECHO <%@> %@", echo, directMessage);
            [twitterEngine sendUpdate:echo];
        }
    }
    
    lastDirectMessageID = [[[messages objectAtIndex:0] objectForKey:@"id"] intValue];
    JRLogDebug(@"lastDirectMessageID <= %ld", lastDirectMessageID);
}


- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier
{
	JRLogDebug(@"Got misc info for %@:\r%@", connectionIdentifier, miscInfo);
    
    double allowedHitsPerHour = [[[miscInfo objectAtIndex:0] objectForKey:@"hourly-limit"] doubleValue];
    JRLogInfo(@"allowedHitsPerHour: %f", allowedHitsPerHour);
    
    allowedHitsPerHour *= 0.50;
    JRLogInfo(@"allowedHitsPerHour (reduced): %f", allowedHitsPerHour);
    
    if (allowedHitsPerHour > 120.0) {
        allowedHitsPerHour = 120.0;
    }
    JRLogInfo(@"allowedHitsPerHour (sane): %f", allowedHitsPerHour);
    
    pollInterval = (60.0/allowedHitsPerHour)*60.0;
    JRLogInfo(@"pollInterval: %f", pollInterval);
    
    [twitterEngine getDirectMessagesSinceID:0 startingAtPage:0];
}

@end
