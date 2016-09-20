//
// SRFileHandle.swift
// SRPath
//
// Created by Seorenn.
// Copyright (c) 2015 Seorenn. All rights reserved.
//

import Foundation

private let SRFileHandleChunkSize = 1024

public enum SRFileHandleMode {
  case read, write
}

public class SRFileHandle: CustomDebugStringConvertible {
  public let path: SRPath
  private let handle: FileHandle
  private let mode: SRFileHandleMode
  private var eofValue: Bool = false
  private lazy var buffer = NSMutableData(capacity: SRFileHandleChunkSize)!
  private let delimiter = "\n".data(using: String.Encoding.utf8)!
  
  public var eof: Bool {
    return eofValue
  }
  
  public init?(pathForReading: SRPath) {
    self.path = pathForReading
    self.mode = .read
    
    if let handle = FileHandle(forReadingAtPath: self.path.string) {
      self.handle = handle
      self.eofValue = false
    } else {
      return nil
    }
  }
  
  public init?(pathForWriting: SRPath) {
    self.path = pathForWriting
    self.mode = .write
    
    if let handle = FileHandle(forWritingAtPath: self.path.string) {
      self.handle = handle
    } else {
      // Failed to get writer handle.
      // Ok. It meanns file not exists, maybe...
      FileManager.default.createFile(atPath: self.path.string, contents: nil, attributes: nil)
      if let handle = FileHandle(forWritingAtPath: self.path.string) {
        self.handle = handle
      } else {
        return nil
      }
    }
    
    self.eofValue = false
  }
  
  deinit {
    close()
  }
  
  public func close() {
    self.handle.closeFile()
  }
  
  public var data: Data? {
    get {
      return FileManager.default.contents(atPath: self.path.string)
    }
    set {
      if newValue != nil {
        try! newValue!.write(to: URL(fileURLWithPath: self.path.string), options: [.atomicWrite])
      }
    }
  }
  
  public var text: String? {
    get {
      do {
        let result = try String(contentsOfFile: self.path.string, encoding: String.Encoding.utf8)
        return result
      }
      catch {
        return nil
      }
    }
    set {
      let data = newValue!.data(using: String.Encoding.utf8)
      self.data = data
    }
  }
  
  public func read(_ length: Int = 0) -> Data? {
    if length <= 0 {
      return self.handle.readDataToEndOfFile()
    } else {
      return self.handle.readData(ofLength: length)
    }
  }
  
  public func write(_ data: Data) {
    assert(mode == .write, "This handle is read-only.")
    self.handle.write(data)
  }
  
  public func readline() -> String? {
    if self.eofValue { return nil }
    
    while true {
      let r = buffer.range(of: delimiter, options: NSData.SearchOptions(rawValue: 0), in: NSMakeRange(0, buffer.length))
      if r.location == NSNotFound {
        let newChunk = self.read(SRFileHandleChunkSize)
        if newChunk == nil || newChunk!.count <= 0 {
          eofValue = true
          
          if buffer.length > 0 {
            let str = NSString(data: buffer as Data, encoding: String.Encoding.utf8.rawValue)
            return str as? String
          }
        }
        
        buffer.append(newChunk!)
      }   // ... if r.location == NSNotFound
      else {
        let str = NSString(data: buffer.subdata(with: NSMakeRange(0, r.location)), encoding: String.Encoding.utf8.rawValue)
        buffer.replaceBytes(in: NSMakeRange(0, r.location + r.length), withBytes: nil, length: 0)
        
        return str as? String
      }
    } // ... while true
  }
  
  public func readlines() -> [String] {
    var result = [String]()
    
    while let line = readline() {
      result.append(line)
    }
    
    return result
  }
  
  public var debugDescription: String {
    var output = "<SRFileHandle: \(self.path.string)"
    if self.mode == .read {
      output = output + " READ-ONLY>"
    } else {
      output = output + " WRITE>"
    }
    return output
  }
}

public func open(_ pathString: String, mode: String) -> SRFileHandle? {
  if mode == "r" {
    return SRFileHandle(pathForReading: SRPath(pathString))
  } else if mode == "w" {
    return SRFileHandle(pathForWriting: SRPath(pathString))
  } else {
    return nil
  }
}
