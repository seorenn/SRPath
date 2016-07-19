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
  
  func test00LogPredefines() {
    print("Application Support Path: \(SRPath.applicationSupportPath)")
  }
  
  func testMisc() {
    let dir = SRPath("/not/exists/path")
    XCTAssertFalse(dir.exists)
    
    let downloadsDir = SRPath.downloadsPath
    XCTAssertTrue(downloadsDir.exists)
    
    let downloadsAnother = SRPath.downloadsPath + "someFile.txt"
    XCTAssertEqual(downloadsAnother.string, downloadsDir.string + "/someFile.txt")
    
    let downloadsSoAnother = SRPath.downloadsPath + "/Another Music.mp3"
    XCTAssertEqual(downloadsSoAnother.string, downloadsDir.string + "//Another Music.mp3")
    
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
  
  func testCreateAndRemove() {
    let path = SRPath.documentsPath + "SRDirectoryTest"
    let dir = path.mkdir(intermediateDirectories: false)
    XCTAssertNotNil(dir)
    XCTAssertTrue(dir!.trash())
    XCTAssertFalse(dir!.exists)
  }
  
  func testCreateAndRemoveWithIntermediation() {
    let path = SRPath.documentsPath + "SRDirectoryTest/Another/Deep/Directory"
    let dir = path.mkdir(intermediateDirectories: true)
    XCTAssertNotNil(dir)
    XCTAssertTrue(dir!.exists)
    
    let removingPath = SRPath.documentsPath + "SRDirectoryTest"
    XCTAssertTrue(removingPath.trash())
    XCTAssertFalse(removingPath.exists)
  }
  
  func testRename() {
    let path = SRPath.documentsPath + "SRDirectoryTest-Previous"
    path.mkdir(intermediateDirectories: true)
    XCTAssertTrue(path.exists)
    
    let renamedFile = path.rename("SRDirectoryTest-New")!
    XCTAssertEqual(renamedFile.name, "SRDirectoryTest-New")
    XCTAssertTrue(renamedFile.exists)
    
    renamedFile.trash()
  }
  
  func testMove() {
    let oldContainer = SRPath.documentsPath + "SRDirectoryContainer1"
    oldContainer.mkdir(intermediateDirectories: true)
    
    let content = oldContainer + "content-dir"
    content.mkdir(intermediateDirectories: true)
    XCTAssertTrue(content.isDirectory)
    
    let newContainer = SRPath.documentsPath + "SRDirectoryContainer2"
    newContainer.mkdir(intermediateDirectories: true)
    XCTAssertTrue(newContainer.isDirectory)
    
    let movedFile = content.moveTo(newContainer)!
    XCTAssertEqual(movedFile.string.stringByDeletingLastPathComponent.lastPathComponent, "SRDirectoryContainer2")
    
    XCTAssertEqual(oldContainer.contents.count, 0)
    XCTAssertEqual(newContainer.contents.count, 1)
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
  
  func testExtensionName() {
    XCTAssertEqual(SRPath("/foo/bar/test/file1").extensionName, "")
    XCTAssertEqual(SRPath("/foo/bar/test/file2.png").extensionName, "png")
    XCTAssertEqual(SRPath("/foo/bar/test.file.has.many.ext").extensionName, "ext")
    XCTAssertEqual(SRPath("/foo/bar/.another_dir").extensionName, "another_dir")
    
    XCTAssertEqual(SRPath("/boo/bar/some1.txt").nameWithoutExtension, "some1")
    XCTAssertEqual(SRPath("/boo/bar/some2").nameWithoutExtension, "some2")
    XCTAssertEqual(SRPath("/foo/bar/.hidden").nameWithoutExtension, ".hidden")
    XCTAssertEqual(SRPath("/foo/bar/.anotherhidden.txt").nameWithoutExtension, ".anotherhidden")
  }
  
  func testStringConvertible() {
    let file = SRPath("/Some/Special/File")
    XCTAssertEqual(String(file), "/Some/Special/File")
  }
  
  func testSizeString() {
    XCTAssertEqual(HumanReadableFileSize(UInt64(1025)), "1KB")
    XCTAssertEqual(HumanReadableFileSize(UInt64(1458)), "1.5KB")
    XCTAssertEqual(HumanReadableFileSize(UInt64(1024 * 1024)), "1MB")
    XCTAssertEqual(HumanReadableFileSize(UInt64(1024 * 1024 * 1024)), "1GB")
    XCTAssertEqual(HumanReadableFileSize(UInt64(1024 * 1024 * 1024 * 1024)), "1TB")
  }
  
  func testFileHandleOperation() {
    let dateString = currentTimeString()
    let filename = "SRPathTest-\(dateString).txt"
    let path = SRPath.documentsPath.string.stringByAppendingPathComponent(filename)
    let testContent = "This\nis\ntest content.\nEOF"
    
    let f = SRPath(path)
    
    // Write the file with text content
    
    if let fp = f.fileHandleForWriting() {
      let data = testContent.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
      XCTAssertNotNil(data)
      fp.write(data!)
      fp.close()
      
      XCTAssertTrue(f.isFile)
    } else {
      XCTFail()
    }
    
    XCTAssertEqual(f.size, 25)
    XCTAssertEqual(f.humanReadableSize, "25B")
    
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
        index += 1
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
        index += 1
      }
    } else {
      XCTFail()
    }
  }
}
