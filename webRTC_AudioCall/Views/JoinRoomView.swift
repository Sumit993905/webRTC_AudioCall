//
//  JoinRoomView.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//

import SwiftUI

struct JoinRoomView: View {

    @State private var roomId = ""
    @State private var goLobby = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {

                TextField("Enter Room ID", text: $roomId)
                    .padding(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(style: StrokeStyle(lineWidth: 1))
                    )

                Button("Join") {
                    goLobby = true
                }
                .disabled(roomId.isEmpty)
                .padding(30)
                .background(Color(.systemBlue))
                .foregroundColor(.white)
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(style: StrokeStyle(lineWidth: 1))
                )
                

                NavigationLink(
                    destination: LobbyView(roomId: roomId),
                    isActive: $goLobby
                ) { EmptyView() }
            }
            .padding()
        }
    }
}


#Preview {
    JoinRoomView()
}
