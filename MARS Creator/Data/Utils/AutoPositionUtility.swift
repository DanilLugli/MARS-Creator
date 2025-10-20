//
//  AutoPositionUtility.swift
//  ScanBuild
//
//  Created by paologiua on 02/05/25.
//


import SwiftUI
import SceneKit
import simd

/**
 * Fornisce una serie di funzioni utili per allineare automaticamente due gruppi di nodi `SCNNode` in uno spazio 3D.
 */
struct AutoPositionUtility {
    // Lista dei tipi di nodo da mantenere
    static let targetTypes = ["Door", "Opening", "Window"]
    
    /**
     * Trova la miglior allineamento tra due set di nodi `SCNNode` attraverso la rotazione e la traslazione, minimizzando l'errore di compatibilità e di trasformazione.
     * La funzione filtra i nodi per tipo, trova i cluster compatibili, quindi calcola la rotazione e la traslazione ottimali che minimizzano l'errore complessivo.
     *
     * - Parameters:
     *   - sourceNodes: Il primo array di nodi `SCNNode` da allineare.
     *   - targetNodes: Il secondo array di nodi `SCNNode` da allineare.
     *   - clusterSize: Numero di nodi per ciascun cluster. Il valore predefinito è 3.
     *   - maxPairs: Numero massimo di coppie di cluster da confrontare. Il valore predefinito è 1000.
     *
     * - Returns: Una tupla contenente:
     *   - `rotationAngle`: L'angolo di rotazione ottimale (in radianti) per l'allineamento.
     *   - `translation`: La traslazione ottimale come `simd_float3` per l'allineamento.
     *   - `error`: L'errore totale di compatibilità e trasformazione per il miglior allineamento trovato.
     */
    static func findBestAlignment(
        from sourceNodes: [SCNNode],
        to targetNodes: [SCNNode],
        clusterSize: Int = 3,
        maxPairs: Int = 1000
    ) -> (rotationAngle: Float, translation: simd_float3, error: Float) {
        let filteredSourceNodes = filterNodesByType(nodes: sourceNodes)
        let filteredTargetNodes = filterNodesByType(nodes: targetNodes)
        
        let clusters = findCompatibleClusters(
            from: filteredSourceNodes,
            and: filteredTargetNodes,
            clusterSize: clusterSize,
            maxPairs: maxPairs
        )
        
        var minError = Float(-1);
        var bestRotationAngle: Float = 0.0;
        var bestTranslation: simd_float3 = simd_float3(0, 0, 0);
        
        // Itera su tutte le combinazioni
        for (sourceCluster, targetCluster, compatibilityError) in clusters {
            let (rotationAngle, translation) = computeTransformation(from: sourceCluster, to: targetCluster)
            
            // Calcola l'errore di trasformazione
            let transformationError = computeTransformationError(
                for: sourceCluster,
                rotationAngle: rotationAngle,
                translation: translation,
                comparedTo: targetCluster
            )
            
            // Calcola l'errore totale
            let error = compatibilityError + transformationError
            
            if (error < minError || minError == Float(-1)) {
                minError = error
                
                bestRotationAngle = rotationAngle;
                bestTranslation = translation;
            }
            
            print("Error: \(error)")
            print("Min error: \(minError)")
            print()
            print("rotationAngle: \(rotationAngle) (\(rotationAngle * 180 / .pi)°)")
            print("translation: \(translation)")
            print()
        }
        
        return (bestRotationAngle, bestTranslation, minError)
    }
    
    /**
     * Filtra i nodi da un array, restituendo solo quelli che appartengono ai tipi specificati in `targetTypes`.
     *
     * La funzione confronta il tipo di ogni nodo nell'array con i tipi presenti nella lista `targetTypes` e restituisce solo i nodi che corrispondono a uno di questi tipi.
     *
     * - Parameters:
     *   - nodes: L'array di nodi `SCNNode` da filtrare.
     *
     * - Returns: Un array di nodi `SCNNode` che appartengono ai tipi specificati in `targetTypes`.
     */
    private static func filterNodesByType(nodes: [SCNNode]) -> [SCNNode] {
        return nodes.filter { node in targetTypes.contains { targetType in node.type == targetType }}
    }
    
