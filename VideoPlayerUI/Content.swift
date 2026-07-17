//
//  Content.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import SwiftUI

// MARK: - Root TabView
struct Content: View {

    @State private var viewModel = VideoLibraryViewModel()
    @State private var selectedTab: MainTab = .videos

    var body: some View {
        
        TabView(selection: $selectedTab) {
            NavigationStack {
                VideoListPage(viewModel: viewModel)
            }
            .tabItem {
                Label("Player", systemImage: "play.square")
            }
            .tag(MainTab.videos)

            NavigationStack {
                FavoriteListPage(viewModel: viewModel)
            }
            .tabItem {
                Label("Favorite", systemImage: "heart")
            }
            .tag(MainTab.favorites)
        }
        .tint(.accentColor)
        .task {
            print(URL.documentsDirectory)
        }
    }
}

#Preview {
    Content()
}

