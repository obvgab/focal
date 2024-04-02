//
//  E30E4976-1A0E-4A62-9516-372789EE6B87: 13:12 3/15/24
//  ContentView.swift by Gab
//  

import SwiftUI

struct ContentView: View {
    @State var selectedFilter: PrecomputedTransforms = .deuteranopiaSim
    
    var body: some View {
        ZStack(alignment: .bottom) {
            let cameraView = MetalView<SamplingDelegate>(.auto)
            cameraView
                .framebufferOnly(false)
                .preferredFramesPerSecond(60)
                .aspectRatio(CGSize(width: 1080, height: 1920), contentMode: .fill) // TODO: Adjust for macOS
                .ignoresSafeArea()

            FilterPicker(selectedFilter: $selectedFilter) { type in cameraView.changeReplacementTexture(type.rawValue) }
                .foregroundStyle(Color(red: 0.9803921569, green: 1.0, blue: 0.8980392157))
                .padding(.horizontal, 25)
                .padding(.vertical)
        }
    }
}

extension MetalView where Delegate == SamplingDelegate {
    func changeReplacementTexture(_ textureName: String) {
        while (delegate.currentFrameTexture == nil) {} // Busy wait??
        delegate.changeReplacementTexture(textureName)
    }
}

enum PrecomputedTransforms: String, CaseIterable, Identifiable {
    var id: Self { return self }
    
    case deuteranopiaSim = "deuteranopia-sim-machado"
    case protanopiaSim = "protanopia-sim-machado"
    case original = "original"
    case deuteranopiaDalton = "deuteranopia-dalton-nvidia"
    case protanopiaDalton = "protanopia-dalton-nvidia"
    
    func displayName() -> String {
        switch self {
        case .deuteranopiaSim: "Green-Blind Simulation"
        case .protanopiaSim: "Red-Blind Simulation"
        case .deuteranopiaDalton: "Green-Blind Correction"
        case .protanopiaDalton: "Red-Blind Correction"
        default: "Normal Colors"
        }
    }
    
    func advancedDisplayName() -> String {
        switch self {
        case .deuteranopiaSim: "Deuteranopia Simulation using Machado's Method"
        case .protanopiaSim: "Protanopia Simulation using Machado's Method"
        case .deuteranopiaDalton: "Deuteranopia Daltonization using Nvidia's Temporally-Stable Transforms"
        case .protanopiaDalton: "Protanopia Daltonization using Nvidia's Temporally-Stable Transforms"
        default: "Straight from the Camera Feed"
        }
    }
}

// Make generic later so I can reuse this in other projects
struct FilterPicker: View {
    @Binding var selectedFilter: PrecomputedTransforms
    var updateTexture: (PrecomputedTransforms) -> Void
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(PrecomputedTransforms.allCases, id: \.self) { transform in
                        Text(transform.displayName())
                            .font(.subheadline)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .background(Capsule().foregroundStyle(transform == selectedFilter ? Color(red: 0.1450980392, green: 0.1137254902, blue: 0.2117647059) : .clear))
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    selectedFilter = transform
                                }
                            }
                    }
                }
            }
            .onChange(of: selectedFilter) { _, transform in
                withAnimation {
                    scrollView.scrollTo(transform, anchor: .center)
                }
                
                updateTexture(transform)
            }
            .onAppear {
                selectedFilter = .original
            }
        }
        .padding()
        .background(Color(red: 0.1098039216, green: 0.09411764706, blue: 0.137254902))
        .clipShape(.rect(cornerRadius: 25))
    }
}

#Preview {
    ContentView()
}
