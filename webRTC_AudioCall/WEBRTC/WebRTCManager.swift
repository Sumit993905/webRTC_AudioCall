//
//  WebRTCManager.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//


import WebRTC
import Combine

@MainActor
final class WebRTCManager: ObservableObject {

    @Published var localVideoTrack: RTCVideoTrack?
    @Published var remoteVideoTrack: RTCVideoTrack?

    let client = WebRTCClient()
    let signaling: SocketSignalingClient

    private var roomId = ""
    private var callType: CallType = .audio

    init(signalingURL: URL) {
        signaling = SocketSignalingClient(url: signalingURL)
        bind()
    }

    func joinRoom(roomId: String) {
        self.roomId = roomId
        signaling.connect()
        signaling.join(roomId: roomId)
    }

    func startCall(type: CallType) {
        self.callType = type

        client.setupAudio()
        if type == .video {
            client.setupVideo()
            localVideoTrack = client.localVideoTrack
        }

        client.createOffer {
            self.signaling.sendOffer($0,
                                     roomId: self.roomId,
                                     callType: type)
        }
    }

    func leaveRoom() {
        signaling.leave(roomId: roomId)
        signaling.disconnect()
        client.peerConnection.close()
    }

    private func bind() {

        client.onICECandidate = { [weak self] in
            guard let self else { return }
            self.signaling.sendICE($0, roomId: self.roomId)
        }

        client.onRemoteVideoTrack = { [weak self] track in
            guard let self else { return }
            // Ensure assignment on the main actor
            Task { @MainActor in
                self.remoteVideoTrack = track
            }
        }

        signaling.onOffer = { [weak self] offer, _ in
            guard let self else { return }
            Task {
                do {
                    try await self.client.peerConnection.setRemoteDescription(offer)
                    self.client.createAnswer { [weak self] answer in
                        guard let self else { return }
                        self.signaling.sendAnswer(answer, roomId: self.roomId)
                    }
                } catch {
                    // Handle or log the error from setting the remote description
                    print("Failed to set remote description for offer: \(error)")
                }
            }
        }

        signaling.onAnswer = { [weak self] answer in
            guard let self else { return }
            Task {
                do {
                    try await self.client.peerConnection.setRemoteDescription(answer)
                } catch {
                    print("Failed to set remote description for answer: \(error)")
                }
            }
        }

        signaling.onICE = { [weak self] candidate in
            guard let self else { return }
            self.client.peerConnection.add(candidate) { error in
                if let error {
                    print("Failed to add ICE candidate: \(error)")
                }
            }
        }
    }
}

