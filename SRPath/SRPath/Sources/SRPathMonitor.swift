//
//  SRPathMonitor.swift
//  SRPath
//
//  Created by Heeseung Seo on 2015. 7. 27..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import SRPathPrivates

#if os(OSX)
  
public protocol SRPathMonitorDelegate {
  func pathMonitor(pathMonitor: SRPathMonitor, detectEvents: [SRPathEvent])
}

public class SRPathMonitor: SRPathMonitorImplDelegate {
  
  public var delegate: SRPathMonitorDelegate?
  public var monitorDeepFile: Bool = false
  
  private let queue: DispatchQueue
  private let impl: SRPathMonitorImpl
  private let paths: [String]
  
  public init(pathStrings: [String], queue: DispatchQueue?, delegate: SRPathMonitorDelegate?) {
    if queue != nil { self.queue = queue! }
    else            { self.queue = DispatchQueue.main }
    
    self.delegate = delegate
    self.paths = pathStrings
    
    self.impl = SRPathMonitorImpl(paths: paths, queue: self.queue)
    self.impl.delegate = self
  }
  
  public convenience init(paths: [SRPath], queue: DispatchQueue?, delegate: SRPathMonitorDelegate?) {
    self.init(pathStrings: paths.map { $0.string }, queue: queue, delegate: delegate)
  }
  
  public convenience init(path: SRPath, queue: DispatchQueue?, delegate: SRPathMonitorDelegate?) {
    self.init(pathStrings: [path.string], queue: queue, delegate: delegate)
  }
  
  public var running: Bool {
    return self.impl.running
  }
  
  public func start() {
    if self.running == false {
      self.impl.start()
    }
  }
  
  public func stop() {
    if self.running {
      self.impl.stop()
    }
  }
  
  private func countItem(path: String) -> Int {
    if path.characters.count <= 0 || path == "/" { return 0 }
    let items = path.components(separatedBy: "/")
    return items.count - 1
  }
  
  private func depthOf(path: String) -> Int? {
    for targetPath in paths {
      if path.range(of: targetPath) != nil {
      //if path.rangeOfString(targetPath) != nil {
        let arrPath = path.replacingOccurrences(of: targetPath, with: "")
        return countItem(path: arrPath)
      }
    }
    
    return nil
  }
  
  @objc public func pathMonitorImpl(_ fileMonitorImpl: SRPathMonitorImpl, detectEventPaths paths: [String], flags: [NSNumber]) {
    let eventFlags = flags as! [Int]
    
    assert(paths.count == eventFlags.count)
    
    var events = [SRPathEvent]()
    for i in 0..<paths.count {
      let path = paths[i]
      let flag = eventFlags[i]
      
      if self.monitorDeepFile == false {
        let depth = self.depthOf(path: path)
        if depth != nil && depth! > 1 { continue }
      }
      
      let event = SRPathEvent(path: SRPath(path), flag: flag)
      events.append(event)
    }
    
    if let delegate = self.delegate {
      delegate.pathMonitor(pathMonitor: self, detectEvents: events)
    }
  }
}
  
#endif  // os(OSX)

