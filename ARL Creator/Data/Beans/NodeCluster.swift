//
//  NodeCluster.swift
//  ScanBuild
//
//  Created by paologiua on 02/05/25.
//


import SwiftUI
import SceneKit
import simd

struct NodeCluster {
    let nodes: [SCNNode]
    let points: [simd_float3]
    let centroid: simd_float3
    let distanceMatrix: [[Float]]
    let relativeHeights: [Float]
    let dimensions: [(width: Float, height: Float, depth: Float)]
    let types: [String?]

    var size: Int {
        return self.nodes.count
    }
    
    init(nodes: [SCNNode]) {
        // Calcolo centroide
        let centroid = nodes.simdWorldPositions.getCentroid()
        
        // Ordinamento nodi
        let sortedNodes = nodes.sorted { distance($0.simdWorldPosition, centroid) < distance($1.simdWorldPosition, centroid) }
        
        // Calcolo punti
        let points = sortedNodes.simdWorldPositions
        
        // Calcolo distanze
        let distanceMatrix = (sortedNodes.simdWorldPositions + [centroid]).getDistanceMatrix()
        
        // Calcolo altezze relative
        let relativeHeights = sortedNodes.simdWorldPositions.getRelativeHeights()
        
        // Calcolo dimensioni
        let dimensions = sortedNodes.map { $0.dimension }
        
        // Calcolo tipi
        let types = sortedNodes.map { $0.type }
        
        self.nodes = sortedNodes
        self.centroid = centroid
        self.points = points
        self.distanceMatrix = distanceMatrix
        self.relativeHeights = relativeHeights
        self.dimensions = dimensions
        self.types = types
    }
    
    func computeCompatibilityError(
        with other: NodeCluster,
        threshold: Float = 0.1,
        distanceWeight: Float = 1.0,
        relativeHeightWeight: Float = 1.0,
        dimensionWeight: Float = 1.0,
        typeMismatchWeight: Float = 1.0,
        typeDiversityWeight: Float = 1.0
    ) -> Float {
        let distanceMSE = self.computeDistanceMSE(with: other, threshold: threshold)
        let relativeHeightMSE = self.computeRelativeHeightMSE(with: other, threshold: threshold)
        let dimensionMSE = self.computeDimensionMSE(with: other, threshold: threshold)
        let typeMismatchMSE = self.computeTypeMismatchMSE(with: other, threshold: threshold)
        let typeDiversityMSE = self.computeTypeDiversityMSE(with: other, threshold: threshold)
        
        return (
            distanceWeight * distanceMSE +
            relativeHeightWeight * relativeHeightMSE +
            dimensionWeight * dimensionMSE +
            typeMismatchWeight * typeMismatchMSE +
            typeDiversityWeight * typeDiversityMSE
        )
    }
    
    func computeDistanceMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.distanceMatrix.count > 0,
            self.distanceMatrix[0].count > 0,
            self.distanceMatrix.count == other.distanceMatrix.count,
            self.distanceMatrix[0].count == other.distanceMatrix[0].count
        else {
            fatalError("The two distance matrices must have the same non-zero dimensions.")
        }

        var mse: Float = 0.0
        
        for (i, row) in self.distanceMatrix.enumerated() {
            for (j, _) in row.enumerated() where j > i {
                let d1 = self.distanceMatrix[i][j]
                let d2 = other.distanceMatrix[i][j]
                
                let diff = abs(d1 - d2)
                mse += diff < threshold ? 0 : pow(diff, 2)
            }
        }

        return mse
    }
    
    func computeRelativeHeightMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.relativeHeights.count > 0,
            self.relativeHeights.count == other.relativeHeights.count
        else {
            fatalError("The two relative height arrays must have the same non-zero dimension.")
        }

        var mse: Float = 0.0
        
        for (i, _) in self.relativeHeights.enumerated() {
            let h1 = self.relativeHeights[i]
            let h2 = other.relativeHeights[i]
            
            let diff = abs(h1 - h2)
            mse += diff < threshold ? 0 : pow(diff, 2)
        }

        return mse
    }
    
    func computeDimensionMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.dimensions.count > 0,
            self.dimensions.count == other.dimensions.count
        else {
            fatalError("The two dimension arrays must have the same non-zero dimension.")
        }

        var mse: Float = 0.0
        
        for (i, _) in self.dimensions.enumerated() {
            let (w1, h1, d1) = self.dimensions[i]
            let (w2, h2, d2) = other.dimensions[i]
            
            let wDiff = abs(w1 - w2)
            mse += wDiff < threshold ? 0 : pow(wDiff, 2)
            
            let hDiff = abs(h1 - h2)
            mse += hDiff < threshold ? 0 : pow(hDiff, 2)
            
            let dDiff = abs(d1 - d2)
            mse += dDiff < threshold ? 0 : pow(dDiff, 2)
        }

        return mse
    }
    
    func computeTypeMismatchMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.types.count > 0,
            self.types.count == other.types.count
        else {
            fatalError("The two type arrays must have the same non-zero dimension.")
        }
        
        var totalError: Float = 0.0
        
        for (i, _) in self.types.enumerated() {
            let selfType = self.types[i] ?? ""
            let otherType = other.types[i] ?? ""
            
            // Calcola un errore binario: 0 se i tipi sono uguali, 1 se sono diversi
            let typeError: Float = (selfType == otherType) ? 0.0 : 1.0
            
            totalError += typeError
        }
        
        // Calcola la media degli errori
        let mse = self.size > 0 ? totalError / Float(self.size) : 1.0
        
        // Applica la soglia, se necessario
        return mse < threshold ? 0.0 : mse
    }
    
    func computeTypeDiversityMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.types.count > 0,
            self.types.count == other.types.count
        else {
            fatalError("The two type arrays must have the same non-zero dimension.")
        }
        
        // Raccoglie tutti i tipi unici nei due cluster
        let selfTypes = Set<String?>(self.types)
        let otherTypes = Set<String?>(other.types)
        
        // Calcola l'unione dei tipi unici tra i due cluster
        let unionTypes = selfTypes.union(otherTypes)
        
        // Se non ci sono tipi, restituisci un valore neutro
        if unionTypes.isEmpty {
            return 0.0
        }
        
        // Calcola quanti tipi diversi ci sono in totale tra i due cluster
        let totalUniqueTypes = Float(unionTypes.count)
        
        // Calcola il punteggio di diversità normalizzato (0-1)
        // Più alto è il valore, maggiore è la diversità
        let diversityScore = totalUniqueTypes / max(Float(selfTypes.count + otherTypes.count), 1.0)
        
        // Invertiamo il punteggio per trasformarlo in un "errore"
        // 1.0 - diversityScore fa sì che alta diversità = basso errore
        let mse = 1.0 - diversityScore
        
        // Applica la soglia, se necessario
        return mse < threshold ? 0.0 : mse
    }
}
