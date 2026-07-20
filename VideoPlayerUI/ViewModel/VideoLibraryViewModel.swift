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
    
    @ObservationIgnored
    let rootFolder: URL = .documentsDirectory           // Documents 根目錄
    
    var items: [VideoItem] = []                         // 目前顯示的影片項目
    var folders: [VideoFolder] = []                     // Documents 底下的子資料夾
    var selectedFolderURL: URL                          // 目前選取的資料夾URL
    
    // 允許掃描的影片副檔名
    @ObservationIgnored
    private let allowedExtensions: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv"]
    
    init() {
        selectedFolderURL = rootFolder
    }
}

// MARK: - 公開屬性
extension VideoLibraryViewModel {
    
    /// 目前選取的資料夾名稱
    var currentFolderPathText: String {
                
        if selectedFolderURL != rootFolder {
            return "\(rootFolder.lastPathComponent)/\(selectedFolderURL.lastPathComponent)"
        }
        
        return rootFolder.lastPathComponent
    }
    
    /// 目前畫面上顯示的資料夾路徑文字
    var selectedFolderName: String {
                
        if selectedFolderURL != rootFolder {
            return selectedFolderURL.lastPathComponent
        }

        return rootFolder.lastPathComponent
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
        items[index].isFavorite.toggle()
    }
    
    /// 讀取 Documents 根目錄底下的影片
    func loadVideosFromDocumentsRoot() {
        
        selectedFolderURL = rootFolder
        
        Task {
            items = await loadVideoItems(at: rootFolder, preserveFavoriteStateFrom: items)
        }
    }
    
    /// 重新整理資料夾與影片清單
    func refreshFoldersAndVideos() {
        
        loadFoldersFromDocuments()
        
        if selectedFolderURL == rootFolder {
            loadVideosFromDocumentsRoot()
        } else {
            reloadSelectedFolderIfNeeded()
        }
    }
    
    /// 讀取指定子資料夾底下的影片
    /// - Parameter folderName: 子資料夾名稱
    func loadVideosFromDocumentsSubfolder(named folderName: String) {
        
        let targetFolderURL = rootFolder.appendingPathComponent(folderName, isDirectory: true)
        selectedFolderURL = targetFolderURL
        
        Task {
            items = await loadVideoItems(at: targetFolderURL, preserveFavoriteStateFrom: items)
        }
    }
}

// MARK: - 私有API
private extension VideoLibraryViewModel {
    
    /// 讀取 Documents 底下的子資料夾
    func loadFoldersFromDocuments() {
        
        do {
            let urls = try WWFileService.folderUrls(at: rootFolder, skipsHiddenFiles: true)
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
            let items = try WWFileService.fileItems(at: folderURL, allowedExtensions: allowedExtensions, skipsHiddenFiles: false)

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
        
        let info = try? await WWFileService.videoInformation(for: item.url)
        let isFavorite = favoriteMap[item.url.path] ?? false
        
        guard let info else { return nil }
        
        return .init(url: item.url, fileName: item.url.lastPathComponent, duration: info.durationSeconds, createdDate: item.createdDate, fileSize: item.fileSize, videoSize: info.size, isFavorite: isFavorite)
    }
}
