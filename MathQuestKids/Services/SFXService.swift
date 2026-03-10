import AVFoundation
import Foundation

enum SFXEvent {
    case tap
    case hint
    case correct
    case incorrect
    case reward
}

final class SFXService {
    private struct ToneSegment {
        let frequencies: [Double]
        let duration: Double
        let amplitude: Float
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let queue = DispatchQueue(label: "NP.MathQuestKids.SFXService")

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        engine.mainMixerNode.outputVolume = 0.55
        engine.prepare()
        try? engine.start()
    }

    func play(_ event: SFXEvent, theme: VisualTheme) {
        queue.async { [weak self] in
            guard let self else { return }
            guard self.ensureEngineRunning() else { return }

            let buffer = self.makeToneBuffer(segments: self.toneSegments(event: event, theme: theme))

            // Schedule first, then play. Calling play() before a scheduled buffer can trigger
            // "player did not see an IO cycle" assertions on some simulator/device states.
            self.player.stop()
            self.player.scheduleBuffer(buffer, at: nil, options: [])
            self.player.play()
        }
    }

    func preview(theme: VisualTheme) {
        play(.reward, theme: theme)
    }

    private func toneSegments(event: SFXEvent, theme: VisualTheme) -> [ToneSegment] {
        let themeShift: Double
        switch theme {
        case .candyland: themeShift = 12
        case .axolotl: themeShift = -18
        case .rainbowUnicorn: themeShift = 22
        case .starsSpace: themeShift = -8
        }

        switch event {
        case .tap:
            return [ToneSegment(frequencies: [420 + themeShift], duration: 0.05, amplitude: 0.18)]
        case .hint:
            return [ToneSegment(frequencies: [440 + themeShift, 554 + themeShift], duration: 0.12, amplitude: 0.20)]
        case .correct:
            return [ToneSegment(frequencies: [524 + themeShift, 659 + themeShift, 784 + themeShift], duration: 0.17, amplitude: 0.22)]
        case .incorrect:
            return [ToneSegment(frequencies: [240 + themeShift, 180 + themeShift], duration: 0.15, amplitude: 0.16)]
        case .reward:
            return [
                ToneSegment(frequencies: [392 + themeShift, 523 + themeShift], duration: 0.16, amplitude: 0.19),
                ToneSegment(frequencies: [523 + themeShift, 659 + themeShift, 784 + themeShift], duration: 0.18, amplitude: 0.22),
                ToneSegment(frequencies: [659 + themeShift, 784 + themeShift, 988 + themeShift], duration: 0.20, amplitude: 0.24),
                ToneSegment(frequencies: [784 + themeShift, 988 + themeShift, 1175 + themeShift], duration: 0.34, amplitude: 0.26)
            ]
        }
    }

    private func makeToneBuffer(segments: [ToneSegment]) -> AVAudioPCMBuffer {
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44_100
        let channelCount = outputFormat.channelCount > 0 ? outputFormat.channelCount : 2
        let totalDuration = segments.reduce(0) { $0 + $1.duration }
        let frameCount = AVAudioFrameCount(sampleRate * max(totalDuration, 0.05))
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channels = buffer.floatChannelData else {
            return buffer
        }

        var frameCursor = 0
        for segment in segments {
            let segmentFrames = Int(sampleRate * segment.duration)
            fillSegment(
                channels: channels,
                channelCount: Int(channelCount),
                sampleRate: sampleRate,
                startFrame: frameCursor,
                frameCount: segmentFrames,
                frequencies: segment.frequencies,
                amplitude: segment.amplitude
            )
            frameCursor += segmentFrames
        }

        return buffer
    }

    private func fillSegment(
        channels: UnsafePointer<UnsafeMutablePointer<Float>>,
        channelCount: Int,
        sampleRate: Double,
        startFrame: Int,
        frameCount: Int,
        frequencies: [Double],
        amplitude: Float
    ) {
        let twoPi = 2.0 * Double.pi
        let attack = max(1.0, Double(frameCount) * 0.12)
        let releaseStart = Double(frameCount) * 0.72

        for localFrame in 0..<frameCount {
            let absoluteFrame = startFrame + localFrame
            let time = Double(localFrame) / sampleRate
            let envelope: Double
            if Double(localFrame) < attack {
                envelope = Double(localFrame) / attack
            } else if Double(localFrame) > releaseStart {
                envelope = max(0, 1 - ((Double(localFrame) - releaseStart) / max(Double(frameCount) - releaseStart, 1)))
            } else {
                envelope = 1
            }

            var sample: Double = 0
            for freq in frequencies {
                sample += sin(twoPi * freq * time)
                sample += 0.34 * sin(twoPi * freq * 2 * time)
                sample += 0.16 * sin(twoPi * freq * 3 * time)
            }
            sample /= max(Double(frequencies.count), 1)
            let value = Float(sample * envelope) * amplitude

            for channelIndex in 0..<channelCount {
                channels[channelIndex][absoluteFrame] = value
            }
        }
    }

    private func ensureEngineRunning() -> Bool {
        if engine.isRunning { return true }
        engine.prepare()
        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }
}
