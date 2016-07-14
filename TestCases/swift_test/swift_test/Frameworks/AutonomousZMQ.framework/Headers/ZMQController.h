//
//  ZMQController.h
//  SmartDesk
//
//  Created by Trong_iOS on 10/2/15.
//  Copyright © 2015 Robotbase. All rights reserved.
//

#import "ZMQObjC.h"
#import "ZMQHelper.h"
#import "ZmqChannel.h"

typedef void(^MayaSuccess)(id object);
typedef void(^MayaError)(NSError *err);

@interface ZMQController : NSObject {
    ZMQContext *ctx;
}

@property (nonatomic, strong) NSMutableArray *arrCallbacks;

+ (ZMQController *)sharedInstance;

#pragma mark - Functions

- (void)removeKey:(NSString *)key;
- (void)startReceiveData;
- (NSString *)myCurrentWifi;
- (void)closeSockets;
- (void)setupProduct:(NSDictionary *)dictProduct onSuccess:(MayaSuccess)loadBlock;
- (void)send:(NSDictionary *)dictParams onSuccess:(MayaSuccess)loadBlock;
- (void)removeAll;

@end
