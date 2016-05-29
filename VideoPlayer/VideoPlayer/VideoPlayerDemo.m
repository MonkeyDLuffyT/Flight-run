//
//  VideoPlayerDemo.m
//  VideoPlayer
//
//  Created by 于博 on 16/5/26.
//  Copyright © 2016年  All rights reserved.
//

#import "VideoPlayerDemo.h"
#import "VideoPlayerController.h"
@interface VideoPlayerDemo ()

@end

@implementation VideoPlayerDemo

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    UIButton *buttonLocal = [[UIButton alloc]initWithFrame:CGRectMake(0, 100, 320, 30)];
    [buttonLocal setTitle:@"播放本地视频" forState:UIControlStateNormal];
    [buttonLocal setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [buttonLocal addTarget:self action:@selector(playLocalMovie) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonLocal];
    UIButton *buttonNet = [[UIButton alloc]initWithFrame:CGRectMake(0, 150, 320, 30)];
    [buttonNet setTitle:@"播放网络视频" forState:UIControlStateNormal];
    [buttonNet setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [buttonNet addTarget:self action:@selector(playNetMovie) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonNet];
    
    UIButton *buttonList = [[UIButton alloc]initWithFrame:CGRectMake(0, 200, 320, 30)];
    [buttonList setTitle:@"播放本地分段视频" forState:UIControlStateNormal];
    [buttonList setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [buttonList addTarget:self action:@selector(playLocalMovieList) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)playLocalMovie{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp4"];
    VideoPlayerController *movieVC = [[VideoPlayerController alloc]initLocalMoviePlayerViewControllerWithURL:url movieTitle:@"电影名称1"];
    [self presentViewController:movieVC animated:YES completion:nil];
}
- (void)playNetMovie{
    NSURL *url = [NSURL URLWithString:@"http://video.szzhangchu.com/heijiaokoumoxilanhuaA.mp4"];
    VideoPlayerController *movieVC = [[VideoPlayerController alloc]initNetworkMoviePlayerViewControllerWithURL:url movieTitle:@"电影名称2"];
    //movieVC.datasource = self;
    
    [self presentViewController:movieVC animated:YES completion:nil];
}
- (void)playLocalMovieList{
    NSURL *url1 = [[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp4"];
    NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"2" withExtension:@"mp4"];
    NSURL *url3 = [[NSBundle mainBundle] URLForResource:@"3" withExtension:@"mp4"];
    NSArray *list = @[url1,url2,url3];
    VideoPlayerController *movieVC = [[VideoPlayerController alloc]initLocalMoviePlayerViewControllerWithURLList:list movieTitle:@"电影名称3"];
    [self presentViewController:movieVC animated:YES completion:nil];
}
@end
