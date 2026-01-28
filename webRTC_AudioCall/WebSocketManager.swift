//
//  WebSocketManager.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//

import Foundation

final class WebSocketManager: NSObject {

    private var webSocketTask: URLSessionWebSocketTask?
    private let queue = DispatchQueue(label: "websocket.queue")

    var onMessage: ((String) -> Void)?

    func connect() {
        let url = URL(string: "wss://26d3430920e9.ngrok-free.app")!
        let session = URLSession(configuration: .default,
                                 delegate: self,
                                 delegateQueue: .main)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receive()
        print("✅ WebSocket connected")
    }

    func send(_ text: String) {
        webSocketTask?.send(.string(text)) { error in
            if let error = error {
                print("❌ WS send error:", error)
            }
        }
    }

    private func receive() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    self?.onMessage?(text)
                }
            case .failure(let error):
                print("❌ WS receive error:", error)
            }
            self?.receive()
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        print("🔌 WebSocket disconnected")
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {}

