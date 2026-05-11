//
//  PlayerView.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/25.
//

import UIKit
import SunellSDK
//import OpenGLES


class PlayerView: UIView {

    var device: SunellDeviceModel {
        didSet {
            // Connection/capability callbacks often replace the model instance while deviceId/channel count stay unchanged; rebuilding every time can tear down active `CAEAGLLayer`, causing many `PlayerViewCell` deinit calls or even GL crashes.
            let sameDevice = (oldValue.deviceId as String) == (device.deviceId as String)
            let sameLayout = sameDevice
                && Self.derivedCellCount(for: oldValue) == Self.derivedCellCount(for: device)
            if sameLayout {
                return
            }
            requestRebuildChannelCells()
        }
    }

    /// Uses the same rules as `rebuildChannelCells` to decide whether physical cell rebuild is required.
    private static func derivedCellCount(for d: SunellDeviceModel) -> Int {
        let raw = max(0, Int(d.chnNum))
        return raw == 0 ? 1 : raw
    }

    var bgScrollView = UIScrollView()
    /// One `PlayerViewCell` per channel; index matches channel order (0..<chnNum).
    private(set) var cellArray: [PlayerViewCell] = []

    /// Callback hook before physical cell rebuild: business side (`LivePlayerPage`) must
    /// synchronously detach current `glLayer` and start `liveStop` + `closeGL`; call `proceed()` in callback
    /// before actual rebuild. This avoids crashes when SDK render_thread still holds old `CAEAGLLayer` pointers
    /// while cells are deallocated, which can crash in `LayerAnimation::unref`.
    /// Parameter `proceed`: business side must call once on main thread after SDK stream stop completes.
    var willRebuildCells: ((_ proceed: @escaping () -> Void) -> Void)?
    /// Prevent reentry when `device.didSet` triggers again during async hook processing.
    private var isRebuildingCells = false
    private var pendingRebuildAfterCurrent = false

    init(frame: CGRect, device: SunellDeviceModel) {
        self.device = device
        super.init(frame: frame)
        setUpSubView()
    }

    required init?(coder: NSCoder) {
        self.device = SunellDeviceModel()
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpSubView() {
        bgScrollView.showsHorizontalScrollIndicator = true
        bgScrollView.bounces = true
        addSubview(bgScrollView)
        // During initialization there is no active `liveStart`, so synchronous rebuild is safe (and `willRebuildCells` is not registered yet).
        doRebuildChannelCells()
    }

    /// Page width matches visible width (fullscreen: screen width); before layout falls back to main screen width.
    private var pageWidth: CGFloat {
        let w = bounds.width
        return w > 0 ? w : UIScreen.main.bounds.width
    }

    /// Current horizontal page index; same as `cellArray` index.
    func currentPageIndex() -> Int {
        let w = pageWidth
        guard w > 0 else { return 0 }
        return Int(round(bgScrollView.contentOffset.x / w))
    }

    /// Regenerate cells from current `device` (for example after connect fills `devType`/`chnNum`) to keep in sync with `LivePlayerPage.device`.
    /// Use `requestRebuildChannelCells` so business side can run `liveStop` + `closeGL` before discarding old `glLayer`.
    func reloadChannelCellsFromDevice() {
        requestRebuildChannelCells()
    }

    /// Entry point: attempt to rebuild cells. If `willRebuildCells` is registered, it **must call `proceed()`** before actual
    /// view teardown; otherwise it falls back to synchronous rebuild (for initialization before `liveStart`).
    private func requestRebuildChannelCells() {
        guard !isRebuildingCells else {
            // Rebuild was triggered again while hook was processing asynchronously; mark and rerun after current cycle finishes.
            pendingRebuildAfterCurrent = true
            return
        }
        guard let willRebuildCells else {
            doRebuildChannelCells()
            return
        }
        isRebuildingCells = true
        willRebuildCells { [weak self] in
            guard let self else { return }
            self.doRebuildChannelCells()
            self.isRebuildingCells = false
            if self.pendingRebuildAfterCurrent {
                self.pendingRebuildAfterCurrent = false
                self.requestRebuildChannelCells()
            }
        }
    }

    /// Build `PlayerViewCell` instances from `device.chnNum`, fill `cellArray`, size horizontal scroll.
    /// Callers (except initialization) must ensure SDK live / GL consumer is already stopped, otherwise SDK may hold
    /// a dangling `CAEAGLLayer` pointer.
    private func doRebuildChannelCells() {
        // Same as teardown: disable implicit animations and explicitly detach each `glLayer` before `removeFromSuperview`.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for cell in cellArray {
            cell.glLayer.contents = nil
            cell.glLayer.removeFromSuperlayer()
        }
        for sub in bgScrollView.subviews {
            sub.removeFromSuperview()
        }
        CATransaction.commit()
        cellArray.removeAll(keepingCapacity: true)

        let count = Self.derivedCellCount(for: device)
        let w = pageWidth
        let h = max(bgScrollView.bounds.height, bounds.height, 1)

        for i in 0 ..< count {
            let cell = PlayerViewCell(frame: CGRect(x: CGFloat(i) * w, y: 0, width: w, height: h))
            bgScrollView.addSubview(cell)
            cellArray.append(cell)
        }

        updateScrollContentSizeAndPaging(pageHeight: h)
    }

    private func updateScrollContentSizeAndPaging(pageHeight: CGFloat) {
        let w = pageWidth
        let n = cellArray.count
        let totalW = w * CGFloat(n)
        bgScrollView.contentSize = CGSize(width: totalW, height: pageHeight)
        // Paging aligns only when visible width equals page width.
        bgScrollView.isPagingEnabled = abs(bgScrollView.bounds.width - w) < 0.5
    }
    
//    override class var layerClass: AnyClass {
//        CAEAGLLayer.self
//    }
//
//    var glLayer: CAEAGLLayer {
//        layer as! CAEAGLLayer
//    }
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupLayer()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupLayer()
//    }
//
//    private func setupLayer() {
//        glLayer.isOpaque = true
//        glLayer.contentsScale = UIScreen.main.scale
//        glLayer.drawableProperties = [
//            kEAGLDrawablePropertyRetainedBacking as String: false,
//            kEAGLDrawablePropertyColorFormat as String: kEAGLColorFormatRGBA8
//        ]
//    }
//
    override func layoutSubviews() {
        super.layoutSubviews()
        bgScrollView.frame = bounds
        let w = pageWidth
        let h = bgScrollView.bounds.height
        guard h > 0, !cellArray.isEmpty else { return }
        for (i, cell) in cellArray.enumerated() {
            cell.frame = CGRect(x: CGFloat(i) * w, y: 0, width: w, height: h)
        }
        updateScrollContentSizeAndPaging(pageHeight: h)
    }
}