    /**
     * Trova le coppie di cluster più compatibili tra due gruppi di nodi `SCNNode`, calcolando un errore di compatibilità per ciascuna combinazione di cluster.
     * La funzione genera tutte le combinazioni possibili di cluster dalle due liste di nodi, calcola il punteggio di compatibilità per ciascuna coppia di cluster
     * e restituisce le migliori coppie ordinate in base all'errore (più basso = più compatibile).
     * Sono previsti vari limiti per ottimizzare il processo, riducendo il numero di nodi e cluster da combinare e confrontare.
     *
     * - Parameters:
     *   - nodes1: Primo array di nodi `SCNNode` da usare per formare il primo gruppo di cluster.
     *   - nodes2: Secondo array di nodi `SCNNode` da usare per formare il secondo gruppo di cluster.
     *   - clusterSize: Numero di nodi per ciascun cluster. Il valore predefinito è 3.
     *   - maxPairs: Numero massimo di coppie di cluster da restituire. Il valore predefinito è 1000.
     *   - maxNodes1: Numero massimo di nodi da prendere dalla prima lista per la generazione dei cluster. Il valore predefinito è 20.
     *   - maxNodes2: Numero massimo di nodi da prendere dalla seconda lista per la generazione dei cluster. Il valore predefinito è 40.
     *   - maxClusters1: Numero massimo di cluster da generare dalla prima lista di nodi. Il valore predefinito è 1000.
     *   - maxClusters2: Numero massimo di cluster da generare dalla seconda lista di nodi. Il valore predefinito è 10000.
     *
     * - Returns: Una lista di tuple contenenti le coppie di cluster più compatibili e il rispettivo errore di compatibilità (cluster1, cluster2, errore).
     *           Le coppie sono ordinate in base all'errore di compatibilità, con le migliori coppie in testa.
     */
    private static func findCompatibleClusters(
        from nodes1: [SCNNode],
        and nodes2: [SCNNode],
        clusterSize: Int = 3,
        maxPairs: Int = 1000,
        maxNodes1: Int = 20,
        maxNodes2: Int = 40,
        maxClusters1: Int = 1000,
        maxClusters2: Int = 10000
    ) -> [(NodeCluster, NodeCluster, Float)] {
        // Controllo che ci siano abbastanza nodi
        guard
            nodes1.count >= clusterSize,
            nodes2.count >= clusterSize
        else {
            return []
        }
        
        // Limito il numero di nodi da combinare per ottimizzazione
        let sampledNodes1 = maxNodes1 >= nodes1.count ? nodes1 : Array(nodes1.shuffled().prefix(maxNodes1))
        
        // Limito il numero di nodi da combinare per ottimizzazione
        let sampledNodes2 = maxNodes2 >= nodes2.count ? nodes2 : Array(nodes2.shuffled().prefix(maxNodes2))
        
        // Genero tutti i possibili cluster dalla prima lista
        let clusters1 = sampledNodes1.combinations(taking: clusterSize).map { NodeCluster(nodes: $0) }
        
        // Genero tutti i possibili cluster dalla seconda lista
        let clusters2 = sampledNodes2.combinations(taking: clusterSize).map { NodeCluster(nodes: $0) }
        
        // Array per memorizzare i risultati (cluster1, cluster2, error)
        var compatibilityErrors: [(NodeCluster, NodeCluster, Float)] = []
        
        // Limito il numero di cluster da confrontare per ottimizzazione
        let sampledClusters1 = maxClusters1 >= clusters1.count ? clusters1 : Array(clusters1.shuffled().prefix(maxClusters1))
        
        // Limito il numero di cluster da confrontare per ottimizzazione
        let sampledClusters2 = maxClusters2 >= clusters2.count ? clusters2 : Array(clusters2.shuffled().prefix(maxClusters2))
        
        // Calcolo i punteggi di compatibilità
        for cluster1 in sampledClusters1 {
            for cluster2 in sampledClusters2 {
                let error = cluster1.computeCompatibilityError(with: cluster2)
                compatibilityErrors.append((cluster1, cluster2, error))
            }
        }
        
        // Ordino in base al punteggio (più basso = più compatibile)
        compatibilityErrors.sort { $0.2 < $1.2 }
        
        // Prendo le migliori coppie
        let bestPairs = Array(compatibilityErrors.prefix(maxPairs))
        
        return bestPairs
    }
    
