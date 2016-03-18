SRPath Framework
================

The Frameworks for File and Directory Path.

## SRPath

Initialization:

<pre>
let path = SRPath.downloadsPath + "someFile.txt"
let file = SRFile(path)
</pre>

Get File Informations:

<pre>
file.isFile               // true
file.isDirectory          // false
file.name                 // "someFile.txt"
file.parentPath           // (SRPath object of your Downloads directory)
file.extensionName        // "txt"
</pre>

Create Directory:

TODO: This will be change to another method.

<pre>
let path = file.documentsPath + "/anotherFile.txt"
let newDir = SRPath(creatingDirectoryPath: path.string, intermediateDirectories: true)
</pre>

Directory Iteration:

<pre>
let directory = SRPath("/foo/bar/path") // Target path is /foo/bar/path
directory.directories                   // Directories in target path. Type is [SRPath]
directory.files                         // Files in target path. Type is [SRPath]
directory.contents                      // All files and directories in target path. Type is [SRPath]
</pre>

Or

<pre>
let contents = dir("/foo/bar/path")
</pre>

And Another Operations:

<pre>
let movedDir = dir.movedToPathString("/foo/bar/some/another/directory")!
let renamedDir = movedDir.renamedPath("another_name")!
renamedDir.trash()
</pre>

## SRFileHandle

Open File:

<pre>
let fin = SRFileHandle(pathForReading: SRPath("/foo/bar/file"))
</pre>

or

<pre>
let file = SRPath("/foo/bar/file")
let fin = file.fileHandleForReading()
</pre>

Read or Write Full Text or NSData:

<pre>
let text = fin.text
fin.text = "This is another text"

let data = fin.data
fin.data = someDataInstance
</pre>

NOTE: Not recommend for huge file.

Pythontic Methods:

<pre>
repeat let line = fin.readline() {
    ...
}
</pre>

or

<pre>
let lines = fin.readlines()
</pre>

TODO: Methods to control File Offset

## SRPathMonitor

SRPathMonitor class monitor changes of some paths. This module support OS X platform only.

Usage Example:

<pre>
class SomeClass {
    let monitor: SRPathMonitor
    init() {
        self.monitor = SRPathMonitor(pathStrings: ["/foo/bar/dir"],
                                           queue: nil,
                                        delegate: self)
        self.monitor.start()
    }

    ...

    func pathMonitor(pathMonitor: SRPathMonitor,
                    detectEvents: [SRPathEvent]) {
        for event in detectEvents {
            if event.created {
                ...
            }
        }
    }
}
</pre>

SRPathEvent support fields likes below:

<pre>
event.path
event.created
event.removed
event.renamed
event.modified
</pre>

# Licensing

SRPath is licensed under MIT License Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
