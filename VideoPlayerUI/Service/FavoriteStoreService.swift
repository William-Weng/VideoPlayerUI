//
//  FavoriteStoreService.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/20.
//

import Foundation
import SwiftUI
import WWFileService

/// 管理影片收藏狀態的服務物件（可被 SwiftUI 觀察）
///
/// - 負責：
///   1. 以 `FavoriteStoreState` 表示收藏資料
///   2. 從指定檔案路徑載入 / 儲存收藏 JSON
///   3. 提供簡潔的收藏操作 API（add/remove/contains）
///
/// - 設計重點：
///   - `FavoriteStoreState` 保持純 Codable，避免 Observation 內部欄位污染 JSON
///   - `FavoriteStoreService` 以 `@Observable` 提供 SwiftUI 自動刷新能力
@Observable
final class FavoriteStoreService {
    
    private let fileUrl: URL
    private let baseUrl: URL
    
    private(set) var state: FavoriteStoreState  // 目前記憶體中的收藏狀態
    
    /// 建立收藏服務
    /// - Parameters:
    ///   - baseUrl: 收藏影片的共同根目錄，預設為 Documents
    ///   - filename: 記錄的JSON檔案名稱
    init(baseUrl: URL, filename: String) {
        self.baseUrl = baseUrl
        self.fileUrl = baseUrl.appendingPathComponent(filename)
        self.state = .init()
    }
}

extension FavoriteStoreService {
    
    /// 對外暴露唯讀的收藏清單（影片 URL -> Date）
    /// 內部雖然以相對路徑儲存，但這裡會轉回完整 URL，方便外部使用。
    var favorite: [URL: Date] {
        
        Dictionary(
            uniqueKeysWithValues: state.favorite.map { relativePath, date in
                (baseUrl.appending(path: relativePath), date)
            }
        )
    }
}

// MARK: - 公開API
extension FavoriteStoreService {
    
    /// 新增一筆收藏影片
    /// - Parameters:
    ///   - url: 要加入收藏的影片 URL
    ///   - date: 收藏時間（預設為現在）
    func add(_ url: URL, date: Date = .now) {
        
        guard let relativePath = url.relativePath(from: baseUrl) else { return }
        state.favorite[relativePath] = date
    }
    
    /// 移除一筆收藏影片
    /// - Parameter url: 要取消收藏的影片 URL
    func remove(_ url: URL) {
        
        guard let relativePath = url.relativePath(from: baseUrl) else { return }
        state.favorite.removeValue(forKey: relativePath)
    }

    /// 檢查指定影片是否已在收藏清單中
    /// - Parameter url: 影片 URL
    /// - Returns: 若已收藏回傳 `true`，否則為 `false`
    func contains(_ url: URL) -> Bool {
        guard let relativePath = url.relativePath(from: baseUrl) else { return false }
        return state.favorite[relativePath] != nil
    }
    
    /// 從指定檔案載入收藏狀態
    ///
    /// 會把 `fileUrl` 所指向的 JSON 檔讀入並 decode 成 `FavoriteStoreState`，
    /// 取代目前記憶體中的 `state`
    /// - Throws: 若檔案不存在、內容格式錯誤或讀取失敗，則拋出對應錯誤
    func load() throws {
        
        let data = try Data(contentsOf: fileUrl)
        let decoder = JSONDecoder.iso8601()
        
        state = try decoder.decode(FavoriteStoreState.self, from: data)
    }
    
    /// 將目前收藏狀態儲存到指定檔案
    ///
    /// 會把 `state` 編碼成 JSON 資料，並寫入 `fileUrl` 指定的位置，JSON 內只會保存相對路徑，不會存完整絕對路徑；一般在使用者切換收藏（add/remove）後呼叫，以確保重啟 app 時收藏仍然存在。
    /// - Throws: 若編碼或寫入檔案失敗，則拋出對應錯誤
    func save() throws {
        
        let encoder = JSONEncoder.iso8601()
        let data = try encoder.encode(state)
        
        try WWFileService.write(data, to: fileUrl)
    }
}

extension JSONDecoder {
    
    static func iso8601(outputFormatting: JSONEncoder.OutputFormatting = [.prettyPrinted, .sortedKeys]) {
        
        let encoder = JSONEncoder()
        
        encoder.outputFormatting = outputFormatting
        encoder.dateEncodingStrategy = .iso8601
    }
}

//// MARK: - 私有API
private extension FavoriteStoreService {
    
    /// 將完整影片 URL 轉成相對於 `baseUrl` 的路徑字串。
    ///
    /// 例如：
    /// `/Documents/Anime/Demo.mp4` -> `Anime/Demo.mp4`
    ///
    /// 若 URL 不在 `baseUrl` 底下，回傳 `nil`。
    func relativePath(from url: URL) -> String? {
        
        let basePath = baseUrl.standardizedFileURL.path
        let fullPath = url.standardizedFileURL.path
        
        guard fullPath.hasPrefix(basePath + "/") else { return nil }
        return String(fullPath.dropFirst(basePath.count + 1))
    }
}
