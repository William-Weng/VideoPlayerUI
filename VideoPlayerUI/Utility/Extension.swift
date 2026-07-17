//
//  Extension.swift
//  VideoPlayerUI
//
//  Created by William.Weng on 2026/7/17.
//

import Foundation

// MARK: - Int64
extension Int64 {
    
    /// 格式化檔案大小
    /// - Returns: 檔案大小字串，例如 `352 KB` 或 `1 MB`
    var byteCountFormat: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

// MARK: - Date
extension Date {
    
    /// 格式化日期時間
    /// - Returns: 日期時間字串 (例如：`2026/7/17 13:58`)
    var formattedDate: String {
        formatted(date: .numeric, time: .shortened)
    }
}

// MARK: - TimeInterval
extension TimeInterval {
    
    /// 將秒數格式化成影片常見時間字串
    ///
    /// 例如：
    /// - `75`  -> `1:15`
    /// - `3661` -> `1:01:01`
    var formattedDuration: String {
        
        let total = max(0, Int(self.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
