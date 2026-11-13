#import <UIKit/UIKit.h>

@interface UITabBarController (PhoneOSM)
- (void)phoneosm_setupFloatingSearchButton;
- (void)phoneosm_openSearchAction;
@end

%hook UITabBarController

- (void)viewDidLayoutSubviews {
    %orig;
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.mobilephone"]) {
        return;
    }

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
    UITabBar *tabBar = self.tabBar;
    if (!tabBar || tabBar.hidden) return;

    CGFloat pillHeight = 56.0;
    CGFloat screenWidth = self.view.bounds.size.width;
    if (screenWidth <= 0) screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    CGFloat leftMargin = 16.0;
    CGFloat rightMargin = 16.0;
    CGFloat gap = 12.0;
    CGFloat circleSize = pillHeight;
    
    CGFloat tabBarWidth = screenWidth - leftMargin - rightMargin - gap - circleSize;
    CGFloat exactY = tabBar.frame.origin.y;
    if (exactY <= 0) {
        exactY = [UIScreen mainScreen].bounds.size.height - pillHeight - 24.0;
    }

    // Ép cứng khung UITabBar bên trái
    tabBar.frame = CGRectMake(leftMargin, exactY, tabBarWidth, pillHeight);

    if (!searchBtn) {
        searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        searchBtn.tag = 88991;
        
        // Nút tìm kiếm dạng icon kính lúp thuần túy không viền nền
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:22.0 weight:UIImageSymbolWeightSemibold];
        UIImage *searchImg = [UIImage systemImageNamed:@"magnifyingglass" withConfiguration:config];
        
        [searchBtn setImage:searchImg forState:UIControlStateNormal];
        searchBtn.tintColor = [UIColor labelColor];
        searchBtn.contentMode = UIViewContentModeScaleAspectFit;

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

%hook UITabBar

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

    // Xóa nền của các nút tab bên trong, chỉ giữ lại thanh viên thuốc chung
    for (UIView *sub in self.subviews) {
        if ([NSStringFromClass([sub class]) isEqualToString:@"UITabBarButton"]) {
            for (UIView *subSub in sub.subviews) {
                // Ẩn các hiệu ứng nền/khung chọn mặc định của hệ thống bên trong từng tab
                if ([NSStringFromClass([subSub class]) containsString:@"Background"] || 
                    [NSStringFromClass([subSub class]) containsString:@"Effect"] ||
                    [NSStringFromClass([subSub class]) containsString:@"BarBackground"]) {
                    subSub.hidden = YES;
                }
            }
        }
    }

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
