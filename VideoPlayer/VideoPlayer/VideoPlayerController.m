//
//  ViewController.m
//  VideoPlayer
//
//  Created by 于博 on 16/5/26.
//  Copyright © 2016年  All rights reserved.
//

#import "VideoPlayerController.h"
#import "Usual.h"
#import "CachePlayerData.h"
typedef NS_ENUM(NSInteger, GestureType){
    GestureTypeOfNone = 0,
    GestureTypeOfVolume,
    GestureTypeOfBrightness,
    GestureTypeOfProgress,
};
@interface VideoPlayerController ()
{   NSString *_movieTitle;
    UIView *_bottomView;
    UIView *_topView;
    UIButton *_playBtn;
    UIButton *_fastBackBtn;
    UIButton *_backwardBtn;
    UIButton *_forwardBtn;
    UIButton *_fastForwardBtn;
    UIProgressView *_progressView;
    UILabel *_beginTimeLabel;
    UILabel *_endTimeLabel;
    UIButton *_returnBtn;
    UILabel *_titleLable;
    UIImageView *_brightnessView ;
    UIProgressView *_brightnessProgress;
    UISlider *_movieProgressSlider;
    UIView *_progressTimeView;
    UILabel *_progressTimeLable_top;
    UIImageView *_progressTimeImageView;
    AVPlayer *_player;
    BOOL _isPlaying;
    NSMutableArray *_movieURLList;
    NSMutableArray *_itemTimeList;
    NSMutableArray *_playItemsList;
    CGFloat _movieLength;
    NSInteger _currentPlayingItem;
    CGFloat _total;
    double _currentPlayTime;
    GestureType _gestureType;
    CGPoint _originalLocation;
    CachePlayerData *_cachePlayerData;
}
@end

@implementation VideoPlayerController
#pragma mark--播放本地视频
- (id)initLocalMoviePlayerViewControllerWithURL:(NSURL *)url movieTitle:(NSString *)movieTitle{
    self = [super init];
    if (self) {
        _movieURLList = [NSMutableArray array];
        [_movieURLList addObject:url];
        _itemTimeList = [NSMutableArray array];
        _playItemsList = [NSMutableArray array];
        _movieTitle = movieTitle;
    }
    return self;
}
#pragma mark--播放网络视频
- (id)initNetworkMoviePlayerViewControllerWithURL:(NSURL *)url movieTitle:(NSString *)movieTitle{
    self = [super init];
    if (self) {
        //获取字符串
        _movieURLList = [NSMutableArray array];
        [_movieURLList addObject:url];
        _itemTimeList = [NSMutableArray array];
        _playItemsList = [NSMutableArray array];
        _movieTitle = movieTitle;
    }
    return self;
}
#pragma mark--播放网络分段视频
- (id)initLocalMoviePlayerViewControllerWithURLList:(NSArray *)urlList movieTitle:(NSString *)movieTitle{
    self = [super init];
    if (self) {
        //获取字符串
        _movieURLList = [NSMutableArray arrayWithArray:urlList];
        _itemTimeList = [NSMutableArray array];
        _playItemsList = [NSMutableArray array];
        _movieTitle = movieTitle;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //配置底部视图
    [self setUpBottomView];
    //配置顶部视图
    [self setUpTopView];
    //配置视频
    [self creatAVPlayer];
    //配置亮度视图
    [self setUpBrightnessView];
    //配置提示框
    [self createProgressTimeLable];
    [self.view bringSubviewToFront:_bottomView];
    [self.view bringSubviewToFront:_topView];
    //添加监听
    [self addNotification];
    //移除监听
    [self removeNotification];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_topView setHidden:YES];
        [_bottomView setHidden:YES];
    });
    //[_progressHUD show:NO];
}

