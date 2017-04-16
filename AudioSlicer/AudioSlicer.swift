//
//  AudioSlicer.swift
//  AudioSlicer
//
//  Created by pebble8888 on 2017/04/15.
//  Copyright © 2017年 pebble8888. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

public struct AudioSlicer {
    static func linearToDb(_ linear:Double) -> Double {
        return 20.0 * log(linear)
    }
    
    static func dbToLinear(_ db:Double) -> Double {
        return pow(10.0, db/20.0)
    }
    
    public init(){
    }
    
    public init(filePath:String){
        self.filePath = filePath
    }
    
    var filePath:String?
    
    private var filename:String? {
        guard let filePath = filePath else {
            return nil
        }
        guard let v = filePath.components(separatedBy: "/").last else {
            return nil
        }
        guard let w = v.components(separatedBy: ".").first else {
            return nil
        }
        return w
    }
    
    /// linear threshold level
    /// [0, 1.0] 
    public var silenceThreshold:Float = 0.01
   
    /// [sec]
    /// must larger than kResolutionFrame
    public var silenceDuration:Double = 1.0
    
    private let kResolutionFrame:Int64 = 512
    
    public enum AudioSlicerError: Error {
        case general
        case notMono
    }
    
    struct SlicePoint {
        var down:Int64
        var up:Int64
    }
    
    public func export(destPath:String) throws -> [String] {
        print("\(destPath)")
        guard let filePath = filePath else { return [] }
        
        let audiofile:AVAudioFile
        do {
            audiofile = try AVAudioFile(forReading: URL(fileURLWithPath: filePath))
        } catch {
            print("\(error)")
            throw error
        }
        // only process mono audio
        if audiofile.fileFormat.channelCount != 1 {
            throw AudioSlicerError.notMono
        }
        let sampleRate = Int(audiofile.fileFormat.sampleRate)
        
        let silenceDurationFrame:Int = Int(Double(sampleRate) * silenceDuration)
        let pcm = AVAudioPCMBuffer(pcmFormat: audiofile.processingFormat, frameCapacity: UInt32(kResolutionFrame))
        
        var remain:Int64 = audiofile.length
        var lastSilFrame:Int64 = 0
        var frame:Int64 = 0
        var points:[SlicePoint] = []
        while remain > 0 {
            try audiofile.read(into: pcm)
            let len:Int64 = Int64(pcm.frameLength)
            assert(len > 0)
            var val:Float = 0
            guard let data = pcm.floatChannelData else {
                throw AudioSlicerError.general
            }
            vDSP_maxmgv(data[0], 1, &val, UInt(len))
            if val > silenceThreshold {
                if frame - lastSilFrame > Int64(silenceDurationFrame) {
                    // append silence block
                    points.append(SlicePoint(down: lastSilFrame, up: frame))
                }
                lastSilFrame = frame + len
            }
            frame += len
            remain -= len
        }
        let fileformat = AVAudioFormat(commonFormat: .pcmFormatInt16, 
                                              sampleRate: audiofile.fileFormat.sampleRate,
                                              channels: 1,
                                              interleaved: true)
        return try _export(destPath:destPath, 
                       points:points, 
                       length:audiofile.length, 
                       sampleRate:sampleRate, 
                       fileformat:fileformat)
    }
    
    struct X {
        var pos:Int64
        var sil:Bool
    }
    
    func _export(destPath:String, 
                 points:[SlicePoint], 
                 length:Int64, 
                 sampleRate:Int, 
                 fileformat:AVAudioFormat) throws -> [String] 
    {
        //print("\(points)")
        var xes:[X] = []
        for v in points {
            xes.append(X(pos:v.down, sil:true))
            xes.append(X(pos:v.up, sil:false))
        }
        
        var filenames:[String] = []
        if let filename = self.filename {
            
            guard let filePath = filePath else { return [] }
            let infile:AVAudioFile
            do {
                infile = try AVAudioFile(forReading: URL(fileURLWithPath: filePath))
            } catch {
                print("\(error)")
                throw error
            }
            
            var outfile:AVAudioFile?
            var idx = xes.startIndex
            
            let outProcessingFormat:AVAudioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: fileformat.sampleRate, channels: 1, interleaved: true)
            
            let inpcm = AVAudioPCMBuffer(pcmFormat: infile.processingFormat, frameCapacity: UInt32(kResolutionFrame))
            let outpcm = AVAudioPCMBuffer(pcmFormat: outProcessingFormat, frameCapacity: UInt32(kResolutionFrame))
            
            var sil:Bool = false
            if let x = xes.first {
                if x.pos > 0 {
                    sil = false
                } else {
                    sil = true
                }
            }
            var frame:Int64 = 0
            var read_remain:Int64 = length
            while read_remain > 0 {
                var processLen:Int64 = kResolutionFrame
                var doFlip = false
                if outfile == nil {
                    let outname = filename + "_\(idx)\(sil ? "_sil" : "").wav"
                    //print("outname \(outname)")
                    let path = destPath + "/" + outname
                    let url = URL(fileURLWithPath: path)
                    outfile = try AVAudioFile(forWriting: url, 
                                              settings: fileformat.settings, 
                                              commonFormat: .pcmFormatFloat32, 
                                              interleaved:true)
                    filenames.append(outname)
                }
                if idx < xes.count {
                    let x = xes[idx]
                    if frame == x.pos {
                        //print("frame \(frame) x.pos \(x.pos)")
                        processLen = x.pos - frame
                        doFlip = true
                        sil = !sil
                    }
                }
                if processLen > 0 { 
                    inpcm.frameLength = UInt32(processLen)
                    try infile.read(into: inpcm)
                    guard let indata = inpcm.floatChannelData else {
                        throw AudioSlicerError.general
                    }
                
                    outpcm.frameLength = UInt32(processLen)
                    if let outdata = outpcm.floatChannelData {
                        outdata[0].assign(from: indata[0], count: Int(processLen)) 
                    }
                    if let outfile = outfile {
                        do {
                            try outfile.write(from: outpcm)
                        } catch {
                            print("\(error)")
                            throw error
                        }
                    }
                }
                
                if doFlip {
                    outfile = nil
                    idx += 1
                }
                
                frame += processLen
                read_remain -= processLen 
            }
        } else {
            fatalError()
        }
        return filenames
    }
    
    
}
