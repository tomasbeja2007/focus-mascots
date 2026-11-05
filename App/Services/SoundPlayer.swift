import AVFoundation
import Foundation

/// Ambient focus sounds (generated live, no audio files) and the completion chime.
@MainActor
final class SoundPlayer {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var generator: NoiseGenerator?
    private var chimePlayer: AVAudioPlayer?
    private(set) var current: AmbientSound = .off

    func playAmbient(_ sound: AmbientSound, volume: Double) {
        stopAmbient()
        guard sound != .off else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate > 0
            ? engine.outputNode.outputFormat(forBus: 0).sampleRate : 44_100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        let gen = NoiseGenerator(kind: sound, sampleRate: sampleRate)
        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let value = gen.next()
                for buffer in buffers {
                    let ptr = UnsafeMutableBufferPointer<Float>(buffer)
                    ptr[frame] = value
                }
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = Float(max(0, min(1, volume)))
        do {
            try engine.start()
            sourceNode = node
            generator = gen
            current = sound
        } catch {
            engine.detach(node)
        }
    }

    func setVolume(_ volume: Double) {
        engine.mainMixerNode.outputVolume = Float(max(0, min(1, volume)))
    }

    func pauseAmbient() {
        if engine.isRunning { engine.pause() }
    }

    func resumeAmbient() {
        guard sourceNode != nil, !engine.isRunning else { return }
        try? engine.start()
    }

    func stopAmbient() {
        engine.stop()
        if let node = sourceNode {
            engine.detach(node)
        }
        sourceNode = nil
        generator = nil
        current = .off
    }

    func playChime(named name: String = "chime") {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            chimePlayer = try AVAudioPlayer(contentsOf: url)
            chimePlayer?.volume = 0.9
            chimePlayer?.play()
        } catch {}
    }
}

/// Real-time noise synthesis. Runs on the audio thread, so it is a plain class
/// with no locks or allocations in `next()`.
final class NoiseGenerator {
    private let kind: AmbientSound
    private let sampleRate: Double
    private var brown: Float = 0
    // Paul Kellet's pink-noise filter state
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0
    private var phase: Double = 0
    private var lowpass: Float = 0
    private var dropEnvelope: Float = 0
    private var dropTone: Float = 0
    private var dropPhase: Float = 0
    private var rng = SystemRandomNumberGenerator()

    init(kind: AmbientSound, sampleRate: Double) {
        self.kind = kind
        self.sampleRate = sampleRate
    }

    private func white() -> Float {
        Float.random(in: -1...1, using: &rng)
    }

    private func pink() -> Float {
        let w = white()
        b0 = 0.99886 * b0 + w * 0.0555179
        b1 = 0.99332 * b1 + w * 0.0750759
        b2 = 0.96900 * b2 + w * 0.1538520
        b3 = 0.86650 * b3 + w * 0.3104856
        b4 = 0.55000 * b4 + w * 0.5329522
        b5 = -0.7616 * b5 - w * 0.0168980
        let out = b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362
        b6 = w * 0.115926
        return out * 0.11
    }

    private func brownNoise() -> Float {
        brown = (brown + 0.02 * white()) / 1.02
        return brown * 3.2
    }

    func next() -> Float {
        switch kind {
        case .off:
            return 0
        case .white:
            return white() * 0.18
        case .pink:
            return pink() * 0.9
        case .brown:
            return brownNoise() * 0.9
        case .rain:
            // Soft hiss plus random droplets.
            let hiss = pink() * 0.45
            lowpass += 0.12 * (hiss - lowpass)
            if dropEnvelope < 0.001 && Float.random(in: 0...1, using: &rng) < 0.0009 {
                dropEnvelope = Float.random(in: 0.15...0.4, using: &rng)
                dropTone = Float.random(in: 1800...4200, using: &rng)
            }
            dropEnvelope *= 0.9985
            dropPhase += dropTone / Float(sampleRate)
            if dropPhase > 1 { dropPhase -= 1 }
            let drop = sinf(dropPhase * 2 * .pi) * dropEnvelope * 0.25
            return lowpass + drop + brownNoise() * 0.35
        case .ocean:
            // Brown noise with a slow swell, like waves rolling in.
            phase += 1 / sampleRate
            let swell = Float(0.55 + 0.45 * sin(phase * 2 * .pi / 9.0))
            return brownNoise() * (0.35 + 0.75 * swell)
        }
    }
}
