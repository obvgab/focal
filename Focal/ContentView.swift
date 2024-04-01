//
//  E30E4976-1A0E-4A62-9516-372789EE6B87: 13:12 3/15/24
//  ContentView.swift by Gab
//  

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            MetalView<SamplingDelegate>(.auto)
                .framebufferOnly(false)
                .preferredFramesPerSecond(60)
                .clipShape(.rect(cornerRadii: .init(topLeading: 0, bottomLeading: 15, bottomTrailing: 15, topTrailing: 0)))
                .ignoresSafeArea()
            Text("Nice")
        }
    }
}

#Preview {
    ContentView()
}
