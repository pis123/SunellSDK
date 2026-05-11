//
//  SunellSDKManager.h
//  SunellSDK
//
//  Created by Sunell on 2026/3/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SunellSDKManager : NSObject
+ (instancetype)shared;
+ (void)connectDevByP2P:(NSString *)uuid port:(int)port user:(NSString *)user pwd:(NSString *)pwd reulstBlock:(void (^)(int result))resultBlock;
@end

NS_ASSUME_NONNULL_END
