//
//  URL+.swift
//  Record WOW HC
//
//  Created by james bouker on 6/7/23.
//

import Foundation

extension URL {
    static func wowHCDefaultRecordingDIR() -> URL {
        var support = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        support = support.appendingPathComponent("WOW HC Screen Recorder", isDirectory: true)
        if !FileManager.default.fileExists(atPath: support.path) {
            try? FileManager.default.createDirectory(atPath: support.absoluteString, withIntermediateDirectories: true)
        }
        return support
    }
}
