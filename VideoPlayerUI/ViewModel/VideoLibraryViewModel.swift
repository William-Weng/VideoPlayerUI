//
//  VideoLibraryViewModel.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import SwiftUI
import WWFileService

/// 影片列表頁的資料與狀態管理
@Observable
final class VideoLibraryViewModel {
        
    var items: [VideoItem] = []                         // 目前顯示的影片項目
    var folders: [VideoFolder] = []                     // Documents 底下的子資料夾
    var selectedFolderURL: URL                          // 目前選取的資料夾URL
    
    @ObservationIgnored
    private let favoriteStore: FavoriteStoreService     // 收藏資料來源（跨資料夾的 URL -> Date），用來把全域收藏狀態映射到當前 `items` 上的 `isFavorite`
    
    @ObservationIgnored
    private var hasLoadedFavorites: Bool = false        // 是否已從磁碟載入過收藏資料 (用來避免在每次換資料夾時重複讀取 favorites.json)
    
    /// 建立影片列表頁的 ViewModel
    ///
    /// - Parameter favoriteStore: 用來讀取與更新收藏狀態的服務物件，會在載入 `items` 後被用來同步 `isFavorite`
    init(favoriteStore: FavoriteStoreService) {
        selectedFolderURL = Costant.rootFolder
        self.favoriteStore = favoriteStore
    }
}

// MARK: - 公開屬性
extension VideoLibraryViewModel {
    
    /// 目前選取的資料夾名稱
    var currentFolderPathText: String {
                
        if selectedFolderURL != Costant.rootFolder {
            return "\(Costant.rootFolder.lastPathComponent)/\(selectedFolderURL.lastPathComponent)"
        }
        
        return Costant.rootFolder.lastPathComponent
    }
    
    /// 目前畫面上顯示的資料夾路徑文字
    var selectedFolderName: String {
                
        if selectedFolderURL != Costant.rootFolder {
            return selectedFolderURL.lastPathComponent
        }

        return Costant.rootFolder.lastPathComponent
    }
    
    /// 目前所有已收藏的影片
    var favoriteItems: [VideoItem] {
        items.filter(\.isFavorite)
    }
}

// MARK: - 公開API
extension VideoLibraryViewModel {
        
    /// 切換影片收藏狀態
    /// - Parameter item: 要切換收藏的影片
    func toggleFavorite(_ item: VideoItem) {
        
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        let url = items[index].url
        
        if favoriteStore.contains(url) {
            favoriteStore.remove(url)
        } else {
            favoriteStore.add(url)
        }
        
        try? favoriteStore.save()
        syncFavoritesToItems()
    }
    
    /// 讀取 Documents 根目錄底下的影片
    func loadVideosFromDocumentsRoot() {
        loadVideo(from: Costant.rootFolder)
    }
    
    /// 重新整理資料夾與影片清單
    func refreshFoldersAndVideos() {
        
        loadFoldersFromDocuments()
        
        if selectedFolderURL == Costant.rootFolder {
            loadVideosFromDocumentsRoot()
        } else {
            reloadSelectedFolderIfNeeded()
        }
    }
    
    /// 讀取指定子資料夾底下的影片
    /// - Parameter folderName: 子資料夾名稱
    func loadVideosFromDocumentsSubfolder(named folderName: String) {
        let targetFolderURL = Costant.rootFolder.appendingPathComponent(folderName, isDirectory: true)
        loadVideo(from: targetFolderURL)
    }
}

// MARK: - 私有API
private extension VideoLibraryViewModel {
    
    /// 讀取 Documents 底下的子資料夾
    func loadFoldersFromDocuments() {
        
        do {
            let urls = try WWFileService.folderUrls(at: Costant.rootFolder, skipsHiddenFiles: true)
            folders = urls.map { VideoFolder(name: $0.lastPathComponent, url: $0) }
        } catch {
            folders = []
        }
    }
    
