# SunellSDK Swift API Documentation

This document is based on `SunellSDK.swift`, `LivePlayerPage.swift`, and `PlayerBackPage.swift`.  
It describes the Swift API surface and the recommended call flows for Live and Playback pages.

Applies to iOS 13+ with `import SunellSDK`.

---

## 1. Core Entry and Types

### 1.1 Entry class

- `SunellSDKEntry`: Unified Swift entry point (connection, live, playback, capability, alarm, monitoring, GL cleanup).
- `SunellSDKEntry.shared`: Instance-style access (mainly used for delegate assignment).

### 1.2 Enums

- `SunellPlaybackSpeed`
  - `.x1` (1x)
  - `.x2` (2x)
- `SunellDeviceChannelStatus`
  - `.unkonw` / `.online` / `.offline`

---

## 2. Delegate Callbacks

Setup:

```swift
SunellSDKEntry.delegate = self
// or
SunellSDKEntry.shared.delegate = self
```

Protocol:

```swift
public protocol Delegate: AnyObject {
    func sunellSDKDeviceErrorStatus(_ deviceModel: SunellDeviceModel,_ type: Int32)
    func sunellSDKStartAutoReconnect(_ deviceModel:SunellDeviceModel)
    func sunellSDKEndAutoReconnect(_ deviceModel:SunellDeviceModel,_ isSuccess: Bool)
    func sunellSDKAlarmInfo(_ deviceModel: SunellDeviceModel, alarmInfo: String)
    func sunellSDKVideoOperation(_ deviceId: String, channelId: Int, eventId: Int, msg: String, playModel: Int)
    func sunellSDKChannelStatusChange(_ channelModel: SunellChannelModel)
}
```

Callback meanings:

- `sunellSDKDeviceErrorStatus`: Device error/offline status changed.
- `sunellSDKStartAutoReconnect`: SDK started auto-reconnect after abnormal disconnect.
- `sunellSDKEndAutoReconnect`: Auto-reconnect finished, `isSuccess` indicates final result.
- `sunellSDKAlarmInfo`: Alarm payload from device.
- `sunellSDKVideoOperation`: Video operation event (`eventId == 100` is commonly used as "video opened successfully").
- `sunellSDKChannelStatusChange`: Channel status change notification.

---

## 3. API List (Grouped by Capability)

> Note: Most interfaces use `result == 0` for success.  
> Some start-type APIs may return `>= 0` as success. Always follow your native SDK/device contract.

### 3.1 Connection Management

- `connectDevByP2P(uuid:port:user:pwd:resultBlock:)`
- `connectDevByIP(ip:port:user:pwd:resultBlock:)`
- `disConnectDev(deviceId:)`

`resultBlock` returns `(Int, SunellDeviceModel)`.  
On success, use `deviceId`, `channels`, and `chnNum` to drive UI/business logic.

### 3.2 Live Preview

- `liveStart(deviceId:channelId:streamType:isHw:caLayer:resultBlock:)`
- `liveStop(deviceId:channelId:resultBlock:)`
- `captureImageWithDeviceId(deviceId:channelId:path:resultBlock:)`
- `audioSwitchWithDeviceId(deviceId:channelId:isOpen:resultBlock:)`
- `talkSwitchWithDeviceId(deviceId:channelId:isOpen:resultBlock:)`
- `qualityAdjustmentWithDeviceId(deviceId:channelId:qualityType:resultBlock:)`

Parameter conventions (Live):

- `streamType`: `1 = HD`, `2 = SD/sub stream`
- `qualityType`: `1 = HD`, `2 = SD`
- `caLayer`: pass `PlayerViewCell.glLayer` (`CAEAGLLayer`)

### 3.3 PTZ and Device Capability

- `getDeviceCapacityWithDeviceId(deviceId:channelId:resultBlock:)`
- `openPTZWithDeivceId(deviceId:channelId:resultBlock:)`
- `closePTZWithDeviceId(deviceId:channelId:resultBlock:)`
- `operationPTZWithDeviceId(deviceId:channelId:arrowType:resultBlock:)`
- `stopPTZWithDeviceId(deviceId:channelId:resultBlock:)`

`arrowType` mapping:

- `1` up
- `2` down
- `3` left
- `4` right
- `5` up-left
- `6` down-left
- `7` up-right
- `8` down-right

### 3.4 White Light and Alarm Audio

- `getWhiteLightAbilityWithDeviceId(deviceId:channelId:resultBlock:)`
- `getWhiteLightSwitchParamWithDeviceId(deviceId:channelId:resultBlock:)`
- `setWhiteLightSwitchParamWithDeviceId(deviceId:channelId:paramJson:resultBlock:)`
- `getAudioAlarmInfoWithDeviceId(deviceId:channelId:resultBlock:)`
- `playAudioAlarmWithDeviceId(deviceId:channelId:displayId:playNum:resultBlock:)`

### 3.5 Playback

- `playBackStartWithDeviceId(deviceId:channelId:startTimeStr:streamType:isHwDec:caLayer:resultBlock:)`
- `playBackStopWithDeviceId(deviceId:channelId:resultBlock:)`
- `playBackPauseWithDeviceId(deviceId:channelId:resultBlock:)`
- `playBackResumeWithDeviceId(deviceId:channelId:resultBlock:)`
- `playBackSeekWithDeviceId(deviceId:channelId:timeStr:resultBlock:)`
- `playBackSetSpeedWithDeviceId(deviceId:channelId:speed:resultBlock:)`

