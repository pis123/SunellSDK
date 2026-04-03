//
//  SunellSDKManager.m
//  SunellSDK
//
//  Created by Sunell on 2026/3/23.
//

#import "SunellSDKManager.h"
#import "P2PManager.h"
#import "Sunell.h"
#import <stdlib.h>
#import "SunellSafeUtil.h"
#import "SunellDeviceModel.h"
#import "SunellChannelModel.h"
#import "SunellInnerDeviceModel.h"
NS_ASSUME_NONNULL_BEGIN
@interface SunellSDKManager()
@property(nonatomic,strong)NSMutableDictionary *handleDict;
@end
@implementation SunellSDKManager

#define HandleMinValue 1000

+ (instancetype)shared{
    static SunellSDKManager *sdkmgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sdkmgr = [[SunellSDKManager alloc]init];
        sdkmgr.handleDict = [NSMutableDictionary dictionary];
    });
    sdks_dev_init(NULL);
    return sdkmgr;
}
+ (SunellInnerDeviceModel*)getInnerDeviceModelByDeviceId:(NSString*)deviceId{
    NSMutableDictionary *dict = [SunellSDKManager shared].handleDict;
    return dict[deviceId];
}

+ (int)getConnectHandleByDeviceId:(NSString*)deviceId{
    return [self getInnerDeviceModelByDeviceId:deviceId].connectHandle;
}
// 记录设备连接后的handle
+ (void)addHandle:(int)handel device:(SunellDeviceModel*)deviceModel{
    NSMutableDictionary *dict = [SunellSDKManager shared].handleDict;
    if (dict == nil) {
        dict = [NSMutableDictionary dictionary];
    }
    if ([self getConnectHandleByDeviceId:deviceModel.deviceId]) { // 之前连接过就覆盖
        SunellInnerDeviceModel *innerDeviceModle = [self getInnerDeviceModelByDeviceId:deviceModel.deviceId];
        innerDeviceModle.connectHandle = handel;
        innerDeviceModle.deviceModel = deviceModel;
        dict[deviceModel.deviceId] = innerDeviceModle;
    }else { // 之前没有连接过就新增
        SunellInnerDeviceModel *innerDeviceModle = [[SunellInnerDeviceModel alloc]init];
        innerDeviceModle.deviceModel = deviceModel;
        innerDeviceModle.connectHandle = handel;
        dict[deviceModel.deviceId] = innerDeviceModle;
    }
    
}
// 更新缓存的connectHandle
+ (void)updateHandel:(int)handle deviceId:(NSString*)deviceId{
    SunellInnerDeviceModel *innerDeviceModle = [self getInnerDeviceModelByDeviceId:deviceId];
    innerDeviceModle.connectHandle = handle;
    NSMutableDictionary *dict = [SunellSDKManager shared].handleDict;
    dict[deviceId] = innerDeviceModle;
}
// 移除handle
+ (void)removeHandleWithdeviceId:(NSString*)deviceId{
    SunellInnerDeviceModel *innerDeviceModle = [self getInnerDeviceModelByDeviceId:deviceId];
    NSMutableDictionary *dict = [SunellSDKManager shared].handleDict;
    [dict removeObjectForKey:deviceId];
    [SunellSDKManager shared].handleDict = dict;
}
// 记录播放的handle
+ (void)addPlayerHandle:(int)playHandle deviceId:(NSString*)deviceId channelId:(int)channelId{
    SunellInnerDeviceModel *innerDeviceModle = [self getInnerDeviceModelByDeviceId:deviceId];
    [innerDeviceModle savePlayeHandleByDeviceId:deviceId channelId:channelId playhandle:playHandle];
}

+ (int)getPlayeHandleByDeviceId:(NSString*)deviceId channelId:(int)channelId{
    SunellInnerDeviceModel *deviceModel = [self getInnerDeviceModelByDeviceId:deviceId];
    return [deviceModel getPlayHandleByDeviceId:deviceId channelId:channelId];
}
/**
 CONN_SOCK_NONE = 0,
 CONN_SOCK_CTRL,                    // 连接
 CONN_SOCK_LIVE,                    // 现场
 CONN_SOCK_PB,                      // 回放
 CONN_SOCK_ALARM,                   // 报警
 CONN_SOCK_PTZ,                     // 云台
 CONN_SOCK_FACE,                       //NVR人脸库
 CONN_SOCK_DETECT,                   //人脸
 CONN_SOCK_THE,                       //热成像
 CONN_SOCK_WIFI,                       //WIFI
 CONN_SOCK_MICROPHONE,               //麦克风（设备到SDK）
 CONN_SOCK_INTERPHONE,               //内置麦（SDK到设备）
 CONN_SOCK_UPDATE,                  //升级设备
 CONN_SOCK_CREAT_PASSWORD,
 CONN_SOCK_MULTI_OBJ,               //多目标图片下载
 CONN_SOCK_COMPARE,                   //NVR多目标对比
 CONN_SOCK_GRID,
 CONN_SOCT_THE_PIC,
 CONN_SOCK_CHN_STATUS,                //nvr 通道状态
 CONN_SOCK_MAX
 */
