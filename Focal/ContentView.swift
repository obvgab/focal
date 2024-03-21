//
//  E30E4976-1A0E-4A62-9516-372789EE6B87: 13:12 3/15/24
//  ContentView.swift by Gab
//  

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            MetalView<SamplingDelegate>(.auto)
                .framebufferOnly(false)
                .preferredFramesPerSecond(60)
        }
    }
}

#Preview {
    ContentView()
}
