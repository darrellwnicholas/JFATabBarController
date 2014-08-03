//
//  JFATabBarController.m
//  JFATabBarController
//
//  Created by Josh Adams on 5/18/13.
//  Copyright (c) 2013 Josh Adams. All rights reserved.
//

#import "JFATabBarController.h"

@interface JFATabBarController () <UINavigationControllerDelegate>
@property (strong, nonatomic) NSMutableArray *tabTitles;
@property (strong, nonatomic) NSMutableArray *tabButtons;
@property (strong, nonatomic) UIScrollView *barView;
@property (nonatomic) CGFloat tabBarHeight;
@end

@implementation JFATabBarController
static const CGFloat IPHONE_TAB_BAR_HEIGHT = 49.0;
static const CGFloat IPAD_TAB_BAR_HEIGHT = 56.0;
static const NSUInteger MAX_TAB_COUNT = 5; // maximum tabs on screen at once
static const CGFloat TITLE_BOTTOM_INSET = 26.0;
static const CGFloat IMAGE_TOP_INSET = 15.0;
static const CGFloat BUTTON_VERTICAL_INSET = 10;
static const CGFloat BUTTON_HEIGHT = 30;
static const CGFloat LABEL_SIZE = 10.0;

- (CGFloat)tabBarHeight
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return IPAD_TAB_BAR_HEIGHT;
    }
    else
    {
        return IPHONE_TAB_BAR_HEIGHT;
    }
}

- (UIScrollView *)barView
{
    if (!_barView)
    {
        CGRect barFrame = CGRectMake(0, self.view.bounds.size.height - self.tabBarHeight, self.view.bounds.size.width, self.tabBarHeight);
        _barView = [[UIScrollView alloc] initWithFrame:barFrame];
    }
    return _barView;
}

- (NSMutableArray *)tabTitles
{
    if (!_tabTitles)
    {
        _tabTitles = [NSMutableArray new];
    }
    return _tabTitles;
}

- (NSMutableArray *)tabButtons
{
    if (!_tabButtons)
    {
        _tabButtons = [NSMutableArray new];
    }
    return _tabButtons;
}

// This is the speed of the view-transition animation. Set it to 0.0 to prevent animation.
static const float TAB_ANIMATION_DURATION = 0.5;

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if (selectedIndex == self.selectedIndex)
    {
        return;
    }
    
    int multiplier = selectedIndex < self.selectedIndex ? 1 : -1;
    UIButton *oldButton = self.tabButtons[self.selectedIndex];
    UIView *oldView = ((UIViewController *)(self.viewControllers[self.selectedIndex])).view;
    [super setSelectedIndex:selectedIndex];
    float frameWidth = oldView.frame.size.width;
    float frameHeight = oldView.frame.size.height;
    CGRect offScreenRect = CGRectMake(frameWidth * multiplier, 0, frameWidth, frameHeight);
    oldView.bounds = CGRectMake(0, 0, frameWidth, frameHeight - self.tabBarHeight - 1);
    [self.view addSubview:oldView];
    [UIView animateWithDuration:TAB_ANIMATION_DURATION animations:^{
        oldView.frame = offScreenRect;
    } completion:^(BOOL finished) {
        [oldView removeFromSuperview];
    }];

    [self setButtonImageAndColor:oldButton image:oldButton.imageView.image color:[UIColor lightGrayColor]];
    UIButton *newButton = self.tabButtons[selectedIndex];
    [self setButtonImageAndColor:newButton image:newButton.imageView.image color:[UIColor blueColor]];
    CGFloat tabWidth = self.view.bounds.size.width / MAX_TAB_COUNT;
    [self.barView scrollRectToVisible:CGRectMake(selectedIndex * tabWidth, 0, tabWidth, self.tabBarHeight) animated:YES];
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    navigationController.navigationBarHidden = YES;
}

- (void)setTab:(UIButton *)sender
{
    [self setSelectedIndex:[self.tabTitles indexOfObject:sender.titleLabel.text]];
}

