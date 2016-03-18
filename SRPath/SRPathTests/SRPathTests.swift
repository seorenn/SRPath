//
//  SRPathTests.swift
//  SRPathTests
//
//  Created by Heeseung Seo on 2016. 3. 18..
//  Copyright © 2016년 Seorenn. All rights reserved.
//

import XCTest
@testable import SRPath

func currentTimeString() -> String {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-ddTHH:mm:ss"
    formatter.timeZone = NSTimeZone.defaultTimeZone()
    
    return formatter.stringFromDate(NSDate())
}

func isEqualDate(left: NSDate, right: NSDate) -> Bool {
    guard let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) else { return false }
    let leftComponents = calendar.components([ .Year, .Month, .Day ], fromDate: left)
    let rightComponents = calendar.components([ .Year, .Month, .Day ], fromDate: right)
    
    return leftComponents.year == rightComponents.year && leftComponents.month == rightComponents.month && leftComponents.day == rightComponents.day
}

private extension String {
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    
    var stringByDeletingLastPathComponent: String {
        return (self as NSString).stringByDeletingLastPathComponent
    }
    
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    
    var stringByDeletingPathExtension: String {
        return (self as NSString).stringByDeletingPathExtension
    }
    
    func stringByAppendingPathComponent(component: String) -> String {
        return (self as NSString).stringByAppendingPathComponent(component)
    }
}

class SRPathTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testSRPathMisc() {
        let dir = SRPath("/not/exists/path")
        XCTAssertFalse(dir.exists)
        
        let downloadsDir = SRPath.downloadsPath
        XCTAssertTrue(downloadsDir.exists)
        
        XCTAssertEqual(downloadsDir.name, "Downloads")
        
        XCTAssertEqual(SRPath("/test/directory/").name, "directory")
        XCTAssertEqual(SRPath("/test/directory/").string, "/test/directory")
        XCTAssertEqual(SRPath("/test/directory").name, "directory")
        XCTAssertEqual(SRPath("/test/directory").string, "/test/directory")
        