static void deviceDisconnectCallback(unsigned int handle, void *p_obj, int type) {
    NSString *deviceId = [NSString stringWithUTF8String:(char*)p_obj];
    if (deviceId == nil) {
        return;
    }
    __block int n_type = type;
    if (type == 0 || type == 19) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKDeviceErrorStatus:type:)] ) {
                SunellInnerDeviceModel *innelDeviceModel = [SunellSDKManager getInnerDeviceModelByDeviceId:deviceId];
                if (innelDeviceModel) {
                    innelDeviceModel.deviceModel.status = 0;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[SunellSDKManager shared].delegate sunellSDKDeviceErrorStatus:innelDeviceModel.deviceModel type:type];
                    });
                }
            }
        });
    }else {
       __block  SunellInnerDeviceModel *innelDeviceModel = [SunellSDKManager getInnerDeviceModelByDeviceId:deviceId];
        innelDeviceModel.connectHandle = 0;
        innelDeviceModel.deviceModel.status = 0;
        [SunellSDKManager updateHandel:0 deviceId:innelDeviceModel.deviceModel.deviceId];
        // 开始重连
        if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKStartAutoReconnect:)]) {
            if (innelDeviceModel) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    innelDeviceModel.deviceModel.status = false;
                    [[SunellSDKManager shared].delegate sunellSDKStartAutoReconnect:innelDeviceModel.deviceModel];
                });
            }
        }
        [SunellSDKManager reConnectWithDeviceModel:innelDeviceModel resultBlcok:^(BOOL ret) { // 重连成功，自动更新连接状态
            if (ret) {
                innelDeviceModel = [SunellSDKManager getInnerDeviceModelByDeviceId:deviceId];
            }
            // 重连结束了
            if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKEndtAutoReconnect:isSuccess:)]) {
                if (innelDeviceModel) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[SunellSDKManager shared].delegate sunellSDKEndtAutoReconnect:innelDeviceModel.deviceModel isSuccess:ret];
                    });
                }
            }
            int returnType = type;
            if (ret == false) { // 重练失败，
                innelDeviceModel.deviceModel.status = 0;
                returnType = 1;
            }
            if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKDeviceErrorStatus:type:)] && innelDeviceModel.deviceModel.deviceId != nil) {
                if (innelDeviceModel) {
                    dispatch_async(dispatch_get_main_queue(), ^{ // 通知代理设备断开链接
                        [[SunellSDKManager shared].delegate sunellSDKDeviceErrorStatus:innelDeviceModel.deviceModel type:returnType];
                    });
                }
            }
        }];
    }
    printf("SunellSDKManager deviceDisconnectCallback,handel:%d,p_obj:%s,type:%d",handle,deviceId,type);
}
+ (void)reConnectWithDeviceModel:(SunellInnerDeviceModel*)innelDeviceModel resultBlcok:(void(^)(BOOL ret))resultBlock{
    __block int handle = 0;
    __block SunellDeviceModel *deviceModel;
    dispatch_group_t group = dispatch_group_create();
    // 关闭之前的链接handle
    sdks_dev_conn_close(innelDeviceModel.connectHandle);
    if (innelDeviceModel.deviceModel.isP2PAdd) {
        dispatch_group_enter(group);
        [SunellSDKManager _connectDevByIp:innelDeviceModel.deviceModel.deviceUUID connectCount:3 isP2P:YES port:innelDeviceModel.deviceModel.port user:innelDeviceModel.deviceModel.userName pwd:innelDeviceModel.deviceModel.pwd reulstBlock:^(int result, SunellDeviceModel * _Nonnull device) {
            handle = result;
            deviceModel = device;
            dispatch_group_leave(group);
        }];
        
    }else {
        dispatch_group_enter(group);
        [SunellSDKManager _connectDevByIp:innelDeviceModel.deviceModel.deviceId connectCount:3 isP2P:false port:innelDeviceModel.deviceModel.port user:innelDeviceModel.deviceModel.userName pwd:innelDeviceModel.deviceModel.pwd reulstBlock:^(int result, SunellDeviceModel * _Nonnull device) {
            handle = result;
            deviceModel = device;
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (resultBlock) {
            if (handle < HandleMinValue) {
                resultBlock(false);
            }else {
                resultBlock(true);
            }
        }
    });
}

// p2p添加设备
+ (void)connectDevByP2P:(NSString *)uuid port:(int)port user:(NSString *)user pwd:(NSString *)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock{
    __weak typeof(self)weakSelf = self;
    [P2PManager getMapAddr:uuid port:port isUpgradeP2P:NO resultBlock:^(int mapResult, P2PMapAddrInfoModel *model) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf _connectDevByIp:model.ip connectCount:5 isP2P:true port:model.relay_port user:user pwd:pwd reulstBlock:resultBlock];
    }];
}
// ip添加设备
+ (void)connectDevByIP:(NSString*)ip port:(int)port user:(NSString*)user pwd:(NSString*)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock{
    [self _connectDevByIp:ip connectCount:5 isP2P:false port:port user:user pwd:pwd reulstBlock:resultBlock];
}
// 调用sdks_dev_conn，然后获取设备信息
+ (void)_connectDevByIp:(NSString*)ip connectCount:(int)connectCount isP2P:(bool)isP2P port:(int)port user:(NSString*)user pwd:(NSString*)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock{

    __block SunellDeviceModel *deviceModel;
    __weak typeof(self) weakSelf = self;
    void (^notify)(int) = ^(int code) {
       __strong typeof(weakSelf) strongSelf = weakSelf;
       if (!strongSelf || !resultBlock) return;
       if (deviceModel) {
           deviceModel.isP2PAdd = isP2P;
           deviceModel.userName = user;
           deviceModel.pwd = pwd;
           if ([deviceModel.channels isKindOfClass:[NSArray class]]) {
               for (id obj in deviceModel.channels) {
                   if ([obj isKindOfClass:[SunellChannelModel class]]) {
                       ((SunellChannelModel *)obj).deviceId = deviceModel.deviceId;
                   }
               }
           }
       }
        
        if (code >= HandleMinValue && deviceModel) {
           [strongSelf addHandle:code device:deviceModel];
        }

       dispatch_async(dispatch_get_main_queue(), ^{
           resultBlock(code, deviceModel);
       });
   };
    if (ip.length  <= 0 || port <= 0 || user.length  <= 0 || pwd.length <= 0) {
        notify(0);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
            const char *ipC = ip.UTF8String;
            const char *userC = user.length > 0 ? user.UTF8String : "";
            const char *pwdC = pwd.length > 0 ? pwd.UTF8String : "";
        
            int handle = sdks_dev_conn(ipC, port, userC, pwdC, deviceDisconnectCallback, (char*)ip.UTF8String);
            int connCount = connectCount;
            int total = connCount;
            while (total-- > 0 && handle < HandleMinValue && handle != -507 && handle != -508) {
                printf("SunellSDKManager 尝试第:%d次连接,handle:%d",connCount - total,handle);
                handle = sdks_dev_conn(ipC, port, userC, pwdC, deviceDisconnectCallback, (char*)ip.UTF8String);
                sleep(5);
            }
        
           NSLog(@"SunellSDKManager handle:%d，devID:%@,dict:%@", handle,ip,[SunellSDKManager shared].handleDict);
            if (handle >= HandleMinValue) {
              
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;

                [strongSelf getDeviceInfoByHandel:handle localId:ip reulstBlock:^(SunellDeviceModel *device) {
                    device.deviceId = isP2P ? device.deviceUUID : device.deviceIp;
                    deviceModel = device;
                    deviceModel.status = device.status;
                    NSLog(@"SunellSDKManager handle:%d，devID:%@,dict:%@", handle,device.deviceId,[SunellSDKManager shared].handleDict);
//                    if (ctx) free(ctx);

                    notify(device ? handle : 0);
                }];
            } else {
//                if (ctx) free(ctx);
                notify(handle);
            }
        });
}

