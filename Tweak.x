#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UITabBar (phoneosmTweak)
@property (nonatomic, strong) UIVisualEffectView *glassBackgroundView;
@property (nonatomic, strong) UIVisualEffectView *activePillIndicator;
@property (nonatomic, strong) UIButton *floatingSearchButton;
- (void)setupiOS26FloatingUI;
- (void)updateActiveTabPill;
- (void)didTapFloatingSearch;
- (UISearchBar *)findSearchBarInView:(UIView *)rootView;
@end

static char kGlassBgKey;
static char kActivePillKey;
static char kSearchBtnKey;

%hook UITabBar

%new
- (UIVisualEffectView *)glassBackgroundView {
    return objc_getAssociatedObject(self, &kGlassBgKey);
}

%new
- (void)setGlassBackgroundView:(UIVisualEffectView *)view {
    objc_setAssociatedObject(self, &kGlassBgKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (UIVisualEffectView *)activePillIndicator {
    return objc_getAssociatedObject(self, &kActivePillKey);
}

%new
- (void)setActivePillIndicator:(UIVisualEffectView *)view {
    objc_setAssociatedObject(self, &kActivePillKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (UIButton *)floatingSearchButton {
    return objc_getAssociatedObject(self, &kSearchBtnKey);
}

%new
- (void)setFloatingSearchButton:(UIButton *)btn {
    objc_setAssociatedObject(self, &kSearchBtnKey, btn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)layoutSubviews {
    %orig;
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.apple.mobilephone"]) {
        return;
    }

    [self setupiOS26FloatingUI];
    
    UIView *superview = self.superview;
    if (!superview) return;

    CGFloat horizontalMargin = 16.0;
    CGFloat spacingBetweenPillAndSearch = 12.0;
    CGFloat barHeight = 64.0;
    CGFloat bottomInset = superview.safeAreaInsets.bottom > 0 ? superview.safeAreaInsets.bottom - 6.0 : 16.0;
    
    CGFloat totalAvailableWidth = superview.bounds.size.width - (horizontalMargin * 2);
    CGFloat searchBtnSize = barHeight;
    CGFloat pillWidth = totalAvailableWidth - searchBtnSize - spacingBetweenPillAndSearch;
    CGFloat originY = superview.bounds.size.height - barHeight - bottomInset;

    self.frame = CGRectMake(horizontalMargin, originY, pillWidth, barHeight);
    self.layer.cornerRadius = barHeight / 2.0;
    self.layer.masksToBounds = NO;
    
    self.backgroundImage = [UIImage new];
    self.shadowImage = [UIImage new];
    self.backgroundColor = [UIColor clearColor];
    
    for (UIView *subview in self.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"BarBackground"]) {
            subview.hidden = YES;
        }
    }

    self.glassBackgroundView.frame = self.bounds;
    self.glassBackgroundView.layer.cornerRadius = barHeight / 2.0;

    CGFloat searchOriginX = horizontalMargin + pillWidth + spacingBetweenPillAndSearch;
    self.floatingSearchButton.frame = CGRectMake(searchOriginX, originY, searchBtnSize, searchBtnSize);
    self.floatingSearchButton.layer.cornerRadius = searchBtnSize / 2.0;

    NSMutableArray<UIView *> *tabBarButtons = [NSMutableArray array];
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            [tabBarButtons addObject:subview];
        }
    }
    
    [tabBarButtons sortUsingComparator:^NSComparisonResult(UIView *v1, UIView *v2) {
        return [@(v1.frame.origin.x) compare:@(v2.frame.origin.x)];
    }];

    if (tabBarButtons.count > 0) {
        CGFloat innerPadding = 6.0;
        CGFloat usableWidth = pillWidth - (innerPadding * 2);
        CGFloat itemWidth = usableWidth / tabBarButtons.count;
        
        for (NSInteger i = 0; i < tabBarButtons.count; i++) {
            UIView *btn = tabBarButtons[i];
            btn.frame = CGRectMake(innerPadding + (i * itemWidth), 4.0, itemWidth, barHeight - 8.0);
        }
    }

    [self updateActiveTabPill];
}

