//
//  SRFileMonitorImpl.h
//  SRFile
//
//  Created by Seorenn on 2015.
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TargetConditionals.h"

#if !TARGET_OS_IPHONE

@class SRPathMonitorImpl;

@protocol SRPathMonitorImplDelegate/* <NSObject>*/

- (void)pathMonitorImpl:(nonnull SRPathMonitorImpl *)fileMonitorImpl
       detectEventPaths:(nonnull NSArray<NSString *> *)paths
                  flags:(nonnull NSArray<NSNumber *> *)flags;

@end

@interface SRPathMonitorImpl : NSObject

@property (atomic, assign) BOOL running;
@property (nullable, nonatomic, strong) id<SRPathMonitorImplDelegate> delegate;

- (nonnull instancetype)initWithPaths:(nonnull NSArray<NSString *> *)paths
                        queue:(nonnull dispatch_queue_t)queue;
- (void)start;
- (void)stop;

@end

#endif  // not TARGET_OS_IPHONE