        XCTAssertFalse(SRPath("/invalid/file/path/").exists)
        let f = SRPath("/not/exists/path/file")
        XCTAssertEqual(f.string, "/not/exists/path/file")
        XCTAssertEqual(f.name, "file")
        XCTAssertNotNil(f.parentPath)
        XCTAssertEqual(f.parentPath!.string, "/not/exists/path")
    }
    
    func testSRPathCreateAndRemove() {
        let path = SRPath.documentsURL.URLByAppendingPathComponent("SRDirectoryTest")
        let dir = SRPath(creatingDirectoryURL: path, intermediateDirectories: false)
        XCTAssertNotNil(dir)
        XCTAssertTrue(dir!.exists)
        
        XCTAssertTrue(dir!.trash())
        XCTAssertFalse(dir!.exists)
    }
    
    func testSRPathCreateAndRemoveWithIntermediation() {
        let url = SRPath.documentsURL.URLByAppendingPathComponent("SRDirectoryTest/Another/Deep/Directory")
        let dir = SRPath(creatingDirectoryURL: url, intermediateDirectories: true)
        XCTAssertNotNil(dir)
        XCTAssertTrue(dir!.exists)
        
        let removingPath = SRPath.documentsPath.string.stringByAppendingPathComponent("SRDirectoryTest")
        let remDir = SRPath(removingPath)
        XCTAssertTrue(remDir.trash())
        XCTAssertFalse(remDir.exists)
    }
    
    func testSRPathRename() {
        let url = SRPath.documentsURL.URLByAppendingPathComponent("SRDirectoryTest-Previous")
        let dir = SRPath(creatingDirectoryURL: url, intermediateDirectories: true)
        XCTAssertNotNil(dir)
        let renamedFile = dir!.renamedPath("SRDirectoryTest-New")!
        XCTAssertEqual(renamedFile.name, "SRDirectoryTest-New")
        XCTAssertTrue(renamedFile.exists)
        
        renamedFile.trash()
    }
    
    func testSRPathMove() {
        let oldContainer = SRPath(creatingDirectoryURL: SRPath.documentsURL.URLByAppendingPathComponent("SRDirectoryContainer1"), intermediateDirectories: true)!
        
        let content = SRPath(creatingDirectoryURL: oldContainer.childPath("content-dir").URL, intermediateDirectories: true)!
        
        let newContainer = SRPath(creatingDirectoryURL: SRPath.documentsURL.URLByAppendingPathComponent("SRDirectoryContainer2"), intermediateDirectories: true)!
        
        let movedFile = content.movedToPath(newContainer)!
        XCTAssertEqual(movedFile.string.stringByDeletingLastPathComponent.lastPathComponent, "SRDirectoryContainer2")
        
        XCTAssertEqual(oldContainer.directories.count, 0)
        
        XCTAssertEqual(newContainer.directories.count, 1)
        
        oldContainer.trash()
        newContainer.trash()
        
        XCTAssertFalse(oldContainer.exists)
        XCTAssertFalse(newContainer.exists)
    }
    
    func testHidden() {
        let file = SRPath("/foo/bar/.hidden")
        XCTAssertTrue(file.isHidden)
    }
    
    func testStringConvertible() {
        let file = SRPath("/Some/Special/File")
        XCTAssertEqual(String(file), "/Some/Special/File")
    }
    
    /*
    func testSRFileOperations() {
    let filename = "SRFileTest-rw-file.txt"
    let path = SRFile.pathForDocuments.stringByAppendingPathComponent(filename)
    let f = SRFile(path)
    let content = "Hello World!\n(This is test text document wrote by SRFile)\n"
    XCTAssert(f.exists == false)
    
    if let handle = f.openForWriting() {
    handle.text = content
    handle.close()
    } else {
    XCTAssert(false)
    }
    
    XCTAssert(f.exists == true)
    
    if let fin = f.openForReading() {
    let readedData = fin.data
    XCTAssert(readedData != nil)
    let readedContent = NSString(data: readedData!, encoding: NSUTF8StringEncoding)
    
    XCTAssert(readedContent == content)
    
    XCTAssert(f.trash() == true)
    XCTAssert(f.exists == false)
    } else {
    XCTAssert(false)
    }
    }
    */
    
    func testSRFileSizeString() {
        XCTAssertEqual(HumanReadableFileSize(UInt64(1025)), "1KB")
        XCTAssertEqual(HumanReadableFileSize(UInt64(1458)), "1.4KB")
        XCTAssertEqual(HumanReadableFileSize(UInt64(1024 * 1024)), "1MB")
        XCTAssertEqual(HumanReadableFileSize(UInt64(1024 * 1024 * 1024)), "1GB")
        XCTAssertEqual(HumanReadableFileSize(UInt64(1024 * 1024 * 1024 * 1024)), "1TB")
    }
    
    func testSRFileOperation() {
        let dateString = currentTimeString()
        let filename = "SRFileTest-\(dateString).txt"
        let path = SRPath.documentsPath.string.stringByAppendingPathComponent(filename)
        let testContent = "This\nis\ntest content.\nEOF"
        
        let f = SRPath(path)
        
        // Write the file with text content
        
        if let fp = f.fileHandleForWriting() {
            let data = testContent.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            XCTAssertNotNil(data)
            fp.write(data!)
            fp.close()
        } else {
            XCTFail()
        }
        
        XCTAssertEqual(f.size, 25)
        XCTAssertEqual(f.humanReadableSize, "25 B")
        
        let today = NSDate()
        XCTAssertTrue(isEqualDate(today, right: f.creationDate!))
        XCTAssertTrue(isEqualDate(today, right: f.modificationDate!))
        
        // Read file's content and compare with it!
        
        if let fin = f.fileHandleForReading() {
            if let readedData = fin.read() {
                let readedContent = NSString(data: readedData, encoding: NSUTF8StringEncoding) as! String
                XCTAssertEqual(readedContent, testContent)
            } else {
                XCTFail()
            }
            
            fin.close()
        } else {
            XCTFail()
        }
        
        // Testing readline and readlines!
        
        if let finput = f.fileHandleForReading() {
            let components = testContent.componentsSeparatedByString("\n")
            var index = 0
            while let line = finput.readline() {
                XCTAssertEqual(line, components[index])
                index++
            }
            
            finput.close()
        }
        
        if let finpall = f.fileHandleForReading() {
            let components = testContent.componentsSeparatedByString("\n")
            let lines = finpall.readlines()
            
            XCTAssertEqual(components.count, lines.count)
            var index = 0
            
            for line in lines {
                XCTAssert(line == components[index])
                index++
            }
        } else {
            XCTFail()
        }
    }
}
