#import <UIKit/UIKit.h>
#import <Contacts/Contacts.h>

@interface PHleyiciKeypadViewController : UIViewController
- (NSString *)numericSearchString;
@end

%hook PHleyiciKeypadViewController

- (void)viewDidLoad {
    %orig;
    // Tùy chỉnh giao diện bàn phím và chèn khung gợi ý tìm kiếm danh bạ
}

// Bắt sự kiện mỗi khi người dùng bấm phím số hoặc xóa số
- (void)phonePad:(id)pad appendString:(NSString *)string {
    %orig;
    [self performSelector:@selector(phoneosm_updateT9Suggestions) withObject:nil afterDelay:0.05];
}

- (void)phonePadDeleteCharacter:(id)pad {
    %orig;
    [self performSelector:@selector(phoneosm_updateT9Suggestions) withObject:nil afterDelay:0.05];
}

%new
- (void)phoneosm_updateT9Suggestions {
    // Lấy chuỗi số đang gõ trên bàn phím
    NSString *currentQuery = nil;
    if ([self respondsToSelector:@selector(numericSearchString)]) {
        currentQuery = [self numericSearchString];
    }
    
    UIView *keypadView = self.view;
    UIVisualEffectView *suggestionBox = [keypadView viewWithTag:778899];

    if (!currentQuery || currentQuery.length == 0) {
        // Nếu chưa gõ số thì ẩn hộp gợi ý đi
        [UIView animateWithDuration:0.2 animations:^{
            suggestionBox.alpha = 0.0;
        }];
        return;
    }

    // Nếu chưa có khung gợi ý, tiến hành tạo mới dạng viên thuốc kính mờ phong cách Liquid Glass
    if (!suggestionBox) {
        CGFloat screenWidth = keypadView.bounds.size.width;
        CGFloat boxWidth = screenWidth - 32.0;
        CGFloat boxHeight = 90.0;
        CGFloat boxY = 60.0; // Nằm phía trên bàn phím số
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
        suggestionBox = [[UIVisualEffectView alloc] initWithEffect:blur];
        suggestionBox.tag = 778899;
        suggestionBox.frame = CGRectMake(16.0, boxY, boxWidth, boxHeight);
        suggestionBox.layer.cornerRadius = 16.0;
        suggestionBox.clipsToBounds = YES;
        suggestionBox.layer.borderWidth = 0.5;
        suggestionBox.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
        
        // Thêm nhãn hiển thị tên gợi ý và số điện thoại khớp
        UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, boxWidth - 32, 24)];
        nameLbl.tag = 778901;
        nameLbl.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightsemibold];
        nameLbl.textColor = [UIColor labelColor];
        [suggestionBox.contentView addSubview:nameLbl];

        UILabel *phoneLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 38, boxWidth - 32, 20)];
        phoneLbl.tag = 778902;
        phoneLbl.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
        phoneLbl.textColor = [UIColor secondaryLabelColor];
        [suggestionBox.contentView addSubview:phoneLbl];

        [keypadView addSubview:suggestionBox];
    }

    // Truy vấn danh bạ an toàn qua CNContactStore (chạy trên background thread để chống treo máy)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CNContactStore *store = [[CNContactStore alloc] init];
        NSArray *keys = @[CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey];
        CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
        
        __block NSString *matchedName = nil;
        __block NSString *matchedPhone = nil;

        [store enumerateContactsWithFetchRequest:request error:nil usingBlock:^(CNContact *contact, BOOL *stop) {
            for (CNLabeledValue<CNPhoneNumber *> *labelValue in contact.phoneNumbers) {
                NSString *phoneNum = labelValue.value.stringValue;
                // Lọc chuỗi số đơn giản để so khớp
                NSString *cleanPhone = [[phoneNum componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
                
                if ([cleanPhone containsString:currentQuery]) {
                    matchedName = [NSString stringWithFormat:@"%@ %@", contact.familyName ?: @"", contact.givenName ?: @""];
                    matchedPhone = phoneNum;
                    *stop = YES;
                    break;
                }
            }
            if (matchedName) *stop = YES;
        }];

        dispatch_async(dispatch_get_main_queue(), ^{
            UILabel *nameLbl = [suggestionBox viewWithTag:778901];
            UILabel *phoneLbl = [suggestionBox viewWithTag:778902];

            if (matchedName) {
                nameLbl.text = matchedName;
                phoneLbl.text = matchedPhone;
                suggestionBox.alpha = 1.0;
            } else {
                nameLbl.text = [NSString stringWithFormat:@"Tìm kiếm số: %@", currentQuery];
                phoneLbl.text = @"Không có trong danh bạ (Bấm để thêm mới)";
                suggestionBox.alpha = 1.0;
            }
        });
    });
}

%end
