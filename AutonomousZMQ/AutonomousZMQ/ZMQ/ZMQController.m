//
//  ZMQController.m
//  SmartDesk
//
//  Created by Trong_iOS on 10/2/15.
//  Copyright © 2015 Robotbase. All rights reserved.
//

#import "ZMQController.h"
#import "CaptiveNetwork.h"
#import "AutonomousUtil.h"

#define AUTONOMOUS_RUN_ON_MAIN_QUEUE(BLOCK_CODE)               dispatch_async(dispatch_get_main_queue(),BLOCK_CODE)
#define AUTONOMOUS_RUN_ON_BACKGROUND_QUEUE(BLOCK_CODE)         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),BLOCK_CODE)
#define AUTONOMOUS_RUN_ON_HIGH_QUEUE(BLOCK_CODE)               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),BLOCK_CODE)

#ifndef EMPTY
#define EMPTY(__OBJECT) ( (nil == __OBJECT) ? YES : ( (nil != __OBJECT && [__OBJECT respondsToSelector:@selector(count)]) ? ([__OBJECT performSelector:@selector(count)] <= 0) : ( (nil != __OBJECT && [__OBJECT respondsToSelector:@selector(length)]) ? ([__OBJECT performSelector:@selector(length)] <= 0) : NO ) ) )
#endif

#ifndef NOTEMPTY
#define NOTEMPTY(__OBJECT) (EMPTY(__OBJECT) == NO)
#endif

#ifndef VALID
#define VALID(__OBJECT, __CLASSNAME) (nil != __OBJECT && [__OBJECT isKindOfClass:[__CLASSNAME class]])
#endif

#ifndef VALID_EMPTY
#define VALID_EMPTY(__OBJECT, __CLASSNAME) (VALID(__OBJECT, __CLASSNAME) == YES && EMPTY(__OBJECT) == YES)
#endif

#ifndef VALID_NOTEMPTY
#define VALID_NOTEMPTY(__OBJECT, __CLASSNAME) (VALID(__OBJECT, __CLASSNAME) == YES && EMPTY(__OBJECT) == NO)
#endif

#ifndef ARRAY_INDEX_EXISTS
#define ARRAY_INDEX_EXISTS(__OBJECT, __INDEX) (VALID(__OBJECT, NSArray) && __INDEX >= 0 && [(NSArray *) __OBJECT count] > __INDEX)
#endif

#ifndef OBJECT_AT_INDEX
#define OBJECT_AT_INDEX(__OBJECT, __INDEX) ((ARRAY_INDEX_EXISTS(__OBJECT, __INDEX)) ? [__OBJECT objectAtIndex:__INDEX] : nil)
#endif

@interface ZMQController()

@property (nonatomic, strong) NSDictionary *dictOptions;

@end

@implementation ZMQController

+ (ZMQController *)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

- (id) init
{
    if (self = [super init]) {
        _arrCallbacks = [NSMutableArray new];
        ctx = [[ZMQContext alloc] initWithIOThreads:15U];
        [self loadRequirements];
    }
    return self;
}

#pragma mark - Private

- (void)loadRequirements {
    self.dictOptions = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"autonomous_config" ofType:@"plist"]];
    if (!VALID(self.dictOptions, NSDictionary)) {
        @throw [NSException exceptionWithName:@"ERROR" reason:@"Autonomous need 'autonomous_config.plist' file!" userInfo:nil];
    }
    NSLog(@"Loaded 'autonomous_config.plist' file");
}

#pragma mark - Public

