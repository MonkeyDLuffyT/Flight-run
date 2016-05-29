//
//  CachePlayerData.h
//  VideoPlayer
//
//  Created by 于博 on 16/5/26.
//  Copyright © 2016年  All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface CachePlayerData : NSObject
@property (nonatomic,strong) NSMutableDictionary *cacheDataDic;
@property (nonatomic,assign) BOOL isFirstOpenPlayer;
+ (CachePlayerData *)sharedCachePlayerData;
- (void)addPlayRecordWithIdentifier:(NSString *)identifier progress:(CGFloat)progress;
@end
