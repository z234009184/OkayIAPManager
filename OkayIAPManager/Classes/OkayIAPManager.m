//
//  OkayIAPManager.m
//  IAPurchDemo
//
//  Created by 张国梁 on 2018/7/10.
//  Copyright © 2018年 张国梁. All rights reserved.
//

#import "OkayIAPManager.h"

#import "UICKeyChainStore.h"


//NSString *const OKAY_PRODUCTID6 = @"6元产品";
//NSString *const OKAY_PRODUCTID30 = @"30元产品";
//NSString *const OKAY_PRODUCTID68 = @"68元产品";


/*****/
NSString *const OKAY_IAP_DATA = @"OKAY_IAP_DATA";
NSString *const OKAY_IAP_ORDERID = @"OKAY_IAP_ORDERID";


@interface OkayIAPManager ()<SKPaymentTransactionObserver,SKProductsRequestDelegate> {
    NSString *_productId; // 产品ID
    IAPCompletionHandle _handle; // 回调处理
    NSString *_orderId; // 订单ID
    NSData *_data; // 凭证
    void(^_checkCallBack)(NSString *orderId, NSData *data);
    SKPaymentTransaction *_transaction;
}

@property (nonatomic, strong) UIWindow *coverWindow;
@end

@implementation OkayIAPManager



- (UIWindow *)coverWindow {
    if (_coverWindow == nil) {
        _coverWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _coverWindow.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(_coverWindow.frame.size.width * 0.5, _coverWindow.frame.size.height * 0.5, 80, 80)];
        activityView.center = _coverWindow.center;
        activityView.layer.cornerRadius = 5;
        activityView.hidesWhenStopped = YES;
        activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [activityView startAnimating];
        activityView.backgroundColor = [UIColor blackColor];
        [_coverWindow addSubview:activityView];
    }
    return _coverWindow;
}

#pragma mark - life circle

//+ (void)load {
//    // 只要类一架载完成 就进行检测订单队列的状态
//    [[SKPaymentQueue defaultQueue] addTransactionObserver:[OkayIAPManager shareInstance]];
//}


static OkayIAPManager *_okayIAPManager = nil;

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _okayIAPManager = [[self alloc] init];
    });
    return _okayIAPManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _okayIAPManager = [super allocWithZone:zone];
    });
    return _okayIAPManager;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return _okayIAPManager;
}

- (instancetype)mutablecopyWithZone:(NSZone *)zone {
    return _okayIAPManager;
}


- (instancetype)init {
    if (self = [super init]) {
        // 购买监听写在程序入口,程序挂起时移除监听,这样如果有未完成的订单将会自动执行并回调 paymentQueue:updatedTransactions:方法
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}


#pragma mark - public method
- (void)startPurchWithProductId:(NSString *)ProductId orderId:(NSString *)orderId completeHandle:(IAPCompletionHandle)handle {
    if (ProductId) {
        if ([SKPaymentQueue canMakePayments]) {
            // 开始购买服务
            _productId = ProductId;
            _handle = handle;
            _orderId = orderId;
            
            NSSet *nsset = [NSSet setWithArray:@[ProductId]];
            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
            request.delegate = self;
            [request start];
            self.coverWindow.hidden = NO;
        } else {
            [self handleActionWithType:OkayIAPurchTypeNotAllow data:nil];
        }
    }
}


#pragma mark - SKProductsRequestDelegate
/// 拉去Apple服务器内购列表
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    self.coverWindow.hidden = YES;
    NSArray *product = response.products;
    if([product count] <= 0){
#if DEBUG
        NSLog(@"--------------没有商品------------------");
#endif
        
        return;
    }
    
    SKProduct *p = nil;
    // 找到ITC上面相应的产品ID
    for(SKProduct *pro in product){
        if([pro.productIdentifier isEqualToString:_productId]){
            p = pro;
            break;
        }
    }
    
#if DEBUG
    NSLog(@"productID:%@", response.invalidProductIdentifiers);
    NSLog(@"产品付费数量:%lu",(unsigned long)[product count]);
    NSLog(@"%@",[p description]);
    NSLog(@"%@",[p localizedTitle]);
    NSLog(@"%@",[p localizedDescription]);
    NSLog(@"%@",[p price]);
    NSLog(@"%@",[p productIdentifier]);
    NSLog(@"发送购买请求");
#endif
    
    
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:p];
    payment.applicationUsername = _orderId;
    [[SKPaymentQueue defaultQueue] addPayment:payment];
     self.coverWindow.hidden = NO;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
