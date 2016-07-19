//
//  SRPath.swift
//  SRPath
//
//  Created by Seorenn (Heeseung Seo)
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

import Foundation

private extension NSURL {
  private var isRootDirectory: Bool {
    return self.path! == "/"
  }
}

private extension String {
  private var firstCharacter: Character {
    return self[startIndex]
  }
  private var lastCharacter: Character {
    return self[index(before: endIndex)]
  }
  private var safePathString: String {
    if characters.count <= 0 { return self }
    if lastCharacter == "/" {
      let toIndex = index(before: index(before: endIndex))
      return self[startIndex...toIndex]
    } else {
      return self
    }
  }
  
  private func stringBackwardBefore(character: Character) -> String {
    if characters.count <= 0 { return self }
    
    var i = index(before: endIndex)
    while i >= startIndex {
      print("index: \(i)")
      if self[i] == character {
        let toIndex = index(after: i)
        return self[toIndex..<endIndex]
      }
      if i > startIndex { i = index(before: i) }
      else { break }
    }
    return ""
  }
  private func stringBackwardRemovedBefore(character: Character) -> String {
    if characters.count <= 0 { return self }
    var i = index(before: endIndex)
    while i >= startIndex {
      if self[i] == character {
        return self[startIndex..<i]
      }
      if i > startIndex { i = index(before: i) }
      else { break }
    }
    return self
  }
}

private extension Double {
  private var firstDecisionString: String {
    let fraction = self - Double(Int(self))
    if fraction >= 0.1 {
      return String(format: "%.1f", self)
    } else {
      return String(format: "%.0f", self)
    }
  }
}

func HumanReadableFileSize(size: Int64) -> String {
  if size < 1000 { return "\(size)B" }
  
  let fSize = Double(size)
  
  let kiloBytes = fSize / 1000
  if kiloBytes < 1000 {
    return kiloBytes.firstDecisionString + "KB"
  }
  
  let megaBytes = kiloBytes / 1000
  if megaBytes < 1000 {
    return megaBytes.firstDecisionString + "MB"
  }
  
  let gigaBytes = megaBytes / 1000
  if gigaBytes < 1000 {
    return gigaBytes.firstDecisionString + "GB"
  }
  
  let teraBytes = gigaBytes / 1000
  return teraBytes.firstDecisionString + "TB"
}

public struct SRPath : Equatable, CustomStringConvertible, CustomDebugStringConvertible {
  public let string: String
  public var URL: NSURL { return NSURL(fileURLWithPath: self.string) }

  public init(_ URL: NSURL) {
    self.string = URL.path!
  }
  
  public init(_ pathString: String) {
    self.string = pathString.safePathString
  }
  
  public init(_ path: SRPath) {
    self.init(path.string)
  }
  
  public var contents: [SRPath] {
    guard isDirectory == true else {
      return [SRPath]()
    }
    
    do {
      let pathStrings = try FileManager.default.contentsOfDirectory(atPath: string)
      let result: [SRPath] = pathStrings.map {
          return self + $0
      }
      return result
    } catch {
      return [SRPath]()
    }
  }
  
  public var exists: Bool {
    return FileManager.default.fileExists(atPath: string)
  }
  
  public var isDirectory: Bool {
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: string, isDirectory: &isDir) {
      return isDir.boolValue
    } else {
      return false
    }
  }
  
  public var isFile: Bool {
    return !self.isDirectory
  }
  
  public var isHidden: Bool {
    return self.name.firstCharacter == Character(".")
  }
  
  public var attributes: [FileAttributeKey : AnyObject]? {
    // Directory has no size
    guard self.exists else { return nil }
    
    return try! FileManager.default.attributesOfItem(atPath: string)
  }
  
  public var size: Int64? {
    guard self.isFile else { return nil }
    guard let attrs = attributes else { return nil }
    
    return attrs[FileAttributeKey.size]?.longLongValue
  }
  
  public var modificationDate: NSDate? {
    guard self.isFile else { return nil }
    guard let attrs = self.attributes else { return nil }
    
    let date = attrs[FileAttributeKey.modificationDate] as! NSDate
    return date
  }
  
  public var creationDate: NSDate? {
    guard self.isFile else { return nil }
    guard let attrs = self.attributes else { return nil }
    
    let date = attrs[FileAttributeKey.creationDate] as! NSDate
    return date
  }
  
  public var humanReadableSize: String? {
    guard let size = self.size else { return nil }
    
    return HumanReadableFileSize(size: size)
  }
  
  public var files: [SRPath] {
    return self.contents.filter({$0.isFile})
  }
  
  public var directories: [SRPath] {
    return self.contents.filter({$0.isDirectory})
  }
  
  public var name: String {
    return self.string.stringBackwardBefore(character: "/")
  }
  
  public var nameWithoutExtension: String {
    let n = self.name.stringBackwardRemovedBefore(character: ".")
    if n.isEmpty { return name }  // case naming hidden file
    
    return n
  }
  
  public var parentPathString: String {
    return self.string.stringBackwardRemovedBefore(character: "/")
  }
  public var parentPath: SRPath? {
    if self.string == "/" || self.string == "" { return nil }
    return SRPath(self.parentPathString)
  }
  
  public var extensionName: String {
    return self.name.stringBackwardBefore(character: ".")
  }
  
  public func trash() -> Bool {
#if os(iOS)
    return false
#else
    do {
      try FileManager.default.trashItem(at: self.URL as URL, resultingItemURL: nil)
    } catch {
      return false
    }

    return true
#endif
  }
  
  // move self to some directory
  public func moveTo(path: SRPath) -> SRPath? {
    guard path.isDirectory else { return nil }
    
    let destinationPath = path + self.name
    
    do {
      try FileManager.default.moveItem(atPath: self.string, toPath: destinationPath.string)
      return destinationPath
    } catch {
      return nil
    }
  }
  
  public func rename(name: String) -> SRPath? {
    let newPath: SRPath
    
    if let parentPath = self.parentPath {
      newPath = parentPath + name
    } else {
      newPath = SRPath("/" + name)
    }

    do {
      try FileManager.default.moveItem(atPath: self.string, toPath: newPath.string)
      return newPath
    } catch {
      return nil
    }
  }
  
  public func copy(toPath: SRPath) -> Bool {
    guard exists && isFile else { return false }
    guard FileManager.default.isReadableFile(atPath: string) else { return false }

    do {
      try FileManager.default.copyItem(atPath: string, toPath: toPath.string)
      return true
    }
    catch {
      return false
    }
  }
  
  public func fileHandleForReading() -> SRFileHandle? {
    if self.exists == false || self.isDirectory { return nil }
    return SRFileHandle(pathForReading: self)
  }
  
  public func fileHandleForWriting() -> SRFileHandle? {
    if self.exists == false {
      if SRPath.createFile(path: self) {
        return SRFileHandle(pathForWriting: self)
      } else {
        return nil
      }
    }
    else if self.exists == true && self.isDirectory {
      return nil
    }
    else {
      return SRFileHandle(pathForWriting: self)
    }
  }
  
  // This is alternate function of file handle
  // Ok. Is this needed? Or use file handle features?
  public var lines: [String]? {
    guard self.exists && self.isFile else { return nil }
    return try? String(contentsOfFile: string)
      .characters
      .split { $0 == "\n" }
      .map(String.init)
  }
    
  public func childPath(childContentName: String) -> SRPath {
    return SRPath(self.string + "/" + childContentName)
  }
  
  // MARK: - Utilities
  
  private static func pathForUserDomain(directory: FileManager.SearchPathDirectory) -> SRPath {
    let paths = NSSearchPathForDirectoriesInDomains(
      directory,
      FileManager.SearchPathDomainMask.userDomainMask,
      true)
    return SRPath(paths.last!)
  }
  
