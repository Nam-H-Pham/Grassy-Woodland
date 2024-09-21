import SwiftUI
import RealityKit
import RealityKitContent

protocol Actor {
    func spawn() -> Entity
    func generateRandomPosition(lodRange: ClosedRange<Float>) -> SIMD3<Float>
}


class EnvManager {
    private var anchors: [String: AnchorEntity] = [:]

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
        let anchor = AnchorEntity(world: [0, 0, 0])
        anchors["Scene"] = anchor
        
        let grassActor = CombinedGrassActor()
        (0..<600).forEach { _ in
            let entity = grassActor.spawn()
            anchor.addChild(entity)
        }

        let branchActor = Branch()
        (0..<20).forEach { _ in
            let entity = branchActor.spawn()
            anchor.addChild(entity)
        }

        let leavesActor = Leaves()
        (0..<50).forEach { _ in
            let entity = leavesActor.spawn()
            anchor.addChild(entity)
        }

        let eucalyptusActor = EucalyptusAlbens()
        (0..<20).forEach { _ in
            let entity = eucalyptusActor.spawn()
            anchor.addChild(entity)
        }
        
        let environmentSoundManager = EnvironmentSoundManager()
        let spatialSoundEntities = environmentSoundManager.spawnAll()
        spatialSoundEntities.forEach { anchor.addChild($0) }
        
    }
}
class SpatialSoundManager {
    private let soundFiles: [String]
    
    init(soundFiles: [String]) {
        self.soundFiles = soundFiles
    }
    
    func generateRandomPosition(radius: Float) -> SIMD3<Float> {
        let theta = Float.random(in: 0...Float.pi * 2)
        let phi = Float.random(in: 0...Float.pi)
        let x = radius * sin(phi) * cos(theta)
        let y = radius * sin(phi) * sin(theta)
        let z = radius * cos(phi)
        
        return SIMD3<Float>(x, y, z)
    }
    
    func spawn(soundFile: String) -> Entity {
        let entity = Entity()
        
        let randomPosition = generateRandomPosition(radius: 15)
        entity.position = randomPosition
        
        entity.addChild(createSpatialAudio(filename: soundFile))
        
        return entity
    }
    
    func spawnAll() -> [Entity] {
        let entities: [Entity] = self.soundFiles.map(spawn)
        return entities
    }
    
    func createSpatialAudio(filename: String) -> Entity {
            // 1. Create an audio source entity
            let audioSource = Entity()
            
            // 2. Add a spatial audio component with a gain level
            audioSource.spatialAudio = SpatialAudioComponent(gain: -2)
            
            // Setting directivity property
        audioSource.spatialAudio?.directivity = .beam(focus: 0.0)
            
            do {
                // 3. Load the audio file resource with looping configuration
                let resource = try AudioFileResource.load(
                    named: filename,
                    configuration: .init(shouldLoop: true))

                // 4. Play the audio resource on the entity
                audioSource.playAudio(resource)
            } catch {
                // Handle the error if the audio file fails to load
                print("Error loading audio file: \(error.localizedDescription)")
            }
            
            // 5. Return the audio source entity
            return audioSource
        }
}

class EnvironmentSoundManager: SpatialSoundManager {
    init() {
        super.init(soundFiles:[
            "Fan_Tailed_Cuckoo.mp3",
            "Flies.mp3",
            "Gang_Gang_Cockatoo.mp3",
            "Rainbow Bee Eater.mp3",
            "Red Wattlebird.mp3"
        ])
    }
}



class BaseActor: Actor {
    private let modelFilenames: [(String, ClosedRange<Float>)]
    private let scale: Float
    private var existingPositions: [SIMD3<Float>] = []
    private let minimumSpacing: Float
    
    init(modelFilenames: [(String, ClosedRange<Float>)], scale: Float = 1.0, minimumSpacing: Float = 0.0) {
        self.modelFilenames = modelFilenames
        self.scale = scale
        self.minimumSpacing = minimumSpacing
    }
    
    func spawn() -> Entity {
        let (modelFilename, lodRange) = selectRandomModelFilenameAndRange()
        let model = loadModel(named: modelFilename)
        let position = generateValidPosition(lodRange: lodRange)
        let entity = createEntityClone(from: model, lodRange: lodRange)
        entity.position = position
        existingPositions.append(position)
        return entity
    }
    
    func selectRandomModelFilenameAndRange() -> (String, ClosedRange<Float>) {
        guard !modelFilenames.isEmpty else {
            fatalError("No model filenames provided. This method must be overridden by subclasses or modelFilenames must be set.")
        }
        return modelFilenames.randomElement()!
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
        } while (!isValidPosition(position) && attempts < 100)
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

class Leaves: BaseActor {
    init(scale: Float = 0.5) {
        super.init(modelFilenames: [
            ("Leaves/Leaves", 1...4)
        ], scale: scale)
    }
}

class Branch: BaseActor {
    init(scale: Float = 1.0) {
        super.init(modelFilenames: [
            ("Branch/Branch1", 5...15),
            ("Branch/Branch2", 5...15),
            ("Branch/Branch3", 5...15)
        ], scale: scale)
    }
}


class CombinedGrassActor: BaseActor {
    private let centerBias: Float
    private let weightedModelFilenames: [(String, ClosedRange<Float>, Float)] // Added weight here
    
    init(scale: Float = 1) {
        self.centerBias = 1.1
        self.weightedModelFilenames = [
            ("Grasses/Rytidosperma_caespitosum/Rytidosperma_caespitosum_2", 1...15, 0.1),
            ("Grasses/Rytidosperma_caespitosum/Rytidosperma_caespitosum_3", 1...15, 0.3),
            ("Grasses/Rytidosperma_caespitosum/Rytidosperma_caespitosum_4", 1...15, 0.4),
            ("Grasses/Themeda_triandra/Themeda_triandra_2", 1...15, 0.05),
            ("Grasses/Themeda_triandra/Themeda_triandra_3", 1...15, 0.05),
            ("Grasses/Themeda_triandra/Themeda_triandra_4", 1...15, 0.1)
        ]
        super.init(modelFilenames: [], scale: scale, minimumSpacing: 0.09)
    }

    override func selectRandomModelFilenameAndRange() -> (String, ClosedRange<Float>) {
        // Calculate cumulative weights
        let totalWeight = weightedModelFilenames.reduce(0) { $0 + $1.2 }
        let randomWeight = Float.random(in: 0..<totalWeight)
        
        var cumulativeWeight: Float = 0
        for (filename, range, weight) in weightedModelFilenames {
            cumulativeWeight += weight
            if randomWeight <= cumulativeWeight {
                return (filename, range)
            }
        }
        return (weightedModelFilenames.last!.0, weightedModelFilenames.last!.1) // Default fallback
    }
}


class EucalyptusAlbens: BaseActor {
    init(scale: Float = 1.0) {
        super.init(modelFilenames: [
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_1_LOD0", 15...20),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_1_LOD1", 20...30),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_1_LOD2", 30...40),
//            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_1_Billboard", 50...60),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_2_LOD0", 15...20),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_2_LOD1", 20...30),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_2_LOD2", 30...40),
//            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_2_Billboard", 50...60),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_3_LOD0", 15...20),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_3_LOD1", 20...30),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_3_LOD2", 30...40)
//            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_3_Billboard", 50...60)
        ], scale: scale, minimumSpacing: 8.0)
    }
}


