//
//  SunellSDKManager.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    SunellSpeed_1,    // 1x
    SunellSpeed_2,    // 2x
}SunellSpeedType;

@class SunellDeviceModel,SunellChannelModel;

@protocol SunellSDKManagerDelegate <NSObject>
@optional;
// Device error / offline callback.
- (void)sunellSDKDeviceErrorStatus:(SunellDeviceModel*)deviceModel type:(int)type;
// Auto reconnect started after abnormal disconnect.
- (void)sunellSDKStartAutoReconnect:(SunellDeviceModel*)deviceModel;
// Auto reconnect finished.
- (void)sunellSDKEndtAutoReconnect:(SunellDeviceModel *)deviceModel isSuccess:(BOOL)isSuccess;
// Alarm payload.
- (void)sunellSDKAlarmInfo:(SunellDeviceModel*)deviceModel alarmInfo:(NSString*)alarmInfo;
// Video operation callback.
- (void)sunellSDKVideoOperation:(NSString*)deviceId channelId:(int)channelId eventId:(int)eventId msg:(NSString*)msg playModel:(int)playModel;
// device channel online /offline
- (void)sunellSDKChannelStatusChangeNotiWithChannelModel:(SunellChannelModel*)channelModel;
@end

@interface SunellSDKManager : NSObject
@property(nonatomic,weak)id<SunellSDKManagerDelegate>delegate;
+ (instancetype)shared;

/**
 * P2P connect result code.
 * result >= 1000: success.
 * result == -507: wrong username.
 * result == -508: wrong password.
 */
+ (void)connectDevByP2P:(NSString *)uuid port:(int)port user:(NSString *)user pwd:(NSString *)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock;

/**
 * Connect by IP / host.
 */
+ (void)connectDevByIP:(NSString*)ip port:(int)port user:(NSString*)user pwd:(NSString*)pwd reulstBlock:(void (^)(int result,SunellDeviceModel *device))resultBlock;
/**
 * Disconnect device.
 */
+ (void)disConnectDevByDeviceId:(NSString*)deviceId;
/**
 * Start live preview.
 * Return value > 0 usually means success (stream id per native SDK).
 */
+ (void)liveStartWithDevice:(NSString*)deviceId channelId:(int)channelId  streamType:(int)streamType isHwDec:(BOOL)isHwDec layer:(CAEAGLLayer*)caLayer resultBlock:(void(^)(int result))resultBlock;
/**
 * Stop live preview.
 */
+ (void)liveStopWithDevice:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;
/**
 * Channel online/offline monitoring (optional).
 */
+ (void)startDeviceChannelStatusMonitoring:(NSString*)deviceId;
+ (void)stopDeviceChannelStatusMonitoring:(NSString*)deviceId;
/**
 * Alarm monitoring (optional).
 */
//+ (void)startDeviceChannelAlarmMonitoring:(NSString*)deviceId;
//+ (void)stopDeviceChannelAlarmMonitoring:(NSString *)deviceId;

/**
 * capture
 */
+ (void)captureImageWithDeviceId:(NSString*)deviceId channelId:(int)channelId path:(NSString*)path resultBlock:(void(^)(int result))resultBlock;
/**
 * switch audio
 */
+ (void)audioSwitchWithDeviceId:(NSString*)deviceId channelId:(int)channelId isOpen:(BOOL)isOpen resultBlock:(void(^)(int result))resultBlock;
/**
 * switch talk
 */
+ (void)talkSwitchWithDeviceId:(NSString*)deviceId channelId:(int)channelId isOpen:(BOOL)isOpen resultBlock:(void(^)(int result))resultBlock;
/**
 * SD / HD Switch
 * qualityType: 1  HD
 * qualityType: 2  SD
 */
+ (void)qualityAdjustmentWithDeviceId:(NSString*)deviceId channelId:(int)channelId type:(int)qualityType resultBlock:(void(^)(int result))resultBlock;
/**
 * Get device capabilities
 * PTZ capability
 * Talk capability
 */
+ (void)getDeviceCapacityWithDeviceId:(NSString*)deviceId channelId:(int)channelId reulstBlock:(void (^)(int result, SunellChannelModel * _Nullable channelModel))resultBlock;