- (UIImage *)maskImage:(UIImage *)imageToMask color:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, imageToMask.size.width, imageToMask.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, imageToMask.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [imageToMask drawInRect:rect];
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.viewControllers count] > MAX_TAB_COUNT)
    {
        self.moreNavigationController.delegate = self;
        self.barView.backgroundColor = [UIColor whiteColor];
        NSUInteger tabCount = [self.viewControllers count];
        for (int i = 0; i < tabCount; i++)
        {
            UIViewController *vc = self.viewControllers[i];
            UITabBarItem *item = vc.tabBarItem;
            UIButton *button = [UIButton new];
            UIBarButtonSystemItem systemItem = [[item valueForKey:@"systemItem"] integerValue];
            NSString *title;
            if (systemItem == 0 && item.title)
            {
                title = item.title;
            }
            else
            {
                switch (systemItem)
                {
                    case UITabBarSystemItemMore:
                        title = @"More";
                        break;
                    case UITabBarSystemItemFavorites:
                        title = @"Favorites";
                        break;
                    case UITabBarSystemItemFeatured:
                        title = @"Featured";
                        break;
                    case UITabBarSystemItemTopRated:
                        title = @"Top Rated";
                        break;
                    case UITabBarSystemItemRecents:
                        title = @"Recents";
                        break;
                    case UITabBarSystemItemContacts:
                        title = @"Contacts";
                        break;
                    case UITabBarSystemItemHistory:
                        title = @"History";
                        break;
                    case UITabBarSystemItemBookmarks:
                        title = @"Bookmarks";
                        break;
                    case UITabBarSystemItemSearch:
                        title = @"Search";
                        break;
                    case UITabBarSystemItemDownloads:
                        title = @"Downloads";
                        break;
                    case UITabBarSystemItemMostRecent:
                        title = @"Recent";
                        break;
                    case UITabBarSystemItemMostViewed:
                        title = @"Most Viewed";
                        break;
                    default:
                        title = @"";
                        break;
                }
            }
            [button setTitle:title forState:UIControlStateNormal];
            [self.tabTitles addObject:title];
            if (i == 0)
            {
                [self setButtonImageAndColor:button image:item.selectedImage color:[UIColor blueColor]];
            }
            else
            {
                [self setButtonImageAndColor:button image:item.selectedImage color:[UIColor lightGrayColor]];
            }
            [button.titleLabel setFont:[UIFont systemFontOfSize:LABEL_SIZE]];
            UILabel *titleLabel = [UILabel new];
            titleLabel.text = title;
            [titleLabel setFont:[UIFont systemFontOfSize:LABEL_SIZE]];
            [titleLabel sizeToFit];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, -item.selectedImage.size.width, -TITLE_BOTTOM_INSET, 0.0)];
            [button setImageEdgeInsets:UIEdgeInsetsMake(-IMAGE_TOP_INSET, 0.0, 0.0, -titleLabel.bounds.size.width)];
            [button addTarget:self action:@selector(setTab:) forControlEvents:UIControlEventTouchUpInside];
            [self.barView addSubview:button];
            [self.tabButtons addObject:button];
        }
        [self.view addSubview:self.barView];
        [self setBarAndButtonPositions];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if ([self.viewControllers count] > MAX_TAB_COUNT)
    {
        [self setBarAndButtonPositions];
    }
}

- (void)setButtonImageAndColor:(UIButton *)button image:(UIImage *)image color:(UIColor*)color
{
    [button setTitleColor:color forState:UIControlStateNormal];
    [button setImage:[self maskImage:image color:color] forState:UIControlStateNormal];
}

- (void)setBarAndButtonPositions
{
    NSUInteger tabCount = [self.viewControllers count];
    float screenWidth = [self currentWidth];
    CGFloat tabWidth = screenWidth / MAX_TAB_COUNT;
    float screenHeight = [self currentHeight];
    CGRect barFrame = CGRectMake(0, screenHeight - self.tabBarHeight, screenWidth, self.tabBarHeight);
    self.barView.frame = barFrame;
    CGSize contentSize = self.barView.bounds.size;
    contentSize.width = screenWidth + tabWidth * (tabCount - MAX_TAB_COUNT);
    self.barView.contentSize = contentSize;
    for (int i = 0; i < tabCount; i++)
    {
        UIView *button = [self.barView subviews][i];
        CGRect buttonFrame = CGRectMake(i * tabWidth, BUTTON_VERTICAL_INSET, tabWidth, BUTTON_HEIGHT);
        button.frame = buttonFrame;
    }
    [self.barView scrollRectToVisible:CGRectMake(self.selectedIndex * tabWidth, 0, tabWidth, self.tabBarHeight) animated:YES];
}

- (float)currentWidth
{
    UIScreen *screen = [UIScreen mainScreen];
    float width = screen.currentMode.size.width / screen.scale;
    float height = screen.currentMode.size.height / screen.scale;
    return (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))? MAX (width, height) : MIN (width, height);
}

- (float)currentHeight
{
    UIScreen *screen = [UIScreen mainScreen];
    float width = screen.currentMode.size.width / screen.scale;
    float height = screen.currentMode.size.height / screen.scale;
    return (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))? MIN (width, height) : MAX (width, height);
}
@end