//
//  VideoFavoriteViewModel.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/20.
//

import SwiftUI
import WWFileService

@Observable
final class VideoFavoriteViewModel {
    
    /// 顯示在「我的收藏」頁上的影片列表 (這裡的 items 不綁定特定資料夾，而是以 FavoriteStore 內所有 URL 為來源)
    var items: [VideoItem] = []
    
    @ObservationIgnored
    private let favoriteStore: FavoriteStoreService
    
    /// 建立收藏頁專用 ViewModel
    /// - Parameter favoriteStore: 用來讀寫收藏資料的服務物件
    init(favoriteStore: FavoriteStoreService) {
        self.favoriteStore = favoriteStore
    }
}

// MARK: - 公開API
extension VideoFavoriteViewModel {
    
    /// 重新載入收藏影片列表
    ///
    /// 從 `favoriteStore.favorite` 取得所有收藏的 URL，再併發讀取每個影片的 metadata，最後更新 `items`
    func reload() async {
        items = await favoriteItems()
    }
    
    /// 切換收藏頁上某個影片的收藏狀態
    /// - Parameter item: 要切換收藏狀態的影片
    ///
    /// 行為：
    /// 1. 找出對應的 URL。
    /// 2. 若已在 FavoriteStore 中則移除收藏，否則加入收藏
    /// 3. 呼叫 `save()` 將最新收藏狀態寫回 JSON 檔
    /// 4. 重新載入收藏列表，確保畫面與資料一致
    func toggleFavorite(_ item: VideoItem) {
        
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        let url = items[index].url
        
        if favoriteStore.contains(url) {
            favoriteStore.remove(url)
        } else {
            favoriteStore.add(url)
        }
        
        try? favoriteStore.save()
        
        Task {
            await reload()
        }
    }
}

// MARK: - 私有API
private extension VideoFavoriteViewModel {
    
    /// 從 FavoriteStore 取得所有收藏影片，並轉成完整的 VideoItem 列表
    ///
    /// 作法：
    /// 1. 取出 `favoriteStore.favorite.keys`（所有收藏的 URL）
    /// 2. 使用 `withThrowingTaskGroup` 併發對每個 URL 執行 `videoFavoriteTask(with:)`
    /// 3. 收集所有成功建立的 `VideoItem`，過濾掉失敗（nil）的項目
    /// 4. 最後依檔名排序，使列表穩定且可預期
    ///
    /// 若任意子任務拋出錯誤，整組會落入 catch，回傳空陣列
    func favoriteItems() async -> [VideoItem] {
        
        do {
            return try await withThrowingTaskGroup(of: VideoItem?.self) { group in
                
                var result: [VideoItem] = []
                
                for url in favoriteStore.favorite.keys {
                    group.addTask { [self] in await videoFavoriteTask(with: url) }
                }
                
                for try await videoItem in group {
                    if let videoItem { result.append(videoItem) }
                }
                
                return result.sorted { $0.fileName < $1.fileName }
            }
        } catch {
            return []
        }
    }
    
    /// 針對單一收藏 URL 建立對應的 VideoItem
    ///
    /// 會：
    /// 1. 使用 WWFileService 讀取影片資訊（長度、尺寸等）
    /// 2. 使用 WWFileService.fileItem(...) 讀取檔案 metadata（建立時間、大小）
    /// 3. 若兩者皆成功，組合成一個標記為已收藏的 VideoItem
    ///
    /// - Parameter url: 收藏影片的檔案 URL
    /// - Returns: 若成功建立，回傳 VideoItem；若檔案不存在或無法取得資訊，回傳 nil
    func videoFavoriteTask(with url: URL) async -> VideoItem? {
        
        guard let info = try? await WWFileService.videoInformation(for: url),
              let item = WWFileService.fileItem(at: url, allowedExtensions: Costant.allowedExtensions, skipsHiddenFiles: true)
        else {
            return nil
        }
        
        return .init(url: url, fileName: url.lastPathComponent, duration: info.durationSeconds, createdDate: item.createdDate, fileSize: item.fileSize, videoSize: info.size, isFavorite: true)
    }
}

