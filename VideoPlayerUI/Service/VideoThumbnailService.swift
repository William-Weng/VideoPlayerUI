//
//  VideoThumbnailService.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import UIKit
import WWFileService

/// 影片縮圖服務，使用 Task 快取避免重複請求
actor VideoThumbnailService {
    
    static let shared = VideoThumbnailService()
    
    private var cache: [URL: Entry] = [:]   // 以影片 URL 為 key 的快取

    /// 取得指定時間點的影片縮圖 (先檢查快取是否已有紀錄)
    /// - Parameters:
    ///   - url: 影片的 URL
    ///   - seconds: 要擷取的時間（秒）
    ///   - maximumSize: 縮圖的最大尺寸
    /// - Returns: 對應時間點的縮圖（可能為 nil）
    func thumbnail(for url: URL, at seconds: Double, maximumSize: CGSize = .init(width: 480, height: 270)) async -> UIImage? {
        
        if let entry = cache[url] {
            
            switch entry {
            case .ready(let image): return image
            case .failed(_): return nil
            case .inProgress(let task):
                do {
                    return try await task.value
                } catch {
                    cache[url] = .failed(error)
                    return nil
                }
            }
        }
        
        let task = Task { () throws -> UIImage in
            try await WWFileService.videoThumbnail(for: url, at: .seconds(seconds), maximumSize: maximumSize)
        }
        
        cache[url] = .inProgress(task)
        
        do {
            let image = try await task.value
            cache[url] = .ready(image)
            return image
        } catch {
            cache[url] = .failed(error)
            return nil
        }
    }
}

// MARK: - 私有 enum
private extension VideoThumbnailService {
    
    /// 快取項目的狀態
    enum Entry {
        case inProgress(Task<UIImage, Error>)   // 縮圖生成中（尚未完成的 Task）
        case ready(UIImage?)                    // 已完成縮圖（成功或 nil）
        case failed(Error)                      // 已知失敗（保留錯誤資訊）
    }
}
