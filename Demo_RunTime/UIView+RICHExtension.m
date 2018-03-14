//
//  UIView+RICHExtension.m
//  Demo_RunTime
//
//  Created by RICH on 2018/3/2.
//  Copyright © 2018年 RICH. All rights reserved.
//

#import "UIView+RICHExtension.h"
#import <objc/runtime.h>

static const char kAnaylizeTitle;

@implementation UIView (RICHExtension)
// 想添加属性，但是又不想继承的场景。大部分是为了扩展iOS SDK中的类，比如UIView，UIViewController。

- (NSString *)rich_anaylizeTitle {
    
    return objc_getAssociatedObject(self, &kAnaylizeTitle);
}

- (void)setRich_anaylizeTitle:(NSString *)rich_anaylizeTitle {
    
    objc_setAssociatedObject(self, &kAnaylizeTitle, rich_anaylizeTitle, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