#pragma mark--视频方面的处理
- (void)creatAVPlayer{
    //防止循环引用
    typeof(_movieLength) *movieLength = &_movieLength;
    typeof(_gestureType) *gestureType = &_gestureType;
    typeof(_currentPlayingItem) *currentPlayingItem = &_currentPlayingItem;
    typeof(_currentPlayTime) *currentPlayTime = &_currentPlayTime;
    //__weak AVPlayer *player = _player;
    __weak NSMutableArray *itemTimeList = _itemTimeList;
    __weak UISlider *movieProgressSlider = _movieProgressSlider;
    __weak UILabel *beginTimeLabel = _beginTimeLabel;
    __weak UILabel *endTimeLabel = _endTimeLabel;
    CGRect playerFrame = CGRectMake(0, 0, self.view.layer.bounds.size.height, self.view.layer.bounds.size.width);
     __block CMTime totalTime = CMTimeMake(0, 0);
    [_movieURLList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AVAsset *asset = [AVAsset assetWithURL:obj];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
        _total = CMTimeGetSeconds(playerItem.asset.duration);
        totalTime.value += playerItem.asset.duration.value;
        totalTime.timescale = playerItem.asset.duration.timescale;
        [_itemTimeList addObject:[NSNumber numberWithDouble:((double)playerItem.asset.duration.value/totalTime.timescale)]];
        [_playItemsList addObject:playerItem];
    }];
    _movieLength = (CGFloat)totalTime.value/totalTime.timescale;
    [_movieProgressSlider setMaximumValue:1.0];
    _player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithURL:(NSURL *)_movieURLList[0]]];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = playerFrame;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    [_player play];
    _currentPlayingItem = 0;
    [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        if (*gestureType != GestureTypeOfProgress) {
            //获取当前时间
            *currentPlayTime = CMTimeGetSeconds(time);
            NSInteger currentTemp = *currentPlayingItem;
            while (currentTemp > 0) {
                
                *currentPlayTime += [[itemTimeList objectAtIndex:currentTemp] doubleValue];
                currentTemp--;
            }
            double changeTime = (*movieLength) - *currentPlayTime;
            
            //movieProgressSlider.value = currentPlayTime/(*movieLength);
            [movieProgressSlider setValue:(*currentPlayTime)/(*movieLength) animated:YES];
            NSDate *currentDate = [NSDate dateWithTimeIntervalSince1970:*currentPlayTime];
            NSDate *changeDate = [NSDate dateWithTimeIntervalSince1970:changeTime];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
            [formatter setDateFormat:((*currentPlayTime)/3600>=1)? @"h:mm:ss":@"mm:ss"];
            NSString *currentTimeStr = [formatter stringFromDate:currentDate];
            [formatter setDateFormat:(changeTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
            NSString *changeTimeStr = [formatter stringFromDate:changeDate];
            beginTimeLabel.text = currentTimeStr;
            endTimeLabel.text = [NSString stringWithFormat:@"%@ %@",changeTime > 0? @"-":@"+",changeTimeStr];
        }
    }];
}
#pragma mark--配置底部视图
- (void)setUpBottomView{
    //创建底部视图
    _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, DEVICE_WIDTH-36.8*SCALE, DEVICE_HEIGHT, 36.8*SCALE)];
    [_bottomView setBackgroundColor:[UIColor clearColor]];
    //创建播放按钮
    _playBtn = [[UIButton alloc] initWithFrame:CGRectMake((DEVICE_HEIGHT-12.0*SCALE)/2,0, 12.0*SCALE, 12.0*SCALE)];
    [_playBtn setImage:[UIImage imageNamed:@"pause_disable.png"] forState:UIControlStateNormal];
    [_playBtn addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    //设置选中状态
    [_playBtn setSelected:YES];
    [_bottomView addSubview:_playBtn];
    //创建快进按钮
    _fastForwardBtn = [[UIButton alloc] initWithFrame:CGRectMake(_playBtn.frame.origin.x+30*SCALE, 0, 12.0*SCALE, 12.0*SCALE)];
    [_fastForwardBtn setBackgroundImage:[UIImage imageNamed:@"fast_forward_disable.png"] forState:UIControlStateNormal];
    [_fastForwardBtn addTarget:self action:@selector(fastForearplay:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_fastForwardBtn];
    //创建快退按钮
    _fastBackBtn = [[UIButton alloc] initWithFrame:CGRectMake(_playBtn.frame.origin.x-30*SCALE, 0, 12.0*SCALE, 12.0*SCALE)];
    [_fastBackBtn setBackgroundImage:[UIImage imageNamed:@"fast_backward_disable.png"] forState:UIControlStateNormal];
    [_fastBackBtn addTarget:self action:@selector(fastBackplay:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_fastBackBtn];
    //创建上个视频按钮
    _backwardBtn = [[UIButton alloc] initWithFrame:CGRectMake(_fastBackBtn.frame.origin.x-30*SCALE, 0, 12.0*SCALE, 12.0*SCALE)];
    [_backwardBtn setBackgroundImage:[UIImage imageNamed:@"backward_disable.png"] forState:UIControlStateNormal];
    [_backwardBtn addTarget:self action:@selector(backwardBtnPlay:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_backwardBtn];
    //创建下个视频
    _forwardBtn = [[UIButton alloc] initWithFrame:CGRectMake(_fastForwardBtn.frame.origin.x+30*SCALE, 0, 12.0*SCALE, 12.0*SCALE)];
    [_forwardBtn setBackgroundImage:[UIImage imageNamed:@"forward_disable.png"] forState:UIControlStateNormal];
    [_forwardBtn addTarget:self action:@selector(forwardBtnPlay:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_forwardBtn];
    //进度条
    _movieProgressSlider = [[UISlider alloc] initWithFrame:CGRectMake(53.3*SCALE,8.0*SCALE+_fastBackBtn.frame.origin.y+_fastBackBtn.frame.size.height, DEVICE_HEIGHT-104*SCALE,25)];
    [_movieProgressSlider setThumbImage:[UIImage imageNamed:@"play_slider.png"] forState:UIControlStateNormal];
    [_movieProgressSlider setTintColor:[UIColor orangeColor]];
    [_movieProgressSlider addTarget:self action:@selector(sliderValueChanged) forControlEvents:UIControlEventValueChanged];
    [_bottomView addSubview:_movieProgressSlider];
    //创建开始多长时间的 label
    _beginTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(6.6*SCALE,8.0*SCALE+_fastBackBtn.frame.origin.y+_fastBackBtn.frame.size.height, 24.4*SCALE, 22.0*SCALE)];
    [_beginTimeLabel setBackgroundColor:[UIColor clearColor]];
    [_beginTimeLabel setTextColor:[UIColor whiteColor]];
    [_beginTimeLabel setTextAlignment:NSTextAlignmentCenter];
    [_beginTimeLabel setFont:[UIFont systemFontOfSize:12]];
    [_bottomView addSubview:_beginTimeLabel];
    //创建结束多长时间的 label
    _endTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_movieProgressSlider.frame.origin.x+_movieProgressSlider.frame.size.width+17.3*SCALE,8.0*SCALE+_fastBackBtn.frame.origin.y+_fastBackBtn.frame.size.height, 30.4*SCALE, 22.0*SCALE)];
    [_endTimeLabel setBackgroundColor:[UIColor clearColor]];
    [_endTimeLabel setTextColor:[UIColor whiteColor]];
    [_endTimeLabel setTextAlignment:NSTextAlignmentCenter];
    [_endTimeLabel setFont:[UIFont systemFontOfSize:12]];
    [_bottomView addSubview:_endTimeLabel];
    [self.view addSubview:_bottomView];
}
#pragma mark--配置顶部视图
- (void)setUpTopView{
    //创建顶部视图
    _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,DEVICE_HEIGHT, 24.8*SCALE)];
    [_topView setBackgroundColor:[UIColor clearColor]];
    [_topView setAlpha:0.8];
    //创建返回按钮
    _returnBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_returnBtn setFrame:CGRectMake(13.3*SCALE, (_topView.frame.size.height-13.3*SCALE)/2, 20.0*SCALE, 20.0*SCALE)];
    [_returnBtn setBackgroundImage:[UIImage imageNamed:@"nav_back_white.png"] forState:UIControlStateNormal];
    [_returnBtn addTarget:self action:@selector(returnMainVC) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:_returnBtn];
    //
    _titleLable = [[UILabel alloc]initWithFrame:CGRectMake(self.view.bounds.size.height/2-200, 0, 400, TopViewHeight)];
    _titleLable.backgroundColor = [UIColor clearColor];
    _titleLable.text = _movieTitle;
    _titleLable.textColor = [UIColor whiteColor];
    _titleLable.textAlignment = NSTextAlignmentCenter;
    [_topView addSubview:_titleLable];
    [self.view addSubview:_topView];
}
#pragma mark--配置屏幕亮度视图
- (void)setUpBrightnessView{
    _brightnessView = [[UIImageView alloc]initWithFrame:CGRectMake(self.view.bounds.size.height/2-63, self.view.frame.size.width/2-63, 125, 125)];
    _brightnessView.image = [UIImage imageNamed:@"video_brightness_bg.png"];
    _brightnessProgress = [[UIProgressView alloc]initWithFrame:CGRectMake(_brightnessView.frame.size.width/2-40, _brightnessView.frame.size.height-30, 80, 10)];
    _brightnessProgress.trackImage = [UIImage imageNamed:@"video_num_bg.png"];
    _brightnessProgress.progressImage = [UIImage imageNamed:@"video_num_front.png"];
    _brightnessProgress.progress = [UIScreen mainScreen].brightness;
    [_brightnessView addSubview:_brightnessProgress];
    [self.view addSubview:_brightnessView];
    _brightnessView.alpha = 0;
}
#pragma mark--配置提示视图
- (void)createProgressTimeLable{
    _progressTimeView = [[UIView alloc]initWithFrame:CGRectMake((self.view.bounds.size.height-200)/2, 60, 200, 60)];
    [_progressTimeView setBackgroundColor:[UIColor clearColor]];
    _progressTimeLable_top = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, 200, 30)];
    _progressTimeLable_top.textAlignment = NSTextAlignmentCenter;
    _progressTimeLable_top.textColor = [UIColor whiteColor];
    _progressTimeLable_top.backgroundColor = [UIColor clearColor];
    _progressTimeLable_top.font = [UIFont systemFontOfSize:17];
    _progressTimeLable_top.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    _progressTimeLable_top.shadowOffset = CGSizeMake(1.0, 1.0);
    [_progressTimeView addSubview:_progressTimeLable_top];
    _progressTimeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(86, 10, 28, 25)];
    [_progressTimeImageView setImage:[UIImage imageNamed:@"recipe_img_dishes_right"]];
    [_progressTimeView addSubview:_progressTimeImageView];
    [_progressTimeView setHidden:YES];
    [self.view addSubview:_progressTimeView];
}
- (void)updateProfressTimeLable{
    double currentTime = floor(_movieLength *_movieProgressSlider.value);
    //转成秒数
    NSDate *currentDate = [NSDate dateWithTimeIntervalSince1970:currentTime];
    NSDate *sumDate = [NSDate dateWithTimeIntervalSince1970:_movieLength];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    [formatter setDateFormat:(currentTime/3600>=1)? @"h:mm:ss":@"mm:ss"];
    NSString *currentTimeStr = [formatter stringFromDate:currentDate];
    
    [formatter setDateFormat:(_movieLength/3600>=1)? @"h:mm:ss":@"mm:ss"];
    NSString *sumTimeStr = [formatter stringFromDate:sumDate];
    _progressTimeLable_top.text = [NSString stringWithFormat:@"%@/%@",currentTimeStr,sumTimeStr];
    
}
#pragma mark--播放按钮的点击事件
- (void)playVideo:(UIButton *)playButton{
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
        [_player play];
        [_playBtn setImage:[UIImage imageNamed:@"pause_disable.png"] forState:UIControlStateNormal];
        
    }else{
        [_player pause];
        [_playBtn setImage:[UIImage imageNamed:@"play_disable.png"] forState:UIControlStateNormal];
    }
}
#pragma mark--返回按钮
- (void)returnMainVC{
    //保存本次播放进度
    _cachePlayerData = [CachePlayerData sharedCachePlayerData];
    [_cachePlayerData addPlayRecordWithIdentifier:_movieTitle progress:_currentPlayTime];
    [self dismissViewControllerAnimated:YES completion:^{
        [_player pause];
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
    }];
    
}
#pragma mark--快进
- (void)fastForearplay:(UIButton *)button{
    [self movieProgressAdd:MovieProgressStep];
}
#pragma mark--快退
- (void)fastBackplay:(UIButton *)button{
    [self movieProgressAdd:-MovieProgressStep];
}
//声音增加
- (void)volumeAdd:(CGFloat)step{
//    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
//    UISlider* volumeViewSlider = nil;
//    for (UIView *view in [volumeView subviews]){
//        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
//            volumeViewSlider = (UISlider*)view;
//            break;
//        }
//    }
//    
//    // retrieve system volume
//     volumeViewSlider.value += step;
//    // change system volume, the value is between 0.0f and 1.0f
//    [volumeViewSlider setValue:volumeViewSlider.value animated:YES];
    
//    // send UI control event to make the change effect right now.
//    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
    [MPMusicPlayerController applicationMusicPlayer].volume += step;

}
//亮度增加
- (void)brightnessAdd:(CGFloat)step{
    [UIScreen mainScreen].brightness += step;
    _brightnessProgress.progress = [UIScreen mainScreen].brightness;
    
}
//快进／快退
- (void)movieProgressAdd:(CGFloat)step{
    _movieProgressSlider.value += (step/_movieLength);
    [self sliderValueChanged];
}
#pragma mark--上个视频的响应事件
- (void)backwardBtnPlay:(UIButton *)button{
    if (_currentPlayingItem  == 0) {
        
        [self returnMainVC];
    }
    else{
        
        _currentPlayingItem--;
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
        [_player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:(NSURL *)_movieURLList[_currentPlayingItem]]];
        [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [_player play];

    }
}
#pragma mark--下个视频的响应事件
- (void)forwardBtnPlay:(UIButton *)button{
    if (_currentPlayingItem + 1  == _movieURLList.count) {
        
        [self returnMainVC];
    }
    else{
        
        _currentPlayingItem++;
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
        [_player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:(NSURL *)_movieURLList[_currentPlayingItem]]];
        [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [_player play];
    }

}
#pragma mark--拉动滑动条
- (void)sliderValueChanged{
    
    double currentTime = floor(_movieLength *_movieProgressSlider.value);
    int i = 0;
    double temp = [((NSNumber *)_itemTimeList[i]) doubleValue];
    while (currentTime > temp) {
        
        ++i;
        temp += [((NSNumber *)_itemTimeList[i]) doubleValue];
    }
    
    if (i != _currentPlayingItem) {
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
        [_player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:(NSURL *)_movieURLList[i]]];
        [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [_player play];
        _currentPlayingItem = i;
    }
    temp -= [((NSNumber *)_itemTimeList[i]) doubleValue];
    
    [self updateProfressTimeLable];
    
    //转换成CMTime才能给player来控制播放进度
    CMTime dragedCMTime = CMTimeMake(currentTime-temp, 1);
    [_player seekToTime:dragedCMTime completionHandler:
     ^(BOOL finish){
         if (_isPlaying == YES){
             [_player play];
         }
     }];

}
- (void)addNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinshPlay) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)didFinshPlay{
    if (_currentPlayingItem+1 == _movieURLList.count) {
        [self returnMainVC];
    }
    else{
        
        ++_currentPlayingItem;
        [_player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:_movieURLList[_currentPlayingItem]]];
        //[_player.currentItem removeObserver:self forKeyPath:@"status"];
        if (_isPlaying == YES){
            [_player play];
        }
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)contex{
    
    if ([keyPath isEqualToString:@"status"]) {
        
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        
        if (playerItem.status == AVPlayerStatusReadyToPlay) {
            //视频加载完成,去掉等待
            //[_progressHUD hide:YES];
            CachePlayerData  *cachePlayerData = [CachePlayerData sharedCachePlayerData];
            //获取上次播放进度,仅对本地有效
            if (!cachePlayerData.isFirstOpenPlayer) {
                CGFloat progress = [cachePlayerData.cacheDataDic[_movieTitle] floatValue];
                _movieProgressSlider.value = progress/_movieLength;
                cachePlayerData.isFirstOpenPlayer = YES;
                [self sliderValueChanged];
                [_player play];
                
            }
        }
    }
}
- (void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[_player.currentItem removeObserver:self forKeyPath:@"status"];
}

