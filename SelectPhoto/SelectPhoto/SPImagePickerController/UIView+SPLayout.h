//
//  UIView+Layout.h
//
//  Created by 谭真 on 15/2/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    SPOscillatoryAnimationToBigger,
    SPOscillatoryAnimationToSmaller,
} SPOscillatoryAnimationType;

@interface UIView (SPLayout)

@property (nonatomic) CGFloat sp_left;        ///< Shortcut for frame.origin.x.
@property (nonatomic) CGFloat sp_top;         ///< Shortcut for frame.origin.y
@property (nonatomic) CGFloat sp_right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic) CGFloat sp_bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic) CGFloat sp_width;       ///< Shortcut for frame.size.width.
@property (nonatomic) CGFloat sp_height;      ///< Shortcut for frame.size.height.
@property (nonatomic) CGFloat sp_centerX;     ///< Shortcut for center.x
@property (nonatomic) CGFloat sp_centerY;     ///< Shortcut for center.y
@property (nonatomic) CGPoint sp_origin;      ///< Shortcut for frame.origin.
@property (nonatomic) CGSize  sp_size;        ///< Shortcut for frame.size.

+ (void)showOscillatoryAnimationWithLayer:(CALayer *)layer type:(SPOscillatoryAnimationType)type;

@end
