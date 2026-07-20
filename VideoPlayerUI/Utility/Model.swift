//
//  Model.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import Foundation
import WWSimpleVideoPlayerViewUI

/// 影片項目資料
struct VideoItem: WWSimpleVideoPlayerDataSource {
    
    let id: UUID = .init()  // 唯一識別碼
    
    let url: URL
    let fileName: String
    let duration: TimeInterval?
    let createdDate: Date?
    let fileSize: Int64?
    let videoSize: CGSize
    
    var isFavorite: Bool
    
    /// 建立影片項目
    /// - Parameters:
    ///   - url: 影片檔案 URL
    ///   - fileName: 影片檔名
    ///   - duration: 影片長度，單位為秒
    ///   - createdDate: 建立日期
    ///   - fileSize: 檔案大小，單位為 bytes
    ///   - fileSize: 影片尺寸，單位為 pixal
    ///   - isFavorite: 是否已收藏
    init(url: URL, fileName: String, duration: TimeInterval?, createdDate: Date?, fileSize: Int64?, videoSize: CGSize, isFavorite: Bool) {
        self.url = url
        self.fileName = fileName
        self.duration = duration
        self.createdDate = createdDate
        self.fileSize = fileSize
        self.videoSize = videoSize
        self.isFavorite = isFavorite
    }
}

/// 影片資料夾資訊
struct VideoFolder: Identifiable, Hashable {
    
    let id = UUID()     // 唯一識別碼
    
    let name: String    // 資料夾名稱
    let url: URL        // 資料夾 URL
}

/// 收藏資料的純狀態模型
///
/// 這個 struct 專門負責「收藏事實」的持久化結構，不帶任何觀察或 UI 邏輯，方便用 Codable 直接編解碼成 JSON。
/// key 為影片的 `URL`，value 為加入收藏的時間。
struct FavoriteStoreState: Codable {
    
    var favorite: [URL: Date] = [:]
}

// MARK: - 公開屬性 (VideoItem)
extension VideoItem {
    
    /// 影片的尺寸格式
    var sizeType: SizeType {
        .init(size: videoSize)
    }
}
