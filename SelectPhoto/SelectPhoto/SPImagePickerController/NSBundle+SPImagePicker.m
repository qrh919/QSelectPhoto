//
//  NSBundle+TZImagePicker.m
//  TZImagePickerController
//
//  Created by 谭真 on 16/08/18.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "NSBundle+SPImagePicker.h"
#import "SPImagePickerController.h"

@implementation NSBundle (SPImagePicker)

+ (NSBundle *)sp_imagePickerBundle {
    NSBundle *bundle = [NSBundle bundleForClass:[SPImagePickerController class]];
    NSURL *url = [bundle URLForResource:@"SPImagePickerController" withExtension:@"bundle"];
    bundle = [NSBundle bundleWithURL:url];
    return bundle;
}

+ (NSString *)sp_localizedStringForKey:(NSString *)key {
    return [self sp_localizedStringForKey:key value:@""];
}

+ (NSString *)sp_localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSBundle *bundle = [SPImagePickerConfig sharedInstance].languageBundle;
    NSString *value1 = [bundle localizedStringForKey:key value:value table:nil];
    return value1;
}

@end
