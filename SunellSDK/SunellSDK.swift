//
//  SunellSDK.swift
//  SunellSDK
//
//  Created by Sunell on 2026/3/23.
//

import Foundation
import UIKit

@objc(SunellSDK)
@objcMembers


public class SunellSDKEntry: NSObject {

    // MARK: - Delegate bridging (ObjC -> Swift)

    /// 外部 Swift 侧代理（方便收到 `SunellSDKManagerDelegate` 回调）。
    public protocol Delegate: AnyObject {
        /// 设备上下线状态发生改变
        func sunellSDKDeviceErrorStatus(_ deviceModel: SunellDeviceModel,_ type: Int32)
        /// 自动开启重连
        func sunellSDKStartAutoReconnect(_ deviceModel:SunellDeviceModel)
        /// 重连结束
        func sunellSDKEndAutoReconnect(_ deviceModel:SunellDeviceModel,_ isSuccess: Bool)
        /// 报警消息
        func sunellSDKAlarmInfo(_ deviceModel: SunellDeviceModel, alarmInfo: String)
        /// 视频操作回调
        func sunellSDKVideoOperation(_ deviceId: String, channelId: Int, eventId: Int, msg: String, playModel: Int)
        
    }

    /// 让旧命名继续可用（如外部已采用 `SunellSDKDelegate`）。
    public typealias SunellSDKDelegate = Delegate

    private final class DelegateBridge: NSObject, SunellSDKManagerDelegate {
        weak var target: Delegate?

        @objc func sunellSDKDeviceErrorStatus(_ deviceModel: SunellDeviceModel,type: Int32) {
            target?.sunellSDKDeviceErrorStatus(deviceModel,type)
        }
        @objc func sunellSDKStartAutoReconnect(_ deviceModel: SunellDeviceModel) {
            target?.sunellSDKStartAutoReconnect(deviceModel)
        }
        @objc func sunellSDKEndtAutoReconnect(_ deviceModel: SunellDeviceModel, isSuccess: Bool) {
            target?.sunellSDKEndAutoReconnect(deviceModel, isSuccess)
        }
        /// 注意：此处签名必须与 ObjC 完全一致（`NSDictionary *`），否则 ObjC 调不到该方法。
        @objc func sunellSDKAlarmInfo(_ deviceModel: SunellDeviceModel, alarmInfo: String) {
            target?.sunellSDKAlarmInfo(deviceModel, alarmInfo: alarmInfo)
        }

        @objc func sunellSDKVideoOperation(_ deviceId: String, channelId: Int32, eventId: Int32, msg: String, playModel: Int32) {
            target?.sunellSDKVideoOperation(
                deviceId,
                channelId: Int(channelId),
                eventId: Int(eventId),
                msg: msg,
                playModel: Int(playModel)
            )
        }
    }

    /// 强引用桥接对象，避免被释放导致收不到回调（`SunellSDKManager.delegate` 为 weak）。
    private static let delegateBridge = DelegateBridge()

    /// 推荐用法：`SunellSDKEntry.delegate = xxx`（静态）或 `SunellSDKEntry.shared.delegate = xxx`（实例）。
    public static weak var delegate: Delegate? {
        didSet {
            delegateBridge.target = delegate
            SunellSDKManager.shared().delegate = delegateBridge
        }
    }

    /// 兼容实例式写法：`SunellSDKEntry.shared.delegate = ...`
    public var delegate: Delegate? {
        get { Self.delegate }
        set { Self.delegate = newValue }
    }

    public static let shared = SunellSDKEntry()

    private override init() { super.init() }
    
    public static func connectDevByP2P(uuid:String,port:Int,user:String,pwd:String,resultBlock:@escaping(Int,SunellDeviceModel) -> Void){
        SunellSDKManager.connectDev(byP2P: uuid, port: Int32(port), user: user, pwd: pwd) { handle,device in
             resultBlock(Int(handle),device)
        }
    }
    public static func connectDevByIP(ip:String,port:Int,user:String,pwd:String,resultBlock:@escaping(Int,SunellDeviceModel) -> Void){
        SunellSDKManager.connectDev(byIP: ip, port: Int32(port), user: user, pwd: pwd) { handle, device in
            resultBlock(Int(handle),device)
        }
    }
    public static func disConnectDev(deviceId:String) -> Void {
        SunellSDKManager.disConnectDev(byDeviceId: deviceId)
    }
    /**
     * channelId：默认为1，NVR则为对应的channelId
     * streamType: 1:高清，2:标清
     * isHw: 是否硬件加速解码
     */
    public static func liveStart(deviceId:String,channelId:Int,streamType:Int,isHw:Bool,caLayer:CAEAGLLayer,resultBlcok:@escaping(Int) -> Void){
        SunellSDKManager.liveStart(withDevice: deviceId, channelId: Int32(channelId), streamType: Int32(streamType), isHwDec: isHw, layer: caLayer) { result in
            resultBlcok(Int(result))
        }
    }
    public static func liveStop(deviceId:String,channelId:Int,resultBlcok:@escaping(Int) -> Void){
        SunellSDKManager.liveStop(withDevice: deviceId, channelId: Int32(channelId)) { result in
            resultBlcok(Int(result))
        }
    }

//    public static func startDeviceChannelStatusMonitoring(deviceId: String) {
//        SunellSDKManager.startDeviceChannelStatusMonitoring(deviceId)
//    }
//
//    public static func stopDeviceChannelStatusMonitoring(deviceId: String) {
//        SunellSDKManager.stopDeviceChannelStatusMonitoring(deviceId)
//    }
//
//    public static func startDeviceChannelAlarmMonitoring(deviceId: String) {
//        SunellSDKManager.startDeviceChannelAlarmMonitoring(deviceId)
//    }
//
//    public static func stopDeviceChannelAlarmMonitoring(deviceId: String) {
//        SunellSDKManager.stopDeviceChannelAlarmMonitoring(deviceId)
//    }
    public static func closeGL(){
        SunellSDKManager.closeGL()
    }
}
