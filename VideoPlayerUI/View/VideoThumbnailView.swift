//
//  VideoThumbnailView.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import SwiftUI
import WWFileService

/// 影片縮圖檢視元件 (會根據影片 URL 非同步載入縮圖，載入完成前顯示 placeholder)
struct VideoThumbnailView: View {
    
    let url: URL                        // 影片的 URL
    
    @State private var image: UIImage?  // 目前載入完成的縮圖
    
    var body: some View {
        
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray.opacity(0.18))
                    .overlay { ProgressView() }
            }
        }
        .task(id: url) {
            image = await VideoThumbnailService.shared.thumbnail(for: url, at: 10.0)
        }
    }
}
