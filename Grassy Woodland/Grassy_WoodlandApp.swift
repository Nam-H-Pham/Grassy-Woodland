//
//  Grassy_WoodlandApp.swift
//  Grassy Woodland
//
//  Created by Nam Pham on 21/9/2024.
//

import SwiftUI

@main
struct Grassy_WoodlandApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
//                .onAppear {
//                    appModel.immersiveSpaceState = .open
//                }
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
