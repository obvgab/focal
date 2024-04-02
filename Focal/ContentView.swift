//
//  E30E4976-1A0E-4A62-9516-372789EE6B87: 13:12 3/15/24
//  ContentView.swift by Gab
//  

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            let cameraView = MetalView<SamplingDelegate>(.auto)
            cameraView
                .framebufferOnly(false)
                .preferredFramesPerSecond(60)
                .ignoresSafeArea()

            FilterPicker { type in cameraView.changeReplacementTexture(type.rawValue) }
                .foregroundStyle(Color(red: 0.9803921569, green: 1.0, blue: 0.8980392157))
                .padding()
        }
    }
}

extension MetalView where Delegate == SamplingDelegate {
    func changeReplacementTexture(_ textureName: String) {
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
    @State var selectedFilter: PrecomputedTransforms?
    @State var showAdvancedName: Bool = false
    var onDragChange: (_ transform: PrecomputedTransforms) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(PrecomputedTransforms.allCases) { transform in
                    Text(transform.displayName())
                        .frame(width: 250, height: 20)
                        .id(transform)
                        .padding(.all)
                        .background(Color(red: 0.1294117647, green: 0.1137254902, blue: 0.1607843137))
                        .clipShape(.rect(cornerRadius: 15))
                }
            }
            .scrollTargetLayout()
        }
        .onChange(of: selectedFilter) { onDragChange(selectedFilter ?? .original) }
        .scrollTargetBehavior(.viewAligned)
        .safeAreaPadding(.horizontal, 50) // TODO: Adjust for macOS
        .scrollPosition(id: $selectedFilter, anchor: .center)
        .onAppear {
            selectedFilter = .original
        }
    }
}

#Preview {
    ContentView()
}