- (void)startReceiveData {
    AUTONOMOUS_RUN_ON_HIGH_QUEUE((^{
        @try {
            ZMQSocket *subscriber = [ctx socketWithType:ZMQ_SUB];
            
            NSString *ip = [NSString stringWithFormat:@"tcp://%@:%d", [self.dictOptions objectForKey:@"SERVER_IP"], [[self.dictOptions objectForKey:@"SERVER_PORT"] intValue]];
            BOOL isBind = [subscriber connectToEndpoint:ip];
            
            if (!isBind) {
                NSLog(@"*** Failed to bind to endpoint [%@].", ip);
                return;
            }
            
            NSString *filter = [[NSUserDefaults standardUserDefaults] objectForKey:@""];
            [subscriber setData:[filter dataUsingEncoding:NSUTF8StringEncoding] forOption:ZMQ_SUBSCRIBE];
            NSData *data = [subscriber receiveDataWithFlags:ZMQ_SNDMORE];
            
            if (data) {
                NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                str = [str stringByReplacingOccurrencesOfString:filter withString:@""];
                NSError *error = nil;
                id JSONObject = [NSJSONSerialization
                                 JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                                 options:NSJSONReadingAllowFragments
                                 error:&error];
                
                if (!error) {
                    [self callBack:JSONObject];
                }
                
            }
            [subscriber close];
            
        }
        @catch (NSException *exception) {
            NSLog(@"Error %@", exception.name);
            
        }
        @finally {
            NSLog(@"Try to get data again!!!");
            [self startReceiveData];
        }
    }));

}

- (void)removeKey:(NSString *)key {
    for (NSDictionary *d in _arrCallbacks) {
        if ([[d.allKeys firstObject] containsString:key]) {
            [_arrCallbacks removeObject:d];
        }
    }
}

- (void)removeAll {
    [_arrCallbacks removeAllObjects];
}

- (void)addKey:(NSString *)key block:(MayaSuccess)loadBlock {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[loadBlock copy] forKey:key];
    
    [self removeKey:key];
    [_arrCallbacks addObject:dict];
}

- (void)callBack:(NSDictionary *)dict {
    if (VALID(dict, NSDictionary)) {
        NSString *key = [dict objectForKey:@"action"];
        for (NSDictionary *d in _arrCallbacks) {
            if ([[d.allKeys firstObject] containsString:key]) {
                MayaSuccess loadBlock = [d objectForKey:key];
                if (loadBlock) {
                    loadBlock(dict);
                }
                [_arrCallbacks removeObject:d];
                return;
            }
        }
    }
}

- (NSString *)myCurrentWifi {
    CaptiveNetwork *captiveNetwork = [CaptiveNetwork new];
    NSDictionary *dict = [captiveNetwork fetchSSIDInfo];
    if (VALID(dict, NSDictionary) && VALID([dict objectForKey:@"SSID"], NSString)) {
        return [dict objectForKey:@"SSID"];
    }
    return @"";
}

- (void)closeSockets {
    [ctx closeSockets];
}

- (void)sendLocalData:(NSString *)str onSuccess:(MayaSuccess)loadBlock {
    __block NSString *ipGateway = [AutonomousUtil getGatewayIP];
    AUTONOMOUS_RUN_ON_HIGH_QUEUE((^{
        @try {
            ZMQSocket *sender = [ctx socketWithType:ZMQ_REQ];
            
            NSString *local_hostpot = [NSString stringWithFormat:@"tcp://%@:%d", ipGateway, [[self.dictOptions objectForKey:@"HOTSPOT_PORT"] intValue]];
            BOOL isBind = [sender connectToEndpoint:local_hostpot];
            
            if (!isBind) {
                NSLog(@"*** Failed to bind to endpoint [%@].", local_hostpot);
                return;
            } else {
                NSLog(@"Bind to endpoint %@ successfully", local_hostpot);
            }
            
            NSLog(@"Sending: %@", str);
            NSData *textData = [str dataUsingEncoding:NSUTF8StringEncoding];
            [sender sendData:textData withFlags:0];
            
            NSData *reply = [sender receiveDataWithFlags:0];
            NSError *error;
            id JSONObject = [NSJSONSerialization
                             JSONObjectWithData:reply
                             options:NSJSONReadingAllowFragments
                             error:&error];
            
            NSLog(@"Receiving data... %@", JSONObject);
            if (loadBlock) {
                loadBlock(JSONObject);
            }
            [sender close];
        }
        @catch (NSException *exception) {

        }
        @finally {
            
        }
    }));
}

@end
