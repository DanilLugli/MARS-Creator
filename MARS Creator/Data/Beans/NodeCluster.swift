//
//  NodeCluster.swift
//  ScanBuild
//
//  Created by paologiua on 02/05/25.
//


import SwiftUI
import SceneKit
import simd

/**
 * Rappresenta un cluster di nodi 3D e fornisce metodi per calcolare l'errore di compatibilità tra due cluster.
 */
struct NodeCluster {
    let nodes: [SCNNode]
    let points: [simd_float3]
    let centroid: simd_float3
    let distanceMatrix: [[Float]]
    let relativeHeights: [Float]
    let volumes: [Float]
    let types: [String?]

    var size: Int {
        return self.nodes.count
    }
    
    /**
     * Inizializza un cluster di nodi a partire da una lista di `SCNNode`, calcolando automaticamente le proprietà geometriche e semantiche.
     * I nodi vengono ordinati in base alla distanza dal centroide, per garantire coerenza nella rappresentazione interna.
     * In questo modo non è necessario dover calcolare l'errore di compatibilità su tutte le permutazioni di nodi.
     *
     * - Parameters:
     *   - nodes: Array di nodi `SCNNode` da includere nel cluster.
     *
     * Le seguenti proprietà vengono calcolate:
     * - `centroid`: il punto medio dei nodi nello spazio 3D.
     * - `nodes`: i nodi ordinati per distanza crescente dal centroide.
     * - `points`: posizioni dei nodi nello spazio.
     * - `distanceMatrix`: matrice delle distanze tra i nodi e il centroide.
     * - `relativeHeights`: altezza relativa di ciascun nodo rispetto agli altri.
     * - `volumes`: volumi di ogni nodo.
     * - `types`: tipo associato a ciascun nodo, se presente.
     */

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
        
        // Calcolo volumi
        let volumes = sortedNodes.map { Float($0.volume) }
        
        // Calcolo tipi
        let types = sortedNodes.map { $0.type }
        
