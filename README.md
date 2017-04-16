# AudioSlicer
Audio file slicer by silence chunk

# Language 
swift 3.1

# Brief

``` swift
let audioslicer = AudioSlicer(filePath:"audio.mp3")
audioslicer.silenceDuration = 2 // sec
audioslicer.silenceThreshold = 0.1 // [0,1]
let slicedFiles = try! audioslicer.export(destPath:docpath) 
```


