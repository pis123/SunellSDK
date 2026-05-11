//
//  LivePlayerPage.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/25.
//

import UIKit
import SunellSDK
internal import UniformTypeIdentifiers

final class LivePlayerPage: UIViewController {

    private var device: SunellDeviceModel
    private var currentChannel: Int {
        didSet {
            if device.channels.count > 0 {
                if let model = device.channels.first(where: {$0.channelId == currentChannel}) {
                    currentChannelModel = model
                }
            }else {
                currentChannelModel = SunellChannelModel()
                currentChannelModel.deviceId = device.deviceId
                currentChannelModel.channelId = 1
                currentChannelModel.status = device.status
                currentChannelModel.channleName = device.deviceName
            }
            
        }
    }
    private lazy var currentChannelModel : SunellChannelModel = {
//        return device.channels.first ?? SunellChannelModel()
        if device.channels.count > 0 {
            if  let model = device.channels.first(where: {$0.channelId == currentChannel}) {
                return model
            }
        }else {
            let model  = SunellChannelModel()
            model.deviceId = device.deviceId
            model.channelId = 1
            model.status = device.status
            model.channleName = device.deviceName
            return model
        }
        return SunellChannelModel()
    }()
    
    private lazy var playAreaView: PlayerView = {
        let v = PlayerView(frame: .zero, device: device)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .black
        return v
    }()

