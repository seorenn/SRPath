//
//  SRPath.swift
//  SRPath
//
//  Created by Seorenn (Heeseung Seo)
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

import Foundation

private let _fm = FileManager.default()

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
  
  private func stringBackwardBeforeCharacter(character: Character) -> String {
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
  private func stringBackwardRemovedBeforeCharacter(character: Character) -> String {
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

func HumanReadableFileSize(size: UInt64) -> String {
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
    
    let fm = FileManager.default()
    do {
      let pathStrings = try fm.contentsOfDirectory(atPath: string)
      let result: [SRPath] = pathStrings.map {
          return self + $0
      }
      return result
    } catch {
      return [SRPath]()
    }
  }
  
  public var exists: Bool {
    return FileManager.default().fileExists(atPath: string)
  }
  
  public var isDirectory: Bool {
    var isDir: ObjCBool = false
    if FileManager.default().fileExists(atPath: string, isDirectory: &isDir) {
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
  
  public var attributes: [String: AnyObject]? {
    // Directory has no size
    guard self.exists else { return nil }
    
    return try! FileManager.default().attributesOfItem(atPath: string)
  }
  
  public var size: UInt64? {
    guard self.isFile else { return nil }
    guard let ats = attributes else { return nil }
    
    return ats[FileAttributeKey.size].longLongValue
    guard let sizeObject = attrs[(FileAttributeKey.size)] else { return nil }
    
    return UInt64(attrs[NSFileSize]!.longLongValue)
  }
  
  public var modificationDate: NSDate? {
    guard self.isFile else { return nil }
    guard let attrs = self.attributes else { return nil }
    
    let date = attrs[NSFileModificationDate] as! NSDate
    return date
  }
  
  public var creationDate: NSDate? {
    guard self.isFile else { return nil }
    guard let attrs = self.attributes else { return nil }
    
    let date = attrs[NSFileCreationDate] as! NSDate
    return date
  }
  
  public var humanReadableSize: String? {
    guard let size = self.size else { return nil }
    
    return HumanReadableFileSize(size)
  }
  
  public var files: [SRPath] {
    return self.contents.filter({$0.isFile})
  }
  
  public var directories: [SRPath] {
    return self.contents.filter({$0.isDirectory})
  }
  
  public var name: String {
    return self.string.stringBackwardBeforeCharacter(Character("/"))
  }
  
  public var nameWithoutExtension: String {
    let n = self.name.stringBackwardRemovedBeforeCharacter(".")
    if n.isEmpty { return name }  // case naming hidden file
    
    return n
  }
  
  public var parentPathString: String {
    return self.string.stringBackwardRemovedBeforeCharacter(Character("/"))
  }
  public var parentPath: SRPath? {
    if self.string == "/" || self.string == "" { return nil }
    return SRPath(self.parentPathString)
  }
  
  public var extensionName: String {
    return self.name.stringBackwardBeforeCharacter(Character("."))
  }
  
  public func trash() -> Bool {
#if os(iOS)
    return false
#else
    do {
      try NSFileManager.defaultManager().trashItemAtURL(self.URL, resultingItemURL: nil)
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
      try NSFileManager.defaultManager().moveItemAtPath(self.string, toPath: destinationPath.string)
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
      try NSFileManager.defaultManager().moveItemAtPath(self.string, toPath: newPath.string)
      return newPath
    } catch {
      return nil
    }
  }
  
  public func copy(toPath: SRPath) -> Bool {
    guard exists && isFile else { return false }
    guard NSFileManager.defaultManager().isReadableFileAtPath(string) else { return false }

    do {
      try NSFileManager.defaultManager().copyItemAtPath(string, toPath: toPath.string)
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
      SRPath.createFile(self)
      return SRFileHandle(pathForWriting: self)
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
    return try? String(contentsOfURL: self.URL)
      .characters
      .split { $0 == "\n" }
      .map(String.init)
  }
    
  public func childPath(childContentName: String) -> SRPath {
    return SRPath(self.string + "/" + childContentName)
  }
  
  // MARK: - Utilities
  
  private static func pathForUserDomain(directory: NSSearchPathDirectory) -> SRPath {
    let paths = NSSearchPathForDirectoriesInDomains(
      directory,
      NSSearchPathDomainMask.UserDomainMask,
      true)
    return SRPath(paths.last!)
  }
  
#if os(OSX)
  public static var downloadsPath: SRPath {
    return SRPath.pathForUserDomain(.DownloadsDirectory)
  }
  
  public static var moviesPath: SRPath {
    return SRPath.pathForUserDomain(.MoviesDirectory)
  }
  
  public static var desktopPath: SRPath {
    return SRPath.pathForUserDomain(.DesktopDirectory)
  }
  
  public static var homePath: SRPath {
    let home = NSProcessInfo.processInfo().environment
    let homePath: AnyObject? = home["HOME"]
    return SRPath(homePath as! String)
  }
#endif  // #if os(OSX)
  
  public static var applicationSupportPath: SRPath {
    let appSupportDir = SRPath.pathForUserDomain(.ApplicationSupportDirectory)
    
    guard let executableName = NSBundle.mainBundle().infoDictionary!["CFBundleExecutable"] as? String else { return appSupportDir }
    return appSupportDir + executableName
  }
  
  public static var cachesPath: SRPath {
    return SRPath.pathForUserDomain(.CachesDirectory)
  }
  
  public static var documentsPath: SRPath {
    return SRPath.pathForUserDomain(.DocumentDirectory)
  }
  
  public static var temporaryPath: SRPath {
    return SRPath(NSTemporaryDirectory())
  }
  
  public static var currentPath: SRPath {
    return SRPath(NSFileManager.defaultManager().currentDirectoryPath)
  }
  
  public static var mainBundlePath: SRPath? {
    guard let resourcePath = NSBundle.mainBundle().resourcePath
      else { return nil }
    return SRPath(resourcePath)
  }
  
  public static func mkdir(pathString: String, intermediateDirectories: Bool = false) -> SRPath? {
    do {
      try _fm.createDirectoryAtPath(
        pathString,
        withIntermediateDirectories: intermediateDirectories,
        attributes: nil)
      return SRPath(pathString)
    } catch {
      return nil
    }
  }
  
  public func mkdir(intermediateDirectories intermediateDirectories: Bool) -> SRPath? {
    do {
      try _fm.createDirectoryAtPath(
        self.string,
        withIntermediateDirectories: intermediateDirectories,
        attributes: nil)
      return self
    } catch {
      return nil
    }
  }
  
  public static func mv(fromPath: SRPath, toPath: SRPath) -> Bool {
    do {
      try NSFileManager.defaultManager().moveItemAtPath(fromPath.string, toPath: toPath.string)
      return true
    } catch {
      return false
    }
  }
  
  public static func createFile(path: SRPath) -> Bool {
    return _fm.createFileAtPath(path.string, contents: nil, attributes: nil)
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
  return left.childPath(right)
}

// MARK: - Helper Functions

public func dir(URL: NSURL = NSURL(fileURLWithPath: "./")) -> [SRPath] {
  return SRPath(URL.path!).contents
}

public func dir(pathString: String = "./") -> [SRPath] {
  return SRPath(pathString).contents
}
