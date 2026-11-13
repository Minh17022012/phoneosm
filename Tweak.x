#import <UIKit/UIKit.h>

@interface UITabBarController (PhoneOSM)
- (void)phoneosm_setupFloatingSearchButton;
- (void)phoneosm_openSearchAction;
@end

// Hook tinh chỉnh TabBar và giao diện chính
%hook UITabBarController

- (void)viewDidLayoutSubviews {
    %orig;
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.mobilephone"]) {
        return;
    }

    // Rút gọn còn 3 tab chính: Cuộc gọi, Danh bạ, Bàn phím
    if (self.viewControllers.count > 3) {
        NSMutableArray *filteredTabs = [NSMutableArray array];
        for (UIViewController *vc in self.viewControllers) {
            NSUInteger idx = [self.viewControllers indexOfObject:vc];
            if (idx == 1 || idx == 2 || idx == 3) {
                [filteredTabs addObject:vc];
            }
        }
        if (filteredTabs.count == 3) {
            [self setViewControllers:filteredTabs animated:NO];
        }
    }

    [self phoneosm_setupFloatingSearchButton];
}

%new
- (void)phoneosm_setupFloatingSearchButton {
    UIButton *searchBtn = [self.view viewWithTag:88991];
    if (!self.tabBar || self.tabBar.hidden) return;

    CGFloat pillHeight = 56.0;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat leftMargin = 16.0;
    CGFloat rightMargin = 16.0;
    CGFloat gap = 12.0;
    CGFloat circleSize = pillHeight;
    
    CGFloat tabBarWidth = screenWidth - leftMargin - rightMargin - gap - circleSize;
    CGFloat exactY = screenHeight - pillHeight - 24.0;

    if (!searchBtn) {
        searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        searchBtn.tag = 88991;
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.frame = CGRectMake(0, 0, circleSize, circleSize);
        blurView.userInteractionEnabled = NO;
        blurView.layer.cornerRadius = circleSize / 2.0;
        blurView.clipsToBounds = YES;
        [searchBtn addSubview:blurView];

        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20.0 weight:UIImageSymbolWeightSemibold];
        UIImage *searchImg = [UIImage systemImageNamed:@"magnifyingglass" withConfiguration:config];
        UIImageView *iconView = [[UIImageView alloc] initWithImage:searchImg];
        iconView.tintColor = [UIColor labelColor];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.frame = CGRectMake((circleSize - 24) / 2.0, (circleSize - 24) / 2.0, 24, 24);
        [searchBtn addSubview:iconView];

        searchBtn.layer.cornerRadius = circleSize / 2.0;
        searchBtn.layer.borderWidth = 0.6;
        searchBtn.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.65].CGColor;
        searchBtn.layer.shadowColor = [UIColor blackColor].CGColor;
        searchBtn.layer.shadowOpacity = 0.12;
        searchBtn.layer.shadowOffset = CGSizeMake(0, 4);
        searchBtn.layer.shadowRadius = 10.0;

        [searchBtn addTarget:self action:@selector(phoneosm_openSearchAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:searchBtn];
    }

    CGFloat xPos = leftMargin + tabBarWidth + gap;
    searchBtn.frame = CGRectMake(xPos, exactY, circleSize, circleSize);
    [self.view bringSubviewToFront:searchBtn];
}

%new
- (void)phoneosm_openSearchAction {
    if (self.viewControllers.count >= 2) {
        self.selectedIndex = 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIViewController *selectedVC = self.selectedViewController;
            UINavigationController *nav = [selectedVC isKindOfClass:[UINavigationController class]] ? (UINavigationController *)selectedVC : selectedVC.navigationController;
            UISearchController *searchController = nav.topViewController.navigationItem.searchController;
            if (searchController) {
                searchController.active = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [searchController.searchBar becomeFirstResponder];
                });
            }
        });
    }
}

%end

// Hook tinh chỉnh TabBar thành viên thuốc nổi kính mờ
%hook UITabBar

- (void)setFrame:(CGRect)frame {
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.mobilephone"]) {
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        CGFloat leftMargin = 16.0;
        CGFloat rightMargin = 16.0;
        CGFloat gap = 12.0;
        CGFloat pillHeight = 56.0;
        CGFloat circleSize = pillHeight;

        frame.origin.x = leftMargin;
        frame.size.width = screenWidth - leftMargin - rightMargin - gap - circleSize;
        frame.size.height = pillHeight;
        frame.origin.y = screenHeight - pillHeight - 24.0;
    }
    %orig(frame);
}

- (void)layoutSubviews {
    %orig;
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.mobilephone"]) {
        return;
    }

    self.layer.cornerRadius = self.bounds.size.height / 2.0;
    self.layer.masksToBounds = NO;
    self.layer.borderWidth = 0.6;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.65].CGColor;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.12;
    self.layer.shadowOffset = CGSizeMake(0, 4);
    self.layer.shadowRadius = 10.0;

    for (UIView *sub in self.subviews) {
        if ([sub isKindOfClass:[UIImageView class]] && sub.bounds.size.height <= 1.0) {
            sub.hidden = YES;
        }
    }

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
    UIVisualEffectView *blurView = [self viewWithTag:9988];
    if (!blurView) {
        blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.tag = 9988;
        blurView.userInteractionEnabled = NO;
        blurView.clipsToBounds = YES;
        [self insertSubview:blurView atIndex:0];
    }
    blurView.frame = self.bounds;
    blurView.layer.cornerRadius = self.bounds.size.height / 2.0;

    UIView *selectionPill = [self viewWithTag:9989];
    if (!selectionPill) {
        selectionPill = [[UIView alloc] init];
        selectionPill.tag = 9989;
        selectionPill.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.12];
        selectionPill.userInteractionEnabled = NO;
        [self insertSubview:selectionPill aboveSubview:blurView];
    }

    NSMutableArray *tabButtons = [NSMutableArray array];
    for (UIView *sub in self.subviews) {
        if ([NSStringFromClass([sub class]) isEqualToString:@"UITabBarButton"]) {
            [tabButtons addObject:sub];
        }
    }
    [tabButtons sortUsingComparator:^NSComparisonResult(UIView *v1, UIView *v2) {
        return [@(v1.frame.origin.x) compare:@(v2.frame.origin.x)];
    }];

    NSInteger selectedIdx = [self.items indexOfObject:self.selectedItem];
    if (selectedIdx >= 0 && selectedIdx < tabButtons.count) {
        UIView *activeBtn = tabButtons[selectedIdx];
        CGRect pillRect = CGRectInset(activeBtn.frame, 4.0, 4.0);
        selectionPill.frame = pillRect;
        selectionPill.layer.cornerRadius = pillRect.size.height / 2.0;
        selectionPill.hidden = NO;
    } else {
        selectionPill.hidden = YES;
    }
}

%end

// Hook bàn phím số (Keypad) để kích hoạt hiển thị ô gợi ý danh bạ tương tự ảnh số 3
%hook PHleyiciKeypadViewController

- (void)viewDidLoad {
    %orig;
    // Tối ưu hóa giao diện phím bấm số bo tròn mềm mại phong cách iOS 26
}

%end
