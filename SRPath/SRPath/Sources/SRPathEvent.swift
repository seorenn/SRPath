//
//  SRPathEvent.swift
//  SRPath
//
//  Created by Heeseung Seo on 2015. 7. 27..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation

#if os(OSX)

import Cocoa

public class SRPathEvent: CustomDebugStringConvertible {
  public let path: SRPath
  public let flag: Int    /*FSEventStreamEventFlags*/
  
  public init(path: SRPath, flag: Int) {
    self.path = path
    self.flag = flag
  }
  
  public var created: Bool {
    return (self.flag & kFSEventStreamEventFlagItemCreated) == kFSEventStreamEventFlagItemCreated
  }
  
  public var removed: Bool {
    return (self.flag & kFSEventStreamEventFlagItemRemoved) == kFSEventStreamEventFlagItemRemoved
  }
  
  public var renamed: Bool {
    return (self.flag & kFSEventStreamEventFlagItemRenamed) == kFSEventStreamEventFlagItemRenamed
  }
  
  public var modified: Bool {
    return (self.flag & kFSEventStreamEventFlagItemModified) == kFSEventStreamEventFlagItemModified
  }
  
  public var debugDescription: String {
    var output = "<SRPathEvent \(self.path.string)"
    
    if self.created {
      output = output + " CREATED"
    }
    if self.removed {
      output = output + " REMOVED"
    }
    if self.renamed {
      output = output + " RENAMED"
    }
    if self.modified {
      output = output + " MODIFIED"
    }
    
    output = output + " (\(self.flag))>"
    return output
  }
}

#endif
