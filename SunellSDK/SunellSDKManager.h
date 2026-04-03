//
//  SunellSDKManager.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@class SunellDeviceModel;

@protocol SunellSDKManagerDelegate <NSObject>
@optional;
// 设备异常状态回掉
- (void)sunellSDKDeviceErrorStatus:(SunellDeviceModel*)deviceModel type:(int)type;
// 异常情况自动重练开启设备
- (void)sunellSDKStartAutoReconnect:(SunellDeviceModel*)deviceModel;
// 是否重连接成功
- (void)sunellSDKEndtAutoReconnect:(SunellDeviceModel *)deviceModel isSuccess:(BOOL)isSuccess;
// 报警消息
- (void)sunellSDKAlarmInfo:(SunellDeviceModel*)deviceModel alarmInfo:(NSString*)alarmInfo;
// 视频操作回掉
- (void)sunellSDKVideoOperation:(NSString*)deviceId channelId:(int)channelId eventId:(int)eventId msg:(NSString*)msg playModel:(int)playModel;

@end

@interface SunellSDKManager : NSObject
@property(nonatomic,weak)id<SunellSDKManagerDelegate>delegate;
+ (instancetype)shared;

/**
 * p2p登录设备结果result
 * result >= 1000 正常
 * result == -507,用户名错误
 * result == - 508,密码错误
 */
+ (void)connectDevByP2P:(NSString *)uuid port:(int)port user:(NSString *)user pwd:(NSString *)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock;

/**
 * iP登录设备
 *
 */
+ (void)connectDevByIP:(NSString*)ip port:(int)port user:(NSString*)user pwd:(NSString*)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock;
/**
 * 断开设备连接
 */
+ (void)disConnectDevByDeviceId:(NSString*)deviceId;
/**
 * 开始直播
 * 播放ID大于0表示成功
 */
+ (void)liveStartWithDevice:(NSString*)deviceId channelId:(int)channelId  streamType:(int)streamType isHwDec:(BOOL)isHwDec layer:(CAEAGLLayer*)caLayer resultBlock:(void(^)(int result))resultBlock;
/**
 * 结束直播
 */
+ (void)liveStopWithDevice:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;
/**
 * 设备通道上下线状态监听
 */
//+ (void)startDeviceChannelStatusMonitoring:(NSString*)deviceId;
//+ (void)stopDeviceChannelStatusMonitoring:(NSString*)deviceId;
/**
 * 设备报警状态监听
 */
//+ (void)startDeviceChannelAlarmMonitoring:(NSString*)deviceId;
//+ (void)stopDeviceChannelAlarmMonitoring:(NSString *)deviceId;
+ (void)closeGL;
@end

NS_ASSUME_NONNULL_END
