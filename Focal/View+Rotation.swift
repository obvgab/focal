//
//  4D46E30A-10B9-4D94-B139-1B9313308181: 08:23 3/16/24
//  View+Rotation.swift by Gab
//

import SwiftUI

#if os(iOS)
import CoreMotion
import UIKit

@MainActor
public class OrientationHandler: ObservableObject {
    public static var shared = OrientationHandler()
    public static func startShared() -> OrientationHandler { if !shared.started { shared.startNotifier() }; return shared }
    
    @Published public var orientation: UIDeviceOrientation = UIDevice.current.orientation
    @Published public var rotation: Double = 0.0
    
    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private var started = false
    
    func startNotifier() {
        manager.accelerometerUpdateInterval = 0.1
        started = true
        
        manager.startAccelerometerUpdates(to: queue) { data, error in
            guard let data = data else { return }
            
            let newOrientation: UIDeviceOrientation = if data.acceleration.x >= 0.5 { .landscapeLeft }
                else if data.acceleration.x <= -0.5 { .landscapeRight }
                else if data.acceleration.y <= -0.5 { .portrait }
                else if data.acceleration.y >= 0.5 { .portraitUpsideDown }
                else { .unknown }
            
            guard newOrientation != .unknown else { return }
            
            if newOrientation != self.orientation {
                DispatchQueue.main.async { [self] in
                    self.orientation = newOrientation
                    withAnimation(.easeIn) {
                        switch orientation {
                        case .portrait: rotation = 0.0; break
                        case .portraitUpsideDown: rotation = 180.0; break
                        case .landscapeLeft: rotation = -90.0; break
                        case .landscapeRight: rotation = 90.0; break
                        default: break
                        }
                    }
                }
            }
        }
    }
}

struct OrientationModifier: ViewModifier {
    @ObservedObject var handler = OrientationHandler.startShared()
    
    func body(content: Content) -> some View {
        return content.rotationEffect(.degrees(handler.rotation))
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

extension View {
    public func rotation() -> some View {
        self.modifier(OrientationModifier())
    }
}
#else
extension View { public func rotation() -> some View { return self } }
#endif