#if DEBUG
     self.coverWindow.hidden = YES;
    NSLog(@"------------------错误-----------------:%@", error);
#endif
}

- (void)requestDidFinish:(SKRequest *)request{
#if DEBUG
    NSLog(@"------------反馈信息结束-----------------");
#endif
}




#pragma mark - SKPaymentTransactionObserver

/**
 监听到交易发生变化

 @param queue 支付队列
 @param transactions 交易数据（有可能有多个交易而且未排序）
 */
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    
    for (SKPaymentTransaction *tran in transactions) {
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                self.coverWindow.hidden = YES;
                // 交易处于队列中，用户已被收费。客户应完成交易。
                [self completeTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchasing:
#if DEBUG
                NSLog(@"交易被添加到服务队列中");
#endif
                break;
            case SKPaymentTransactionStateRestored:
                self.coverWindow.hidden = YES;
#if DEBUG
                NSLog(@"交易已从用户的购买历史记录中恢复。客户应完成交易。");
#endif
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStateFailed:
                // 在添加到服务器队列之前，交易已取消或失败。
                [self failedTransaction:tran];
                break;
            default:
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    self.coverWindow.hidden = YES;
#if DEBUG
    NSLog(@"已经从支付队列中移除");
#endif
}



#pragma mark - private method

/**
 回调处理

 @param type 内购状态
 @param data 数据
 */
- (void)handleActionWithType:(OkayIAPurchType)type data:(NSData *)data{
#if DEBUG
    switch (type) {
        case OkayIAPurchTypeSuccess:
            NSLog(@"购买成功");
            break;
        case OkayIAPurchTypeFailed:
            NSLog(@"购买失败");
            break;
        case OkayIAPurchTypeCancel:
            NSLog(@"用户取消购买");
            break;
        case OkayIAPurchTypeVerFailed:
            NSLog(@"订单校验失败");
            break;
        case OkayIAPurchTypeVerSuccess:
            NSLog(@"订单校验成功");
            break;
        case OkayIAPurchTypeNotAllow:
            NSLog(@"不允许程序内付费");
            break;
        default:
            break;
    }
#endif
    if(_handle){
        _handle(type, _orderId, data, _transaction);
    }
}


#pragma mark - transactionStatus
/**
 交易完成

 @param transaction 交易信息
 */
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    // Your application should implement these two methods.
    NSString *productIdentifier = transaction.payment.productIdentifier;
    NSData *data = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
//    NSString *receipt = [data base64EncodedStringWithOptions:0];
    if ([productIdentifier length] > 0) {
        NSLog(@"%@", transaction.transactionIdentifier);
        if (data) {
            NSLog(@"%@", [data base64EncodedStringWithOptions:0]);
            // 将本次购买凭证存储到本地
            [self saveCurrentTransaction:data];
            _transaction = transaction;
            
            // 购买完成
            [self handleActionWithType:OkayIAPurchTypeSuccess data:data];
        } else {
            // 交易凭证为空验证失败
            [self handleActionWithType:OkayIAPurchTypeVerFailed data:nil];
        }


        
        // 将交易信息发送给苹果服务器进行校验（应该服务器验证）
//        [self verifyPurchaseWithPaymentTransaction:transaction isTestServer:YES];
    }
}


