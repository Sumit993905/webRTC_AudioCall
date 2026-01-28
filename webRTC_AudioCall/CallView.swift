//
//  CallView.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//

import SwiftUI

struct CallView: View {

    private let socket = WebSocketManager()
    private let rtc = WebRTCManager()

    var body: some View {
        VStack(spacing: 20) {

            Button("Connect") {
                rtc.socket = socket
                socket.onMessage = { rtc.handleSignal($0) }
                socket.connect()
                print("Connected Sucessfully.....")
            }

            Button("Start Call") {
                rtc.startCall()   // sirf 1 device dabayega
            }

            Button("Mute / Unmute") {
                rtc.toggleMute()
            }

            Button("End Call") {
                rtc.endCall()
                socket.disconnect()
            }
            .foregroundColor(.red)
        }
        .padding()
    }
}


#Preview {
    CallView()
}
