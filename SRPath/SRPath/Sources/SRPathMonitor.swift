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
    
    private let queue: dispatch_queue_t
    private let impl: SRPathMonitorImpl
    private let paths: [String]
    
    public init(pathStrings: [String], queue: dispatch_queue_t?, delegate: SRPathMonitorDelegate?) {
        if queue != nil { self.queue = queue! }
        else            { self.queue = dispatch_get_main_queue() }
        
        self.delegate = delegate
        self.paths = pathStrings
        
        self.impl = SRPathMonitorImpl(paths: paths, queue: self.queue)
        self.impl.delegate = self
    }
    
    public convenience init(paths: [SRPath], queue: dispatch_queue_t?, delegate: SRPathMonitorDelegate?) {
        self.init(pathStrings: paths.map { $0.string }, queue: queue, delegate: delegate)
    }
    
    public convenience init(path: SRPath, queue: dispatch_queue_t?, delegate: SRPathMonitorDelegate?) {
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
    
    private func countPathItem(path: String) -> Int {
        if path.characters.count <= 0 || path == "/" { return 0 }
        let items = path.componentsSeparatedByString("/")
        return items.count - 1
    }
    
    private func depthOfPath(path: String) -> Int? {
        for targetPath in self.paths {
            if path.rangeOfString(targetPath) != nil {
                let arrPath = path.stringByReplacingOccurrencesOfString(targetPath, withString: "")
                return self.countPathItem(arrPath)
            }
        }
        
        return nil
    }

    @objc public func pathMonitorImpl(fileMonitorImpl: SRPathMonitorImpl, detectEventPaths paths: [String], flags: [NSNumber]) {
        let eventFlags = flags as! [Int]
        
        assert(paths.count == eventFlags.count)
        
        var events = [SRPathEvent]()
        for (var i=0; i < paths.count; i++) {
            let path = paths[i]
            let flag = eventFlags[i]
            
            if self.monitorDeepFile == false {
                let depth = self.depthOfPath(path)
                if depth != nil && depth! > 1 { continue }
            }
            
            let event = SRPathEvent(path: SRPath(path), flag: flag)
            events.append(event)
        }
        
        if let delegate = self.delegate {
            delegate.pathMonitor(self, detectEvents: events)
        }
    }
}

#endif  // os(OSX)