%new
- (void)setupiOS26FloatingUI {
    if (!self.glassBackgroundView) {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.userInteractionEnabled = NO;
        blurView.clipsToBounds = YES;
        
        blurView.layer.borderWidth = 0.8;
        blurView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.55].CGColor;
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 6);
        self.layer.shadowRadius = 16.0;
        self.layer.shadowOpacity = 0.12;
        
        [self insertSubview:blurView atIndex:0];
        self.glassBackgroundView = blurView;
    }

    if (!self.activePillIndicator) {
        UIBlurEffect *pillBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial];
        UIVisualEffectView *pillView = [[UIVisualEffectView alloc] initWithEffect:pillBlur];
        pillView.userInteractionEnabled = NO;
        pillView.clipsToBounds = YES;
        pillView.backgroundColor = [[UIColor systemBackgroundColor] colorWithAlphaComponent:0.45];
        pillView.layer.borderWidth = 0.5;
        pillView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7].CGColor;
        
        [self insertSubview:pillView aboveSubview:self.glassBackgroundView];
        self.activePillIndicator = pillView;
    }

    if (!self.floatingSearchButton && self.superview) {
        UIButton *searchBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        
        UIBlurEffect *btnBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
        UIVisualEffectView *btnBlurView = [[UIVisualEffectView alloc] initWithEffect:btnBlur];
        btnBlurView.frame = searchBtn.bounds;
        btnBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        btnBlurView.userInteractionEnabled = NO;
        btnBlurView.clipsToBounds = YES;
        btnBlurView.layer.cornerRadius = 32.0;
        btnBlurView.layer.borderWidth = 0.8;
        btnBlurView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.55].CGColor;
        [searchBtn insertSubview:btnBlurView atIndex:0];
        
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:21 weight:UIImageSymbolWeightMedium];
        UIImage *searchIcon = [UIImage systemImageNamed:@"magnifyingglass" withConfiguration:config];
        [searchBtn setImage:searchIcon forState:UIControlStateNormal];
        searchBtn.tintColor = [UIColor labelColor];
        
        searchBtn.layer.shadowColor = [UIColor blackColor].CGColor;
        searchBtn.layer.shadowOffset = CGSizeMake(0, 6);
        searchBtn.layer.shadowRadius = 16.0;
        searchBtn.layer.shadowOpacity = 0.12;
        
        [searchBtn addTarget:self action:@selector(didTapFloatingSearch) forControlEvents:UIControlEventTouchUpInside];
        
        [self.superview addSubview:searchBtn];
        self.floatingSearchButton = searchBtn;
    }
}

%new
- (void)updateActiveTabPill {
    if (!self.selectedItem || !self.activePillIndicator) return;
    
    UIView *selectedButtonView = nil;
    if ([self.selectedItem respondsToSelector:@selector(view)]) {
        selectedButtonView = [self.selectedItem valueForKey:@"view"];
    }
    
    if (selectedButtonView) {
        CGRect targetFrame = CGRectInset(selectedButtonView.frame, 2.0, 2.0);
        self.activePillIndicator.layer.cornerRadius = targetFrame.size.height / 2.0;
        
        [UIView animateWithDuration:0.28
                              delay:0
             usingSpringWithDamping:0.82
              initialSpringVelocity:0.6
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            self.activePillIndicator.frame = targetFrame;
        } completion:nil];
    }
}

%new
- (void)didTapFloatingSearch {
    if (self.items.count >= 3) {
        UITabBarItem *contactsItem = self.items[2];
        [self setSelectedItem:contactsItem];
        
        if ([self.delegate respondsToSelector:@selector(tabBar:didSelectItem:)]) {
            [self.delegate tabBar:self didSelectItem:contactsItem];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIWindow *keyWindow = self.window;
            for (UIView *view in keyWindow.subviews) {
                UISearchBar *searchBar = [self findSearchBarInView:view];
                if (searchBar) {
                    [searchBar becomeFirstResponder];
                    break;
                }
            }
        });
    }
}

%new
- (UISearchBar *)findSearchBarInView:(UIView *)rootView {
    if ([rootView isKindOfClass:[UISearchBar class]]) {
        return (UISearchBar *)rootView;
    }
    for (UIView *subview in rootView.subviews) {
        UISearchBar *found = [self findSearchBarInView:subview];
        if (found) return found;
    }
    return nil;
}

%end
