import SwiftUI
import RealityKit
import RealityKitContent



class WoodlandsEnvironment: EnvironmentManager {
    override func assembleActors() {
        let anchor = AnchorEntity(world: [0, 0, 0])
        anchor.addChild(AnchorEntity(plane: .horizontal))
            
        anchors["Scene"] = anchor
        
        let grassActor = CombinedGrassActor()
        (0..<2000).forEach { _ in
            anchor.addChild(grassActor.spawn())
        }

        let branchActor = Branch()
        (0..<15).forEach { _ in
            anchor.addChild(branchActor.spawn())
        }

        let leavesActor = Leaves()
        (0..<50).forEach { _ in
            anchor.addChild(leavesActor.spawn())
        }

        let eucalyptusActor = EucalyptusAlbens()
        (0..<10).forEach { _ in
            anchor.addChild(eucalyptusActor.spawn())
        }
        
        let environmentSoundManager = EnvironmentSoundManager()
        let spatialSoundEntities = environmentSoundManager.spawnAll()
        spatialSoundEntities.forEach { anchor.addChild($0) }
        
        anchor.components.set(GroundingShadowComponent(castsShadow: true))
    }
}

class EnvironmentSoundManager: SpatialSoundManager {
    init() {
        super.init(soundFiles:[
            "Fan_Tailed_Cuckoo",
            "Flies",
            "Gang_Gang_Cockatoo",
            "Rainbow Bee Eater",
            "Red Wattlebird"
        ])
    }
}

class Leaves: Planter {
    init(scale: Float = 0.25) {
        super.init(modelFilenames: [
            ("Leaves/Leaves", 1...4)
        ], scale: scale)
    }
}

class Branch: Planter {
    init(scale: Float = 1.0) {
        super.init(modelFilenames: [
            ("Branch/Branch1", 5...15),
            ("Branch/Branch2", 5...15),
            ("Branch/Branch3", 5...15)
        ], scale: scale)
    }
}


class CombinedGrassActor: Planter {
    private let weightedModelFilenames: [(String, ClosedRange<Float>, Float)] // Added weight here
    
    init(scale: Float = 0.7) {
        let minDistance: Float = 1
        let maxDistance: Float = 10
        self.weightedModelFilenames = [
            ("Grasses/Rytidosperma_caespitosum/Rytidosperma_caespitosum_2", minDistance...maxDistance, 0.1),
            ("Grasses/Rytidosperma_caespitosum/Rytidosperma_caespitosum_3", minDistance...maxDistance, 0.3),
            ("Grasses/Rytidosperma_caespitosum/Rytidosperma_caespitosum_4", minDistance...maxDistance, 0.4),
            ("Grasses/Themeda_triandra/Themeda_triandra_2", minDistance...maxDistance, 0.05),
            ("Grasses/Themeda_triandra/Themeda_triandra_3", minDistance...maxDistance, 0.05),
            ("Grasses/Themeda_triandra/Themeda_triandra_4", minDistance...maxDistance, 0.1),
            
            ("Grasses/Rytidosperma_caespitosum/Rytidosperma_caespitosum_2_LOD1", minDistance...maxDistance, 0.1),
            ("Grasses/Rytidosperma_caespitosum/Rytidosperma_caespitosum_3_LOD1", minDistance...maxDistance, 0.3),
            ("Grasses/Rytidosperma_caespitosum/Rytidosperma_caespitosum_4_LOD1", minDistance...maxDistance, 0.4),
            ("Grasses/Themeda_triandra/Themeda_triandra_2_LOD1", minDistance...maxDistance, 0.05),
            ("Grasses/Themeda_triandra/Themeda_triandra_3_LOD1", minDistance...maxDistance, 0.05),
            ("Grasses/Themeda_triandra/Themeda_triandra_4_LOD1", minDistance...maxDistance, 0.1)
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


class EucalyptusAlbens: Planter {
    init(scale: Float = 0.5) {
        super.init(modelFilenames: [
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_1_LOD0", 8...15),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_1_LOD1", 15...30),
//            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_1_LOD2", 30...40),
//            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_1_Billboard", 50...60),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_2_LOD0", 8...15),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_2_LOD1", 15...30),
//            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_2_LOD2", 30...40),
//            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_2_Billboard", 50...60),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_3_LOD0", 8...15),
            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_3_LOD1", 15...30),
//            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_3_LOD2", 30...40)
//            ("Trees/Eucalyptus_Albens/Eucalyptus_Albens_3_Billboard", 50...60)
        ], scale: scale, minimumSpacing: 4)
    }
    
    override func createEntityClone(from model: Entity, lodRange: ClosedRange<Float>) -> Entity {
            let entity = super.createEntityClone(from: model, lodRange: lodRange)
            
            let grassActor = CombinedGrassActor()
            (0..<20).forEach { _ in
                let angle = Float.random(in: 0...(2 * .pi))
                let radius: Float = 1
                let randomX = radius * cos(angle)
                let randomZ = radius * sin(angle)
                let randomPosition = SIMD3<Float>(randomX, 0, randomZ)
            
                entity.addChild(grassActor.spawn(at: randomPosition))
                
            }
            
            return entity
        }

}
