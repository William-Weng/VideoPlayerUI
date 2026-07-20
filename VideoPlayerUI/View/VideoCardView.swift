//
//  VideoCardView.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/16.
//

import SwiftUI

/// 影片卡片元件
struct VideoCardView: View {

    let item: VideoItem         // 影片資料
    var onFavorite: () -> Void  // 點擊收藏按鈕時的動作
    
    var body: some View {
        
        VStack(spacing: 0) {
            topHeader
            Divider()
            bottomInfoBar
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 私有子視圖
private extension VideoCardView {
        
    /// 上方內容區塊，包含縮圖、檔名、檔案資訊與收藏按鈕
    var topHeader: some View {
        
        HStack(alignment: .top, spacing: 12) {
            
            VideoThumbnailView(url: item.url)
                .frame(width: 96, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            fileMetaView
            
            Spacer(minLength: 0)

            Button(action: onFavorite) {
                Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(item.isFavorite ? .red : .secondary)
                    .frame(width: 36, height: 36)
                    .background(Color(uiColor: .tertiarySystemBackground), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    /// 檔案資訊區塊，包含檔名與描述文字
    var fileMetaView: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            
            Text(item.fileName)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(fileMetaText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    /// 下方資訊列
    var bottomInfoBar: some View {
        
        HStack {
            Label("Player", systemImage: "play.fill")
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .foregroundStyle(.primary)
        .overlay(alignment: .bottomTrailing) {
            Text(item.sizeType.title)
                .font(.caption.bold())
                .foregroundStyle(item.sizeType.foregroundColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(item.sizeType.backgroundColor)
                )
                .offset(x: -8, y: -8)
        }
    }
}

// MARK: - 私有屬性
private extension VideoCardView {
    
    /// 組合檔案資訊文字
    var fileMetaText: String {
        
        let durationText = item.duration.map { $0.formattedDuration } ?? "未知長度"
        let dateText = item.createdDate.map { $0.formattedDate } ?? "未知日期"
        
        let sizeText: String = {
            guard let fileSize = item.fileSize else { return "未知大小" }
            return fileSize.byteCountFormat
        }()
        
        return "\(durationText) / \(sizeText)\n\(dateText)"
    }
}