    /**
     * Calcola la trasformazione (rotazione e traslazione) che allinea il cluster di nodi di origine a quello di destinazione.
     * La trasformazione consiste in una rotazione attorno all'asse Y e una traslazione che porta il centroide del cluster di origine
     * a sovrapporsi con il centroide del cluster di destinazione.
     *
     * - Parameters:
     *   - sourceCluster: Il cluster di nodi di origine da trasformare.
     *   - targetCluster: Il cluster di nodi di destinazione a cui allineare il cluster di origine.
     *
     * - Returns: Una tupla contenente due valori:
     *   - `rotationAngle`: L'angolo di rotazione (in radianti) attorno all'asse Y necessario per allineare il cluster di origine al cluster di destinazione.
     *   - `translation`: Il vettore di traslazione necessario per allineare il centroide del cluster di origine con quello del cluster di destinazione.
     *
     * La funzione presuppone che entrambi i cluster abbiano almeno 3 nodi e che abbiano lo stesso numero di nodi.
     */
    private static func computeTransformation(
        from sourceCluster: NodeCluster,
        to targetCluster: NodeCluster
    ) -> (rotationAngle: Float, translation: simd_float3) {
        guard sourceCluster.size == targetCluster.size, sourceCluster.size >= 3 else {
            fatalError("Clusters of at least 3 nodes are required")
        }
        
        // 1. Recupera punti e centroidi
        let sourcePoints = sourceCluster.points
        let targetPoints = targetCluster.points
        
        let sourceCentroid = sourceCluster.centroid
        let targetCentroid = targetCluster.centroid
        
        // 2. Sottrai i centroidi dai punti
        let centeredSourcePoints = sourcePoints.map { $0 - sourceCentroid }
        let centeredTargetPoints = targetPoints.map { $0 - targetCentroid }
        
        // 3. Trova l'angolo di rotazione ottimale attorno all'asse y
        var numerator: Float = 0
        var denominator: Float = 0
        
        for i in 0..<sourcePoints.count {
            let source = centeredSourcePoints[i]
            let target = centeredTargetPoints[i]
            
            // Per rotazione attorno all'asse y: x' = x*cos(θ) + z*sin(θ), z' = -x*sin(θ) + z*cos(θ)
            numerator += source.z * target.x - source.x * target.z
            denominator += source.x * target.x + source.z * target.z
        }
        
        let rotationAngle = atan2(numerator, denominator)
        
        // 4. Calcola la matrice di rotazione
        let cosTheta = cos(rotationAngle)
        let sinTheta = sin(rotationAngle)
        
        let rotationMatrix = simd_float3x3(
            simd_float3(cosTheta, 0, sinTheta),
            simd_float3(0, 1, 0),
            simd_float3(-sinTheta, 0, cosTheta)
        )
        
        // 5. Ruota i punti centrati e calcola la traslazione
        let rotatedSourcePoints = sourcePoints.map { rotationMatrix.transpose * $0 }
        
        // La traslazione è la differenza tra il centroide del target e il centroide del source ruotato
        let rotatedSourceCentroid = rotatedSourcePoints.getCentroid()
        let translation = targetCentroid - rotatedSourceCentroid
        
        return (rotationAngle, translation)
    }
    
    /**
     * Calcola l'errore di trasformazione tra due cluster di nodi, applicando una rotazione e una traslazione al cluster di origine
     * e confrontando i punti risultanti con quelli del cluster di destinazione.
     *
     * La funzione assume che i due cluster abbiano lo stesso numero di nodi, altrimenti verrà sollevato un errore.
     *
     * - Parameters:
     *   - sourceCluster: Il cluster di nodi di origine su cui applicare la trasformazione.
     *   - rotationAngle: Angolo di rotazione da applicare ai nodi del cluster di origine.
     *   - translation: Vettore di traslazione da applicare ai nodi del cluster di origine.
     *   - targetCluster: Il cluster di nodi di destinazione con cui confrontare i punti trasformati.
     *
     * - Returns: Un valore `Float` che rappresenta la somma degli errori quadratici tra i punti trasformati del cluster di origine
     *            e i punti del cluster di destinazione. Maggiore è il valore, maggiore è la differenza tra i due cluster.
     */
    private static func computeTransformationError(
        for sourceCluster: NodeCluster,
        rotationAngle: Float,
        translation: simd_float3,
        comparedTo targetCluster: NodeCluster
    ) -> Float {
        guard sourceCluster.size == targetCluster.size else {
            fatalError("Clusters must have the same number of nodes")
        }
        
        let sourcePoints = sourceCluster.points
        let targetPoints = targetCluster.points
        
        return sourcePoints.enumerated().reduce(0.0) { (totalError, element) in
            let i = element.offset
            let transformedPoint = sourcePoints[i].transformXZ(rotationAngle: rotationAngle, translation: translation)
            let error = simd_length(transformedPoint - targetPoints[i])
            
            print("A: \(sourcePoints[i])")
            print("transformedPoint: \(transformedPoint)")
            print("B: \(targetPoints[i])")
            print()
            
            return totalError + pow(error, 2)
        }
    }
}
