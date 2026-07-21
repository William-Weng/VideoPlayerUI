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

// MARK: - JSONEncoder
extension JSONEncoder {
    
    /// 建立使用 ISO8601 日期格式的 JSONEncoder
    /// - Parameter outputFormatting: JSON 輸出格式，預設為 prettyPrinted + sortedKeys
    /// - Returns: 已設定完成的 JSONEncoder
    static func iso8601(outputFormatting: OutputFormatting = [.prettyPrinted, .sortedKeys]) -> JSONEncoder {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
        encoder.dateEncodingStrategy = .iso8601
        
        return encoder
    }
}

// MARK: - JSONDecoder
extension JSONDecoder {
    
    /// 建立使用 ISO8601 日期格式的 JSONDecoder
    /// - Returns: 已設定完成的 JSONDecoder
    static func iso8601() -> JSONDecoder {
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return decoder
    }
}

// MARK: - TimeInterval
extension URL {
    
    /// 回傳目前 URL 相對於指定 baseURL 的相對路徑
    ///
    /// 例如：
    /// - baseURL = /Users/me/Documents
    /// - self    = /Users/me/Documents/Anime/Demo.mp4
    /// - 回傳值  = "Anime/Demo.mp4"
    ///
    /// - Parameter baseURL: 用來當作比較基準的根路徑
    /// - Returns: 相對於 baseURL 的路徑字串；如果目前 URL 不在 baseURL 之下，則回傳 nil
    func relativePath(from baseURL: URL) -> String? {
        
        let basePath = baseURL.standardizedFileURL.path
        let fullPath = standardizedFileURL.path
        
        guard fullPath.hasPrefix(basePath + "/") else { return nil }
        return String(fullPath.dropFirst(basePath.count + 1))
    }
}