    /// 從指定資料夾讀取影片項目，並保留原本的收藏狀態
    /// - Parameters:
    ///   - folderURL: 要掃描的資料夾 URL
    ///   - oldItems: 先前的影片清單，用來延續收藏狀態
    /// - Returns: 新的影片項目陣列
    func loadVideoItems(at folderURL: URL, preserveFavoriteStateFrom oldItems: [VideoItem]) async -> [VideoItem] {
        
        let favoriteMap = Dictionary(uniqueKeysWithValues: oldItems.map { ($0.url.path, $0.isFavorite) } )
        
        do {
            let items = try WWFileService.fileItems(at: folderURL, allowedExtensions: Costant.allowedExtensions, skipsHiddenFiles: false)

            return try await withThrowingTaskGroup(of: VideoItem?.self) { group in
                
                var result: [VideoItem] = []
                
                for item in items {
                    group.addTask { [self] in await videoItemTask(with: item, favoriteMap: favoriteMap) }
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
    
    /// 重新載入目前選取的資料夾內容
    ///
    /// 行為順序：
    /// 1. 如果目前選取的資料夾仍存在，就重新載入該資料夾
    /// 2. 如果目前選取的資料夾已不存在，就切換到第一個資料夾
    /// 3. 如果沒有任何子資料夾，就回到 Documents 根目錄
    func reloadSelectedFolderIfNeeded() {
        
        if folders.contains(where: { $0.name == selectedFolderName }) {
            loadVideosFromDocumentsSubfolder(named: selectedFolderName)
        } else if let firstFolder = folders.first {
            loadVideosFromDocumentsSubfolder(named: firstFolder.name)
        } else {
            loadVideosFromDocumentsRoot()
        }
    }
    
    /// 針對單一檔案建立對應的 VideoItem
    /// - Parameters:
    ///   - item: WWFileService 回傳的檔案資訊物件
    ///   - favoriteMap: 以檔案路徑為 key 的「是否收藏」對應表
    /// - Returns: 若成功取得影片資訊就回傳 VideoItem，失敗則為 nil
    func videoItemTask(with item: FileServiceItem, favoriteMap: [String : Bool]) async -> VideoItem? {
                
        guard let info = try? await WWFileService.videoInformation(for: item.url) else { return nil }
        
        let isFavorite = favoriteMap[item.url.path] ?? false
        
        return .init(url: item.url, fileName: item.url.lastPathComponent, duration: info.durationSeconds, createdDate: item.createdDate, fileSize: item.fileSize, videoSize: info.size, isFavorite: isFavorite)
    }
    
    /// 從指定資料夾載入影片列表，並套用收藏狀態
    /// - Parameter folder: 要載入的資料夾 URL
    func loadVideo(from folder: URL) {
        
        selectedFolderURL = folder
        
        Task {
            loadFavoritesFromDiskIfNeeded()
            items = await loadVideoItems(at: folder, preserveFavoriteStateFrom: items)
            syncFavoritesToItems()
        }
    }
    
    /// 若尚未從磁碟載入過收藏資料，則讀取 favorites JSON 並更新內部狀態
    ///
    /// 這個方法會以 `hasLoadedFavorites` 作為防護，確保 `favoriteStore.load()` 只在第一次需要時被呼叫，避免在每次切換資料夾或重載列表時重複讀檔
    func loadFavoritesFromDiskIfNeeded() {
        
        if !hasLoadedFavorites {
            try? favoriteStore.load()
            hasLoadedFavorites = true
        }
    }
    
    /// 將 FavoriteStore 內的收藏狀態同步到目前的 `items` 上
    ///
    /// 行為：
    /// 1. 取得所有已收藏影片的 URL 集合
    /// 2. 針對當前 `items` 中每一個 `VideoItem`，檢查其 URL 是否在收藏集合內，並更新 `isFavorite` flag
    ///
    /// 這樣可以保證：
    /// - 當重新載入某個資料夾的影片列表時，收藏狀態會正確反映在 UI 上
    /// - 切換收藏（add/remove + save）之後，只要再次呼叫本方法，當前畫面的 `items[index].isFavorite` 就會與 FavoriteStoreState 一致
    func syncFavoritesToItems() {
        
        let favoriteURLs = Set(favoriteStore.favorite.keys)
        
        for index in items.indices {
            
            let url = items[index].url
            let isFavorite = favoriteURLs.contains(url)
            
            items[index].isFavorite = isFavorite
        }
    }
}
