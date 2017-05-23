//
//  HTAlertController.m
//  HTAlertController
//
//  Created by zhanght on 2016/12/6.
//  Copyright © 2016年 zhanght. All rights reserved.
//

#import "HTAlertController.h"

/** 图层结构
    1. overlayView (superView : View) 铺满View
    2. containerView (superView : View) 铺满View
    3. alertView (superView : containerView) 横竖都居中，width : kAlertViewWidth(270)，height : alertViewHeightConstraint(可变)
    4. textAreaScrollView (superView : alertView) 铺满alertView
    5. textAreaView (superView : textAreaScrollView) 铺满textAreaScrollView
    6. textContainer (superView : textAreaView) 横向居中，width : kInnerContentWidth(240)，height : textContainerHeightConstraint(可变)，上部贴textAreaView，
 */


#define OverlayViewColor [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]

const CGFloat kButtonCornerRadius = 4.0;
const CGFloat kAlertViewWidth = 270.0;
const CGFloat kAlertViewPadding = 15.0;
const CGFloat kInnerContentWidth = 240.0;
const CGFloat kButtonHeight = 44.0;
const CGFloat kButtonMargin = 10.0;






@interface HTAlertAnimation : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic, assign) BOOL isPresenting;
+ (instancetype)alertAnimationWithIsPresenting:(BOOL)isPresenting;
@end

@interface HTAlertController () <UIViewControllerTransitioningDelegate>
@property (nonatomic, strong) NSMutableArray<HTAlertAction *> *actions;
@property (nonatomic, strong) NSMutableArray<UIButton *> *buttons;
@property (nullable, nonatomic, strong) NSString *message;

@property (strong, nonatomic, nonnull) UIView *overlayView;
@property (strong, nonatomic, nonnull) UIView *containerView;
@property (strong, nonatomic, nonnull) UIView *alertView;
@property (strong, nonatomic) NSLayoutConstraint *alertViewHeightConstraint;

@property (strong, nonatomic, nonnull) UIScrollView *textAreaScrollView;
@property (assign, nonatomic) CGFloat textAreaHeight;

@property (strong, nonatomic, nonnull) UIView *textAreaView;
@property (strong, nonatomic, nonnull) UIView *textContainer;
@property (strong, nonatomic) NSLayoutConstraint *textContainerHeightConstraint;

@property (strong, nonatomic, nonnull) UILabel *messageLabel;

@property (nonatomic, strong) UIScrollView *buttonAreaScrollView;
@property (strong, nonatomic) NSLayoutConstraint *buttonAreaScrollViewHeightConstraint;
@property (assign, nonatomic) CGFloat buttonAreaHeight;

@property (nonatomic, strong) UIView *buttonAreaView;
@property (nonatomic, strong) UIView *buttonContainer;
@property (nonatomic, strong) NSLayoutConstraint *buttonContainerHeightConstraint;

@property (nonatomic, assign) CGFloat keyboardHeight;

- (void)addAction:(HTAlertAction *)action;
@end


@implementation HTAlertAction
+ (instancetype)actionWithTitle:(nullable NSString *)title handler:(nullable ActionHandler)handler {
    HTAlertAction *action = [[HTAlertAction alloc] init];
    action->_title = title;
    action.handler = handler;
    return action;
}
@end


@implementation HTAlertAnimation

+ (instancetype)alertAnimationWithIsPresenting:(BOOL)isPresenting {
    HTAlertAnimation *animation = [[HTAlertAnimation alloc] init];
    animation.isPresenting = isPresenting;
    return animation;
    
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    return self.isPresenting ? 0.45 : 0.25;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    if (self.isPresenting) {
        [self presentAnimateTransition:transitionContext];
    } else {
        [self dismissAnimateTransition:transitionContext];
    }
}