#pragma mark - 断开设备连接
+ (void)disConnectDevByDeviceId:(NSString*)deviceId{
    int handle = [SunellSDKManager getConnectHandleByDeviceId:deviceId];
    sdks_dev_conn_close(handle);
    [self removeHandleWithdeviceId:deviceId];
}
#pragma mark - 通过handle来获取设备信息
+ (void)getDeviceInfoByHandel:(int)handle localId:(NSString*)devID reulstBlock:(void (^)(SunellDeviceModel *device))resultBlock{
    SunellDeviceModel *deviceModel = nil;
    if (handle >= HandleMinValue) {
        // 获取设备信息
        dev_general_info_t info = dev_general_info_t{0};
        int nRet = sdks_dev_get_general_info(handle, &info);
        if (nRet == 0){
            // 获取设备信息成功
            deviceModel = [[SunellDeviceModel alloc]init];
            deviceModel.deviceId = devID;
            deviceModel.status = 1;
            deviceModel.deviceUUID = [SunellSafeUtil safeStringFromCString:info.dev_id];
            deviceModel.deviceName = [SunellSafeUtil safeStringFromCString:info.dev_name];
            deviceModel.deviceStyle = [SunellSafeUtil safeStringFromCString:info.dev_style];
            deviceModel.deviceIp = [SunellSafeUtil safeStringFromCString:info.dev_ip];
            deviceModel.deviceMac = [SunellSafeUtil safeStringFromCString:info.dev_mac];
            deviceModel.productModel = [SunellSafeUtil safeStringFromCString:info.prod_model];
            deviceModel.deviceSN = [SunellSafeUtil safeStringFromCString:info.dev_sn];
            deviceModel.swInfo =  [SunellSafeUtil safeStringFromCString:info.sw_info];
            deviceModel.hwInfo =  [SunellSafeUtil safeStringFromCString:info.hw_info];
            deviceModel.devType =  info.dev_type;
            deviceModel.port = info.dev_port;
            if (deviceModel.devType == 14 || deviceModel.devType == 17) {
                NSMutableArray *chnels = [NSMutableArray array];
                for (int i = 0; i < 2; i++) {
                    SunellChannelModel *chnModel = [[SunellChannelModel alloc]init];
                    chnModel.channelId = i + 1;
                    chnModel.status = 1;
                    [chnels addObject:chnModel];
                }
                deviceModel.channels = chnels;
                deviceModel.chnNum = 2;
            }else if (deviceModel.devType == 5 || deviceModel.devType == 2 || deviceModel.devType == 10){
                char *szList = NULL;
                int ret = sdks_dev_get_chn_info(handle, &szList);
                if (ret == 0 && szList != NULL) {
                    NSString *chnsInfo = [NSString stringWithUTF8String:szList];
                    NSError *error;
                    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:[chnsInfo dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
                    if (data && data[@"data"]) {
                        NSArray *dictArray = data[@"data"];
                        NSMutableArray *channels = [NSMutableArray array];
                        for (NSDictionary *dictChannel in dictArray) {
                            SunellChannelModel *channelModel = [[SunellChannelModel alloc]init];
                            channelModel.channelId = [dictChannel[@"chn"] intValue];
                            channelModel.deviceId = deviceModel.deviceId;
                            channelModel.status = [dictChannel[@"status"] intValue];
                            channelModel.channleName = dictChannel[@"name"];
                            [channels addObject:channelModel];
                        }
                        deviceModel.channels = channels;
                        deviceModel.chnNum = (int)channels.count;
                    }else {
                        // 解析szList失败
                        deviceModel = nil;
                    }
                }else {
                    // 接口sdks_dev_get_chn_info失败
                    deviceModel = nil;
                }
            }
        }else {
            // 接口sdks_dev_get_general_info失败
            deviceModel = nil;
        }
    }
    if (resultBlock) {
        resultBlock(deviceModel);
    }
}

void startVideoResultCb(unsigned int handle, int stream_id, void* p_obj, const char* p_time){
    char * p_objChar = (char *)p_obj;
    NSString *p_timeStr = [NSString stringWithUTF8String:(char *)p_time];
    NSString *deviceId = [NSString stringWithUTF8String:p_objChar];
    NSLog(@"SunellSDKManager startVideoResultCb:handle:%d ,streamId:%d,deviceId:%@,p_timeStr:%@",handle,stream_id,deviceId,p_timeStr);
}
#pragma mark - 开始直播
+ (void)liveStartWithDevice:(NSString*)deviceId channelId:(int)channelId  streamType:(int)streamType isHwDec:(BOOL)isHwDec layer:(CAEAGLLayer*)caLayer resultBlock:(nonnull void (^)(int))resultBlock{
    __block int nRet = -1;
    void (^start)(void) = ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        void *pWnd = (__bridge void *)(caLayer);
         nRet = sdks_md_live_start(handle, channelId, streamType, pWnd, isHwDec, startVideoResultCb, (char *)deviceId.UTF8String);
        NSLog(@"SunellSDKManager liveStartWithDevice handle:%d,nRet:%d，chanelId:%d,devID:%@,dict:%@", handle,nRet,channelId,deviceId,[SunellSDKManager shared].handleDict);
        if (nRet >= 0) { // nRet为打开的视频流id，需要记录，作为操作视频的参数传入
            // 表示sdks_md_live_start调用成功
            [self addPlayerHandle:nRet deviceId:deviceId channelId:channelId];
//            [self addPlayerHandle:nRet deviceId:deviceId];
        }
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(nRet);
            });
            
        }
        
    };
    if ([NSThread isMainThread]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            start();
        });
    } else {
        dispatch_sync(dispatch_get_global_queue(0, 0), start);
    }
   
}

