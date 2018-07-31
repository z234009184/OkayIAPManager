//
//  OkayIAPManager.h
//  IAPurchDemo
//
//  Created by 张国梁 on 2018/7/10.
//  Copyright © 2018年 张国梁. All rights reserved.
//

/**
 本组建为IAP内购组件，内部封装从客户端到Apple服务器之间的内购流程，与业务相关的验证流程通过Block回调给外界与业务解耦。
 漏单处理方案:
    可以在业务各处添加检测是否有漏单方法,如 程序启动完成/进入产品付费页面/进入个人中心页面 等等
    当和本地服务器处理完订单业务后 务必清除本地缓存凭证
 
 注意事项：
 1.沙盒环境测试appStore内购流程的时候，请使用没越狱的设备。
 2.请务必使用真机来测试，一切以真机为准。
 3.项目的Bundle identifier需要与您申请AppID时填写的bundleID一致，不然会无法请求到商品信息。
 4.如果是你自己的设备上已经绑定了自己的AppleID账号请先注销掉,否则你哭爹喊娘都不知道是怎么回事。
 5.订单校验 苹果审核app时，仍然在沙盒环境下测试，所以需要先进行正式环境验证，如果发现是沙盒环境则转到沙盒验证。
    识别沙盒环境订单方法：
    1.根据字段 environment = sandbox。
    2.根据验证接口返回的状态码,如果status=21007，则表示当前为沙盒环境。
 */


#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef enum : NSUInteger {
    OkayIAPurchTypeSuccess = 0,   // 购买成功
    OkayIAPurchTypeFailed = 1,    // 购买失败
    OkayIAPurchTypeCancel = 2,    // 取消购买
    OkayIAPurchTypeVerFailed = 3, // 订单校验失败 (服务端验证的话用不到)
    OkayIAPurchTypeVerSuccess = 4,// 订单校验成功 (服务端验证的话用不到)
    OkayIAPurchTypeNotAllow = 5,  // 不允许内购
} OkayIAPurchType;


typedef void(^IAPCompletionHandle)(OkayIAPurchType type, NSString *order, NSData *data, SKPaymentTransaction *transaction);

/**
   App内购管理者
 */
@interface OkayIAPManager : NSObject

+ (instancetype)shareInstance;

/**
 开始内购

 @param ProductId 内购产品ID (需要从ITC网站构建)
 @param orderId 订单号 
 @param handle 回调Block
 */
- (void)startPurchWithProductId:(NSString *)ProductId orderId:(NSString *)orderId completeHandle:(IAPCompletionHandle)handle;


/**
 检查本地是否有丢失的订单（未校验服务器的）

 @param callBack 未校验订单的凭证数据
 */
- (void)checkLoseIAPOrderCallBack:(IAPCompletionHandle)callBack;


/**
 移除完成的交易（清除本地缓存凭证）
 */
- (void)removeCurrentTransaction;
@end
