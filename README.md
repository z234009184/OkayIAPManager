# OkayIAPManager

[![CI Status](https://img.shields.io/travis/zhangguoliang/OkayIAPManager.svg?style=flat)](https://travis-ci.org/zhangguoliang/OkayIAPManager)
[![Version](https://img.shields.io/cocoapods/v/OkayIAPManager.svg?style=flat)](https://cocoapods.org/pods/OkayIAPManager)
[![License](https://img.shields.io/cocoapods/l/OkayIAPManager.svg?style=flat)](https://cocoapods.org/pods/OkayIAPManager)
[![Platform](https://img.shields.io/cocoapods/p/OkayIAPManager.svg?style=flat)](https://cocoapods.org/pods/OkayIAPManager)

## Introduce

It's a easy In-App Purchase Lib.
To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 8.0 or later.

## Installation

OkayIAPManager is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'OkayIAPManager'
```

## Usage

```
/// start purchase
- (IBAction)action:(id)sender {
    
    [[OkayIAPManager shareInstance] startPurchWithProductId:@"cn.okay.IAPurch_1" orderId:@"xxx" completeHandle:^(OkayIAPurchType type, NSString *orderId, NSData *data, SKPaymentTransaction *transaction) {
        
    }];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    /// check drop order
    [[OkayIAPManager shareInstance] checkLoseIAPOrderCallBack:^(OkayIAPurchType type, NSString *order, NSData *data) {
        if (type == OkayIAPurchTypeSuccess) {
            /// simulate verify purchase result at your servers.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                /// must be removeCurrentTransaction in the end.
                [[OkayIAPManager shareInstance] removeCurrentTransaction];
            });
        }
    }];
    
    return YES;
}
```


## Author

zhangguoliang, zhangguoliang@okay.cn

## License

OkayIAPManager is available under the MIT license. See the LICENSE file for more info.
