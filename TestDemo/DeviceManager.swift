//
//  DeviceManager.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/25.
//

import Foundation
import SunellSDK

/// 设备列表内存缓存 + Application Support 沙盒 JSON 持久化，下次启动自动恢复。
final class DeviceManager: NSObject {

    static let shared = DeviceManager()

    private let ioQueue = DispatchQueue(label: "com.sunell.testdemo.devicemanager", qos: .utility)
    /// 批量重连：在子线程调度，避免阻塞调用方
    private static let connectQueue = DispatchQueue(label: "com.sunell.testdemo.devicemanager.connect", qos: .utility)
    private var devices: [SunellDeviceModel] = []

    /// 设备列表变更时通知 UI 刷新（object 为 nil）
    static let deviceListDidChangeNotification = Notification.Name("SunellDeviceListDidChange")

    private override init() {
        super.init()
        loadFromDiskSync()
        connectAllDevice()
    }

    /// 对列表中设备发起重连：P2P 走 `connectDevByP2P`，否则走 `connectDevByIP`（`userName`、`pwd` 任一为空则跳过 IP 重连）。
    /// 在后台队列遍历并调用 SDK，避免阻塞当前线程。
    func connectAllDevice() {
        let snapshot: [SunellDeviceModel] = ioQueue.sync { Array(devices) }
        Self.connectQueue.async { [weak self] in
            guard let self else { return }
            for device in snapshot {
                if device.isP2PAdd {
                    let uuid = device.deviceUUID
                    guard !uuid.isEmpty else { continue }
                    let port = Int(device.port)
                    let user = device.userName
                    let pwd = device.pwd
                    SunellSDKEntry.connectDevByP2P(uuid: uuid, port: port, user: user, pwd: pwd) { [weak self] _, deviceModel in
                        guard let self else { return }
                        
                        self.applyReconnectedStatus(deviceModel: deviceModel) { $0.deviceUUID == uuid }
                    }
                } else {
                    let user = device.userName
                    let pwd = device.pwd
                    guard !user.isEmpty, !pwd.isEmpty else { continue }
                    let ip = device.deviceIp
                    guard !ip.isEmpty, device.port > 0 else { continue }
                    let uuid = device.deviceUUID
                    let devId = device.deviceId
                    let port = Int(device.port)
                    SunellSDKEntry.connectDevByIP(ip: ip, port: port, user: user, pwd: pwd) { [weak self] _, deviceModel in
                        guard let self else { return }
                        self.applyReconnectedStatus(deviceModel: deviceModel) { d in
                            if !uuid.isEmpty { return d.deviceUUID == uuid }
                            if !devId.isEmpty { return d.deviceId == devId }
                            return d.deviceIp == ip && d.port == device.port
                        }
                    }
                }
            }
        }
    }

    /// 将回调中的在线状态写回列表中的同一台设备（按 `matches` 定位）。
    private func applyReconnectedStatus(deviceModel: SunellDeviceModel, matches: @escaping (SunellDeviceModel) -> Bool) {
        ioQueue.async { [weak self] in
            guard let self else { return }
            guard let idx = self.devices.firstIndex(where: matches) else { return }
            let stored = self.devices[idx]
            // 每次连接后deviceId都不一样，(deviceId)是一个临时的不是真实的设备Id，
            stored.deviceId = deviceModel.deviceId;
            guard stored.status != deviceModel.status else { return }
            stored.status = deviceModel.status
            self.saveToDiskSync()
            self.postChangeOnMain()
        }
    }

    // MARK: - Public API

    /// 当前内存中的全部设备（快照，顺序与存储一致）
    func allDevices() -> [SunellDeviceModel] {
        ioQueue.sync { Array(devices) }
    }

    /// 添加设备；若 `deviceUUID` 已存在则覆盖同 UUID 的项
    func addDevice(_ device: SunellDeviceModel) {
        ioQueue.async { [weak self] in
            guard let self else { return }
            let uuid = device.deviceUUID
            if let idx = self.devices.firstIndex(where: { ($0.deviceUUID) == uuid && !uuid.isEmpty }) {
                self.devices[idx] = device
            } else {
                self.devices.append(device)
            }
            self.saveToDiskSync()
            self.postChangeOnMain()
        }
    }

    /// 按设备 UUID 删除
    func removeDevice(deviceUUID: String) {
        let key = deviceUUID
        ioQueue.async { [weak self] in
            guard let self else { return }
            self.devices.removeAll { ($0.deviceUUID) == key }
            self.saveToDiskSync()
            self.postChangeOnMain()
        }
    }

    /// 删除指定模型（按 UUID 匹配）
    func removeDevice(_ device: SunellDeviceModel) {
        removeDevice(deviceUUID: device.deviceUUID)
    }

    /// 清空列表并写盘
    func removeAllDevices() {
        ioQueue.async { [weak self] in
            guard let self else { return }
            self.devices.removeAll()
            self.saveToDiskSync()
            self.postChangeOnMain()
        }
    }

