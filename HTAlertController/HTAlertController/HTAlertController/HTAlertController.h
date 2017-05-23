//
//  HTAlertController.h
//  HTAlertController
//
//  Created by zhanght on 2016/12/6.
//  Copyright © 2016年 zhanght. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HTAlertAction;
typedef void(^ActionHandler)(HTAlertAction * _Nullable action);

@interface HTAlertAction : NSObject
@property (nullable, nonatomic, readonly) NSString *title;
@property (nullable, nonatomic, copy) ActionHandler handler;
+ (nullable instancetype)actionWithTitle:(nullable NSString *)title handler:(nullable ActionHandler)handler;
@end

@interface HTAlertController : UIViewController

+ (nonnull instancetype)alertControllerWithMessage:(nullable NSString *)message;

- (void)addAction:(nonnull HTAlertAction *)action;
@end