- (void)presentAnimateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    HTAlertController *alertController = (HTAlertController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    
    alertController.overlayView.alpha = 0.0;
    alertController.alertView.alpha = 0.0;
    alertController.alertView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    [containerView addSubview:alertController.view];
    
    [UIView animateWithDuration:0.25 animations:^{
        alertController.overlayView.alpha = 1.0;
        alertController.alertView.alpha = 1.0;
        alertController.alertView.transform = CGAffineTransformMakeScale(1.05, 1.05);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            alertController.alertView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (finished) {
                [transitionContext completeTransition:YES];
            }
        }];
    }];
}

- (void)dismissAnimateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    HTAlertController *alertController = (HTAlertController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        alertController.overlayView.alpha = 0.0;
        alertController.alertView.alpha = 0.0;
        alertController.alertView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

@end



@implementation HTAlertController

+ (nonnull instancetype)alertControllerWithMessage:(nullable NSString *)message {
    HTAlertController *instance = [[HTAlertController alloc] initWithMessage:message];
    return instance;
}

- (nonnull instancetype)initWithMessage:(nullable NSString *)message {
    self = [super init];
    if (self) {
        self.providesPresentationContextTransitionStyle = YES;
        self.definesPresentationContext = YES;
        self.modalPresentationStyle = UIModalPresentationCustom;
        
        _actions = [NSMutableArray array];
        _buttons = [NSMutableArray array];
        _message = message;
        
        self.view.backgroundColor = [UIColor clearColor];
        
        self.transitioningDelegate = self;
        
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        
        //self.view
        self.view.frame = CGRectMake(0, 0, screenSize.width, screenSize.height);
        
        //overlayView
        _overlayView = [[UIView alloc] init];
        _overlayView.backgroundColor = OverlayViewColor;
        [self.view addSubview:_overlayView];
        
        //containerView
        _containerView = [[UIView alloc] init];
        [self.view addSubview:_containerView];
        
        //alertView
        _alertView = [[UIView alloc] init];
        _alertView.backgroundColor = [UIColor colorWithRed:239/255.0 green:240/255.0 blue:242/255.0 alpha:1.0];
        [_containerView addSubview:_alertView];
        
        //textAreaScrollView
        _textAreaScrollView = [[UIScrollView alloc] init];
        [_alertView addSubview:_textAreaScrollView];
        
        //textAreaView
        _textAreaView = [[UIView alloc] init];
        [_textAreaScrollView addSubview:_textAreaView];
        
        //textContainer
        _textContainer = [[UIView alloc] init];
        [_textAreaView addSubview:_textContainer];
        
        //buttonAreaScrollView
        _buttonAreaScrollView = [[UIScrollView alloc] init];
        [_alertView addSubview:_buttonAreaScrollView];
        
        //buttonAreaView
        _buttonAreaView = [[UIView alloc] init];
        [_buttonAreaScrollView addSubview:_buttonAreaView];
        
        //buttonContainer
        _buttonContainer = [[UIView alloc] init];
        [_buttonAreaView addSubview:_buttonContainer];
        
        //-----------------------------
        //Layout Constraint
        //-----------------------------
        _overlayView.translatesAutoresizingMaskIntoConstraints = NO;
        _containerView.translatesAutoresizingMaskIntoConstraints = NO;
        _alertView.translatesAutoresizingMaskIntoConstraints = NO;
        _textAreaScrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _textAreaView.translatesAutoresizingMaskIntoConstraints = NO;
        _textContainer.translatesAutoresizingMaskIntoConstraints = NO;
        _buttonAreaScrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _buttonAreaView.translatesAutoresizingMaskIntoConstraints = NO;
        _buttonContainer.translatesAutoresizingMaskIntoConstraints = NO;
        
        //self.view
        NSLayoutConstraint *overlayViewTop = [NSLayoutConstraint constraintWithItem:_overlayView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        NSLayoutConstraint *overlayViewBottom = [NSLayoutConstraint constraintWithItem:_overlayView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        NSLayoutConstraint *overlayViewLeft = [NSLayoutConstraint constraintWithItem:_overlayView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        NSLayoutConstraint *overlayViewRight = [NSLayoutConstraint constraintWithItem:_overlayView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
        NSLayoutConstraint *containerViewTop = [NSLayoutConstraint constraintWithItem:_containerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        NSLayoutConstraint *containerViewBottom = [NSLayoutConstraint constraintWithItem:_containerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        NSLayoutConstraint *containerViewLeft = [NSLayoutConstraint constraintWithItem:_containerView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        NSLayoutConstraint *containerViewRight = [NSLayoutConstraint constraintWithItem:_containerView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
        [self.view addConstraints:@[overlayViewTop, overlayViewBottom, overlayViewLeft, overlayViewRight, containerViewTop, containerViewBottom, containerViewLeft, containerViewRight]];
        
        //containerView
        NSLayoutConstraint *alertViewCenterX = [NSLayoutConstraint constraintWithItem:_alertView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
        NSLayoutConstraint *alertViewCenterY = [NSLayoutConstraint constraintWithItem:_alertView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_containerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
        [_containerView addConstraints:@[alertViewCenterX, alertViewCenterY]];
        
        //alertView
        NSLayoutConstraint *alertViewWidth = [NSLayoutConstraint constraintWithItem:_alertView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kAlertViewWidth];
        _alertViewHeightConstraint = [NSLayoutConstraint constraintWithItem:_alertView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:1000];
        [_alertView addConstraints:@[alertViewWidth, _alertViewHeightConstraint]];
        
        NSLayoutConstraint *textAreaScrollViewTop = [NSLayoutConstraint constraintWithItem:_textAreaScrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_alertView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        NSLayoutConstraint *textAreaScrollViewBottom = [NSLayoutConstraint constraintWithItem:_textAreaScrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_alertView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        NSLayoutConstraint *textAreaScrollViewLeft = [NSLayoutConstraint constraintWithItem:_textAreaScrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_alertView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        NSLayoutConstraint *textAreaScrollViewRight = [NSLayoutConstraint constraintWithItem:_textAreaScrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_alertView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
        NSLayoutConstraint *buttonAreaScrollViewRight = [NSLayoutConstraint constraintWithItem:_buttonAreaScrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_alertView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
        NSLayoutConstraint *buttonAreaScrollViewLeft = [NSLayoutConstraint constraintWithItem:_buttonAreaScrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_alertView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        NSLayoutConstraint *buttonAreaScrollViewBottom = [NSLayoutConstraint constraintWithItem:_buttonAreaScrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_alertView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        [_alertView addConstraints:@[textAreaScrollViewTop, textAreaScrollViewBottom, textAreaScrollViewLeft, textAreaScrollViewRight, buttonAreaScrollViewRight, buttonAreaScrollViewLeft, buttonAreaScrollViewBottom]];
        
        //textAreaScrollView
        NSLayoutConstraint *textAreaViewTop = [NSLayoutConstraint constraintWithItem:_textAreaView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_textAreaScrollView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        NSLayoutConstraint *textAreaViewBottom = [NSLayoutConstraint constraintWithItem:_textAreaView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_textAreaScrollView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        NSLayoutConstraint *textAreaViewLeft = [NSLayoutConstraint constraintWithItem:_textAreaView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_textAreaScrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        NSLayoutConstraint *textAreaViewRight = [NSLayoutConstraint constraintWithItem:_textAreaView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_textAreaScrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
#warning textAreaViewWidth
        NSLayoutConstraint *textAreaViewWidth = [NSLayoutConstraint constraintWithItem:_textAreaView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_textAreaScrollView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
        [_textAreaScrollView addConstraints:@[textAreaViewTop, textAreaViewBottom, textAreaViewLeft, textAreaViewRight, textAreaViewWidth]];
        
        //textArea
#warning constraint
        NSLayoutConstraint *textAreaViewHeight = [NSLayoutConstraint constraintWithItem:_textAreaView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_textContainer attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
        NSLayoutConstraint *textContainerTop = [NSLayoutConstraint constraintWithItem:_textContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_textAreaView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        NSLayoutConstraint *textContainerCenterX = [NSLayoutConstraint constraintWithItem:_textContainer attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_textAreaView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
        [_textAreaView addConstraints:@[textAreaViewHeight, textContainerTop, textContainerCenterX]];
        
        //textContainer
        NSLayoutConstraint *textContainerWidth = [NSLayoutConstraint constraintWithItem:_textContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kInnerContentWidth];
        _textContainerHeightConstraint = [NSLayoutConstraint constraintWithItem:_textContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
        [_textContainer addConstraints:@[textContainerWidth, _textContainerHeightConstraint]];
        
        //buttonAreaScrollView
        _buttonAreaScrollViewHeightConstraint = [NSLayoutConstraint constraintWithItem:_buttonAreaScrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
        NSLayoutConstraint *buttonAreaViewTop = [NSLayoutConstraint constraintWithItem:_buttonAreaView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_buttonAreaScrollView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        NSLayoutConstraint *buttonAreaViewBottom = [NSLayoutConstraint constraintWithItem:_buttonAreaView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_buttonAreaScrollView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        NSLayoutConstraint *buttonAreaViewLeft = [NSLayoutConstraint constraintWithItem:_buttonAreaView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_buttonAreaScrollView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
        NSLayoutConstraint *buttonAreaViewRight = [NSLayoutConstraint constraintWithItem:_buttonAreaView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_buttonAreaScrollView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
#warning buttonAreaViewWidth
        NSLayoutConstraint *buttonAreaViewWidth = [NSLayoutConstraint constraintWithItem:_buttonAreaView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_buttonAreaScrollView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
        [_buttonAreaScrollView addConstraints:@[_buttonAreaScrollViewHeightConstraint, buttonAreaViewTop, buttonAreaViewBottom, buttonAreaViewLeft, buttonAreaViewRight, buttonAreaViewWidth]];
        
        //buttonAreaView
        NSLayoutConstraint *buttonAreaViewHeight = [NSLayoutConstraint constraintWithItem:_buttonAreaView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_buttonContainer attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0];
        NSLayoutConstraint *buttonContainerTop = [NSLayoutConstraint constraintWithItem:_buttonContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_buttonAreaView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        NSLayoutConstraint *buttonContainerCenterX = [NSLayoutConstraint constraintWithItem:_buttonContainer attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_buttonAreaView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
        [_buttonAreaView addConstraints:@[buttonAreaViewHeight, buttonContainerTop, buttonContainerCenterX]];
        
        //buttonContainer
        NSLayoutConstraint *buttonContainerWidth = [NSLayoutConstraint constraintWithItem:_buttonContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kInnerContentWidth];
        _buttonContainerHeightConstraint = [NSLayoutConstraint constraintWithItem:_buttonContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
        [_buttonContainer addConstraints:@[buttonContainerWidth, _buttonContainerHeightConstraint]];

        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self layoutView];
}

- (void)layoutView {
    _overlayView.backgroundColor = OverlayViewColor;
    
    //-------------------------
    //textArea Layout
    //-------------------------
    BOOL hasMessage = _message!=nil;
    CGFloat textAreaPositionY = kAlertViewPadding;
    if (hasMessage) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.frame = CGRectMake(0, 0, kInnerContentWidth, 0.0);
        _messageLabel.numberOfLines = 0;
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.text = _message;
        [_messageLabel sizeToFit];
        _messageLabel.frame = CGRectMake(0, textAreaPositionY, kInnerContentWidth, _messageLabel.frame.size.height);
        [_textContainer addSubview:_messageLabel];
        textAreaPositionY += _messageLabel.frame.size.height + 5.0;//textField used
    }
    if (!hasMessage) {
        textAreaPositionY = 0.0;
    }
    _textAreaHeight = textAreaPositionY;
    _textAreaScrollView.contentSize = CGSizeMake(kAlertViewWidth, _textAreaHeight);
    _textContainerHeightConstraint.constant = _textAreaHeight;
    
    //-------------------------
    //buttonArea Layout
    //-------------------------
    CGFloat buttonAreaPositionY = kButtonMargin;
    
    //buttons
    if (_buttons.count == 2) {
        CGFloat buttonWidth = (kInnerContentWidth - kButtonMargin) / 2.0;
        CGFloat buttonPositionX = 0.0;
        for (UIButton *button in _buttons) {
            HTAlertAction *action = _actions[button.tag - 1];
            [button setTitle:action.title forState:UIControlStateNormal];
            button.frame = CGRectMake(buttonPositionX, buttonAreaPositionY, buttonWidth, kButtonHeight);
            buttonPositionX += kButtonMargin + buttonWidth;
            
            button.backgroundColor = [UIColor redColor];
        }
        buttonAreaPositionY += kButtonHeight;
    } else {
        for (UIButton *button in _buttons) {
            HTAlertAction *action = _actions[button.tag - 1];
            [button setTitle:action.title forState:UIControlStateNormal];
            button.frame = CGRectMake(0, buttonAreaPositionY, kInnerContentWidth, kButtonHeight);
            buttonAreaPositionY += kButtonHeight + kButtonMargin;
            
            button.backgroundColor = [UIColor redColor];
        }
        buttonAreaPositionY -= kButtonMargin;
    }
    buttonAreaPositionY += kAlertViewPadding;
    
    if (_buttons.count == 0) buttonAreaPositionY = 0.0;
    
    //buttonAreaScrollView Height
    _buttonAreaHeight = buttonAreaPositionY;
    _buttonAreaScrollView.contentSize = CGSizeMake(kAlertViewWidth, _buttonAreaHeight);
    _buttonContainerHeightConstraint.constant = _buttonAreaHeight;
    
    //-------------------------
    //alertView Layout
    //-------------------------
    [self reloadAlertViewHeight];
    _alertView.frame = CGRectMake(_alertView.frame.origin.x, _alertView.frame.origin.y, kAlertViewWidth, _alertViewHeightConstraint.constant);

}

- (void)reloadAlertViewHeight {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat maxHeight = screenSize.height - _keyboardHeight;
    
    // for avoiding constraint error
    _buttonAreaScrollViewHeightConstraint.constant = 0.0;
    
    // alertView height constraint
    CGFloat alertViewHeight = _textAreaHeight + _buttonAreaHeight;
    if (alertViewHeight > maxHeight) alertViewHeight = maxHeight;
    _alertViewHeightConstraint.constant = alertViewHeight;
    
    // buttonAreaScrollView height constraint
    CGFloat buttonAreaScrollViewHeight = _buttonAreaHeight;
    if (buttonAreaScrollViewHeight > maxHeight) buttonAreaScrollViewHeight = maxHeight;
    _buttonAreaScrollViewHeightConstraint.constant = buttonAreaScrollViewHeight;
}

- (void)addAction:(HTAlertAction *)action {
    [self.actions addObject:action];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.masksToBounds = YES;
    [button setTitle:action.title forState:UIControlStateNormal];
    button.layer.cornerRadius = 3;
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = self.actions.count;
    [self.buttons addObject:button];
    [self.buttonContainer addSubview:button];
}

- (void)buttonTapped:(UIButton *)button {
    button.selected = YES;
    HTAlertAction *action = self.actions[button.tag - 1];
    if (action.handler != nil) {
        action.handler(action);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [HTAlertAnimation alertAnimationWithIsPresenting:YES];
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [HTAlertAnimation alertAnimationWithIsPresenting:NO];
}

@end


