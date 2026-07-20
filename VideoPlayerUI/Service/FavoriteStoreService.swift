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
    
    private(set) var state: FavoriteStoreState  // 目前記憶體中的收藏狀態
    
    /// 建立收藏服務
    /// - Parameter fileUrl: 收藏資料要讀寫的檔案 URL
    init(fileUrl: URL) {
        self.fileUrl = fileUrl
        self.state = FavoriteStoreState()
    }
}

extension FavoriteStoreService {
    
    /// 對外暴露唯讀的收藏清單（URL -> Date），若需要修改，請改用 `add` / `remove` 等方法。
    var favorite: [URL: Date] {
        state.favorite
    }
}

extension FavoriteStoreService {
    
    /// 新增一筆收藏影片
    /// - Parameters:
    ///   - url: 要加入收藏的影片 URL
    ///   - date: 收藏時間（預設為現在）
    func add(_ url: URL, date: Date = .now) {
        state.favorite[url] = date
    }
    
    /// 移除一筆收藏影片
    /// - Parameter url: 要取消收藏的影片 URL
    func remove(_ url: URL) {
        state.favorite.removeValue(forKey: url)
    }

    /// 檢查指定影片是否已在收藏清單中
    /// - Parameter url: 影片 URL
    /// - Returns: 若已收藏回傳 `true`，否則為 `false`
    func contains(_ url: URL) -> Bool {
        state.favorite[url] != nil
    }
    
    /// 從指定檔案載入收藏狀態
    ///
    /// 會把 `fileUrl` 所指向的 JSON 檔讀入並 decode 成 `FavoriteStoreState`，取代目前記憶體中的 `state`
    /// - Throws: 若檔案不存在、內容格式錯誤或讀取失敗，則拋出對應錯誤
    func load() throws {
        state = try WWFileService.read(FavoriteStoreState.self, from: fileUrl)
    }

    /// 將目前收藏狀態儲存到指定檔案
    ///
    /// 會把 `state` 編碼成 JSON 資料，並寫入 `fileUrl` 指定的位置
    /// 一般在使用者切換收藏（add/remove）後呼叫，以確保重啟 app 時收藏仍然存在
    /// - Throws: 若編碼或寫入檔案失敗，則拋出對應錯誤
    func save() throws {
        
        let data = try JSONEncoder().encode(state)
        try WWFileService.write(data, to: fileUrl)
    }
}