        self.nodes = sortedNodes
        self.centroid = centroid
        self.points = points
        self.distanceMatrix = distanceMatrix
        self.relativeHeights = relativeHeights
        self.volumes = volumes
        self.types = types
    }
    
    /**
     * Calcola un errore complessivo di compatibilità tra due cluster di nodi,
     * combinando diverse metriche (distanza, altezza relativa, volumi, tipo) con pesi configurabili.
     *
     * - Parameters:
     *   - other: Il cluster di nodi con cui confrontare il cluster corrente.
     *   - threshold: Soglia comune sotto la quale le differenze vengono considerate trascurabili (default: 0.1).
     *   - distanceWeight: Peso assegnato all'errore sulle distanze tra coppie di nodi (default: 1.0).
     *   - relativeHeightWeight: Peso assegnato all'errore sulle altezze relative (default: 1.0).
     *   - volumeWeight: Peso assegnato all'errore sui volumi (default: 1.0).
     *   - typeMismatchWeight: Peso assegnato all'errore da disallineamento di tipo (default: 1.0).
     *   - typeDiversityWeight: Peso assegnato all'errore da diversità di tipo complessiva (default: 1.0).
     *
     * - Returns: Un valore `Float` che rappresenta l'errore totale di compatibilità, calcolato come somma pesata delle varie metriche.
     *            Un valore più basso indica maggiore compatibilità tra i due cluster.
     */
    func computeCompatibilityError(
        with other: NodeCluster,
        threshold: Float = 0.1,
        distanceWeight: Float = 1.0,
        relativeHeightWeight: Float = 1.0,
        volumeWeight: Float = 1.0,
        typeMismatchWeight: Float = 1.0,
        typeDiversityWeight: Float = 1.0
    ) -> Float {
        let distanceMSE = self.computeDistanceMSE(with: other, threshold: threshold)
        let relativeHeightMSE = self.computeRelativeHeightMSE(with: other, threshold: threshold)
        let volumeMSE = self.computeVolumeMSE(with: other, threshold: threshold)
        let typeMismatchMSE = self.computeTypeMismatchMSE(with: other, threshold: threshold)
        let typeDiversityMSE = self.computeTypeDiversityMSE(with: other, threshold: threshold)
        
        return (
            distanceWeight * distanceMSE +
            relativeHeightWeight * relativeHeightMSE +
            volumeWeight * volumeMSE +
            typeMismatchWeight * typeMismatchMSE +
            typeDiversityWeight * typeDiversityMSE
        )
    }
    
    /**
     * Calcola l'errore quadratico medio (MSE) tra le distanze tra coppie di nodi nei due cluster.
     * Le differenze inferiori alla soglia specificata vengono ignorate.
     *
     * - Parameters:
     *   - other: Il cluster di nodi con cui confrontare la matrice delle distanze del cluster corrente.
     *   - threshold: Soglia al di sotto della quale le differenze tra distanze sono considerate trascurabili (default: 0.1).
     *
     * - Returns: Un valore `Float` che rappresenta la somma degli errori quadratici tra le distanze corrispondenti.
     *            Vengono considerate solo le distanze tra le coppie di nodi (parte superiore della matrice, senza la diagonale).
     */
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
    
    /**
     * Calcola l'errore quadratico medio (MSE) tra le altezze relative dei nodi di due cluster.
     * Le differenze minime sotto una soglia specificata vengono ignorate.
     *
     * - Parameters:
     *   - other: Il cluster di nodi con cui confrontare il cluster corrente.
     *   - threshold: Soglia al di sotto della quale le differenze tra altezze sono considerate trascurabili (default: 0.1).
     *
     * - Returns: Un valore `Float` che rappresenta la somma degli errori quadratici tra le altezze relative dei nodi.
     *            Un valore più alto indica maggiore disallineamento verticale relativo tra i due cluster.
     */
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
    
    /**
     * Calcola l'errore quadratico medio (MSE) tra i volumi dei nodi di due cluster.
     * Le differenze inferiori alla soglia vengono ignorate.
     *
     * - Parameters:
     *   - other: Il cluster di nodi con cui confrontare il cluster corrente.
     *   - threshold: Soglia al di sotto della quale le differenze tra volumi sono considerate trascurabili (default: 0.1).
     *
     * - Returns: Un valore `Float` che rappresenta la somma degli errori quadratici tra i volumi dei nodi dei due cluster.
     *            Maggiore è il valore, più i cluster differiscono nei volumi.
     */
    func computeVolumeMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.volumes.count > 0,
            self.volumes.count == other.volumes.count
        else {
            fatalError("The two volume arrays must have the same non-zero dimension.")
        }

        var mse: Float = 0.0
        
        for (i, _) in self.volumes.enumerated() {
            let v1 = self.volumes[i]
            let v2 = other.volumes[i]
            
            let diff = abs(v1 - v2)
            mse += diff < threshold ? 0 : pow(diff, 2)
        }

        return mse
    }
    
    /**
     * Calcola l'errore quadratico medio (MSE) tra i tipi dei nodi di due cluster, posizione per posizione.
     * Ogni disallineamento tra tipi è considerato un errore binario (1.0), mentre una corrispondenza vale 0.0.
     *
     * - Parameters:
     *   - other: Il cluster di nodi con cui confrontare il cluster corrente.
     *   - threshold: Soglia al di sotto della quale l'errore viene considerato trascurabile (default: 0.1).
     *
     * - Returns: Un valore `Float` tra 0.0 e 1.0 che rappresenta la percentuale media di tipi disallineati.
     *            Un valore basso indica una buona corrispondenza tra i tipi, mentre uno alto indica molte discrepanze.
     */
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
    
    /**
     * Calcola una metrica di errore (MSE) che rappresenta la diversità tra i tipi di due cluster di nodi.
     * Più simili sono i tipi, minore sarà il valore restituito.
     *
     * - Parameters:
     *   - other: Un altro cluster di nodi con cui confrontare il cluster corrente.
     *   - threshold: Soglia al di sotto della quale l'errore viene considerato trascurabile (default: 0.1).
     *
     * - Returns: Un valore `Float` tra 0.0 e 1.0 che rappresenta la diversità tra i tipi dei due cluster.
     *            Un valore vicino a 0 indica alta similarità, mentre un valore vicino a 1 indica alta diversità.
     */
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
