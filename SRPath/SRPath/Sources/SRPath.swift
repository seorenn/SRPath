//
//  SRPath.swift
//  SRPath
//
//  Created by Seorenn (Heeseung Seo)
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

import Foundation

private let _fm = NSFileManager.defaultManager()

private extension NSURL {
    private var isRootDirectory: Bool {
        return self.path! == "/"
    }
}

private extension String {
    private var firstCharacter: Character {
        return self[self.startIndex]
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
    if size < 1024 { return "\(size) B" }
    
    let fSize = Double(size)
    
    let kiloBytes = fSize / 1024
    if kiloBytes < 1024 {
        return kiloBytes.firstDecisionString + "KB"
    }
    
    let megaBytes = kiloBytes / 1024
    if megaBytes < 1024 {
        return megaBytes.firstDecisionString + "MB"
    }
    
    let gigaBytes = megaBytes / 1024
    if gigaBytes < 1024 {
        return gigaBytes.firstDecisionString + "GB"
    }
    
    let teraBytes = gigaBytes / 1024
    return teraBytes.firstDecisionString + "TB"
}

// TODO: It may be the common type ;-)
public protocol SRPathType {
    var exists: Bool { get }
    var name: String { get }
    var extensionName: String { get }
    var isDirectory: Bool { get }
}

public struct SRPath : SRPathType, Equatable, CustomStringConvertible, CustomDebugStringConvertible {

    public let URL: NSURL
    
    public var string: String {
        return self.URL.path!
    }

    public init(_ URL: NSURL) {
        self.URL = URL
    }
    
    public init(_ pathString: String) {
        self.init(NSURL(fileURLWithPath: pathString))
    }
    
    public init(_ path: SRPath) {
        self.init(path.URL)
    }
    
    public init?(creatingDirectoryURL: NSURL, intermediateDirectories: Bool) {
        self.URL = creatingDirectoryURL
        if SRPath.mkdir(creatingDirectoryURL.path!, intermediateDirectories: intermediateDirectories) == false {
            return nil
        }
    }
    
    public init?(creatingDirectoryPath: String, intermediateDirectories: Bool) {
        self.init(creatingDirectoryURL: NSURL(fileURLWithPath: creatingDirectoryPath), intermediateDirectories: intermediateDirectories)
    }
    
    public var contents: [SRPath] {
        guard self.isDirectory == true else {
            return [SRPath]()
        }
        
        let fm = NSFileManager.defaultManager()
        do {
            let urls = try fm.contentsOfDirectoryAtURL(self.URL, includingPropertiesForKeys: nil, options: [])
            let result: [SRPath] = urls.map {
                return SRPath($0)
            }
            return result
        } catch {
            return [SRPath]()
        }
    }
    
    public var exists: Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(self.string)
    }
    
    public var isDirectory: Bool {
        var isDir: ObjCBool = false
        let exists = _fm.fileExistsAtPath(self.string, isDirectory: &isDir)
        
        if !exists { return false }
        return isDir.boolValue
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
        
        return try! NSFileManager.defaultManager().attributesOfItemAtPath(self.string)
    }
    
    public var size: UInt64? {
        guard self.isFile else { return nil }
        guard let attrs = self.attributes else { return nil }
        
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
        return self.URL.lastPathComponent!
    }
    
    public var parentURL: NSURL {
        return self.URL.URLByDeletingLastPathComponent!
    }
    public var parentPathString: String {
        return self.parentURL.path!
    }
    public var parentPath: SRPath? {
        if self.URL.isRootDirectory { return nil }
        return SRPath(self.parentURL)
    }
    
