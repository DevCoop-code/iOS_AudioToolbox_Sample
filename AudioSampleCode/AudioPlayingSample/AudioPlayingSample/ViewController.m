//
//  ViewController.m
//  AudioPlayingSample
//
//  Created by HanGyo Jeong on 11/11/2019.
//  Copyright © 2019 HanGyoJeong. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.player = [[AudioSamplePlayer alloc]init];
    [self.player playSound];
}


@end
