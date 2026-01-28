//
//  CallView.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//

import SwiftUI
import WebRTC

struct CallView: View {

    let roomId: String
    let callType: CallType
    let manager: WebRTCManager

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {

            if callType == .video,
               let remote = manager.remoteVideoTrack {
                RemoteVideoView(videoTrack: remote)
            }

            HStack {
                Button("End Call") {
                    manager.leaveRoom()
                    dismiss()
                }
            }
        }
        .onAppear {
            manager.startCall(type: callType)
        }
    }
}


#Preview("Audio Call") {
    ZStack {
        Color.black
        VStack {
            Spacer()
            Text("Audio Call")
                .foregroundColor(.white)
                .font(.title)
            Spacer()
        }
    }
}

#Preview("Video Call") {
    ZStack {
        RemoteVideoView(videoTrack: nil)
        LocalVideoView(videoTrack: nil)
            .frame(width: 120, height: 180)
            .cornerRadius(12)
            .padding()
            .position(x: 300, y: 150)
    }
}
