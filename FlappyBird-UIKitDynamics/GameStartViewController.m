//
//  ViewController.m
//  FlappyBird-UIKitDynamics
//
//  Created by Brian Rojas on 2/10/14.
//  Copyright (c) 2014 Brian Rojas. All rights reserved.
//

#import "GameStartViewController.h"

@interface GameStartViewController () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation GameStartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self shakeTitleMessage];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GameBeginSegue"]) {
        UIViewController *vc = segue.destinationViewController;
        vc.transitioningDelegate = self;
        vc.modalPresentationStyle = UIModalPresentationCustom;
    }
}

#pragma mark - Private methods

- (void)shakeTitleMessage
{
    [UIView animateWithDuration:0.4 delay:0.0 options:0 animations:^{
        CGRect frame = self.titleLabel.frame;
        frame.origin.y = 137.0f;
        self.titleLabel.frame = frame;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 delay:0.0 options:0 animations:^{
            CGRect frame = self.titleLabel.frame;
            frame.origin.y = 145.0f;
            self.titleLabel.frame = frame;
        } completion:^(BOOL finished) {
            [self shakeTitleMessage];
        }];
    }];
}

#pragma mark - UIViewControllerTransitioningDelegate methods

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning methods

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.8;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    
    UIView *coverView = [[UIView alloc] initWithFrame:containerView.bounds];
    coverView.backgroundColor = [UIColor blackColor];
    coverView.alpha = 0.0f;
    [containerView addSubview:coverView];
    
    UIView *toView = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey].view;
    
    [UIView animateWithDuration:0.4 animations:^{
        coverView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [containerView addSubview:toView];
        [containerView bringSubviewToFront:coverView];
        [UIView animateWithDuration:0.4 animations:^{
            coverView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [coverView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }];
}

@end
