// Decode an Apple Positional Audio Codec (APAC) track to 4-channel PCM.
//
// Usage (macOS 15+):  swift decode-apac.swift input.mov output.caf
//
// Reads the first audio track with 4 or more channels (the APAC spatial
// track; iPhone spatial captures also carry a stereo AAC track we skip),
// decodes it via AVFoundation and writes linear-PCM CAF. The channel
// order of Apple's ambisonic captures is ambiX (ACN/SN3D): W, Y, Z, X.

import AVFoundation

let args = CommandLine.arguments
guard args.count == 3 else {
    print("usage: swift decode-apac.swift <input.mov> <output.caf>")
    exit(1)
}
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])

let asset = AVURLAsset(url: inURL)
guard let track = asset.tracks(withMediaType: .audio).first(where: { t in
    t.formatDescriptions.contains { d in
        let desc = d as! CMFormatDescription
        guard let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee
        else { return false }
        return asbd.mChannelsPerFrame >= 4
    }
}) else {
    print("error: no 4-channel (spatial) audio track found")
    exit(2)
}

let reader = try AVAssetReader(asset: asset)
let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
    AVFormatIDKey: kAudioFormatLinearPCM,
    AVLinearPCMBitDepthKey: 32,
    AVLinearPCMIsFloatKey: true,
    AVLinearPCMIsNonInterleaved: true,
])
reader.add(output)
reader.startReading()

var outFile: AVAudioFile?
var frames: Int64 = 0
while let sbuf = output.copyNextSampleBuffer() {
    let n = CMSampleBufferGetNumSamples(sbuf)
    guard n > 0, let desc = CMSampleBufferGetFormatDescription(sbuf) else { continue }
    let fmt = AVAudioFormat(cmAudioFormatDescription: desc)
    if outFile == nil {
        // file settings must describe an interleaved format (CAF layout);
        // the processing format (commonFormat/interleaved:) matches our
        // deinterleaved float32 buffers — ExtAudioFile interleaves on write
        let fileSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: fmt.sampleRate,
            AVNumberOfChannelsKey: Int(fmt.channelCount),
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
        ]
        outFile = try AVAudioFile(forWriting: outURL, settings: fileSettings,
                                  commonFormat: .pcmFormatFloat32,
                                  interleaved: false)
    }
    guard let pcm = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(n))
    else { continue }
    pcm.frameLength = AVAudioFrameCount(n)
    try CMSampleBufferCopyPCMDataIntoAudioBufferList(
        sbuf, at: 0, frameCount: Int32(n), into: pcm.mutableAudioBufferList)
    try outFile!.write(from: pcm)
    frames += Int64(n)
}
if reader.status == .failed {
    print("error: \(reader.error?.localizedDescription ?? "unknown")")
    exit(3)
}
print("wrote \(frames) frames to \(outURL.path)")
