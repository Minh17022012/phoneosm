#import <UIKit/UIKit.h>
#import <Contacts/Contacts.h>

// Hook vào UILabel để theo dõi dãy số đang được nhập trên màn hình bàn phím
%hook UILabel

- (void)setText:(NSString *)text {
    %orig;
    
    // Kiểm tra nếu đây là chuỗi số đang quay số (chứa các ký tự số, khoảng trắng hoặc dấu cộng và độ dài từ 1-15 ký tự)
    if (text && text.length > 0 && text.length <= 15) {
        NSCharacterSet *numericSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789+*# "];
        if ([text rangeOfCharacterFromSet:[numericSet invertedSet]].location == NSNotFound) {
            // Gọi hàm hiển thị gợi ý danh bạ dựa trên chuỗi số 'text'
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PhoneOSMSmartT9Update" object:text];
        }
    }
}

%end

// Hook UITabBarController hoặc PHKeypadViewController để chèn khung gợi ý kính mờ
@interface UITabBarController (SmartT9)
- (void)phoneosm_setupT9SuggestionOverlay;
@end

%hook UITabBarController

- (void)viewDidLayoutSubviews {
    %orig;
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.mobilephone"]) {
        return;
    }
    [self phoneosm_setupT9SuggestionOverlay];
}

%new
- (void)phoneosm_setupT9SuggestionOverlay {
    UIView *rootView = self.view;
    UIVisualEffectView *suggestionBox = [rootView viewWithTag:998877];

    if (!suggestionBox) {
        CGFloat screenWidth = rootView.bounds.size.width;
        CGFloat boxWidth = screenWidth - 32.0;
        CGFloat boxHeight = 80.0;
        // Đặt vị trí nằm phía trên thanh Tab Bar hoặc khu vực bàn phím
        CGFloat boxY = rootView.bounds.size.height - 240.0; 

        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
        suggestionBox = [[UIVisualEffectView alloc] initWithEffect:blur];
        suggestionBox.tag = 998877;
        suggestionBox.frame = CGRectMake(16.0, boxY, boxWidth, boxHeight);
        suggestionBox.layer.cornerRadius = 16.0;
        suggestionBox.clipsToBounds = YES;
        suggestionBox.layer.borderWidth = 0.6;
        suggestionBox.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.65].CGColor;
        suggestionBox.alpha = 0.0; // Mặc định ẩn đi khi chưa gõ số

        UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, boxWidth - 32, 24)];
        nameLbl.tag = 998878;
        nameLbl.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
        nameLbl.textColor = [UIColor labelColor];
        [suggestionBox.contentView addSubview:nameLbl];

        UILabel *phoneLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 38, boxWidth - 32, 20)];
        phoneLbl.tag = 998879;
        phoneLbl.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
        phoneLbl.textColor = [UIColor secondaryLabelColor];
        [suggestionBox.contentView addSubview:phoneLbl];

        [rootView addSubview:suggestionBox];

        // Đăng ký nhận sự kiện khi người dùng gõ số
        [[NSNotificationCenter defaultCenter] addObserverForName:@"PhoneOSMSmartT9Update" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            NSString *query = note.object;
            if (!query || query.length == 0) {
                suggestionBox.alpha = 0.0;
                return;
            }

            // Truy vấn danh bạ bất đồng bộ chống treo máy
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                CNContactStore *store = [[CNContactStore alloc] init];
                NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
                CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
                
                __block NSString *matchedName = nil;
                __block NSString *matchedPhone = nil;

                [store enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact *contact, BOOL *stop) {
                    for (CNLabeledValue<CNPhoneNumber *> *labelValue in contact.phoneNumbers) {
                        NSString *phoneNum = labelValue.value.stringValue;
                        NSString *cleanPhone = [[phoneNum componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
                        
                        if ([cleanPhone containsString:query]) {
                            matchedName = [NSString stringWithFormat:@"%@ %@", contact.familyName ?: @"", contact.givenName ?: @""];
                            matchedPhone = phoneNum;
                            *stop = YES;
                            break;
                        }
                    }
                    if (matchedName) *stop = YES;
                }];

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (matchedName) {
                        nameLbl.text = matchedName;
                        phoneLbl.text = matchedPhone;
                        suggestionBox.alpha = 1.0;
                    } else {
                        nameLbl.text = [NSString stringWithFormat:@"Tìm kiếm số: %@", query];
                        phoneLbl.text = @"Không có trong danh bạ";
                        suggestionBox.alpha = 1.0;
                    }
                });
            });
        }];
    }
    [rootView bringSubviewToFront:suggestionBox];
}

%end
