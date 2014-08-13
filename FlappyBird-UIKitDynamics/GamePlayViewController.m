//
//  GamePlayViewController.m
//  FlappyBird-UIKitDynamics
//
//  Created by Brian Rojas on 2/10/14.
//  Copyright (c) 2014 Brian Rojas. All rights reserved.
//

#import "GamePlayViewController.h"

#define ARC4RANDOM_MAX 0x100000000
#define TOUCH_VELOCITY CGPointMake(0.0f, -425.0f)
#define PIPE_Y_INSET_MIN 90
#define PIPE_GAP_HEIGHT 140.0f

typedef NS_ENUM(NSInteger, GamePlayViewControllerMode) {
    GamePlayViewControllerModeGetReady,
    GamePlayViewControllerInFlight,
    GamePlayViewControllerGameOver
};

@interface GamePlayViewController () <UICollisionBehaviorDelegate>

@property (weak, nonatomic) IBOutlet UIView *flappyBirdView;
@property (weak, nonatomic) IBOutlet UIView *groundView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *okButton;

@property (nonatomic) GamePlayViewControllerMode mode;

@property (nonatomic) NSInteger score;

@property (strong, nonatomic) UIDynamicAnimator *dynamicAnimator;
@property (strong, nonatomic) UIGravityBehavior *gravityBehavior;
@property (strong, nonatomic) UIDynamicItemBehavior *flappyBirdItemBehavior;
@property (strong, nonatomic) UIDynamicItemBehavior *unmovableItemBehavior;
@property (strong, nonatomic) UICollisionBehavior *collisionBehavior;

@end

@implementation GamePlayViewController

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    self.gravityBehavior = [[UIGravityBehavior alloc] init];
    self.gravityBehavior.magnitude = 1.0f;
    [self.dynamicAnimator addBehavior:self.gravityBehavior];
    
    self.flappyBirdItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.flappyBirdView]];
    self.flappyBirdItemBehavior.allowsRotation = NO;
    [self.dynamicAnimator addBehavior:self.flappyBirdItemBehavior];
    
    self.unmovableItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.groundView]];
    self.unmovableItemBehavior.allowsRotation = NO;
    self.unmovableItemBehavior.density = 1000.0f;
    [self.dynamicAnimator addBehavior:self.unmovableItemBehavior];
    
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.flappyBirdView, self.groundView]];
    self.collisionBehavior.collisionDelegate = self;
    [self.dynamicAnimator addBehavior:self.collisionBehavior];
    
    CGFloat minAngle = -90.0f * M_PI / 180.0f;
    CGFloat maxAngle = 90.0f * M_PI / 180.0f;
    __weak GamePlayViewController *weakSelf = self;
    self.gravityBehavior.action = ^{
        CGPoint velocity = [weakSelf.flappyBirdItemBehavior linearVelocityForItem:weakSelf.flappyBirdView];
        CGFloat angle = velocity.y / 20.0f * M_PI / 180.0f;
        weakSelf.flappyBirdView.transform = CGAffineTransformMakeRotation(MIN(MAX(angle, minAngle), maxAngle));
    };
    
    self.mode = GamePlayViewControllerModeGetReady;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Private methods

- (void)shakeFlappyBird
{
    CGFloat originalY = CGRectGetMinY(self.flappyBirdView.frame);
    [UIView animateWithDuration:0.4 delay:0.0 options:0 animations:^{
        CGRect frame = self.flappyBirdView.frame;
        frame.origin.y = originalY - 7.0f;
        self.flappyBirdView.frame = frame;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4 delay:0.0 options:0 animations:^{
            CGRect frame = self.flappyBirdView.frame;
            frame.origin.y = originalY;
            self.flappyBirdView.frame = frame;
        } completion:^(BOOL finished) {
            if (self.mode == GamePlayViewControllerModeGetReady) {
                [self shakeFlappyBird];
            }
        }];
    }];
}

- (void)setMode:(GamePlayViewControllerMode)mode
{
    _mode = mode;
    
    if (mode == GamePlayViewControllerModeGetReady) {
        [self shakeFlappyBird];
        self.statusLabel.text = @"Get Ready";
    } else if (mode == GamePlayViewControllerInFlight) {
        self.statusLabel.text = @"";
        
        [self.gravityBehavior addItem:self.flappyBirdView];
        [self.flappyBirdItemBehavior addLinearVelocity:TOUCH_VELOCITY forItem:self.flappyBirdView];
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self spawnPipe];
        });
    } else if (self.mode == GamePlayViewControllerGameOver) {
        [self.dynamicAnimator removeBehavior:self.gravityBehavior];
        [self.dynamicAnimator removeBehavior:self.flappyBirdItemBehavior];
        [self.dynamicAnimator removeBehavior:self.unmovableItemBehavior];
        [self.dynamicAnimator removeBehavior:self.collisionBehavior];
        
        self.statusLabel.text = @"Game Over";
        self.okButton.hidden = NO;
        
        [self.view bringSubviewToFront:self.statusLabel];
        [self.view bringSubviewToFront:self.okButton];
    }
}

- (void)spawnPipe
{
    double random = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat yMin = PIPE_Y_INSET_MIN;
    CGFloat yMax = CGRectGetMinY(self.groundView.frame) - PIPE_Y_INSET_MIN;
    CGFloat y = yMin + (yMax - yMin) * random;
    [self spawnPipeWithHoleAtYFromTop:y];
    
    double delayInSeconds = 1.4;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self spawnPipe];
    });
}