#if os(OSX)
  public static var downloadsPath: SRPath {
    return SRPath.pathForUserDomain(directory: .downloadsDirectory)
  }
  
  public static var moviesPath: SRPath {
    return SRPath.pathForUserDomain(directory: .moviesDirectory)
  }
  
  public static var desktopPath: SRPath {
    return SRPath.pathForUserDomain(directory: .desktopDirectory)
  }
  
  public static var homePath: SRPath {
    let home = ProcessInfo.processInfo.environment
    let homePath: AnyObject? = home["HOME"]
    return SRPath(homePath as! String)
  }
#endif  // #if os(OSX)
  
  public static var applicationSupportPath: SRPath {
    let appSupportDir = SRPath.pathForUserDomain(directory: .applicationSupportDirectory)
    
    guard let executableName = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String else { return appSupportDir }
    return appSupportDir + executableName
  }
  
  public static var cachesPath: SRPath {
    return SRPath.pathForUserDomain(directory: .cachesDirectory)
  }
  
  public static var documentsPath: SRPath {
    return SRPath.pathForUserDomain(directory: .documentDirectory)
  }
  
  public static var temporaryPath: SRPath {
    return SRPath(NSTemporaryDirectory())
  }
  
  public static var currentPath: SRPath {
    return SRPath(FileManager.default.currentDirectoryPath)
  }
  
  public static var mainBundlePath: SRPath? {
    guard let resourcePath = Bundle.main.resourcePath
      else { return nil }
    return SRPath(resourcePath)
  }
  
  public static func mkdir(pathString: String, intermediateDirectories: Bool = false) -> SRPath? {
    do {
      try FileManager.default.createDirectory(
        atPath: pathString,
        withIntermediateDirectories: intermediateDirectories,
        attributes: nil)
      return SRPath(pathString)
    } catch {
      return nil
    }
  }
  
  public func mkdir(intermediateDirectories: Bool) -> SRPath? {
    do {
      try FileManager.default.createDirectory(
        atPath: self.string,
        withIntermediateDirectories: intermediateDirectories,
        attributes: nil)
      return self
    } catch {
      return nil
    }
  }
  
  public static func mv(fromPath: SRPath, toPath: SRPath) -> Bool {
    do {
      try FileManager.default.moveItem(atPath: fromPath.string, toPath: toPath.string)
      return true
    } catch {
      return false
    }
  }
  
  public static func createFile(path: SRPath) -> Bool {
    return FileManager.default.createFile(atPath: path.string, contents: nil, attributes: nil)
  }
  
  // MARK: - String Convertible
  
  public var description: String {
    return self.string
  }
  
  public var debugDescription: String {
    return "SRPath(\(self.string))"
  }
}

// MARK: - Operators

public func == (left: SRPath, right: SRPath) -> Bool {
  return left.string == right.string
}

public func + (left: SRPath, right: String) -> SRPath {
  assert(left.isDirectory, "lvalue is must directory")
  return left.childPath(childContentName: right)
}

// MARK: - Helper Functions

public func dir(URL: NSURL = NSURL(fileURLWithPath: "./")) -> [SRPath] {
  return SRPath(URL.path!).contents
}

public func dir(pathString: String = "./") -> [SRPath] {
  return SRPath(pathString).contents
}
