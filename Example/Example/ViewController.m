//
//  ViewController.m
//  Example
//
//  Created by hang_pan on 2020/8/19.
//  Copyright © 2020 hang_pan. All rights reserved.
//

#import "ViewController.h"
#import <ExtSignalChannel/ExtSignalChannel.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    __weak typeof(self) weakSelf = self;
    
    [[ExtSignalChannel singleton] addSubscriber:self forSignalName:@"test.1.signal" withHandler:^(ExtSignal * _Nonnull signal) {
        NSLog(@"%@  #1:  %@", weakSelf, signal.params);
    }];
    
    [[ExtSignalChannel singleton] addSubscriber:self forSignalName:@"test.2.signal" withHandler:^(ExtSignal * _Nonnull signal) {
        NSLog(@"%@  #2:  %@", weakSelf, signal.params);
    }];
    [[ExtSignalChannel singleton] addSubscriber:self forSignalName:@"test.2.signal" withSelector:@selector(handleTest2:)];
    
    [[ExtSignalChannel singleton] addSubscriber:self forSignalName:@"test.3.signal" withHandler:^(ExtSignal * _Nonnull signal) {
        NSLog(@"%@  #3:  %@", weakSelf, signal.params);
    }];
    
    [self.ext_signalChannel addSubscriber:self forSignalName:@"test.4.signal" withHandler:^(ExtSignal * _Nonnull signal) {
        NSLog(@"%@  #4:  %@", weakSelf, signal.params);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTest3:) name:@"test.3.signal" object:@"3"];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
}

- (void)handleTest2:(ExtSignal *)signal {
    NSLog(@"%@  #2.2  %@", self, signal.params);
}

- (void)handleTest3:(NSNotification *)noti {
    NSLog(@"%@  #3.3  %@", self, noti.object);
}

- (void)handleTap:(UITapGestureRecognizer *)tap {
    [[ExtSignalChannel singleton] sendSignalName:@"test.1.signal"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"test.2.signal" object:@"2"];
    [[ExtSignalChannel singleton] sendSignalName:@"test.3.signal" params:@"3"];
    [[ExtSignalChannel singleton] sendSignalName:@"test.4.signal" params:@"4"];
    [self.ext_signalChannel sendSignalName:@"test.4.signal" params:@"4.1"];

    ViewController *vc = [ViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
