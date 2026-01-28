//
//  CallType.swift
//  webRTC_AudioCall
//
//  Created by Sumit Raj Chingari on 28/01/26.
//

import Foundation

enum CallType: String, Identifiable {
    case audio
    case video

    var id: String { rawValue }
}

