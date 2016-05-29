//
//  Usual.h
//
//  Created by 于博 on 16/5/26.
//  Copyright © 2016年 All rights reserved.
//

#define Usual_h
#pragma mark--屏幕宽高
#define DEVICE_WIDTH [UIScreen mainScreen].bounds.size.width
#pragma mark--判断手机型号
#define IS_IPHONE4 ((DEVICE_HEIGHT - 480)==0)
#define IS_IPHONE5 ((DEVICE_HEIGHT - 568)==0)
#define IS_IPHONE6 ((DEVICE_HEIGHT - 667) == 0)
#define IS_IPHONE6_PLUS ((DEVICE_HEIGHT - 736) == 0)
//计算分辨率
#define SCALE ((IS_IPHONE6_PLUS)?(736/480.0):((IS_IPHONE4)?(1.0):(568/480.0)))
#define DEVICE_HEIGHT [UIScreen mainScreen].bounds.size.height
#pragma mark--底部的高度
#define TopViewHeight 44
#define BottomViewHeight 72
#define VolumeStep 0.02f
#define BrightnessStep 0.02f
#define MovieProgressStep 5.0f