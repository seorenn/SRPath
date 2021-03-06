//
//  SRPathTests.swift
//  SRPathTests
//
//  Created by Heeseung Seo on 2016. 3. 18..
//  Copyright © 2016년 Seorenn. All rights reserved.
//

import XCTest
@testable import SRPath

fileprivate func currentTimeString() -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-ddTHH:mm:ss"
  formatter.timeZone = TimeZone.current
  
  return formatter.string(from: Date())
}

fileprivate func isEqualDate(_ left: Date, right: Date) -> Bool {
  let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
  let leftComponents = calendar.dateComponents([ .year, .month, .day ], from: left)
  let rightComponents = calendar.dateComponents([ .year, .month, .day ], from: right)
  
  return leftComponents.year == rightComponents.year && leftComponents.month == rightComponents.month && leftComponents.day == rightComponents.day
}

fileprivate extension String {
  fileprivate var lastPathComponent: String {
    return (self as NSString).lastPathComponent
  }
  
  fileprivate var stringByDeletingLastPathComponent: String {
    return (self as NSString).deletingLastPathComponent
  }
  
  fileprivate var pathExtension: String {
    return (self as NSString).pathExtension
  }
  
  fileprivate var stringByDeletingPathExtension: String {
    return (self as NSString).deletingPathExtension
  }
  
  fileprivate func stringByAppendingPathComponent(_ component: String) -> String {
    return (self as NSString).appendingPathComponent(component)
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
    XCTAssertNotNil(path.mkdir(intermediateDirectories: true))
    XCTAssertTrue(path.exists)
    
    let renamedFile = path.rename(name: "SRDirectoryTest-New")!
    XCTAssertEqual(renamedFile.name, "SRDirectoryTest-New")
    XCTAssertTrue(renamedFile.exists)
    
    XCTAssertTrue(renamedFile.trash())
  }
  
  func testMove() {
    let oldContainer = SRPath.documentsPath + "SRDirectoryContainer1"
    XCTAssertNotNil(oldContainer.mkdir(intermediateDirectories: true))
    
    let content = oldContainer + "content-dir"
    XCTAssertNotNil(content.mkdir(intermediateDirectories: true))
    XCTAssertTrue(content.isDirectory)
    
    let newContainer = SRPath.documentsPath + "SRDirectoryContainer2"
    XCTAssertNotNil(newContainer.mkdir(intermediateDirectories: true))
    XCTAssertTrue(newContainer.isDirectory)
    
    let movedFile = content.moveTo(path: newContainer)!
    XCTAssertEqual(movedFile.string.stringByDeletingLastPathComponent.lastPathComponent, "SRDirectoryContainer2")
    
    XCTAssertEqual(oldContainer.contents.count, 0)
    XCTAssertEqual(newContainer.contents.count, 1)
    XCTAssertEqual(newContainer.directories.count, 1)
    
    XCTAssertTrue(oldContainer.trash())
    XCTAssertTrue(newContainer.trash())
    
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
    XCTAssertEqual(String(describing: file), "/Some/Special/File")
  }
  
  func testSizeString() {
    XCTAssertEqual(HumanReadableFileSize(size: Int64(1025)), "1KB")
    XCTAssertEqual(HumanReadableFileSize(size: Int64(1458)), "1.5KB")
    XCTAssertEqual(HumanReadableFileSize(size: Int64(1024 * 1024)), "1MB")
    XCTAssertEqual(HumanReadableFileSize(size: Int64(1024 * 1024 * 1024)), "1GB")
    XCTAssertEqual(HumanReadableFileSize(size: Int64(1024 * 1024 * 1024 * 1024)), "1TB")
  }
  
  func testFileHandleOperation() {
    let dateString = currentTimeString()
    let filename = "SRPathTest-\(dateString).txt"
    let path = SRPath.documentsPath.string.stringByAppendingPathComponent(filename)
    let testContent = "This\nis\ntest content.\nEOF"
    
    let f = SRPath(path)
    
    // Write the file with text content
    
    if let fp = f.fileHandleForWriting() {
      let data = testContent.data(using: String.Encoding.utf8, allowLossyConversion: false)
      XCTAssertNotNil(data)
      fp.write(data!)
      fp.close()
      
      XCTAssertTrue(f.isFile)
    } else {
      XCTFail()
    }
    
    XCTAssertEqual(f.size, 25)
    XCTAssertEqual(f.humanReadableSize, "25B")
    
    let today = Date()
    XCTAssertTrue(isEqualDate(today, right: f.creationDate! as Date))
    XCTAssertTrue(isEqualDate(today, right: f.modificationDate! as Date))
    
    // Read file's content and compare with it!
    
    if let fin = f.fileHandleForReading() {
      if let readedData = fin.read() {
        let readedContent = NSString(data: readedData, encoding: String.Encoding.utf8.rawValue) as! String
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
      let components = testContent.components(separatedBy: "\n")
      var index = 0
      while let line = finput.readline() {
        XCTAssertEqual(line, components[index])
        index += 1
      }
      
      finput.close()
    }
    
    if let finpall = f.fileHandleForReading() {
      let components = testContent.components(separatedBy: "\n")
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
