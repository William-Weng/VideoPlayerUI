//
//  FavoriteListPage.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import SwiftUI

// MARK: - Favorite Page
struct FavoriteListPage: View {

    @State var viewModel: VideoLibraryViewModel

    var body: some View {
        Group {
            if viewModel.favoriteItems.isEmpty {
                emptyItemView
            } else {
                itemView
            }
        }
        .navigationTitle("我的收藏")
    }
}

// MARK: 私有子視圖 (主要)
private extension FavoriteListPage {
    
    /// 空狀態畫面
    var emptyItemView: some View {
        
        ContentUnavailableView {
            Label("沒有收藏", systemImage: "heart.slash")
        } description: {
            Text("先到 Player 分頁把影片加入收藏")
        }
    }
    
    /// 影片列表畫面
    var itemView: some View {
        
        ScrollView {
            
            LazyVStack(spacing: 16) {
                ForEach(viewModel.favoriteItems) { item in
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
