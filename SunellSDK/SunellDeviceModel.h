//
//  SunellDeviceModel.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SunellChannelModel;
@interface SunellDeviceModel : NSObject
@property(nonatomic,strong)NSString *deviceUUID; // 设备Id
@property(nonatomic,strong)NSString *deviceName; // 设备名称
@property(nonatomic,strong)NSString *userName; // 登录名称
@property(nonatomic,strong)NSString *pwd; // 登录账号
@property(nonatomic,strong)NSString *deviceStyle; // 设备类型
@property(nonatomic,strong)NSString *deviceIp; // 设备ip
@property(nonatomic,strong)NSString *deviceMac; // mac地址
@property(nonatomic,strong)NSString *productModel; // 产品模组
@property(nonatomic,strong)NSString *deviceSN; // SN
@property(nonatomic,strong)NSString *swInfo; // 软件包信息
@property(nonatomic,strong)NSString *hwInfo; // 硬件信息
@property(nonatomic,strong)NSString *deviceId;
@property(nonatomic,assign)int devType; // 设备类型号
@property(nonatomic,assign)int port; // 端口号
@property(nonatomic,assign)int chnNum; // 通道数量
@property(nonatomic,strong)NSArray<SunellChannelModel*> *channels;// 通道信息
@property(nonatomic,assign)NSInteger status; // 在线状态 1:在线，0:离线
@property(nonatomic,assign)BOOL isP2PAdd;// 通过P2P添加的设备
@end

NS_ASSUME_NONNULL_END
