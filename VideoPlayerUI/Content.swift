//
//  Content.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import SwiftUI

// MARK: - Root TabView
struct Content: View {

    @State private var selectedTab: MainTab = .videos
    @State private var itemViewModel: VideoLibraryViewModel
    @State private var favoriteViewModel: VideoFavoriteViewModel
    
    private let favoriteStore: FavoriteStoreService
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            NavigationStack {
                VideoListPage(viewModel: itemViewModel)
            }
            .tabItem {
                Label("Player", systemImage: "play.square")
            }
            .tag(MainTab.videos)

            NavigationStack {
                FavoriteListPage(viewModel: favoriteViewModel)
            }
            .tabItem {
                Label("Favorite", systemImage: "heart")
            }
            .tag(MainTab.favorites)
        }
        .tint(.accentColor)
        .environment(favoriteStore)
    }
    
    init() {
        favoriteStore = FavoriteStoreService(baseUrl: Constant.rootFolder, filename: Constant.favoriteFileName)
        _itemViewModel = .init(initialValue: .init(favoriteStore: favoriteStore))
        _favoriteViewModel = .init(initialValue: .init(favoriteStore: favoriteStore))
    }
}

#Preview {
    Content()
}

