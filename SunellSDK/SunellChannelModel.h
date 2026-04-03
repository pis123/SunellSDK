//
//  SunellChannelModel.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SunellChannelModel : NSObject
@property(nonatomic,assign)int channelId;
@property(nonatomic,strong)NSString *deviceId;
@property(nonatomic,assign)int status;// 4098：在线；0:没有接入设备；其他值：离线
@property(nonatomic,strong)NSString *channleName;
@end

NS_ASSUME_NONNULL_END