Time format conventions (used in playback page):

- DateTime: `yyyy-MM-dd HH:mm:ss`
- Single-day query: `yyyy-MM-dd` (length 10)

### 3.6 Playback Record Queries

- `getPlayBackOneDayRecordListWithDeviceId(deviceId:channelId:dayStr:resultBlock:)`
- `getPlayBackRecordWithinACertainPeriodOfTimeWithDeviceId(deviceId:channelId:startDateStr:endDateStr:resultBlock:)`
- `getWhichDaysWithinTheTimePeriodHavePlaybackRecordsWithDeviceId(deviceId:channelId:startDayStr:endDayStr:resultBlock:)`

### 3.7 Channel Monitoring and Renderer Cleanup

- `startDeviceChannelAlarmMonitoring(deviceId:)`
- `stopDeviceChannelAlarmMonitoring(deviceId:)`
- `closeGL()`

---

## 4. Live Page Call Flow (`LivePlayerPage`)

Recommended sequence:

1. Call `liveStart(...)` after layout is ready.
2. Wait for `sunellSDKVideoOperation` with `eventId == 100` before enabling toolbar actions.
3. After video success, request capabilities:
   - `getDeviceCapacityWithDeviceId` (Talk/PTZ)
   - `getWhiteLightAbilityWithDeviceId` (White light)
4. When switching channel pages, call `liveStop` first, then `liveStart` for target channel.
5. On app background/page exit:
   - `liveStop`
   - `closeGL`

Live toolbar mapping:

- Capture: `captureImageWithDeviceId`
- Audio toggle: `audioSwitchWithDeviceId`
- Talk toggle: `talkSwitchWithDeviceId`
- Stream switch: `qualityAdjustmentWithDeviceId`
- PTZ: `openPTZ` / `operationPTZ` / `stopPTZ`
- White light: `getWhiteLightSwitchParam` + `setWhiteLightSwitchParam`
- Alarm audio: `getAudioAlarmInfo` + `playAudioAlarm`
- Channel monitor: `startDeviceChannelAlarmMonitoring` / `stopDeviceChannelAlarmMonitoring`

---

## 5. Playback Page Call Flow (`PlayerBackPage`)

Recommended sequence:

1. Call `playBackStart(...)` after layout is ready.
2. After start succeeds, call `playBackSetSpeed(..., .x1)` to sync default speed.
3. Control actions:
   - Pause: `playBackPause`
   - Resume: `playBackResume`
   - Seek: `playBackSeek`
   - Speed: `playBackSetSpeed(.x1/.x2)`
4. When switching channel pages, call `playBackStop` first, then `playBackStart` on the new channel.
5. On page exit/background:
   - `playBackStop`
   - `closeGL`

Query mapping:

- One-day records: `getPlayBackOneDayRecordList`
- Time-range records: `getPlayBackRecordWithinACertainPeriodOfTime`
- Days with recordings: `getWhichDaysWithinTheTimePeriodHavePlaybackRecords`

---

## 6. Key Parameters and Best Practices

- `channelId`
  - IPC default: `1`
  - NVR: map from real channel list
- `streamType` / `qualityType`
  - `1 = HD`, `2 = SD`
- `playNum` (alarm audio)
  - `0` usually means loop forever (native contract)
- `result` interpretation
  - Most control APIs: success on `0`
  - Start-type APIs: often success on `>= 0`, and should be confirmed with delegate events

Stability tips (already applied in Demo):

- Do not enable PTZ/Talk/White-light actions before video is truly ready.
- On lifecycle transitions (background, page pop), always perform `stop + closeGL`.
- Use `eventId == 100` as the UI unlock signal for "video actually opened".

---

## 7. Minimal Integration Example

```swift
import SunellSDK

final class Demo: NSObject, SunellSDKEntry.Delegate {
    func start() {
        SunellSDKEntry.delegate = self
        SunellSDKEntry.connectDevByIP(ip: "192.168.1.10", port: 37777, user: "admin", pwd: "123456") { ret, dev in
            guard ret >= 0 else { return }
            // Keep dev.deviceId for liveStart/playBackStart later.
        }
    }

    func sunellSDKVideoOperation(_ deviceId: String, channelId: Int, eventId: Int, msg: String, playModel: Int) {}
    func sunellSDKDeviceErrorStatus(_ deviceModel: SunellDeviceModel, _ type: Int32) {}
    func sunellSDKStartAutoReconnect(_ deviceModel: SunellDeviceModel) {}
    func sunellSDKEndAutoReconnect(_ deviceModel: SunellDeviceModel, _ isSuccess: Bool) {}
    func sunellSDKAlarmInfo(_ deviceModel: SunellDeviceModel, alarmInfo: String) {}
    func sunellSDKChannelStatusChange(_ channelModel: SunellChannelModel) {}
}
```

---

## 8. Reference Files

- `SunellSDK/SunellSDK.swift`
- `TestDemo/Player/LiveViewController/LivePlayerPage.swift`
- `TestDemo/Player/PlayerBackViewController/PlayerBackPage.swift`
- `SunellSDK/SunellSDKManager.h`
