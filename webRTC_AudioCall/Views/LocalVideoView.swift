//
//  LocalVideoView.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//

import SwiftUI
import WebRTC

struct LocalVideoView: UIViewRepresentable {

    let videoTrack: RTCVideoTrack?

    func makeUIView(context: Context) -> UIView {

        guard let track = videoTrack else {
            let label = UILabel()
            label.text = "Local Video"
            label.textColor = .white
            label.textAlignment = .center
            label.backgroundColor = .darkGray
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
    LocalVideoView(videoTrack: nil)
        .frame(width: 120, height: 180)
}
