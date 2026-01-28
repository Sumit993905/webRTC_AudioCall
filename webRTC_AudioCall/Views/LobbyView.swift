//
//  LobbyView.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//

import SwiftUI

struct LobbyView: View {

    let roomId: String

    @State private var userCount = 1
    @State private var ready = false
    @State private var callType: CallType?

    @StateObject private var manager =
        WebRTCManager(signalingURL: URL(string: "https://YOUR_NGROK_URL")!)

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {

            Text("Room: \(roomId)")
            Text("Users: \(userCount)/2")

            Button("🎧 Audio Call") {
                callType = .audio
            }
            .disabled(!ready)

            Button("🎥 Video Call") {
                callType = .video
            }
            .disabled(!ready)

            Button("Leave Room") {
                manager.leaveRoom()
                dismiss()
            }
            .foregroundColor(.red)

            NavigationLink(
                destination: CallView(
                    roomId: roomId,
                    callType: callType ?? .audio,
                    manager: manager
                ),
                isActive: Binding(
                    get: { callType != nil },
                    set: { if !$0 { callType = nil } }
                )
            ) { EmptyView() }
        }
        .onAppear {
            manager.joinRoom(roomId: roomId)

            manager.signaling.onJoined = { count in
                userCount = count
            }

            manager.signaling.onReady = {
                ready = true
                userCount = 2
            }
        }
    }
}


#Preview {
    VStack(spacing: 20) {
        Text("Room: 123")
        Text("Users: 2/2")
            .foregroundColor(.green)

        Button("🎧 Audio Call") {}
        Button("🎥 Video Call") {}

        Button("Leave Room"){}
            .foregroundColor(.red)
    }
    .padding()
}