/**
 * Enable PTZ
 */
+ (void)openPTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;
/**
 * Disable PTZ
 */
+ (void)closePTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;

/**
 * operation PTZ
 * arrowType:
 * PTZ_UP = 1,        // up
   PTZ_DOWN = 2,      // down
   PTZ_LEFT = 3,      // left
   PTZ_RIGHT = 4,     // right
   PTZ_LEFT_UP = 5,   // up-left
   PTZ_LEFT_DOWN = 6, // down-left
   PTZ_RIGHT_UP = 7,  // up-right
   PTZ_RIGHT_DOWN = 8, // down-right
 */
+ (void)operationPTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId arrowType:(int)arrowType resultBlock:(void(^)(int result))resultBlock;

+ (void)stopPTZWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;

/**
 * Get white-light capability
 */
+ (void)getWhiteLightAbilityWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result,NSString* _Nullable jsonStr))resultBlock;

/// Read current white-light parameters (JSON string defined by the device).
+ (void)getWhiteLightSwitchParamWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result, NSString * _Nullable jsonStr))resultBlock;
/// Send white-light parameter JSON (avoid `set` prefix, otherwise Swift imports it as a property setter and no matching member appears).
+ (void)applyWhiteLightSwitchParamWithDeviceId:(NSString*)deviceId channelId:(int)channelId paramJson:(NSString*)paramJson resultBlock:(void(^)(int result))resultBlock;
// Get alarm audio data
+ (void)getAudioAlarmInfoWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result,NSString * _Nullable jsonStr))resultBlock;
/**
 * displayId: audio id (retrieved from + (void)getAudioAlarmInfoWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result,NSString * _Nullable jsonStr))resultBlock)
 * playNum: number of play times, 0 means loop forever
 *
 */
+ (void)playAudioAlarmWithDeviceId:(NSString*)deviceId channelId:(int)channelId displayId:(int)displayId playNum:(int)playNum resultBlock:(void(^)(int result))resultBlock;

// Start playback
+ (void)playbackStartWithDeviceId:(NSString*)deviceId channelId:(int)channelId startTimeStr:(NSString*)startTimeStr streamType:(int)streamType isHwDec:(BOOL)isHwDec layer:(CAEAGLLayer*)caLayer resultBlock:(void(^)(int result))resultBlock;
// Stop playback
+ (void)playBackStopWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;

// Pause playback
+ (void)playBackPauseWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;

// Resume playback
+ (void)playBackResumeWithDeviceId:(NSString*)deviceId channelId:(int)channelId resultBlock:(void(^)(int result))resultBlock;

// seek
+ (void)playBackSeekWithDeviceId:(NSString*)deviceId channelId:(int)channelId startTimeStr:(NSString*)startTimeStr resultBlock:(void(^)(int result))resultBlock;

// speed
+ (void)playBackSetSpeedWithDeviceId:(NSString*)deviceId channelId:(int)channelId speed:(SunellSpeedType)speedType resultBlock:(void(^)(int result))resultBlock;

// Get playback records for a specific day
+ (void)getPlayBackOneDayRecordListWithDeviceId:(NSString*)deviceId channelId:(int)channelId dayStr:(NSString*)dayStr resultBlock:(void(^)(int result,NSString * jsonStr))resultBlock;
// Get playback records for a time range
+ (void)getPlayBackRecordWithinACertainPeriodOfTimeWithDeviceId:(NSString*)deviceId channelId:(int)channelId startDateStr:(NSString*)startDateStr endDateStr:(NSString*)endDateStr resultBlock:(void(^)(int result,NSString * jsonStr))resultBlock;
// Get days that contain playback records within a time range
+ (void)getWhichDaysWithinTheTimePeriodHavePlaybackRecordsWithDeviceId:(NSString*)deviceId channelId:(int)channelId startDayStr:(NSString*)startDayStr endDayStr:(NSString*)endDayStr resultBlock:(void(^)(int result,NSString* jsonStr))resultBlock;
+ (void)closeGL;
@end

NS_ASSUME_NONNULL_END
