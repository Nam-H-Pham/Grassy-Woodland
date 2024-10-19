//
//  EnvironmentManager.swift
//  Grassy Woodland
//
//  Created by Nam Pham on 10/10/2024.
//
import SwiftUI
import RealityKit
import RealityKitContent

class EnvironmentManager {
    public var anchors: [String: AnchorEntity] = [:]

    /// Adds all anchors to the given RealityViewContent.
    func addAllAnchors(to content: RealityViewContent) {
        anchors.values.forEach { content.add($0) }
    }

    /// Removes all anchors from the given RealityViewContent.
    func removeAllAnchors(from content: RealityViewContent) {
        anchors.values.forEach { content.remove($0) }
    }

    /// Assembles actors by creating and storing anchors.
    func assembleActors() {
        // This method should be overridden by subclasses to assemble specific actors.
    }
}