#pragma mark - 结束直播
+ (void)liveStopWithDevice:(NSString*)deviceId channelId:(int)channelId resultBlock:(nonnull void (^)(int))resultBlock{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        int playerHandle = [self getPlayeHandleByDeviceId:deviceId channelId:channelId];
        int nRet = sdks_md_live_stop(handle, playerHandle);
        NSLog(@"SunellSDKManager liveStopWithDevice handle:%d,nRet:%d,playHandle:%d,channelId:%d，deviceId:%@,dict:%@", handle,nRet,playerHandle,channelId,deviceId,[SunellSDKManager shared].handleDict);
        if (resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(nRet);
            });
            
        }
    });
   
//    return nRet;
}



void deviceChannelStateCallBack(unsigned int handle, void **p_data, void *p_obj){
    char *m_data = (char *)*p_data;
    NSString *data = [NSString stringWithUTF8String:(char *)*p_data];
    NSString *obj = [NSString stringWithUTF8String:(char *)p_obj];
    printf("SunellSDKManager deviceChannelStateCallBack:handle:%d,m_data:%s,obj:%s",handle,data,obj);
}

/**
 * 设备上下线状态监听
 */
+ (void)startDeviceChannelStatusMonitoring:(NSString*)deviceId{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue) {
         sdks_dev_start_chn_status(handle, deviceChannelStateCallBack, (char *)deviceId.UTF8String);
        }
    });
}
/**
 * 移除设备上下线监听
 */
