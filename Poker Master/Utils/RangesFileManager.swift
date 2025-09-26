//
//  RangesFileManager.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/4/25.
//

import Foundation
class RangesFileManager {
    
    static func getRangesFileURL() -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docDir.appendingPathComponent("ranges.json")
    }
    
    static func loadInitialRangesIfNeeded() {
        let fileManager = FileManager.default
        let url = getRangesFileURL()
        
        // Check if the file already exists in the Documents directory
        if !fileManager.fileExists(atPath: url.path) {
            // If not, copy it from the app's bundle
            if let bundleURL = Bundle.main.url(forResource: "Ranges", withExtension: "json"),
               let data = try? Data(contentsOf: bundleURL) {
                do {
                    try data.write(to: url)  // Save the file to the Documents directory
                    print("ranges.json copied to Documents directory")
                } catch {
                    print("Failed to write file to Documents directory: \(error)")
                }
            }
        }
    }

    static func loadRanges() -> [String: [String: [String]]] {
        let url = getRangesFileURL()
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: [String: [String]]].self, from: data) {
            return decoded
        }
        return [:]  // Return an empty dictionary if loading fails
    }

    static func saveRanges(for baseKey: String, size: String, raiseRanges: [String], callRanges: [String]) {
        var ranges = loadRanges() // Load existing data
        
        // Replace only the call and raise entries
        ranges[size]?["\(baseKey)_raise"] = raiseRanges
        ranges[size]?["\(baseKey)_call"] = callRanges
        
        print("Saving ranges: \(baseKey)_raise and \(baseKey)_call")
        
        let url = getRangesFileURL()
        
        do {
            let data = try JSONEncoder().encode(ranges)
            try data.write(to: url, options: .atomic)
            print("✅ Successfully saved raise & call ranges for \(baseKey)")
        } catch {
            print("❌ Error saving ranges: \(error)")
        }
    }
    
    static func reloadRangesFromBundle() {
        let destinationURL = getRangesFileURL()
        
        if let bundleURL = Bundle.main.url(forResource: "Ranges", withExtension: "json"),
           let data = try? Data(contentsOf: bundleURL) {
            do {
                try data.write(to: destinationURL, options: .atomic)
                print("✅ Successfully reloaded ranges from Xcode bundle into memory.")
            } catch {
                print("❌ Failed to reload ranges: \(error)")
            }
        } else {
            print("❌ Could not find Ranges.json in bundle.")
        }
    }

}

