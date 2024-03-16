//
//  9D35A7E8-5468-45B4-ACFC-37738B5C1AD0: 13:12 3/15/24
//  FocalApp.swift by Gab
//  

import SwiftUI

@main
struct FocalApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