    /// 重新从沙盒加载（一般无需调用，启动时已加载）
    func reloadFromDisk() {
        ioQueue.async { [weak self] in
            guard let self else { return }
            self.loadFromDiskSync()
            self.postChangeOnMain()
        }
    }

    // MARK: - 沙盒路径

    private var cacheDirectoryURL: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("SunellDeviceCache", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var devicesFileURL: URL {
        cacheDirectoryURL.appendingPathComponent("devices.json", isDirectory: false)
    }

    // MARK: - 持久化

    private struct DevicesFileDTO: Codable {
        var devices: [DeviceCacheDTO]
    }

    private struct DeviceCacheDTO: Codable {
        var deviceUUID: String
        var deviceName: String
        /// 旧版 JSON 无此字段时解码为 `nil`，恢复为空串
        var userName: String?
        var pwd: String?
        var deviceStyle: String
        var deviceIp: String
        var deviceMac: String
        var productModel: String
        var deviceSN: String
        var swInfo: String
        var hwInfo: String
        var deviceId: String
        var devType: Int
        var port: Int
        var chnNum: Int
        var status: Int
        /// 旧版 `devices.json` 无此字段时解码为 `nil`，恢复为 `false`
        var isP2PAdd: Bool?
        var channels: [ChannelCacheDTO]
    }

    private struct ChannelCacheDTO: Codable {
        var channelId: Int
        var deviceId: String
        var status: Int
        var channleName: String
    }

    private func loadFromDiskSync() {
        let url = devicesFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            devices = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(DevicesFileDTO.self, from: data)
            devices = decoded.devices.map { Self.model(from: $0) }
        } catch {
            devices = []
        }
    }

    private func saveToDiskSync() {
        let dto = DevicesFileDTO(devices: devices.map { Self.dto(from: $0) })
        do {
            let data = try JSONEncoder().encode(dto)
            try data.write(to: devicesFileURL, options: [.atomic])
        } catch {
            // 写盘失败时保留内存数据，仅忽略错误
        }
    }

    private func postChangeOnMain() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.deviceListDidChangeNotification, object: nil)
        }
    }

    // MARK: - 模型 ↔ DTO

    private static func dto(from model: SunellDeviceModel) -> DeviceCacheDTO {
        let chs: [ChannelCacheDTO] = channelModels(from: model.channels as Any?).map { ch in
            ChannelCacheDTO(
                channelId: Int(ch.channelId),
                deviceId: ch.deviceId,
                status: Int(ch.status),
                channleName: ch.channleName
            )
        }
        return DeviceCacheDTO(
            deviceUUID: model.deviceUUID,
            deviceName: model.deviceName,
            userName: model.userName,
            pwd: model.pwd,
            deviceStyle: model.deviceStyle,
            deviceIp: model.deviceIp,
            deviceMac: model.deviceMac,
            productModel: model.productModel,
            deviceSN: model.deviceSN,
            swInfo: model.swInfo,
            hwInfo: model.hwInfo,
            deviceId: model.deviceId,
            devType: Int(model.devType),
            port: Int(model.port),
            chnNum: Int(model.chnNum),
            status: Int(model.status),
            isP2PAdd: model.isP2PAdd,
            channels: chs
        )
    }

    private static func channelModels(from raw: Any?) -> [SunellChannelModel] {
        if let list = raw as? [SunellChannelModel] {
            return list
        }
        if let array = raw as? NSArray {
            var out: [SunellChannelModel] = []
            out.reserveCapacity(array.count)
            for case let ch as SunellChannelModel in array {
                out.append(ch)
            }
            return out
        }
        return []
    }

    private static func model(from dto: DeviceCacheDTO) -> SunellDeviceModel {
        let m = SunellDeviceModel()
        m.deviceUUID = dto.deviceUUID
        m.deviceName = dto.deviceName
        m.userName = dto.userName ?? ""
        m.pwd = dto.pwd ?? ""
        m.deviceStyle = dto.deviceStyle
        m.deviceIp = dto.deviceIp
        m.deviceMac = dto.deviceMac
        m.productModel = dto.productModel
        m.deviceSN = dto.deviceSN
        m.swInfo = dto.swInfo
        m.hwInfo = dto.hwInfo
        m.deviceId = dto.deviceId
        m.devType = Int32(dto.devType)
        m.port = Int32(dto.port)
        m.chnNum = Int32(dto.chnNum)
        // 从沙盒恢复的设备一律视为离线，真实在线状态需由 SDK 监听等逻辑后续刷新
        m.status = 0
        m.isP2PAdd = dto.isP2PAdd ?? false
        let channels: [SunellChannelModel] = dto.channels.map { c in
            let ch = SunellChannelModel()
            ch.channelId = Int32(c.channelId)
            ch.deviceId = c.deviceId
            ch.status = Int32(c.status)
            ch.channleName = c.channleName
            return ch
        }
        m.channels = channels
        return m
    }
}
