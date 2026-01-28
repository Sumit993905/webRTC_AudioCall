//
//  RemoteVideoView.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//

import SwiftUI
import WebRTC

struct RemoteVideoView: UIViewRepresentable {

    let videoTrack: RTCVideoTrack?

    func makeUIView(context: Context) -> UIView {

        guard let track = videoTrack else {
            // 🔹 Preview / fallback
            let label = UILabel()
            label.text = "Remote Video"
            label.textColor = .white
            label.textAlignment = .center
            label.backgroundColor = .black
            return label
        }

        let view = RTCMTLVideoView()
        view.videoContentMode = .scaleAspectFill
        track.add(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}


#Preview {
    RemoteVideoView(videoTrack: nil)
        .frame(height: 300)
}

