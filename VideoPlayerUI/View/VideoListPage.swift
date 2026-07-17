//
//  VideoListPage.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import SwiftUI

/// 影片列表頁
struct VideoListPage: View {
    
    @State var viewModel: VideoLibraryViewModel
    
    var body: some View {
        
        Group {
            if viewModel.items.isEmpty {
                emptyItemView
            } else {
                itemView
            }
        }
        .navigationTitle("影片列表")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            resetItem
        }
        .safeAreaInset(edge: .top) {
            folderSelectorBar
        }
        .onAppear {
            if viewModel.folders.isEmpty && viewModel.items.isEmpty {
                viewModel.refreshFoldersAndVideos()
            }
        }
    }
}

// MARK: 私有子視圖 (主要)
private extension VideoListPage {
    
    /// 空狀態畫面
    var emptyItemView: some View {
        
        ContentUnavailableView {
            Label("沒有影片", systemImage: "film.stack")
        } description: {
            Text(viewModel.folders.isEmpty ? "Documents 下目前沒有子資料夾或影片" : "目前資料夾沒有影片")
        } actions: {
            Button("重新整理") {
                viewModel.refreshFoldersAndVideos()
            }
        }
    }
      
    /// 影片列表畫面
    var itemView: some View {
        
        ScrollView {
            
            LazyVStack(spacing: 16) {
                ForEach(viewModel.items) {
                    navigationLinkView(item: $0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    /// 上方資料夾選擇區
    var folderSelectorBar: some View {
        
        VStack(alignment: .leading, spacing: 14) {
            folderTitleView
            folderChipScrollView
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.bar)
    }
    
    /// 右上角重新整理按鈕
    var resetItem: some ToolbarContent {
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.refreshFoldersAndVideos()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
}

// MARK: 私有子視圖 (次要)
private extension VideoListPage {
    
    /// 目前路徑標題
    var folderTitleView: some View {
        
        HStack {
            Label(viewModel.currentFolderPathText, systemImage: "folder")
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
    }
    
    /// 資料夾 chip 的水平捲動區
    var folderChipScrollView: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            
            HStack(spacing: 10) {
                
                folderChip(title: viewModel.rootFolder.lastPathComponent, isSelected: viewModel.selectedFolderName.isEmpty, action: {
                    viewModel.loadVideosFromDocumentsRoot()
                })
                
                ForEach(viewModel.folders) { folder in
                    folderChip(title: folder.name, isSelected: viewModel.selectedFolderName == folder.name, action: {
                        viewModel.loadVideosFromDocumentsSubfolder(named: folder.name)
                    })
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: 私有子視圖 (次要)
private extension VideoListPage {
    
    /// 單一資料夾 chip
    /// - Parameters:
    ///   - title: 顯示文字
    ///   - isSelected: 是否為目前選取
    ///   - action: 點擊後執行的動作
    func folderChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        
        Button(action: action) {
            
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? Color.teal : Color(uiColor: .secondarySystemBackground))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.primary.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
    
    /// 影片卡片的導航入口
    /// - Parameter item: 影片項目
    func navigationLinkView(item: VideoItem) -> some View {
        
        NavigationLink {
            VideoPlayerPage(item: item, isAutoplay: false)
                .toolbar(.hidden, for: .tabBar)
        } label: {
            VideoCardView(item: item, onFavorite: {
                viewModel.toggleFavorite(item)
            })
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VideoListPage(viewModel: .init())
}
