//
//  SceneDelegate.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/23.
//

import UIKit
import SunellSDK
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        SunellSDKEntry.delegate = self
   
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
     

}

extension SceneDelegate: SunellSDKEntry.Delegate {
    func sunellSDKDeviceErrorStatus(_ deviceModel: SunellDeviceModel, _ type: Int32) {
        print(deviceModel.deviceId,type)
        print("SceneDelegate sunellSDKDeviceErrorStatus:",type)
    }
    
    func sunellSDKStartAutoReconnect(_ deviceModel: SunellDeviceModel) {
        print(deviceModel.status)
        // 更新沙盒和当前device的在线状态
        print("SceneDelegate sunellSDKStartAutoReconnect:",deviceModel.status)
        // 设备掉线正在发起重连
        DeviceManager.shared.addDevice(deviceModel)
        NotificationCenter.default.post(
            name: .sunellDeviceAutoReconnectStatusDidChange,
            object: nil,
            userInfo: [
                "deviceId": deviceModel.deviceId,
                "status": deviceModel.status
            ]
        )
    }
    
    func sunellSDKEndAutoReconnect(_ deviceModel: SunellDeviceModel, _ isSuccess: Bool) {
        print(deviceModel.deviceId,isSuccess)
        // 更新沙盒和当前device的在线状态
        print(deviceModel.status)
        print("SceneDelegate sunellSDKEndAutoReconnect:",deviceModel.status)
        if(isSuccess){
            // 重新上线
            DeviceManager.shared.addDevice(deviceModel)
            NotificationCenter.default.post(
                name: .sunellDeviceAutoReconnectStatusDidChange,
                object: nil,
                userInfo: [
                    "deviceId": deviceModel.deviceId,
                    "status": deviceModel.status,
                ]
            )
        }
        
    }
    
    func sunellSDKAlarmInfo(_ deviceModel: SunellDeviceModel, alarmInfo: String) {
        // 未实现
    }
    
    func sunellSDKVideoOperation(_ deviceId: String, channelId: Int, eventId: Int, msg: String, playModel: Int) {
        // 未实现
    }
    
  
    
    
    
}

extension Notification.Name {
    /// 自动重连阶段变化：`userInfo` 含 `phase`（`start` / `end`）、`deviceId`、`status`，`end` 时含 `success`。
    static let sunellDeviceAutoReconnectStatusDidChange = Notification.Name("sunellDeviceAutoReconnectStatusDidChange")
}
