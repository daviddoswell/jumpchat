//
//  JumpChatApp.swift
//  JumpChat
//
//  Created by David Doswell on 5/12/25.
//

import SwiftUI

@main
struct JumpChatApp: App {
    init() {
        NetworkUtils.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
