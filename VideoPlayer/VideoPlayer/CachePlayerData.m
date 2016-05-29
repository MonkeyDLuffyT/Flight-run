//
//  CachePlayerData.m
//  VideoPlayer
//
//  Created by 于博 on 16/5/26.
//  Copyright © 2016年  All rights reserved.
//

#import "CachePlayerData.h"

@implementation CachePlayerData
+ (CachePlayerData *)sharedCachePlayerData{
    static CachePlayerData *cachePlayerData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       cachePlayerData = [[CachePlayerData alloc] init];
    });
    return cachePlayerData;
}
- (void)addPlayRecordWithIdentifier:(NSString *)identifier progress:(CGFloat)progress{
    _cacheDataDic = [[NSMutableDictionary alloc] init];
     [_cacheDataDic setObject:@(progress) forKey:identifier];
    _isFirstOpenPlayer = NO;
}
@end