+ (void)stopDeviceChannelStatusMonitoring:(NSString*)deviceId{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue) {
            sdks_dev_stop_chn_status(handle);
        }
    });
}

void alarmCallBack(unsigned int handle, void** p_data, void* p_obj)
{
    char *m_data = (char *)*p_data;
    NSString *data = [NSString stringWithUTF8String:(char *)*p_data];
    NSString *obj = [NSString stringWithUTF8String:(char *)p_obj];
    printf("SunellSDKManager alarmCallBack:handle:%d,m_data:%s",handle,m_data);
//    if ([[SunellSDKManager shared].delegate respondsToSelector:@selector(sunellSDKAlarmInfo:alarmInfo:)]) {
//
//    }
}
/**
 * 设备报警状态监听
 */
+ (void)startDeviceChannelAlarmMonitoring:(NSString*)deviceId{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue) {
            sdks_dev_start_alarm(handle, (SDK_ALARM_CB)alarmCallBack, NULL);
        }
    });
}
/**
 * 关闭报警接受
 */
+ (void)stopDeviceChannelAlarmMonitoring:(NSString *)deviceId{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int handle = [self getConnectHandleByDeviceId:deviceId];
        if (handle >= HandleMinValue) {
            sdks_dev_stop_alarm(handle);
        }
    });
}
/**
 * 关闭所有的视频
 */
+ (void)closeGL{
    NSDictionary *dict = [SunellSDKManager shared].handleDict;
    NSArray *allValues = dict.allValues;
    NSMutableSet *seenInners = [NSMutableSet set];
    for (SunellInnerDeviceModel *model in allValues) {
        if (!model || [seenInners containsObject:model]) { continue; }
        [seenInners addObject:model];
        int connecthandle = model.connectHandle;
        NSArray *allPlayerHandles = model.playerHandleDictionary.allValues;
        for ( NSNumber *playHandleNumber in allPlayerHandles) {
            int playHandle = [playHandleNumber intValue];
            if (playHandle >= 0 && connecthandle >= HandleMinValue) {
                sdks_md_glconsumer_stop(connecthandle, playHandle);
            }
        }
    }

}

@end

NS_ASSUME_NONNULL_END
