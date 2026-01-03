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
                    Log.ranges.info("ranges.json copied to Documents directory")
                } catch {
                    Log.ranges.error("Failed to copy ranges.json to Documents directory: \(error, privacy: .private)")
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
        
        let url = getRangesFileURL()
        
        do {
            let data = try JSONEncoder().encode(ranges)
            try data.write(to: url, options: .atomic)
            Log.ranges.info("Saved raise & call ranges for \(baseKey)")
        } catch {
            Log.ranges.error("❌ Failed to save ranges for \(baseKey): \(error, privacy: .private)")
        }
    }
    
    static func reloadRangesFromBundle() {
        let destinationURL = getRangesFileURL()
        
        if let bundleURL = Bundle.main.url(forResource: "Ranges", withExtension: "json"),
           let data = try? Data(contentsOf: bundleURL) {
            do {
                try data.write(to: destinationURL, options: .atomic)
                Log.ranges.info("Reloaded ranges from Xcode bundle into memory.")
            } catch {
                Log.ranges.error("❌ Failed to reload ranges: \(error, privacy: .private)")
            }
        } else {
            Log.ranges.error("❌ Could not find Ranges.json in bundle.")
        }
    }

}