    private let bottomPlaceholderView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        return v
    }()

    /// `true` when stream quality is HD, otherwise SD (`false` by default).
    private var isStreamHD: Bool = false
    private var isAudioOn: Bool = false
    /// Treat `getWhiteLightAbility` success as white-light control support for the current channel.
    private var supportsWhiteLight: Bool = false

    private lazy var captureButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_Capture"))
        b.addTarget(self, action: #selector(captureTapped), for: .touchUpInside)
        return b
    }()
    private lazy var ptzButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_PTZ"))
        b.addTarget(self, action: #selector(ptzTapped), for: .touchUpInside)
        return b
    }()

    private var ptzKeyboardView: PTZKeyboardView?
    private lazy var audioButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_Mute"))
        b.addTarget(self, action: #selector(audioTapped), for: .touchUpInside)
        return b
    }()
    private lazy var talkButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_TalkClose"))
        b.addTarget(self, action: #selector(talkTapped), for: .touchUpInside)
        b.setTitle(TKLocalizedString("TK_TalkOpen"), for: .selected)
        return b
    }()
    private lazy var streamButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_StreamSD"))
        b.addTarget(self, action: #selector(streamTapped), for: .touchUpInside)
        return b
    }()

    private lazy var whiteLightButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_WhiteLight"))
        b.addTarget(self, action: #selector(whiteLightTapped), for: .touchUpInside)
        return b
    }()
    private lazy var alarmButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_PlayAlarm"))
        b.addTarget(self, action: #selector(playAlarmTapped), for: .touchUpInside)
        return b
    }()

    private lazy var channelStatusMonitorButton: UIButton = {
        let b = Self.makeToolbarButton(title: TKLocalizedString("TK_ChannelStatusMonitorStart"))
        b.addTarget(self, action: #selector(channelStatusMonitorTapped), for: .touchUpInside)
        b.setTitle(TKLocalizedString("TK_ChannelStatusMonitorStop"), for: .selected)
        b.isSelected = false
        b.titleLabel?.numberOfLines = 1
        b.titleLabel?.adjustsFontSizeToFitWidth = false
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        return b
    }()

    /// First row: Snapshot / Audio / Talk / Stream / PTZ.
    private lazy var toolbarRow1: UIStackView = {
        let s = UIStackView(arrangedSubviews: [
            captureButton, audioButton, talkButton, streamButton, ptzButton
        ])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.alignment = .fill
        s.distribution = .fillEqually
        s.spacing = 8
        return s
    }()
    /// Second row: White Light and Alarm Audio (below the PTZ row).
    private lazy var toolbarRow2: UIStackView = {
        let s = UIStackView(arrangedSubviews: [whiteLightButton, alarmButton])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.alignment = .fill
        s.distribution = .fillEqually
        s.spacing = 8
        return s
    }()
    /// Third row: Channel status listener (below white light row); left-aligned with width slightly wider than text.
    private lazy var toolbarRow3: UIStackView = {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let s = UIStackView(arrangedSubviews: [channelStatusMonitorButton, spacer])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .fill
        s.spacing = 0
        return s
    }()
    private lazy var toolbarStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [toolbarRow1, toolbarRow2, toolbarRow3])
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .fill
        s.distribution = .fill
        s.spacing = 10
        return s
    }()

    private let pageIndicatorContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        v.layer.cornerRadius = 8
        v.layer.masksToBounds = true
        v.isUserInteractionEnabled = false
        return v
    }()

    private let pageIndicatorLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        l.text = "0/0"
        return l
    }()

    private var didStartLive = false
    /// Defer device alignment and first-play cell rebuild to the next RunLoop to avoid `reload`/layout recursion in `layoutSubviews`, which can trigger duplicate `startLive` calls and GL crashes.
    private var deferredLiveBootstrapWorkItem: DispatchWorkItem?
    /// Exit cleanup (`liveStop` + `closeGL`) has run, to avoid duplicate release between back action and `viewDidDisappear`.
    private var livePreviewTornDown = false
    /// Stream was proactively stopped when Scene became inactive/background; resume on foreground.
    private var suspendedForSceneLifecycle = false
    private var reconnectStatusObserver: NSObjectProtocol?
    private var scenePauseObserver: NSObjectProtocol?
    private var sceneResumeObserver: NSObjectProtocol?
    private var videoOperationObserver: NSObjectProtocol?

    init(device: SunellDeviceModel) {
        self.device = device
        currentChannel = 1
        super.init(nibName: nil, bundle: nil)
    }
    var snaphotPath : String!
    var thumbnailPath : String!
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = TKLocalizedString("TK_Live")
        snaphotPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/snaphot/");
        thumbnailPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/thumbnailPath/");

        // Ensure folders exist so SDK can write images.
        if let snaphotPath {
            try? FileManager.default.createDirectory(atPath: snaphotPath, withIntermediateDirectories: true)
        }
        if let thumbnailPath {
            try? FileManager.default.createDirectory(atPath: thumbnailPath, withIntermediateDirectories: true)
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationController?.navigationBar.tintColor = .black

        view.addSubview(playAreaView)
        view.addSubview(bottomPlaceholderView)
        bottomPlaceholderView.addSubview(toolbarStack)

        playAreaView.bgScrollView.delegate = self
        // When channel count or device instance changes and cells must be physically rebuilt, run `liveStop` + `closeGL` first,
        // then let `PlayerView` remove old `glLayer` after SDK releases the GL consumer.
        playAreaView.willRebuildCells = { [weak self] proceed in
            self?.tearDownForCellRebuild(proceed: proceed)
        }

        playAreaView.addSubview(pageIndicatorContainer)
        pageIndicatorContainer.addSubview(pageIndicatorLabel)

        let playHeight = UIScreen.main.bounds.width * (3.0 / 4.0)

        NSLayoutConstraint.activate([
            playAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playAreaView.heightAnchor.constraint(equalToConstant: playHeight),

            bottomPlaceholderView.topAnchor.constraint(equalTo: playAreaView.bottomAnchor),
            bottomPlaceholderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPlaceholderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPlaceholderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            toolbarStack.topAnchor.constraint(equalTo: bottomPlaceholderView.safeAreaLayoutGuide.topAnchor, constant: 12),
            toolbarStack.leadingAnchor.constraint(equalTo: bottomPlaceholderView.leadingAnchor, constant: 16),
            toolbarStack.trailingAnchor.constraint(equalTo: bottomPlaceholderView.trailingAnchor, constant: -16),

            pageIndicatorContainer.centerXAnchor.constraint(equalTo: playAreaView.centerXAnchor),
            pageIndicatorContainer.bottomAnchor.constraint(equalTo: playAreaView.bottomAnchor, constant: -12),

            pageIndicatorLabel.topAnchor.constraint(equalTo: pageIndicatorContainer.topAnchor, constant: 6),
            pageIndicatorLabel.leadingAnchor.constraint(equalTo: pageIndicatorContainer.leadingAnchor, constant: 12),
            pageIndicatorLabel.bottomAnchor.constraint(equalTo: pageIndicatorContainer.bottomAnchor, constant: -6),
            pageIndicatorLabel.trailingAnchor.constraint(equalTo: pageIndicatorContainer.trailingAnchor, constant: -12)
        ])

        playAreaView.accessibilityIdentifier = device.deviceId
        playAreaView.bringSubviewToFront(pageIndicatorContainer)
        updatePageIndicator()

        // Disable the toolbar when entering the page to avoid operations before video is truly opened.
        setToolbarInteractionEnabled(false)

        reconnectStatusObserver = NotificationCenter.default.addObserver(
            forName: .sunellDeviceAutoReconnectStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.handleAutoReconnectStatusNotification(note)
        }
        videoOperationObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("sunellSDKVideoOperation"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let dict = notification.object as? [String: Any] else {
                return
            }
            let deviceId = dict["deviceId"] as? String
            let channelId = Self.readChannelId(from: dict)
            let eventId = dict["eventId"] as? Int
            if eventId == 100,
               deviceId == self?.device.deviceId,
               self?.currentChannel == channelId {
                print("打开成功")
                // White-light permission depends on `getWhiteLightAbility`; keep it disabled first to prevent accidental taps.
                self?.supportsWhiteLight = false
                self?.setToolbarInteractionEnabled(true)
                self?.getDeviceTalkAndPTZCapcity { [weak self] in
                    self?.applyTalkAndPTZCapabilityToToolbar()
                }
                // Request white-light capability only after video starts successfully, then apply highlighted/disabled styles.
                self?.refreshWhiteLightPermissionAfterVideoReady()
            }
        }

        scenePauseObserver = NotificationCenter.default.addObserver(
            forName: .sunellSceneWillResignActivePauseVideo,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseLiveForSceneResignActive()
        }
        sceneResumeObserver = NotificationCenter.default.addObserver(
            forName: .sunellSceneDidBecomeActiveResumeVideo,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeLiveAfterSceneBecomeActive()
        }
        
    }

    /// On backgrounding or call overlays: stop stream and close GL to prevent GPU submissions in background.
    /// `closeGL` is still required in the `liveStop` callback, but **do not capture self**; the closure holds immutable copies only:
    /// `deviceId` / `channelId`, to avoid races if deinit happens before delayed callbacks.
    private func pauseLiveForSceneResignActive() {
        guard view.window != nil, didStartLive else { return }
        suspendedForSceneLifecycle = true
        setToolbarInteractionEnabled(false)

        // The layer remains in hierarchy during background (it is reused after resume), so do not detach it here,
        // only clear contents once to avoid SDK submitting to stale surfaces in background.
        let cells = playAreaView.cellArray
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for cell in cells {
            cell.glLayer.contents = nil
        }
        CATransaction.commit()

        let deviceId = device.deviceId
        let channelId = Int(currentChannel)
        SunellSDKEntry.liveStop(deviceId: deviceId, channelId: channelId) { _ in
            SunellSDKEntry.closeGL()
        }
    }

    /// On foreground return: if still on live page and stream was paused by lifecycle, restart stream (toolbar still waits for eventId 100).
    private func resumeLiveAfterSceneBecomeActive() {
        guard view.window != nil, suspendedForSceneLifecycle else { return }
        suspendedForSceneLifecycle = false
        let page = playAreaView.currentPageIndex()
        startLive(onPage: page)
    }

    /// Compatible with ObjC/UserInfo values like `NSNumber`, preventing `channelId` mismatches.
    private static func readChannelId(from dict: [String: Any]) -> Int? {
        if let n = dict["channelId"] as? Int { return n }
        if let n = dict["channelId"] as? NSNumber { return n.intValue }
        return nil
    }
    
    // Get device talk and PTZ permissions (recommended after the "video opened successfully" callback).
    private func getDeviceTalkAndPTZCapcity(completion: (() -> Void)? = nil) {
        let finish: () -> Void = {
            guard let completion else { return }
            if Thread.isMainThread {
                completion()
            } else {
                DispatchQueue.main.async(execute: completion)
            }
        }

        // normal: not requested/failed; capable: supported; not_capable: unsupported
        let needRequest = (currentChannelModel.ptzCapacity == SunellDeviceCapacityType_normal)
            || (currentChannelModel.talkCapacity == SunellDeviceCapacityType_normal)
        guard needRequest else {
            finish()
            return
        }

        SunellSDKEntry.getDeviceCapacityWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { [weak self] result, channelModel in
            guard let self else { return }
            if result == 0 {
                print("获取能力成功")
                if let channelModel {
                    print("channelId:",currentChannelModel.channelId)
                    if currentChannelModel.channelId == channelModel.channelId {
                        currentChannelModel.ptzCapacity = channelModel.ptzCapacity
                        currentChannelModel.talkCapacity = channelModel.talkCapacity
                    }
                }
            } else {
                print("获取能力失败")
            }
            finish()
        }
    }

    private func applyTalkAndPTZCapabilityToToolbar() {
        // Allow tap only after video is open and toolbar is enabled; otherwise keep disabled.
        guard captureButton.isEnabled else {
            talkButton.isEnabled = false
            talkButton.isUserInteractionEnabled = false
            talkButton.alpha = 0.45
            ptzButton.isEnabled = false
            ptzButton.isUserInteractionEnabled = false
            ptzButton.alpha = 0.45
            alarmButton.isEnabled = false
            alarmButton.isUserInteractionEnabled = false
            alarmButton.alpha = 0.45
            applyWhiteLightButtonAppearance()
            return
        }
        
        let talkCapable = (currentChannelModel.talkCapacity == SunellDeviceCapacityType_capable)
        let ptzCapable = (currentChannelModel.ptzCapacity == SunellDeviceCapacityType_capable)

        talkButton.isEnabled = talkCapable
        talkButton.isUserInteractionEnabled = talkCapable
        talkButton.alpha = talkCapable ? 1.0 : 0.45
        if !talkCapable, talkButton.isSelected {
            talkButton.isSelected = false
        }

        ptzButton.isEnabled = ptzCapable
        ptzButton.isUserInteractionEnabled = ptzCapable
        ptzButton.alpha = ptzCapable ? 1.0 : 0.45

        applyWhiteLightButtonAppearance()
        alarmButton.isEnabled = true
        alarmButton.isUserInteractionEnabled = true
        alarmButton.alpha = 1.0
    }

    /// Refresh white-light button based on video readiness and `supportsWhiteLight`: highlight when available, disable when unavailable.
    private func applyWhiteLightButtonAppearance() {
        let videoReady = captureButton.isEnabled
        if !videoReady {
            whiteLightButton.isEnabled = false
            whiteLightButton.isUserInteractionEnabled = false
            Self.styleWhiteLightButton(whiteLightButton, highlighted: false)
            return
        }
        whiteLightButton.isEnabled = supportsWhiteLight
        whiteLightButton.isUserInteractionEnabled = supportsWhiteLight
        Self.styleWhiteLightButton(whiteLightButton, highlighted: supportsWhiteLight)
    }

    /// Call only after video opens (`eventId == 100`) and use `getWhiteLightAbilityWithDeviceId` to determine white-light capability.
    private func refreshWhiteLightPermissionAfterVideoReady() {
        SunellSDKEntry.getWhiteLightAbilityWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { [weak self] result, json in
            guard let self else { return }
            self.supportsWhiteLight = Self.parseWhiteLightAbilityPermitted(result: result, json: json)
            self.applyWhiteLightButtonAppearance()
        }
    }

    /// `getWhiteLightAbility`: treat `result == 0` and JSON not explicitly disabled as capable; extend parsing by device protocol if needed.
    private static func parseWhiteLightAbilityPermitted(result: Int, json: String?) -> Bool {
        guard result == 0 else { return false }
        guard let json, !json.isEmpty,
              let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return true
        }
        let denyKeys = ["support", "Support", "enable", "Enable", "able", "Able", "WhiteLightEnable", "white_light_enable"]
        for key in denyKeys {
            if let n = root[key] as? Int, n == 0 { return false }
            if let b = root[key] as? Bool, b == false { return false }
        }
        if let n = root["result"] as? Int, n != 0 { return false }
        if let n = root["code"] as? Int, n != 0 { return false }
        if let n = root["WhiteLight"] as? Int, n == 0 { return false }
        if let n = root["white_light"] as? Int, n == 0 { return false }
        return true
    }

    /// Capable: highlighted (border + light background + themed text); otherwise disabled gray.
    private static func styleWhiteLightButton(_ b: UIButton, highlighted: Bool) {
        if highlighted {
            b.alpha = 1.0
            b.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.14)
            b.layer.borderColor = UIColor.systemBlue.cgColor
            b.layer.borderWidth = 1.5
            b.setTitleColor(.systemBlue, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        } else {
            b.alpha = 0.45
            b.backgroundColor = .white
            b.layer.borderColor = UIColor.black.withAlphaComponent(0.22).cgColor
            b.layer.borderWidth = 1
            b.setTitleColor(.label.withAlphaComponent(0.55), for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        }
    }

    private static func applyChannelStatusMonitorTitles(to button: UIButton) {
        button.setTitle(TKLocalizedString("TK_ChannelStatusMonitorStart"), for: .normal)
        button.setTitle(TKLocalizedString("TK_ChannelStatusMonitorStop"), for: .selected)
        button.setTitleColor(.black, for: .selected)
    }

    /// Toolbar buttons: gray and untappable when disabled; enable only after successful playback callback (`eventId == 100`).
    private func setToolbarInteractionEnabled(_ enabled: Bool) {
        let alwaysButtons: [UIButton] = [captureButton, audioButton, streamButton, alarmButton, channelStatusMonitorButton]
        for b in alwaysButtons {
            b.isEnabled = enabled
            b.isUserInteractionEnabled = enabled
            b.alpha = enabled ? 1.0 : 0.45
        }

        if !enabled {
            channelStatusMonitorButton.isSelected = false
            Self.applyChannelStatusMonitorTitles(to: channelStatusMonitorButton)
            talkButton.isEnabled = false
            talkButton.isUserInteractionEnabled = false
            talkButton.alpha = 0.45
            ptzButton.isEnabled = false
            ptzButton.isUserInteractionEnabled = false
            ptzButton.alpha = 0.45
            applyWhiteLightButtonAppearance()
        } else {
            // When enabled==true, PTZ/talk tap states are controlled by capability values (disabled first, refreshed after capability arrives).
            applyTalkAndPTZCapabilityToToolbar()
            Self.applyChannelStatusMonitorTitles(to: channelStatusMonitorButton)
        }
    }

    private func cancelPendingDeferredLiveBootstrap() {
        deferredLiveBootstrapWorkItem?.cancel()
        deferredLiveBootstrapWorkItem = nil
    }

    /// Must stop stream and close GL when leaving live page or in `deinit`; relying only on nav back can miss swipe-back paths and keep memory high.
    ///
    /// Critical ordering constraints:
    /// 1. On the main thread, synchronously detach all `cell.glLayer` instances and clear `contents` so they leave the tree before
    ///    `CATransaction.commit()`. This is the key to avoiding `LayerAnimation::unref` crashes -
    ///    the SDK render_thread modifies `CAEAGLLayer` properties / triggers implicit animations; if the layer is destroyed before detach,
    ///    commit can over-release animations attached to the layer during `CA::Layer::destroy`.
    /// 2. Then asynchronously run `liveStop`/`closeGL`. In callbacks, **do not capture `self`**, so resources are still released even if controller deallocates first.
    ///    This ensures SDK-side GL consumers / decode surfaces are released completely.
    ///
    /// - Parameter completion: called after `closeGL` completes in `liveStop` callback (on main thread); if stream was never started or already released, callback is still dispatched asynchronously to main thread.
    private func tearDownLivePreviewIfNeeded(completion: (() -> Void)? = nil) {
        cancelPendingDeferredLiveBootstrap()
        let finish: () -> Void = {
            guard let completion else { return }
            if Thread.isMainThread {
                completion()
            } else {
                DispatchQueue.main.async(execute: completion)
            }
        }

        guard !livePreviewTornDown else {
            finish()
            return
        }
        guard didStartLive else {
            livePreviewTornDown = true
            detachAllGLLayersSynchronously()
            finish()
            return
        }
        livePreviewTornDown = true
        suspendedForSceneLifecycle = false
        setToolbarInteractionEnabled(false)
        playAreaView.bgScrollView.delegate = nil

        detachAllGLLayersSynchronously()

        let deviceId = device.deviceId
        let channelId = Int(currentChannel)
        let needTalkOff = talkButton.isSelected

        if needTalkOff {
            print("talkSwitchWithDeviceId1")
            SunellSDKEntry.talkSwitchWithDeviceId(deviceId: deviceId, channelId: channelId, isOpen: false) { _ in
                print("talkSwitchWithDeviceId2")
            }
        }
        print("talkSwitchWithDeviceId3")
        SunellSDKEntry.liveStop(deviceId: deviceId, channelId: channelId) { _ in
            print("talkSwitchWithDeviceId4")
            SunellSDKEntry.closeGL()
            finish()
        }
    }

    /// On main thread, synchronously detach all `PlayerViewCell.glLayer`, clear `contents`, and disable implicit animations.
    /// Must run before SDK `liveStop` / `closeGL` to break coupling between SDK render_thread and visible layer tree.
    private func detachAllGLLayersSynchronously() {
        let cells = playAreaView.cellArray
        guard !cells.isEmpty else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for cell in cells {
            cell.glLayer.contents = nil
            cell.glLayer.removeFromSuperlayer()
        }
        CATransaction.commit()
    }

    /// Called when `PlayerView` is about to physically rebuild cells (channel count / device instance changes).
    /// Stop current SDK live + GL consumer before letting `PlayerView` remove cells;
    /// then reset `didStartLive` / `livePreviewTornDown` so `viewDidLayoutSubviews`
    /// can bootstrap new cells again automatically.
    private func tearDownForCellRebuild(proceed: @escaping () -> Void) {
        cancelPendingDeferredLiveBootstrap()
        suspendedForSceneLifecycle = false
        setToolbarInteractionEnabled(false)

        detachAllGLLayersSynchronously()

        let resume: () -> Void = { [weak self] in
            // After old cells are discarded and GL consumers are released, the next layout pass may call `startLive` again.
            self?.didStartLive = false
            self?.livePreviewTornDown = false
            proceed()
        }

        guard didStartLive else {
            resume()
            return
        }

        let deviceId = device.deviceId
        let channelId = Int(currentChannel)
        let needTalkOff = talkButton.isSelected

        if needTalkOff {
            SunellSDKEntry.talkSwitchWithDeviceId(deviceId: deviceId, channelId: channelId, isOpen: false) { _ in }
        }
        SunellSDKEntry.liveStop(deviceId: deviceId, channelId: channelId) { _ in
            SunellSDKEntry.closeGL()
            resume()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pushing child pages like snapshot preview keeps `isMovingFromParent` false, so stream is not stopped by mistake.
        // Use `viewWillDisappear` instead of `viewDidDisappear`: the view is still in the window, so all `glLayer`
        // are still in hierarchy and can be detached synchronously from superlayer before later `CATransaction.commit` stages,
        // preventing layer-state races with SDK render_thread and eliminating `LayerAnimation::unref` crash stacks.
        let leavingStack = isMovingFromParent || isBeingDismissed
            || (navigationController?.isBeingDismissed == true)
        if leavingStack {
            tearDownLivePreviewIfNeeded()
        }
    }

    deinit {
        print("\nLivePlayerPage deinit\n")
        cancelPendingDeferredLiveBootstrap()
        // Controller is already released, so do not start another async `liveStop` (captured self becomes nil immediately, and
        // calling `closeGL` again in SDK callbacks can race with soon-to-be-destroyed view tree). In normal paths,
        // teardown has already run in `backTapped` / `viewWillDisappear`; this block only handles abnormal paths
        // by synchronously closing GL once to ensure SDK does not continue writing to destroyed `CAEAGLLayer`.
        if !livePreviewTornDown {
            livePreviewTornDown = true
            SunellSDKEntry.closeGL()
        }
        if let reconnectStatusObserver {
            NotificationCenter.default.removeObserver(reconnectStatusObserver)
        }
        if let scenePauseObserver {
            NotificationCenter.default.removeObserver(scenePauseObserver)
        }
        if let sceneResumeObserver {
            NotificationCenter.default.removeObserver(sceneResumeObserver)
        }
        if let videoOperationObserver {
            NotificationCenter.default.removeObserver(videoOperationObserver)
        }
    }

    /// On auto-reconnect success, resume live preview.
    private func handleAutoReconnectStatusNotification(_ note: Notification) {
        guard let info = note.userInfo,
              let deviceId = info["deviceId"] as? String,
              deviceId == device.deviceId
        else { return }

        let status = info["status"] as? Int
        if(status == 1){
            // Device back online.
            let page = playAreaView.currentPageIndex()
            startLive(onPage: page)
        }else {
            // ...
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updatePageIndicator()

        guard !didStartLive else { return }
        guard playAreaView.bounds.width > 0, playAreaView.bounds.height > 0 else { return }

        scheduleDeferredLiveBootstrapFromLayoutIfNeeded()
    }

    /// Defer to next main-queue cycle: run `syncPlayAreaCells` first, then `startLive` when appropriate, avoiding `reloadChannelCells` or duplicate start in the current layout chain.
    private func scheduleDeferredLiveBootstrapFromLayoutIfNeeded() {
        guard !didStartLive else { return }
        deferredLiveBootstrapWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.deferredLiveBootstrapWorkItem = nil
            self.performDeferredLiveBootstrapFromLayout()
        }
        deferredLiveBootstrapWorkItem = work
        DispatchQueue.main.async(execute: work)
    }

    private func performDeferredLiveBootstrapFromLayout() {
        guard !didStartLive else { return }
        guard playAreaView.bounds.width > 0, playAreaView.bounds.height > 0 else { return }

        syncPlayAreaCellsWithDevice()

        let expectedCells = expectedPlayCellCount()
        guard expectedCells > 0, !playAreaView.cellArray.isEmpty else { return }

        let lastPageIndex = max(0, playAreaView.cellArray.count - 1)
        let page = min(max(0, playAreaView.currentPageIndex()), lastPageIndex)
        currentChannel = channelIdForCellIndex(page)
        didStartLive = true

        setToolbarInteractionEnabled(false)
        startLive(onPage: page)
        updatePageIndicator()
    }

    /// Same as `PlayerView`: when `chnNum==0`, treat as channel count unavailable and use single-window layout (`1/1`) regardless of `devType`.
    private func expectedPlayCellCount() -> Int {
        let raw = max(0, Int(device.chnNum))
        if raw == 0 {
            return 1
        }
        return raw
    }

    /// The list-page `device` may be replaced or updated in place after connect; keep preview cell count aligned with current model.
    private func syncPlayAreaCellsWithDevice() {
        let expected = expectedPlayCellCount()
        guard expected > 0 else { return }

        if playAreaView.device !== device {
            playAreaView.device = device
            return
        }
        if playAreaView.cellArray.count != expected {
            playAreaView.reloadChannelCellsFromDevice()
        }
    }

    /// Bottom label: current page (1-based) / total channel pages。
    /// When `chnNum == 0` (single-cell fallback), always display as `1/1` to avoid early-layout `0/0` when `cellArray` is still empty.
    private func updatePageIndicator() {
        var total = playAreaView.cellArray.count
        if total == 0, Int(device.chnNum) == 0 {
            total = 1
        }
        guard total > 0 else {
            pageIndicatorLabel.text = "0/0"
            pageIndicatorContainer.isHidden = true
            return
        }
        pageIndicatorContainer.isHidden = false
        let idx = playAreaView.currentPageIndex()
        let current = min(max(0, idx), total - 1) + 1
        pageIndicatorLabel.text = "\(current)/\(total)"
    }

    /// Map `cellArray` index to SDK `channelId` (prefers `device.channels` order)。
    /// If `chnNum` is unavailable (0, single-cell fallback / empty `cellArray`), always play channel `1`.
    private func channelIdForCellIndex(_ index: Int) -> Int {
        if Int(device.chnNum) == 0 {
            return 1
        }
        if let list = device.channels as? [SunellChannelModel], index >= 0, index < list.count {
            return Int(list[index].channelId)
        }
        if let arr = device.channels as? NSArray, index >= 0, index < arr.count {
            if let ch = arr.object(at: index) as? SunellChannelModel {
                return Int(ch.channelId)
            }
        }
        return index + 1
    }
   
    private func startLive(onPage page: Int) {
        guard page >= 0, page < playAreaView.cellArray.count else { return }
        let chId = channelIdForCellIndex(page)
        let cell = playAreaView.cellArray[page]
        currentChannel = chId
        setToolbarInteractionEnabled(false)
        SunellSDKEntry.liveStart(
            deviceId: device.deviceId,
            channelId: chId,
            streamType: 2,
            isHw: false,
            caLayer: cell.glLayer) { ret in
                if ret >= 0 { // >= 0: live start API succeeded.
                    print("start Live success");
                }else {
                    print("start Live error");
                }
            }
       
    }

    private func switchLiveToVisiblePageIfNeeded() {
        let page = playAreaView.currentPageIndex()
        updatePageIndicator()
        guard page >= 0, page < playAreaView.cellArray.count else { return }
        let chId = channelIdForCellIndex(page)
        if Int32(chId) == currentChannel { return }

        setToolbarInteractionEnabled(false)
        if talkButton.isSelected {
            print("switchLiveToVisiblePageIfNeeded1")
            SunellSDKEntry.talkSwitchWithDeviceId(deviceId: device.deviceId, channelId:currentChannel, isOpen: false) { result in
                self.talkButton.isSelected.toggle()
                print("switchLiveToVisiblePageIfNeeded2")
            }
        }
        print("switchLiveToVisiblePageIfNeeded3")
        SunellSDKEntry.liveStop(deviceId: device.deviceId, channelId: Int(currentChannel)) { [weak self] ret in
            print("switchLiveToVisiblePageIfNeeded4")
            guard let self else { return }
            if ret == 0 {
                self.startLive(onPage: page)
            } else {
                print("live stop error")
            }
        }
        
    }

    @objc private func backTapped() {
        navigationItem.leftBarButtonItem?.isEnabled = false
        tearDownLivePreviewIfNeeded { [weak self] in
            guard let self else { return }
            guard self.navigationController?.topViewController === self else { return }
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc private func captureTapped() {
        print("capture tapped")
        let str = "capture";
        let imageFile = (snaphotPath as NSString).appendingPathComponent("\(str)_\(currentChannel).jpg")
        
        SunellSDKEntry.captureImageWithDeviceId(deviceId: device.deviceId, channelId: currentChannel, path: imageFile) { result in
            
            if result == 0 {
                print("capture Image success")
                SunellAlertView.show(title: "view Capture Image", message: "", onConfirm: { [weak self] in
                    print("jump view Capture Image")
                    guard let self = self else { return }
                    let page = SunellImageViewPage(imageFilePath: imageFile)
                    self.navigationController?.pushViewController(page, animated: true)
                })
            }else {
                print("capture Image failed")
            }
        }
    }

    @objc private func ptzTapped() {
        SunellSDKEntry.openPTZWithDeivceId(deviceId: device.deviceId, channelId: currentChannel) { result in
            if result == 0{
                // open success
                print("ptz open success")
            }else {
                // open failed
                print("ptz open failed")
            }
        }
        if let v = ptzKeyboardView {
            v.animateOut { [weak self] in
                self?.ptzKeyboardView?.removeFromSuperview()
                self?.ptzKeyboardView = nil
            }
            return
        }

        let items: [PTZKeyboardView.Direction: PTZKeyboardView.Item] = [
            .up: .init(key: "TK_PTZ_Up"),
            .upRight: .init(key: "TK_PTZ_UpRight"),
            .right: .init(key: "TK_PTZ_Right"),
            .downRight: .init(key: "TK_PTZ_DownRight"),
            .down: .init(key: "TK_PTZ_Down"),
            .downLeft: .init(key: "TK_PTZ_DownLeft"),
            .left: .init(key: "TK_PTZ_Left"),
            .upLeft: .init(key: "TK_PTZ_UpLeft")
        ]

        let v = PTZKeyboardView(items: items)
       
        v.onTapItem = { title in
//            PTZ_UP = 1,        // up
//            PTZ_DOWN = 2,      // down
//            PTZ_LEFT = 3,      // left
//            PTZ_RIGHT = 4,     // right
//            PTZ_LEFT_UP = 5,   // up-left
//            PTZ_LEFT_DOWN = 6, // down-left
//            PTZ_RIGHT_UP = 7,  // up-right
//            PTZ_RIGHT_DOWN = 8, // down-right
            var optionArrowType = 0
            switch title {
            case TKLocalizedString("TK_PTZ_Up"):
              print("PTZ:", title)
                optionArrowType = 1
            case TKLocalizedString("TK_PTZ_UpRight"):
                optionArrowType = 7
            case TKLocalizedString("TK_PTZ_Right"):
                optionArrowType = 4
            case TKLocalizedString("TK_PTZ_DownRight"):
                optionArrowType = 8
            case TKLocalizedString("TK_PTZ_Down"):
                optionArrowType = 2
            case TKLocalizedString("TK_PTZ_DownLeft"):
                optionArrowType = 6
            case TKLocalizedString("TK_PTZ_Left"):
                optionArrowType = 3
            case TKLocalizedString("TK_PTZ_UpLeft"):
                optionArrowType = 5
            default:
                print("other")
            }
            
            SunellSDKEntry.operationPTZWithDeviceId(
                deviceId: self.device.deviceId,
                channelId: self.currentChannel,
                arrowType: optionArrowType
            ) { result in
                
                if result == 0 {
                    DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 0.8) {
                        SunellSDKEntry.stopPTZWithDeviceId(
                            deviceId: self.device.deviceId,
                            channelId: self.currentChannel
                        ) { stopResult in
                            if stopResult == 0 {
                                // success
                            }
                        }
                    }
                }
            }
            
        }
        
        
        
        v.onClose = { [weak self] in
            guard let self, let v = self.ptzKeyboardView else { return }
            v.animateOut { [weak self] in
                self?.ptzKeyboardView?.removeFromSuperview()
                self?.ptzKeyboardView = nil
            }
        }
        view.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: view.topAnchor),
            v.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        ptzKeyboardView = v
        v.animateIn()
    }

    @objc private func audioTapped() {
        isAudioOn.toggle()
        audioButton.setTitle(
            isAudioOn ? TKLocalizedString("TK_Audio") : TKLocalizedString("TK_Mute"),
            for: .normal
        )
        audioButton.isEnabled = false
        SunellSDKEntry.audioSwitchWithDeviceId(deviceId: device.deviceId, channelId: currentChannel, isOpen: isAudioOn) { result in
            self.audioButton.isEnabled = true
            if result == 0 {
                print("audio option success");
            }else {
                print("audio option failed");
            }
        }
    }

    @objc private func talkTapped() {
        print("talk tapped")
        talkButton.isEnabled = false
        talkButton.isSelected.toggle()
        SunellSDKEntry.talkSwitchWithDeviceId(deviceId: device.deviceId, channelId: currentChannel, isOpen: talkButton.isSelected) { result in
            self.talkButton.isEnabled = true
            if result == 0 {
                print("talk option success");
            }else {
                print("talk option failed");
            }
        }
    }

    @objc private func streamTapped() {
        isStreamHD.toggle()
        streamButton.setTitle(
            isStreamHD ? TKLocalizedString("TK_StreamHD") : TKLocalizedString("TK_StreamSD"),
            for: .normal
        )
        SunellSDKEntry.qualityAdjustmentWithDeviceId(deviceId: device.deviceId, channelId: currentChannel, qualityType: isStreamHD ? 1 : 2) { result in
            if result == 0 {
                print("change stream option Success")
            }else {
                print("change stream option failed")
            }
        }
    }

    @objc private func channelStatusMonitorTapped() {
        channelStatusMonitorButton.isSelected.toggle()
        if channelStatusMonitorButton.isSelected {
            print("通道状态监听已开启")
            SunellSDKEntry.startDeviceChannelAlarmMonitoring(deviceId: device.deviceId)
        } else {
            print("通道状态监听已关闭")
            SunellSDKEntry.stopDeviceChannelAlarmMonitoring(deviceId: device.deviceId)
        }
    }

    @objc private func whiteLightTapped() {
        guard supportsWhiteLight else { return }
        whiteLightButton.isEnabled = false
        SunellSDKEntry.getWhiteLightSwitchParamWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { [weak self] result, json in
            guard let self else { return }
            let reenable: () -> Void = {
                self.applyWhiteLightButtonAppearance()
            }
            guard result == 0, let json, !json.isEmpty else {
                print("white light get param failed, ret=\(result)")
                reenable()
                return
            }
            Self.toggleWhiteLightInParamJSON(json) { toggledJson in
                guard let toggledJson else {
                    DispatchQueue.main.async {
                        print("white light: could not derive toggle from JSON")
                        reenable()
                    }
                    return
                }
                SunellSDKEntry.setWhiteLightSwitchParamWithDeviceId(
                    deviceId: self.device.deviceId,
                    channelId: self.currentChannel,
                    paramJson: toggledJson
                ) { setRet in
                    DispatchQueue.main.async {
                        print("white light set ret=\(setRet)")
                        reenable()
                    }
                }
            }
        }
    }

    @objc private func playAlarmTapped() {
        alarmButton.isEnabled = false
        SunellSDKEntry.getAudioAlarmInfoWithDeviceId(deviceId: device.deviceId, channelId: currentChannel) { [weak self] result, retJsonStr in
            guard let self else { return }
            let reenableAlarm: () -> Void = {
                let on = self.captureButton.isEnabled
                self.alarmButton.isEnabled = on
                self.alarmButton.isUserInteractionEnabled = on
            }
            defer { reenableAlarm() }

            guard result == 0, let json = retJsonStr, !json.isEmpty else {
                print("alarmAudio: failed result=\(result) json=\(retJsonStr ?? "nil")")
                return
            }
            print("alarmAudio:", json)
            do {
                let parsed = try AudioAlarmInfoJSONParser.parse(json)
                let files = parsed.audioAlarmParam.audioFileList
                let listVC = AudioAlarmFileListViewController(items: files, delegate: self)
                let nav = UINavigationController(rootViewController: listVC)
                nav.modalPresentationStyle = .pageSheet
                if #available(iOS 15.0, *) {
                    if let sheet = nav.sheetPresentationController {
                        sheet.detents = [.medium(), .large()]
                        sheet.prefersGrabberVisible = true
                    }
                }
                self.present(nav, animated: true)
            } catch {
                print("alarmAudio JSON parse error:", error)
            }
        }
    }

    /// Toggle switch-like fields in device JSON and serialize back to string; try common field names first, otherwise use the first integer key with value 0/1.
    private static func toggleWhiteLightInParamJSON(_ json: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = json.data(using: .utf8),
                  var root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let priorityKeys = [
                "WhiteLightSwitch", "white_light_switch", "WhiteLightState", "white_light_state",
                "enable", "Enable", "switch", "Switch", "state", "State"
            ]
            var changed = false
            for key in priorityKeys {
                if let v = root[key] as? Int {
                    root[key] = v == 0 ? 1 : 0
                    changed = true
                    break
                }
                if let v = root[key] as? Bool {
                    root[key] = !v
                    changed = true
                    break
                }
            }
            if !changed {
                for (k, v) in root {
                    if let n = v as? Int, n == 0 || n == 1 {
                        root[k] = n == 0 ? 1 : 0
                        changed = true
                        break
                    }
                }
            }
            guard changed,
                  JSONSerialization.isValidJSONObject(root),
                  let out = try? JSONSerialization.data(withJSONObject: root, options: []),
                  let outStr = String(data: out, encoding: .utf8)
            else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(outStr) }
        }
    }

    private static func makeToolbarButton(title: String) -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.black, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        b.titleLabel?.adjustsFontSizeToFitWidth = true
        b.titleLabel?.minimumScaleFactor = 0.5
        b.titleLabel?.textAlignment = .center
        b.layer.borderColor = UIColor.black.cgColor
        b.layer.borderWidth = 1
        b.layer.cornerRadius = 5
        b.clipsToBounds = true
        b.translatesAutoresizingMaskIntoConstraints = false
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        return b
    }
}

// MARK: - AudioAlarmFileListViewControllerDelegate

extension LivePlayerPage: AudioAlarmFileListViewControllerDelegate {

    func audioAlarmFileList(_ controller: AudioAlarmFileListViewController, didSelect file: AudioAlarmFileItem) {
        controller.dismiss(animated: true) { [weak self] in
            self?.playAudioAlarmUsingSDK(file: file)
        }
    }

    private func playAudioAlarmUsingSDK(file: AudioAlarmFileItem) {
        SunellSDKEntry.playAudioAlarmWithDeviceId(
            deviceId: device.deviceId,
            channelId: currentChannel,
            displayId: file.audioFileId,
            playNum: 2
        ) { result in
            print("playAudioAlarm displayId=\(file.audioFileId) playNum=\(file.audioDisplayNum) ret=\(result)")
        }
    }
}

// MARK: - UIScrollViewDelegate

extension LivePlayerPage: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePageIndicator()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        switchLiveToVisiblePageIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            switchLiveToVisiblePageIfNeeded()
        }
    }
}
