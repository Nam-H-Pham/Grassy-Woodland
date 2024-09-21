//
//  ContentView.swift
//  Grassy Woodland
//
//  Created by Nam Pham on 21/9/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    var body: some View {
        VStack {

            Text("Grassy Woodland Demo")

            ToggleImmersiveSpaceButton()
        }
        .padding()
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(AppModel())
}
