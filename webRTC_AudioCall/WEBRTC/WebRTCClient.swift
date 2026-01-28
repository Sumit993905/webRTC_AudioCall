//
//  WebRTCClient.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//

import WebRTC
import AVFoundation

final class WebRTCClient: NSObject {

    let peerConnection: RTCPeerConnection
    var audioTrack: RTCAudioTrack?
    var localVideoTrack: RTCVideoTrack?

    var onICECandidate: ((RTCIceCandidate) -> Void)?
    var onRemoteVideoTrack: ((RTCVideoTrack) -> Void)?

    override init() {
        let factory = RTCPeerConnectionFactory()
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]
        config.sdpSemantics = .unifiedPlan

        peerConnection = factory.peerConnection(
            with: config,
            constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil),
            delegate: nil
        )!

        super.init()
        peerConnection.delegate = self
    }

    func setupAudio() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord,
                                 mode: .voiceChat,
                                 options: [.defaultToSpeaker])
        try? session.setActive(true)

        let factory = RTCPeerConnectionFactory()
        let source = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        audioTrack = factory.audioTrack(with: source, trackId: "audio0")
        if let audioTrack = audioTrack {
            _ = peerConnection.add(audioTrack, streamIds: ["stream0"]) // add(_:streamIds:) is sync in current SDK
        }
    }

    func setupVideo() {
        let factory = RTCPeerConnectionFactory()
        let source = factory.videoSource()
        localVideoTrack = factory.videoTrack(with: source, trackId: "video0")
        if let localVideoTrack = localVideoTrack {
            _ = peerConnection.add(localVideoTrack, streamIds: ["stream0"]) // add(_:streamIds:) is sync in current SDK
        }
    }

    func createOffer(cb: @escaping (RTCSessionDescription) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
                let sdp = try await self.peerConnection.offer(for: constraints)
                try await self.peerConnection.setLocalDescription(sdp)
                await MainActor.run {
                    cb(sdp)
                }
            } catch {
                // You may want to surface this error via another callback or logging
                print("Failed to create offer/set local description: \(error)")
            }
        }
    }

    func createAnswer(cb: @escaping (RTCSessionDescription) -> Void) {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
                let sdp = try await self.peerConnection.answer(for: constraints)
                try await self.peerConnection.setLocalDescription(sdp)
                await MainActor.run {
                    cb(sdp)
                }
            } catch {
                print("Failed to create answer/set local description: \(error)")
            }
        }
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    

    func peerConnection(_ pc: RTCPeerConnection,
                        didAdd rtpReceiver: RTCRtpReceiver,
                        streams: [RTCMediaStream]) {

        if let video = rtpReceiver.track as? RTCVideoTrack {
            onRemoteVideoTrack?(video)
        }

        if let audio = rtpReceiver.track as? RTCAudioTrack {
            audio.isEnabled = true
        }
    }

    func peerConnection(_ pc: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {
        onICECandidate?(candidate)
    }
}
