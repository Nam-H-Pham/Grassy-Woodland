//
//  BaseActor.swift
//  Grassy Woodland
//
//  Created by Nam Pham on 10/10/2024.
//
import SwiftUI
import RealityKit
import RealityKitContent


class Planter {
    
    private let translation: SIMD3<Float>
    private let modelFilenames: [(String, ClosedRange<Float>)]
    private let scale: Float
    private var existingPositions: [SIMD3<Float>] = []
    private let minimumSpacing: Float
    
    init(modelFilenames: [(String, ClosedRange<Float>)], scale: Float = 1.0, minimumSpacing: Float = 0.0, translation: SIMD3<Float> = SIMD3<Float>(0, 0, 0)) {
        self.translation = translation
        self.modelFilenames = modelFilenames
        self.scale = scale
        self.minimumSpacing = minimumSpacing
    }
    
    func spawn() -> Entity {
        let (modelFilename, lodRange) = selectRandomModelFilenameAndRange()
        let model = loadModel(named: modelFilename)
        let position = generateValidPosition(lodRange: lodRange) + translation
        let entity = createEntityClone(from: model, lodRange: lodRange)
        entity.position = position + translation
        existingPositions.append(position)
        return entity
    }
    
    func spawn(at position: SIMD3<Float>) -> Entity {
        let (modelFilename, lodRange) = selectRandomModelFilenameAndRange()
        let model = loadModel(named: modelFilename)
        let entity = createEntityClone(from: model, lodRange: lodRange)
        entity.position = position + translation
        existingPositions.append(position)
        return entity
    }
    
    func selectRandomModelFilenameAndRange() -> (String, ClosedRange<Float>) {
        guard !modelFilenames.isEmpty else {
            fatalError("No model filenames provided. This method must be overridden by subclasses or modelFilenames must be set.")
        }

        let totalWeight = modelFilenames.reduce(Float(0)) { total, element in
            let rangeSize = Float(element.1.upperBound - element.1.lowerBound)
            return total + rangeSize
        }

        let randomValue = Float.random(in: 0..<totalWeight)
        var cumulativeWeight: Float = 0.0
        var selectedModels: [(String, ClosedRange<Float>)] = []

        for (filename, range) in modelFilenames {
            let rangeSize = Float(range.upperBound - range.lowerBound)
            cumulativeWeight += rangeSize
            if randomValue < cumulativeWeight {
                selectedModels.append((filename, range))
            }
        }

        guard !selectedModels.isEmpty else {
            fatalError("Failed to select a model filename. This should never happen.")
        }

        // Randomize among models with the same LOD range.
        return selectedModels.randomElement()!
    }

    
    func loadModel(named filename: String) -> Entity {
        do {
            return try ModelEntity.load(named: filename, in: realityKitContentBundle)
        } catch {
            fatalError("Failed to load model: \(filename), error: \(error)")
        }
    }
    
    func createEntityClone(from model: Entity, lodRange: ClosedRange<Float>) -> Entity {
        let clone = model.clone(recursive: true)
        
        // Apply scaling based on the provided scale factor
        let randomScaleFactor = Float.random(in: 0.7...1.2) * scale
        clone.scale = SIMD3<Float>(repeating: randomScaleFactor)
        
        // Apply random position
        let position = generateRandomPosition(lodRange: lodRange)
        clone.position = position
        
        // Apply random rotation
        let horizontalRotationAngle = Float.random(in: 0...(2 * .pi))
        let horizontalRotation = simd_quatf(angle: horizontalRotationAngle, axis: [0, 1, 0])
        clone.transform.rotation = horizontalRotation
        
        return clone
    }
    
    func generateRandomPosition(lodRange: ClosedRange<Float>) -> SIMD3<Float> {
        let angle = Float.random(in: 0...(2 * .pi))
        let radius = Float.random(in: lodRange)
        let xPosition = radius * cos(angle)
        let zPosition = radius * sin(angle)
        return SIMD3<Float>(xPosition, 0, zPosition)
    }
    
    private func generateValidPosition(lodRange: ClosedRange<Float>) -> SIMD3<Float> {
        var position: SIMD3<Float>
        var attempts = 0
        repeat {
            position = generateRandomPosition(lodRange: lodRange)
            attempts += 1
        } while (!isValidPosition(position) && attempts < 150)
        return position
    }
    
    private func isValidPosition(_ position: SIMD3<Float>) -> Bool {
        for existingPosition in existingPositions {
            let distance = simd_distance(existingPosition, position)
            if distance < minimumSpacing {
                return false
            }
        }
        return true
    }
    
}
