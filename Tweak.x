#import <UIKit/UIKit.h>

%hook UITabBar

- (void)layoutSubviews {
    %orig;
    
    // Chỉ áp dụng giao diện bo tròn dạng viên thuốc cho ứng dụng Điện thoại
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.mobilephone"]) {
        return;
    }

    self.layer.cornerRadius = 26.0;
    self.layer.masksToBounds = YES;
    
    // Tạo hiệu ứng kính mờ Liquid Glass
    if (@available(iOS 13.0, *)) {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
        UIVisualEffectView *blurView = [self viewWithTag:9988];
        if (!blurView) {
            blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
            blurView.tag = 9988;
            blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            blurView.userInteractionEnabled = NO;
            [self insertSubview:blurView atIndex:0];
        }
        blurView.frame = self.bounds;
    }
}

- (void)setFrame:(CGRect)frame {
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.mobilephone"]) {
        // Thu gọn hai bên để tạo khoảng hở nổi (Floating Pill)
        CGFloat horizontalMargin = 20.0;
        if (frame.size.width > (horizontalMargin * 2)) {
            frame.origin.x = horizontalMargin;
            frame.size.width -= (horizontalMargin * 2);
            frame.origin.y -= 10.0;
        }
    }
    %orig(frame);
}

%end
