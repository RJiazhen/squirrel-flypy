//
//  FlypydzSingleCharCodeIndex.swift
//  Squirrel
//
//  Maintains an in-memory single-character code index parsed from flypydz.dict.yaml,
//  used by quick-add auto code generation to avoid repeated disk scans.
//

import Foundation


/// Parses `flypydz.dict.yaml` tab entries into a single-character-to-code map for quick-add hints.
final class FlypydzSingleCharCodeIndex {
  private var map: [String: String] = [:]
  private var loadedURL: URL?
  private var loadedModificationDate: Date?

  /// Returns the first loaded flypydz code for a single graphic character, or nil when missing.
  func code(for word: String) -> String? {
    guard word.count == 1 else { return nil }
    return map[word]
  }

  /// Reloads the index when the preferred URL changes or its modification timestamp changes.
  func ensureLoaded(preferringUser userURL: URL, sharedFallback: URL?) {
    let userPath = userURL.path(percentEncoded: false)
    let userExists = FileManager.default.fileExists(atPath: userPath)
    var chosen: URL?
    if userExists {
      chosen = userURL
    } else if let sharedFallback {
      let sharedPath = sharedFallback.path(percentEncoded: false)
      if FileManager.default.fileExists(atPath: sharedPath) {
        chosen = sharedFallback
      }
    }
    guard let url = chosen else {
      map = [:]
      loadedURL = nil
      loadedModificationDate = nil
      return
    }
    let attrs = try? FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
    let mdate = attrs?[.modificationDate] as? Date
    if loadedURL == url, let mdate, let loadedModificationDate, mdate == loadedModificationDate, !map.isEmpty {
      return
    }
    load(from: url, modificationDate: mdate)
  }

  /// Reads the dictionary file and fills `map` with the first code per single-character key.
  private func load(from url: URL, modificationDate: Date?) {
    map = [:]
    loadedURL = url
    loadedModificationDate = modificationDate
    guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else { return }
    for lineSub in text.split(separator: "\n", omittingEmptySubsequences: false) {
      let line = String(lineSub)
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.isEmpty { continue }
      if trimmed.hasPrefix("#") { continue }
      if trimmed == "---" || trimmed == "..." { continue }
      if trimmed.hasPrefix("name:") || trimmed.hasPrefix("version:") || trimmed.hasPrefix("sort:") { continue }
      guard let tabIdx = trimmed.firstIndex(of: "\t") else { continue }
      let word = String(trimmed[..<tabIdx])
      let codePart = trimmed[trimmed.index(after: tabIdx)...]
      let code = String(codePart).trimmingCharacters(in: .whitespacesAndNewlines)
      guard word.count == 1, !code.isEmpty else { continue }
      if map[word] == nil {
        map[word] = code
      }
    }
  }
}
