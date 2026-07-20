//
//  VideoPlayerPage.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import SwiftUI
import WWSimpleVideoPlayerViewUI
import WWFileService

/// 影片播放器頁面
struct VideoPlayerPage: View {

    /// 用來記住目前的自動隱藏任務 (下一次觸發時可先取消舊的，避免多個延遲任務同時存在)
    @State static var autoHideTask: Task<Void, Never>?
    
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
            .toolbarBackground(.white, for: .navigationBar)
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

// MARK: - 私有API
private extension VideoPlayerPage {
   
    /// 切換控制列顯示狀態
    /// - Parameter seconds: 若切到顯示狀態後，多久會自動隱藏
    func toggleChrome(with seconds: TimeInterval = 2.0) {
        
        showsChrome.toggle()

        if showsChrome {
            scheduleAutoHide(with: seconds)
        } else {
            Self.autoHideTask?.cancel()
            Self.autoHideTask = nil
        }
    }
    
    /// 延遲一段時間後自動隱藏控制列
    /// - Parameter seconds: 延遲秒數
    func scheduleAutoHide(with seconds: TimeInterval = 2.0) {
        
        Self.autoHideTask?.cancel()
        
        Self.autoHideTask = Task { @MainActor in
            
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch {
                return
            }
            
            guard !Task.isCancelled else { return }
            
            withAnimation {
                showsChrome = false
            }
        }
    }
}