/**
 交易失败

 @param transaction 交易信息
 */
- (void)failedTransaction:(SKPaymentTransaction *)transaction{
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [self handleActionWithType:OkayIAPurchTypeFailed data:nil];
    }else{
        [self handleActionWithType:OkayIAPurchTypeCancel data:nil];
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}



/**
 存储本次交易凭证 (目前是只支持缓存一条交易凭证)

 @param data 交易凭证
 */
- (void)saveCurrentTransaction:(NSData *)data {
    [UICKeyChainStore setData:data forKey:OKAY_IAP_DATA];
    [UICKeyChainStore setString:_orderId forKey:OKAY_IAP_ORDERID];
}


/**
 移除本次交易凭证
 */
- (void)removeCurrentTransaction {
    [UICKeyChainStore removeItemForKey:OKAY_IAP_DATA];
    [UICKeyChainStore removeItemForKey:OKAY_IAP_ORDERID];
    if (_transaction) {
        [[SKPaymentQueue defaultQueue] finishTransaction:_transaction];
    }
}


- (void)checkLoseIAPOrderCallBack:(IAPCompletionHandle)handle {
    NSData *data = [UICKeyChainStore dataForKey:OKAY_IAP_DATA];
    NSString *orderId = [UICKeyChainStore stringForKey:OKAY_IAP_ORDERID];
    _data = data;
    _orderId = orderId;
    _handle = handle;

}



/**
 通过交易信息校验购买状态（应该服务端进行）

 @param transaction 交易信息
 @param flag 是否是测试
 */
- (void)verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)transaction isTestServer:(BOOL)flag{
    //交易验证
    /** 本地请求Apple服务器验证代码（应该让服务器请求）------------------start----------------  **/
    NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];
    
    NSLog(@"%@", [[NSString alloc] initWithData:receipt encoding:NSUTF8StringEncoding]);
    
    NSError *error;
    NSDictionary *requestContents = @{
                                      @"receipt-data": [receipt base64EncodedStringWithOptions:0]
                                      };
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                          options:0
                                                            error:&error];

    if (!requestData) { // 交易凭证为空验证失败
        [self handleActionWithType:OkayIAPurchTypeVerFailed data:nil];
        return;
    }

    //In the test environment, use https://sandbox.itunes.apple.com/verifyReceipt
    //In the real environment, use https://buy.itunes.apple.com/verifyReceipt

    NSString *serverString = @"https://buy.itunes.apple.com/verifyReceipt";
    if (flag) {
        serverString = @"https://sandbox.itunes.apple.com/verifyReceipt";
    }
    NSURL *storeURL = [NSURL URLWithString:serverString];
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];

//    NSOperationQueue *queue = [[NSOperationQueue alloc] init];


    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:storeRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            // 无法连接服务器,购买校验失败
            [self handleActionWithType:OkayIAPurchTypeVerFailed data:nil];
        } else {
            NSError *error;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!jsonResponse) {
                // 苹果服务器校验数据返回为空校验失败
                [self handleActionWithType:OkayIAPurchTypeVerFailed data:nil];
            }

            // 先验证正式服务器,如果正式服务器返回21007再去苹果测试服务器验证,沙盒测试环境苹果用的是测试服务器
            NSString *status = [NSString stringWithFormat:@"%@",jsonResponse[@"status"]];
            if (status && [status isEqualToString:@"21007"]) {
                [self verifyPurchaseWithPaymentTransaction:transaction isTestServer:YES];
            }else if(status && [status isEqualToString:@"0"]){
                [self handleActionWithType:OkayIAPurchTypeVerSuccess data:nil];
            }
#if DEBUG
            NSLog(@"%@",jsonResponse);
#endif
        }
    }];
    [task resume];
    /** 本地请求Apple服务器验证代码（应该让服务器请求）------------------end---------------- **/
    
    
    
}




@end
