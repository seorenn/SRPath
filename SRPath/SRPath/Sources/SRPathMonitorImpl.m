//
//  SRPathMonitorImpl.m
//  SRPath
//
//  Created by Seorenn on 2015.
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

#import "SRPathMonitorImpl.h"

#if !TARGET_OS_IPHONE

static void
FileSystemEventStreamCallback(ConstFSEventStreamRef streamRef,
                              void *clientCallBackInfo,
                              size_t numEvents,
                              void *eventPaths,
                              const FSEventStreamEventFlags eventFlags[],
                              const FSEventStreamEventId eventIds[]);

@interface SRPathMonitorImpl () {
    FSEventStreamRef _fsEventStream;
    id<SRPathMonitorImplDelegate> _delegate;
    dispatch_queue_t _queue;
}

@end

@implementation SRPathMonitorImpl

- (nonnull instancetype)initWithPaths:(nonnull NSArray<NSString *> *)paths
                                queue:(nonnull dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;
        [self prepareWithPaths:paths];
        
        if (_fsEventStream == NULL) return nil;
        
        self.running = NO;
    }
    return self;
}

- (void)dealloc {
    _delegate = nil;
    
    if (self.running) {
        [self stop];
    }
    
    if (_fsEventStream != NULL) {
        FSEventStreamRelease(_fsEventStream);
        _fsEventStream = NULL;
    }
}

- (void)start {
    self.running = YES;
    FSEventStreamSetDispatchQueue(_fsEventStream, _queue);
    FSEventStreamStart(_fsEventStream);
}

- (void)stop {
    self.running = NO;
    FSEventStreamStop(_fsEventStream);
    FSEventStreamSetDispatchQueue(_fsEventStream, NULL);
}

//- (void)prepareWithPath:(NSString *)path {
//    FSEventStreamContext context = {0};
//    context.info = (__bridge void*)self;
//    context.copyDescription = NULL;
//    context.release = NULL;
//    context.retain = NULL;
//    context.version = 0;
//    
//    NSArray *paths = @[path];
//    
//    FSEventStreamCreateFlags flags = kFSEventStreamCreateFlagUseCFTypes |
//                                     kFSEventStreamCreateFlagFileEvents |
//                                     kFSEventStreamCreateFlagNoDefer    |
//                                     kFSEventStreamCreateFlagWatchRoot;
//    
//    _fsEventStream = FSEventStreamCreate(NULL,
//                                         FileSystemEventStreamCallback,
//                                         &context,
//                                         (__bridge CFArrayRef)paths,
//                                         kFSEventStreamEventIdSinceNow,
//                                         0.1,   // Latency
//                                         flags);
//}

- (void)prepareWithPaths:(NSArray *)paths {
    FSEventStreamContext context = {0};
    context.info = (__bridge void*)self;
    context.copyDescription = NULL;
    context.release = NULL;
    context.retain = NULL;
    context.version = 0;
    
    FSEventStreamCreateFlags flags = kFSEventStreamCreateFlagUseCFTypes |
    kFSEventStreamCreateFlagFileEvents |
    kFSEventStreamCreateFlagNoDefer    |
    kFSEventStreamCreateFlagWatchRoot;
    
    _fsEventStream = FSEventStreamCreate(NULL,
                                         FileSystemEventStreamCallback,
                                         &context,
                                         (__bridge CFArrayRef)paths,
                                         kFSEventStreamEventIdSinceNow,
                                         0.1,   // Latency
                                         flags);
}

- (void)eventWithPaths:(NSArray *)paths flags:(NSArray *)flags {
    if (_delegate) {
        [_delegate pathMonitorImpl:self detectEventPaths:paths flags:flags];
    }
}

@end

static void
FileSystemEventStreamCallback(ConstFSEventStreamRef streamRef,
                              void *clientCallBackInfo,
                              size_t numEvents,
                              void *eventPaths,
                              const FSEventStreamEventFlags eventFlags[],
                              const FSEventStreamEventId eventIds[]) {
    SRPathMonitorImpl *instance = (__bridge SRPathMonitorImpl *)clientCallBackInfo;
    NSArray *paths = (__bridge NSArray *)eventPaths;
    NSMutableArray *flags = [[NSMutableArray alloc] init];
    
    for (int i=0; i < numEvents; i++) {
        int flag = eventFlags[i];
        [flags addObject:[NSNumber numberWithInt:flag]];
    }
    
    [instance eventWithPaths:paths flags:flags];
}

#endif  // not TARGET_OS_IPHONE

