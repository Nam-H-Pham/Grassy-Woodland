import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {

    var body: some View {
        RealityView { content in
            
            let envManager = WoodlandsEnvironment()
            
            envManager.assembleActors()
            envManager.addAllAnchors(to:                 content)
        
        }
    }
}

#Preview(immersionStyle: .automatic) {
    ImmersiveView()
}
