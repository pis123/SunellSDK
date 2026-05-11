//
//  PlayerViewCell.swift
//  TestDemo
//
//  Created by Sunell on 2026/3/30.
//

import UIKit

/// Preview area: use a normal `UIView` root layer plus a child `CAEAGLLayer` for OpenGL rendering.
/// This avoids UIKit treating SDK drawable binding on `render_thread` as direct root-layer mutation when `layerClass == CAEAGLLayer`.
/// Warnings may still appear, but this is safer than using EAGL as root layer; a complete fix requires SDK main-thread binding or migration to Metal/VT.
class PlayerViewCell: UIView {

    /// Rendering surface passed to SDK (child layer, not `self.layer`).
    let glLayer = CAEAGLLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGLSublayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGLSublayer()
    }

    private func setupGLSublayer() {
        glLayer.isOpaque = true
        glLayer.contentsScale = UIScreen.main.scale
        glLayer.drawableProperties = [
            kEAGLDrawablePropertyRetainedBacking as String: false,
            kEAGLDrawablePropertyColorFormat as String: kEAGLColorFormatRGBA8
        ]
        layer.addSublayer(glLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glLayer.frame = bounds
    }
    deinit {
        print("PlayerViewCell deinit")
    }
}
