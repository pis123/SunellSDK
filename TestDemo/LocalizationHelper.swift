//
//  LocalizationHelper.swift
//  SunellSDKDemo
//
//  Created by Sunell on 2026/3/17.
//

import Foundation

/// 本地化字符串封装，只需传入 key 即可
/// Localizable.strings 中所有 key 以 TK_ 开头
func TKLocalizedString(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}
