//
//  SocketSignalingClient.swift
//  webRTC_AudioCall
//

//

import SocketIO
import WebRTC

final class SocketSignalingClient {

    private let manager: SocketManager
    private let socket: SocketIOClient

    // Callbacks
    var onJoined: ((Int) -> Void)?
    var onReady: (() -> Void)?
    var onOffer: ((RTCSessionDescription, CallType) -> Void)?
    var onAnswer: ((RTCSessionDescription) -> Void)?
    var onICE: ((RTCIceCandidate) -> Void)?
    var onPeerLeft: (() -> Void)?

    init(url: URL) {
        manager = SocketManager(
            socketURL: url,
            config: [.log(true), .compress, .forceWebsockets(true)]
        )
        socket = manager.defaultSocket
        setupListeners()
    }

    func connect() { socket.connect() }
    func disconnect() { socket.disconnect() }

    func join(roomId: String) {
        socket.emit("join", ["roomId": roomId])
    }

    func leave(roomId: String) {
        socket.emit("leave", ["roomId": roomId])
    }

    func sendOffer(_ sdp: RTCSessionDescription,
                   roomId: String,
                   callType: CallType) {
        socket.emit("offer", [
            "roomId": roomId,
            "sdp": sdp.sdp,
            "callType": callType.rawValue
        ])
    }

    func sendAnswer(_ sdp: RTCSessionDescription,
                    roomId: String) {
        socket.emit("answer", [
            "roomId": roomId,
            "sdp": sdp.sdp
        ])
    }

    func sendICE(_ ice: RTCIceCandidate,
                 roomId: String) {
        socket.emit("ice", [
            "roomId": roomId,
            "candidate": [
                "candidate": ice.sdp,
                "sdpMid": ice.sdpMid ?? "",
                "sdpMLineIndex": ice.sdpMLineIndex
            ]
        ])
    }

    private func setupListeners() {

        socket.on("joined") { data, _ in
            let count = (data.first as? [String: Any])?["userCount"] as? Int ?? 1
            self.onJoined?(count)
        }

        socket.on("ready") { _, _ in
            self.onReady?()
        }

        socket.on("offer") { data, _ in
            let dict = data.first as! [String: Any]
            let sdp = RTCSessionDescription(
                type: .offer,
                sdp: dict["sdp"] as! String
            )
            let type = CallType(rawValue: dict["callType"] as! String)!
            self.onOffer?(sdp, type)
        }

        socket.on("answer") { data, _ in
            let dict = data.first as! [String: Any]
            let sdp = RTCSessionDescription(
                type: .answer,
                sdp: dict["sdp"] as! String
            )
            self.onAnswer?(sdp)
        }

        socket.on("ice") { data, _ in
            let cand = (data.first as! [String: Any])["candidate"] as! [String: Any]
            let ice = RTCIceCandidate(
                sdp: cand["candidate"] as! String,
                sdpMLineIndex: cand["sdpMLineIndex"] as! Int32,
                sdpMid: cand["sdpMid"] as? String
            )
            self.onICE?(ice)
        }

        socket.on("peer-left") { _, _ in
            self.onPeerLeft?()
        }
    }
}