#pragma mark--横屏处理
- (BOOL)shouldAutorotate
{
    return NO;
    
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations NS_AVAILABLE_IOS(6_0) __TVOS_PROHIBITED;
{
    return UIInterfaceOrientationMaskLandscapeRight;
    //return self.orietation;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != self.orietation);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark--touch 事件
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    UITouch *touch = [touches anyObject];
    CGPoint currentLocation = [touch locationInView:self.view];
    CGFloat offset_x = currentLocation.x - _originalLocation.x;
    CGFloat offset_y = currentLocation.y - _originalLocation.y;
    
    if (CGPointEqualToPoint(_originalLocation,CGPointZero)) {
        _originalLocation = currentLocation;
        
        return;
    }
    _originalLocation = currentLocation;
    
    CGRect frame = [UIScreen mainScreen].bounds;
    if (_gestureType == GestureTypeOfNone) {
        
        if ((currentLocation.x > frame.size.height*0.8) && (ABS(offset_x) <= ABS(offset_y))){
            
            _gestureType = GestureTypeOfVolume;
        }else if ((currentLocation.x < frame.size.height*0.2) && (ABS(offset_x) <= ABS(offset_y))){
            
            _gestureType = GestureTypeOfBrightness;
        }else if ((ABS(offset_x) > ABS(offset_y))) {
            
            _gestureType = GestureTypeOfProgress;
            _progressTimeView.hidden = NO;
        }
    }
    if ((_gestureType == GestureTypeOfProgress) && (ABS(offset_x) > ABS(offset_y))) {
        [_progressTimeView setHidden:NO];
        if (offset_x > 0) {
            
            //            NSLog(@"横向向右");
            _movieProgressSlider.value += 0.005;
            [_progressTimeImageView setImage:[UIImage imageNamed:@"recipe_img_dishes_right"]];
            
        }
        else{
            //            NSLog(@"横向向左");
            _movieProgressSlider.value -= 0.005;
            [_progressTimeImageView setImage:[UIImage imageNamed:@"recipe_img_dishes_left"]];
        }
        [self updateProfressTimeLable];
    }
    else if ((_gestureType == GestureTypeOfVolume) && (currentLocation.x > frame.size.height*0.8) && (ABS(offset_x) <= ABS(offset_y))){
        if (offset_y > 0){
            [self volumeAdd:-VolumeStep];
        }
        else{
            [self volumeAdd:VolumeStep];
        }
    }
    else if ((_gestureType == GestureTypeOfBrightness) && (currentLocation.x < frame.size.height*0.2) && (ABS(offset_x) <= ABS(offset_y))){
        if (offset_y > 0) {
            _brightnessView.alpha = 1;
            [self brightnessAdd:-BrightnessStep];
        }else{
            _brightnessView.alpha = 1;
            [self brightnessAdd:BrightnessStep];
        }
    }
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    if (_topView.hidden && _bottomView.hidden) {
        [_topView setHidden:NO];
        [_bottomView setHidden:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_topView setHidden:YES];
            [_bottomView setHidden:YES];
        });
    }
    else{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_topView setHidden:YES];
            [_bottomView setHidden:YES];
        });
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (_gestureType == GestureTypeOfProgress) {
        _gestureType = GestureTypeOfNone;
        [self sliderValueChanged];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [_progressTimeView setHidden:YES];
        });
    }
    else if(_gestureType == GestureTypeOfBrightness){
        _gestureType = GestureTypeOfNone;
        _progressTimeView.hidden = YES;
        if (_brightnessView.alpha) {
            [UIView animateWithDuration:1 animations:^{
                _brightnessView.alpha = 0;
            }];
        }
    }
}
@end