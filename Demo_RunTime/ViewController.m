//
//  ViewController.m
//  Demo_RunTime
//
//  Created by RICH on 2018/3/2.
//  Copyright © 2018年 RICH. All rights reserved.
//

#import "ViewController.h"
#import "CustomObject.h"
#import <objc/runtime.h>
#import "UIView+RICHExtension.h"

@interface ViewController ()
@property (strong,nonatomic)CustomObject * myObj;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self test_NSObjectMetaClass];
//
//    [self test_superClass];
//
//    [self test_alloc_init];
//
    [self test_resoveInstanceMethod];
    
    [self test_forwardingTargetForSelector];
    
    [self test_CategoryDynamicAddProperty];
    
    NSArray * array = @[@{@"key":@{@"1":@"2"},@"key2":@"value2"},
                        @{@"key":@{@"1":@"3"},@"key2":@"value2"},
                        @{@"key":@{@"1":@"4"},@"key2":@"value2"}
                        ];
    NSLog(@"%@",[array valueForKeyPath:@"key.1"]);
}

#pragma mark - TestMethod
// instance object (isa)-> class object (isa)-> meta class object -> NSOjbect meta class
- (void)test_NSObjectMetaClass {
    
    Class class = [CustomObject class];
    
    Class metaClass         = object_getClass(class);
    Class metaOfMetaClass   = object_getClass(metaClass);
    Class rootMetaClass     = object_getClass(metaOfMetaClass);
    
    NSLog(@"CustomOvject类对象是:%p", class);
    NSLog(@"CustomOvject类元对象是:%p", metaClass);
    NSLog(@"metaClass类元对象:%p", metaOfMetaClass);
    NSLog(@"metaOfMetaClass的类元对象的是:%p", rootMetaClass);
    NSLog(@"NSObject类元对象:%p", object_getClass([NSObject class]));
}

- (void)test_superClass {
    
    Class class           = [CustomObject class];
    Class superClass      = class_getSuperclass(class);
    Class superOfNSObject = class_getSuperclass(superClass);
    
    NSLog(@"CustomObject类对象是:%p",class);
    NSLog(@"CustomObject类superClass是:%p",superClass);
    NSLog(@"NSObject的superClass是:%p",superOfNSObject);
}

// alloc init 要放一起写  因为alloc和init有可能返回不同的对象
- (void)test_alloc_init {
    
    id a = [NSMutableArray alloc];
    id b = [a init];
    NSLog(@"a:%p", a);
    NSLog(@"b:%p", b);
}

- (void)test_resoveInstanceMethod {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
//    [self performSelector:@selector(dynamicSelector) withObject:nil];
    if([self respondsToSelector:@selector(dynamicSelector)]) {
        NSLog(@"immplement");
    }else {
        NSLog(@"no immplement");
    }
#pragma clang diagnostic pop
}

- (void)test_forwardingTargetForSelector {
    
    self.myObj = [[CustomObject alloc]init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [self performSelector:@selector(dynamicSelector) withObject:nil];
#pragma clang diagnostic pop
}

- (void)test_CategoryDynamicAddProperty {
    
    UIButton *testButton = [[UIButton alloc]init];
    testButton.frame = CGRectMake(0, 0, 200, 100);
    testButton.center = self.view.center;
    testButton.backgroundColor = [UIColor redColor];
    testButton.rich_anaylizeTitle = @"testTitle";
    [testButton setTitle:testButton.rich_anaylizeTitle forState:UIControlStateNormal];
    [self.view addSubview:testButton];
}

- (void)test_nameWithInstance {
    
}

// 根据实例对象查找类型  也就是“反射"
- (NSString *)nameWithInstance:(id)instance {
    unsigned int numIvars = 0;
    NSString *key = nil;
    Ivar *ivars = class_copyIvarList([self class], &numIvars);
    for (int i = 0; i < numIvars; i++) {
        Ivar thisIvar = ivars[i];
        const char *type = ivar_getTypeEncoding(thisIvar);
        NSString *stringType = [NSString stringWithCString:type encoding:NSUTF8StringEncoding];
        if (![stringType hasPrefix:@"@"]) {
            continue;
        }
        if ((object_getIvar(self, thisIvar) == instance)) {
            key = [NSString stringWithUTF8String:ivar_getName(thisIvar)];
            break;
        }
    }
    free(ivars);
    return key;
}

#pragma mark - 动态转发机制方法实现
/*
 在Objective中，对一个对象发送一个它没有实现的Selector是完全合法的，这样做可以隐藏某一个消息背后实现，也可以模拟多继承（OC不支持多继承）。这个机制就是动态转发机制。
 
 ＋resolveInstanceMethod:
 - forwardingTargetForSelector:
 - forwardInvocation:
 */

/*
 动态为实例方法提供一个实现
 这个方法在Objective C消息转发机制之前被调用
 */
void myMethod(id self, SEL _cmd) {
    
    NSLog(@"This is added dynamic method");
}

// 动态方法的机制第一步，类自己处理
+ (BOOL)resolveInstanceMethod:(SEL)sel {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (sel == @selector(dynamicSelector)) {
#pragma clang diagnostic pop
//        class_addMethod(<#Class  _Nullable __unsafe_unretained cls#>, <#SEL  _Nonnull name#>, <#IMP  _Nonnull imp#>, <#const char * _Nullable types#>)
        class_addMethod([self class], sel, (IMP)myMethod, "v@:");
        return YES;
    }else {
        return [super resolveInstanceMethod:sel];
    }
}

+ (BOOL)resolveClassMethod:(SEL)sel {
    
    if (sel == @selector(dynamicSelector)) {
        class_addMethod(object_getClass(self), sel, (IMP)myMethod, "v@:");
        return YES;
    }else {
        return [class_getSuperclass(self) resolveClassMethod:sel];
    }
}

// 第二步（第一步不能处理的情况下），调用forwardingTargetForSelector来简单的把执行任务转发给另一个对象，到这里，还是廉价调用
- (id)forwardingTargetForSelector:(SEL)aSelector {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (aSelector == @selector(dynamicSelector) && [self.myObj respondsToSelector:@selector(dynamicSelector)]) {
        return self.myObj;
    }else {
        return [super forwardingTargetForSelector:aSelector];
    }
#pragma clang diagnostic pop
}



// 第三步，当前两步都不能处理的时候，调用forwardInvocation转发给别人，返回值仍然返回给最初的Selector
- (void)forwardInvocation:(NSInvocation *)anInvocation {
//    [anInvocation selector];
    if ([self.myObj respondsToSelector:@selector(dynamicSelector)]) {
        [anInvocation invokeWithTarget:self.myObj];
    }else {
        [super forwardInvocation:anInvocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [CustomObject instanceMethodSignatureForSelector:aSelector];
}

//总结: 消息转发机制使得OC可以进行”多继承”,比如有一个消息中心负责处理消息，这个消息中心很多个类都要用，继承或者聚合都不是很好的解决方案，使用单例看似可以，但单例的缺点也是很明显的。这时候，把消息转发给消息中心，无疑是一个较好的解决方案。

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