    public var extensionName: String {
        return self.URL.pathExtension!
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
    
    public func movedPathToURL(URL: NSURL) -> SRPath? {
        let newURL = URL.URLByAppendingPathComponent(self.name)
        do {
            try NSFileManager.defaultManager().moveItemAtURL(self.URL, toURL: newURL)
            return SRPath(newURL)
        } catch {
            return nil
        }
    }
    public func movedToPathString(pathString: String) -> SRPath? {
        return self.movedPathToURL(NSURL(fileURLWithPath: pathString))
    }
    public func movedToPath(path: SRPath) -> SRPath? {
        if path.exists == false || path.isFile { return nil }
        
        return self.movedPathToURL(path.URL)
    }

    public func renamedPath(name: String) -> SRPath? {
        let newPath = self.parentURL.URLByAppendingPathComponent(name)
        do {
            try NSFileManager.defaultManager().moveItemAtURL(self.URL, toURL: newPath)
            return SRPath(newPath)
        } catch {
            return nil
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
    
    public func childPath(childContentName: String) -> SRPath {
        let newURL = self.URL.URLByAppendingPathComponent(childContentName)
        return SRPath(newURL)
    }
    
    // MARK: - Utilities
    
    private static func pathForUserDomain(directory: NSSearchPathDirectory) -> SRPath {
        let paths = NSSearchPathForDirectoriesInDomains(directory, NSSearchPathDomainMask.UserDomainMask, true)
        return SRPath(paths.last!)
    }
    
    private static func pathURLForUserDomain(directory: NSSearchPathDirectory) -> NSURL {
        let fm = NSFileManager.defaultManager()
        let paths = fm.URLsForDirectory(directory, inDomains: NSSearchPathDomainMask.UserDomainMask)
        return paths.last!
    }
    
#if os(OSX)
    public static var downloadsPath: SRPath {
        return SRPath.pathForUserDomain(.DownloadsDirectory)
    }
    public static var downloadsURL: NSURL {
        return SRPath.pathURLForUserDomain(.DownloadsDirectory)
    }
    
    public static var moviesPath: SRPath {
        return SRPath.pathForUserDomain(.MoviesDirectory)
    }
    public static var moviesURL: NSURL {
        return SRPath.pathURLForUserDomain(.MoviesDirectory)
    }
    
    public static var desktopPath: SRPath {
        return SRPath.pathForUserDomain(.DesktopDirectory)
    }
    public static var desktopURL: NSURL {
        return SRPath.pathURLForUserDomain(.DesktopDirectory)
    }
    
    public static var homePath: SRPath {
        let home = NSProcessInfo.processInfo().environment
        let homePath: AnyObject? = home["HOME"]
        return SRPath(homePath as! String)
    }
    public static var homeURL: NSURL {
        return NSURL(fileURLWithPath: SRPath.homePath.string, isDirectory: true)
    }
#endif  // #if os(OSX)
  
    public static var applicationSupportsPath: SRPath {
        return SRPath.pathForUserDomain(.ApplicationSupportDirectory)
    }
    public static var applicationSupportsURL: NSURL {
        return SRPath.pathURLForUserDomain(.ApplicationSupportDirectory)
    }
    
    public static var cachesPath: SRPath {
        return SRPath.pathForUserDomain(.CachesDirectory)
    }
    public static var cachesURL: NSURL {
        return SRPath.pathURLForUserDomain(.CachesDirectory)
    }
    
    public static var documentsPath: SRPath {
        return SRPath.pathForUserDomain(.DocumentDirectory)
    }
    public static var documentsURL: NSURL {
        return SRPath.pathURLForUserDomain(.DocumentDirectory)
    }
    
    public static var temporaryPath: SRPath {
        return SRPath(NSTemporaryDirectory())
    }
    public static var temporaryURL: NSURL {
        return NSURL(fileURLWithPath: SRPath.temporaryPath.string, isDirectory: true)
    }
    
    public static var currentPath: SRPath {
        return SRPath(NSFileManager.defaultManager().currentDirectoryPath)
    }
    public static var currentURL: NSURL {
        return NSURL(fileURLWithPath: SRPath.currentPath.string, isDirectory: true)
    }
    
    public static var mainBundlePath: SRPath? {
        guard let resourcePath = NSBundle.mainBundle().resourcePath
            else { return nil }
        return SRPath(resourcePath)
    }
    public static var mainBundleURL: NSURL? {
        guard let path = SRPath.mainBundlePath else { return nil }
        return NSURL(fileURLWithPath: path.string, isDirectory: true)
    }
    
    public static func mkdir(pathString: String, intermediateDirectories: Bool = false) -> Bool {
        do {
            try _fm.createDirectoryAtPath(pathString, withIntermediateDirectories: intermediateDirectories, attributes: nil)
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
        return "SRFile(\(self.string))"
    }
}

// MARK: - Operators

public func == (left: SRPath, right: SRPath) -> Bool {
    return left.string == right.string
}

public func + (left: SRPath, right: String) -> SRPath {
    assert(left.isDirectory, "lvalue is not directory")
    return left.childPath(right)
}

// MARK: - Helper Functions

public func dir(URL: NSURL = NSURL(fileURLWithPath: "./")) -> [SRPath] {
    return SRPath(URL).contents
}

public func dir(pathString: String = "./") -> [SRPath] {
    return dir(NSURL(fileURLWithPath: pathString))
}
