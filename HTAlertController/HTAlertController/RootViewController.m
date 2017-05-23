//
//  RootViewController.m
//  HTAlertController
//
//  Created by zhanght on 2016/12/6.
//  Copyright © 2016年 zhanght. All rights reserved.
//

#import "RootViewController.h"
#import "HTAlertController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor orangeColor];
    
   
    
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showAction:(id)sender {
    
    HTAlertController *alert = [HTAlertController alertControllerWithMessage:@"你确定要关闭窗口吗？你确定要关闭窗口吗？你确定要关闭窗口吗？你确定要关闭窗口吗？你确定要关闭窗口吗？"];
    HTAlertAction *action = [HTAlertAction actionWithTitle:@"确定" handler:^(HTAlertAction * _Nullable action) {
        NSLog(@"-- ht log -- 确定 tapped");
    }];
    HTAlertAction *cancelAction = [HTAlertAction actionWithTitle:@"取消" handler:^(HTAlertAction * _Nullable action) {
        NSLog(@"-- ht log -- 取消 tapped");
    }];
    [alert addAction:action];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
