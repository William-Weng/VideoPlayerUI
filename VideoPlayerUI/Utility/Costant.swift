//
//  Costant.swift
//  VideoPlayerUI
//
//  Created by iOS on 2026/7/17.
//

import SwiftUI

/// 常用常數
enum Costant {
    
    // 允許掃描的影片副檔名
    static let allowedExtensions: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv"]
    
    // Documents 根目錄
    static let rootFolder: URL = .documentsDirectory
    
    // 記錄書籤的JSON檔案位置
    static let jsonFileUrl = Costant.rootFolder.appendingPathComponent("favorites.json")
}

/// 主畫面分頁
enum MainTab: Hashable {
    case videos     // 影片列表分頁
    case favorites  // 收藏列表分頁
}

/// 影片尺寸分類
enum SizeType: Hashable {
    
    case SD     // 720x480 (480p)
    case HD     // 1280x720 (720p)
    case FHD    // 1920x1080 (1080p)
    case _2K    // 2560x1440 (1440p)
    case _4K    // 3840x2160 (2160p)
    case _8K    // 7680x4320 (4320p)
    
    /// 根據影片尺寸轉成SizeType
    /// - Parameter size: CGSize
    init(size: CGSize) {
        
        let value = min(size.width, size.height)
        
        if value > 4300 { self = ._8K; return }
        if value > 2100 { self = ._4K; return }
        if value > 1400 { self = ._2K; return }
        if value > 1000 { self = .FHD; return }
        if value > 700 { self = .HD; return }
        self = .SD
    }
}

// MARK: - 公開屬性 (SizeType)
extension SizeType {
    
    /// 顯示文字
    var title: String {
        
        switch self {
        case .SD: return "SD"
        case .HD: return "HD"
        case .FHD: return "FHD"
        case ._2K: return "2K"
        case ._4K: return "4K"
        case ._8K: return "8K"
        }
    }
    
    /// 前景色
    var foregroundColor: Color { .white }
    
    /// 背景色
    var backgroundColor: Color {
        
        switch self {
        case .SD: return .gray
        case .HD: return .blue
        case .FHD: return .red
        case ._2K: return .blue
        case ._4K: return .brown
        case ._8K: return .indigo
        }
    }
}
