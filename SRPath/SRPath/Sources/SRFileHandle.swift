//
// SRFileHandle.swift
// SRPath
//
// Created by Seorenn.
// Copyright (c) 2015 Seorenn. All rights reserved.
//

import Foundation

private let _fm = NSFileManager.defaultManager()
private let SRFileHandleChunkSize = 1024

public enum SRFileHandleMode {
    case Read, Write
}

public class SRFileHandle: CustomDebugStringConvertible {
    public let path: SRPath
    //public let URL: NSURL
    private let handle: NSFileHandle?
    private let mode: SRFileHandleMode
    private var eofValue: Bool = false
    private lazy var buffer = NSMutableData(capacity: SRFileHandleChunkSize)!
    private let delimiter = "\n".dataUsingEncoding(NSUTF8StringEncoding)!

    public var eof: Bool {
        return eofValue
    }

    public init?(pathForReading: SRPath) {
        self.path = pathForReading
        self.mode = .Read
        
        do {
            let h = try NSFileHandle(forReadingFromURL: self.path.URL)
            self.handle = h
            self.eofValue = false
        }
        catch {
            self.handle = nil
            return nil
        }
    }
    
    public init?(pathForWriting: SRPath) {
        self.path = pathForWriting
        self.mode = .Write
        
        var h = try? NSFileHandle(forWritingToURL: self.path.URL)
        if h == nil {
            NSFileManager.defaultManager().createFileAtPath(self.path.string, contents: nil, attributes: nil)
            h = try? NSFileHandle(forWritingToURL: self.path.URL)
        }
        
        if h == nil {
            self.handle = nil
            return nil
        }
        
        self.handle = h
        self.eofValue = false
    }

    deinit {
        close()
    }
    
    public func close() {
        if let h = handle {
            h.closeFile()
        }
    }

    public var data: NSData? {
        get {
            return _fm.contentsAtPath(self.path.string)
        }
        set {
            if newValue != nil {
                newValue!.writeToFile(self.path.string, atomically: true)
            }
        }
    }

    public var text: String? {
        get {
            do {
                let result = try String(contentsOfFile: self.path.string, encoding: NSUTF8StringEncoding)
                return result
            }
            catch {
                return nil
            }
        }
        set {
            let data = newValue!.dataUsingEncoding(NSUTF8StringEncoding)
            self.data = data
        }
    }

    public func read(length: Int = 0) -> NSData? {
        if length <= 0 {
            return handle?.readDataToEndOfFile()
        } else {
            return handle?.readDataOfLength(length)
        }
    }

    public func write(data: NSData) {
        assert(mode == .Write, "This handle is read-only.")
        handle?.writeData(data)
    }

    public func readline() -> String? {
        if self.eofValue { return nil }
        
        while true {
            let r = buffer.rangeOfData(delimiter, options: NSDataSearchOptions(rawValue: 0), range: NSMakeRange(0, buffer.length))
            if r.location == NSNotFound {
                let newChunk = self.read(SRFileHandleChunkSize)
                if newChunk == nil || newChunk?.length <= 0 {
                    eofValue = true
                    
                    if buffer.length > 0 {
                        let str = NSString(data: buffer, encoding: NSUTF8StringEncoding)
                        return str as? String
                    }
                }
                
                buffer.appendData(newChunk!)
            }   // ... if r.location == NSNotFound
            else {
                let str = NSString(data: buffer.subdataWithRange(NSMakeRange(0, r.location)), encoding: NSUTF8StringEncoding)
                buffer.replaceBytesInRange(NSMakeRange(0, r.location + r.length), withBytes: nil, length: 0)
                
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
        if self.mode == .Read {
            output = output + " READ-ONLY>"
        } else {
            output = output + " WRITE>"
        }
        return output
    }
}

public func open(pathString: String, mode: String) -> SRFileHandle? {
    if mode == "r" {
        return SRFileHandle(pathForReading: SRPath(pathString))
    } else if mode == "w" {
        return SRFileHandle(pathForWriting: SRPath(pathString))
    } else {
        return nil
    }
}