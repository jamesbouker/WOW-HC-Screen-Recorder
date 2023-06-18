//
//  Codable+.swift
//  WOW HC Screen Recorder
//
//  Created by james bouker on 6/17/23.
//

import Foundation

extension Encodable {
    func save(to filename: String) {
        let documentsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let url = documentsDirectory.appendingPathComponent(filename)
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url)
    }
}

extension Decodable {
    static func saved<T: Decodable>(at filename: String) -> T? {
        let documentsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let url = documentsDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
