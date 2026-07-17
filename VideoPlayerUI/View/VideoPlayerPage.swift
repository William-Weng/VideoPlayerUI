//
//  VideoPlayerPage.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import SwiftUI
import WWSimpleVideoPlayerViewUI

/// 影片播放器頁面
struct VideoPlayerPage: View {

    @State var item: VideoItem      // 目前播放的影片項目
    @State var isAutoplay: Bool     // 是否自動播放
    
    @State private var showsChrome = true
    
    // 播放器外觀設定
    private let configure: WWSimpleVideoPlayerConfigure = .init(thumb: Image("bilibili"), mainColor: .mint, thumbnailStep: 5.0, thumbnailSize: .init(width: 240, height: 136))
    
    var body: some View {
        
        WWSimpleVideoPlayerViewUI<VideoItem>(source: $item, isAutoplay: $isAutoplay, configure: configure)
            .frame(maxWidth: .infinity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.container, edges: .top)
            .toolbar(showsChrome ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                toolBarTitleView
            }
            .toolbar(.hidden, for: .tabBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded { toggleChrome() }
            )
            .task {
                scheduleAutoHide()
            }.onDisappear {
                showsChrome = true
            }
    }
}

// MARK: - 私有子視圖
private extension VideoPlayerPage {
    
    /// 導航列中央顯示的標題
    @ToolbarContentBuilder
    var toolBarTitleView: some ToolbarContent {
        
        ToolbarItem(placement: .principal) {
            Text(item.fileName)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

private extension VideoPlayerPage {
    
    func toggleChrome() {
        showsChrome.toggle()
        if showsChrome { scheduleAutoHide() }
    }
    
    func scheduleAutoHide() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            withAnimation { showsChrome = false }
        }
    }
}
