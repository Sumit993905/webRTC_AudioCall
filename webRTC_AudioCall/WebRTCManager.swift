//
//  WebRTCManager.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//

import WebRTC
import AVFoundation

final class WebRTCManager: NSObject {

    private let factory = RTCPeerConnectionFactory()
    private var peerConnection: RTCPeerConnection!
    private var localAudioTrack: RTCAudioTrack?

    var socket: WebSocketManager?

    // MARK: - INIT
    override init() {
        super.init()
        setupAudioSession()
        setupPeerConnection()
        createAudioTrack()
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord,
                                 mode: .voiceChat,
                                 options: [.defaultToSpeaker])
        try? session.setActive(true)
    }

    // MARK: - PeerConnection
    private func setupPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )

        peerConnection = factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
    }

    // MARK: - Audio Track
    private func createAudioTrack() {
        let source = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil,
                                                                   optionalConstraints: nil))
        let track = factory.audioTrack(with: source, trackId: "audio0")
        localAudioTrack = track
        peerConnection.add(track, streamIds: ["stream0"])
    }

    // =====================================================
    // ▶️ START CALL (Offer)
    // =====================================================
    func startCall() {
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveAudio": "true"],
            optionalConstraints: nil
        )

        peerConnection.offer(for: constraints) { [weak self] sdp, error in
            guard let self = self, let sdp = sdp else { return }

            self.peerConnection.setLocalDescription(sdp) { _ in
                let json: [String: Any] = [
                    "type": "sdp",
                    "sdp": sdp.sdp
                ]
                self.sendJSON(json)
                print("📤 Offer sent")
            }
        }
    }

    // =====================================================
    // 📥 HANDLE SIGNAL (SDP + ICE)
    // =====================================================
    func handleSignal(_ text: String) {
        guard
            let data = text.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let type = json["type"] as? String
        else { return }

        if type == "sdp" {
            handleRemoteSDP(json["sdp"] as! String)
        }

        if type == "ice" {
            let candidate = RTCIceCandidate(
                sdp: json["candidate"] as! String,
                sdpMLineIndex: Int32(json["sdpMLineIndex"] as! Int),
                sdpMid: json["sdpMid"] as? String
            )
            peerConnection.add(candidate) { error in
                if let error = error {
                    print("❌ Failed to add ICE candidate:", error)
                } else {
                    print("✅ ICE candidate added")
                }
            }

        }
    }

    private func handleRemoteSDP(_ sdpString: String) {
        let type: RTCSdpType = sdpString.contains("a=setup:actpass") ? .offer : .answer
        let sdp = RTCSessionDescription(type: type, sdp: sdpString)

        peerConnection.setRemoteDescription(sdp) { [weak self] _ in
            guard let self = self else { return }
            if type == .offer {
                self.createAnswer()
            }
        }
    }

    private func createAnswer() {
        peerConnection.answer(for: RTCMediaConstraints(mandatoryConstraints: nil,
                                                       optionalConstraints: nil)) { [weak self] answer, _ in
            guard let self = self, let answer = answer else { return }

            self.peerConnection.setLocalDescription(answer) { _ in
                let json: [String: Any] = [
                    "type": "sdp",
                    "sdp": answer.sdp
                ]
                self.sendJSON(json)
                print("📤 Answer sent")
            }
        }
    }

    // =====================================================
    // 🔇 MUTE / UNMUTE
    // =====================================================
    func toggleMute() {
        guard let track = localAudioTrack else { return }
        track.isEnabled.toggle()
        print(track.isEnabled ? "🎙️ Mic ON" : "🔇 Mic OFF")
    }

    // =====================================================
    // ❌ END CALL
    // =====================================================
    func endCall() {
        peerConnection.close()
        try? AVAudioSession.sharedInstance().setActive(false)
        print("📞 Call ended")
    }

    // MARK: - JSON Send Helper
    private func sendJSON(_ dict: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let text = String(data: data, encoding: .utf8) {
            socket?.send(text)
        }
    }
}

// MARK: - ICE Delegate
extension WebRTCManager: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
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
    

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didGenerate candidate: RTCIceCandidate) {

        let json: [String: Any] = [
            "type": "ice",
            "sdpMid": candidate.sdpMid ?? "",
            "sdpMLineIndex": candidate.sdpMLineIndex,
            "candidate": candidate.sdp
        ]
        sendJSON(json)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection,
                        didAdd stream: RTCMediaStream) {
        print("🔊 Remote audio connected")
    }

    // baaki delegate methods empty
}

