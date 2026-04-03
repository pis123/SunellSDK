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
            rebuildChannelCells()
        }
    }

    var bgScrollView = UIScrollView()
    /// 与通道一一对应的 `PlayerViewCell`，下标与通道序号对应（0..<chnNum）。
    private(set) var cellArray: [PlayerViewCell] = []

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
        rebuildChannelCells()
    }

    /// 单页宽度：与可视区域一致（全屏播放器时等于屏宽）；`layout` 前回退到主屏宽度。
    private var pageWidth: CGFloat {
        let w = bounds.width
        return w > 0 ? w : UIScreen.main.bounds.width
    }

    /// 当前横向分页下标，与 `cellArray` 下标一致。
    func currentPageIndex() -> Int {
        let w = pageWidth
        guard w > 0 else { return 0 }
        return Int(round(bgScrollView.contentOffset.x / w))
    }

    /// 根据当前 `device.chnNum` 创建 `PlayerViewCell`，写入 `cellArray` 并铺满横向滚动区域。
    private func rebuildChannelCells() {
        for sub in bgScrollView.subviews {
            sub.removeFromSuperview()
        }
        cellArray.removeAll(keepingCapacity: true)

        let count = max(0, Int(device.chnNum))
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
        // 仅当可视宽度与单页宽度一致时系统分页才对齐
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