- (void)spawnPipeWithHoleAtYFromTop:(CGFloat)y
{
    UIColor *pipeColor = [UIColor colorWithRed:98.0f/255.0f
                                         green:182.0f/255.0f
                                          blue:35.0f/255.0f
                                         alpha:1.0f];
    
    
    UIView *pipeTopView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds), 0.0f,
                                                                   57.0f, y - PIPE_GAP_HEIGHT / 2.0f)];
    pipeTopView.backgroundColor = pipeColor;
    pipeTopView.userInteractionEnabled = NO;
    [self.view addSubview:pipeTopView];
    
    CGFloat pipeTotalHeight = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.groundView.bounds);
    CGFloat bottomPipeHeight = pipeTotalHeight - PIPE_GAP_HEIGHT - CGRectGetHeight(pipeTopView.bounds);
    
    UIView *pipeBottomView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds),
                                                                      CGRectGetMaxY(pipeTopView.frame) + PIPE_GAP_HEIGHT,
                                                                      57.0f, bottomPipeHeight)];
    pipeBottomView.backgroundColor = pipeColor;
    pipeBottomView.userInteractionEnabled = NO;
    [self.view addSubview:pipeBottomView];
    
    [self.collisionBehavior addItem:pipeTopView];
    [self.collisionBehavior addItem:pipeBottomView];
    
    [self.unmovableItemBehavior addItem:pipeTopView];
    [self.unmovableItemBehavior addItem:pipeBottomView];
    
    UIAttachmentBehavior *pipeTopAttachment = [[UIAttachmentBehavior alloc] initWithItem:pipeTopView
                                                                        attachedToAnchor:pipeTopView.center];
    UIAttachmentBehavior *pipeBottomAttachment = [[UIAttachmentBehavior alloc] initWithItem:pipeBottomView
                                                                           attachedToAnchor:pipeBottomView.center];
    
    [self.dynamicAnimator addBehavior:pipeTopAttachment];
    [self.dynamicAnimator addBehavior:pipeBottomAttachment];
    
    __block CGFloat previousPipeX = CGRectGetMinX(pipeTopView.frame);
    [self interpolateValueFrom:pipeTopView.center.x to:-CGRectGetWidth(pipeTopView.bounds)/2.0f currentTime:0.0 endTime:3.0 frameBlock:^(CGFloat interpolatedValue, BOOL *stop) {
        CGPoint anchorPoint = pipeTopAttachment.anchorPoint;
        anchorPoint.x = interpolatedValue;
        pipeTopAttachment.anchorPoint = anchorPoint;
        
        anchorPoint = pipeBottomAttachment.anchorPoint;
        anchorPoint.x = interpolatedValue;
        pipeBottomAttachment.anchorPoint = anchorPoint;
        
        if (CGRectGetMinX(pipeTopView.frame) < CGRectGetMinX(self.flappyBirdView.frame) &&
            previousPipeX > CGRectGetMinX(self.flappyBirdView.frame)) {
            self.score++;
            self.statusLabel.text = [NSString stringWithFormat:@"%d", self.score];
        }
        previousPipeX = CGRectGetMinX(pipeTopView.frame);
        
        if (self.mode != GamePlayViewControllerInFlight) {
            *stop = YES;
        }
    } completionBlock:^{
        [self.collisionBehavior removeItem:pipeTopView];
        [self.collisionBehavior removeItem:pipeBottomView];
        [self.unmovableItemBehavior removeItem:pipeTopView];
        [self.unmovableItemBehavior removeItem:pipeBottomView];
        [self.dynamicAnimator removeBehavior:pipeTopAttachment];
        [self.dynamicAnimator removeBehavior:pipeBottomAttachment];
        
        if (self.mode == GamePlayViewControllerInFlight) {
            [pipeTopView removeFromSuperview];
            [pipeBottomView removeFromSuperview];
        }
    }];
}

- (void)interpolateValueFrom:(CGFloat)from
                          to:(CGFloat)to
                 currentTime:(NSTimeInterval)currentTime
                     endTime:(NSTimeInterval)endTime
                  frameBlock:(void (^)(CGFloat interpolatedValue, BOOL *stop))frameBlock
             completionBlock:(void (^)())completionBlock
{
    CGFloat percentThru = currentTime / endTime;
    BOOL stop = NO;
    frameBlock(from + (to - from) * percentThru, &stop);
    
    if (currentTime < endTime && !stop) {
        double delayInSeconds = 1.0 / 30.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self interpolateValueFrom:from to:to currentTime:currentTime+delayInSeconds endTime:endTime frameBlock:frameBlock completionBlock:completionBlock];
        });
    } else {
        completionBlock();
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self didTapView];
}

#pragma mark - Action methods

- (void)didTapView
{
    if (self.mode == GamePlayViewControllerModeGetReady) {
        self.mode = GamePlayViewControllerInFlight;
    } else if (self.mode == GamePlayViewControllerInFlight) {
        if (CGRectGetMinY(self.flappyBirdView.frame) > 0.0f) {
            CGPoint velocity = [self.flappyBirdItemBehavior linearVelocityForItem:self.flappyBirdView];
            velocity.x = 0.0f;
            velocity.y = TOUCH_VELOCITY.y - velocity.y;
            [self.flappyBirdItemBehavior addLinearVelocity:velocity forItem:self.flappyBirdView];
        }
    }
}

- (IBAction)didPressOK:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollisionBehaviorDelegate methods

- (void)collisionBehavior:(UICollisionBehavior*)behavior beganContactForItem:(id <UIDynamicItem>)item1 withItem:(id <UIDynamicItem>)item2 atPoint:(CGPoint)p
{
    self.mode = GamePlayViewControllerGameOver;
}

@end
