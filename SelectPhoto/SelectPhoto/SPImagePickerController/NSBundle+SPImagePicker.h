//
//  NSBundle+TZImagePicker.h
//  TZImagePickerController
//
//  Created by 谭真 on 16/08/18.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSBundle (SPImagePicker)

+ (NSBundle *)sp_imagePickerBundle;

+ (NSString *)sp_localizedStringForKey:(NSString *)key value:(NSString *)value;
+ (NSString *)sp_localizedStringForKey:(NSString *)key;

@end

