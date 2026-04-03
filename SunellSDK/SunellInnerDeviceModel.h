//
//  SunellInnerDeviceModel.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/26.
//

#import <SunellSDK/SunellSDK.h>

NS_ASSUME_NONNULL_BEGIN
/**
 * SDK内部处理一些逻辑的辅助类，不对外暴露，
 */
@class SunellDeviceModel;
@interface SunellInnerDeviceModel : NSObject
@property(nonatomic,assign)int connectHandle;
@property(nonatomic,strong)NSMutableDictionary *playerHandleDictionary;
@property(nonatomic,strong)SunellDeviceModel *deviceModel;
- (void)savePlayeHandleByDeviceId:(NSString*)deviceId channelId:(int)channelId playhandle:(int)playHandle;
- (int)getPlayHandleByDeviceId:(NSString*)deviceId channelId:(int)channelId;
@end

NS_ASSUME_NONNULL_END
