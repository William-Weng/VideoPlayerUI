//
//  Constant.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/17.
//

import SwiftUI

/// 常用常數
enum Constant {
    
    // 允許掃描的影片副檔名
    static let allowedExtensions: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv"]
    
    // Documents 根目錄
    static let rootFolder: URL = .documentsDirectory
    
    // 記錄書籤的JSON檔案名稱
    static let favoriteFileName = "Favorites.json"
    
    // 取得在第幾秒取得縮圖
    static let thumbnailDurtion: TimeInterval = 10.0
}

/// 主畫面分頁
enum MainTab: Hashable {
    case videos     // 影片列表分頁
    case favorites  // 收藏列表分頁
}

/// 影片尺寸分類
enum SizeType: Hashable {
    
    case SD         // 720x480 (480p)
    case HD         // 1280x720 (720p)
    case FHD        // 1920x1080 (1080p)
    case `2K`       // 2560x1440 (1440p)
    case `4K`       // 3840x2160 (2160p)
    case `8K`       // 7680x4320 (4320p)
    
    /// 根據影片尺寸轉成SizeType
    /// - Parameter size: CGSize
    init(size: CGSize) {
        
        let value = min(size.width, size.height)
        
        if value > 4300 { self = .`8K`; return }
        if value > 2100 { self = .`2K`; return }
        if value > 1400 { self = .`2K`; return }
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
        case .`2K`: return "2K"
        case .`4K`: return "4K"
        case .`8K`: return "8K"
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
        case .`2K`: return .blue
        case .`4K`: return .brown
        case .`8K`: return .indigo
        }
    }
}
