//
//  ZMQController.h
//  SmartDesk
//
//  Created by Trong_iOS on 10/2/15.
//  Copyright © 2015 Robotbase. All rights reserved.
//

#import "ZMQObjC.h"
#import "ZMQHelper.h"

typedef void(^MayaSuccess)(id object);
typedef void(^MayaError)(NSError *err);

@interface ZMQController : NSObject {
    ZMQContext *ctx;
}

@property (nonatomic, strong) NSMutableArray *arrCallbacks;

+ (ZMQController *)sharedInstance;

#pragma mark - Functions

/*
 * Subcribe channel based on 2 keys: 'SERVER_IP' + 'SERVER_PORT'
 * Notes: 
 *   + We are using ZMQ publish/subcribe method
 **/
- (void)startReceiveData;

/*
 * Get current wifi name which connected from iPhone
 **/
- (NSString *)myCurrentWifi;

/*
 * We need close all sockets when application terminate or in background
 **/
- (void)closeSockets;

/*
 * Send message in local network.
 * Notes:
 *   + We are using ZMQ request/reply method
 **/
- (void)sendLocalData:(NSString *)str onSuccess:(MayaSuccess)loadBlock;

/*
 * Remove callback based on 'action' key
 *
 **/
- (void)removeKey:(NSString *)key;
- (void)removeAll;

@end
