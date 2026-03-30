//
//  VisionService.swift
//  ScreenshotEditor
//
//  AI-powered annotation suggestions using Vision Framework
//

import Vision
import AppKit
import Foundation

/// Service for AI-powered annotation suggestions
class VisionService {

    static let shared = VisionService()

    private init() {}

    // MARK: - Text Detection

    /// Detect text regions in an image
    /// - Parameters:
    ///   - image: The image to analyze
    ///   - completion: Callback with detected text regions
    func detectTextRegions(in image: NSImage, completion: @escaping ([TextRegion]) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            DispatchQueue.main.async {
                completion([])
            }
            return
        }

        var textRegions: [TextRegion] = []

        // Create text detection request
        let textRequest = VNRecognizeTextRequest { request, error in
            if let error = error {
                #if DEBUG
                print("[VisionService] Text detection error: \(error)")
                #endif
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }

                // Get bounding box in image coordinates
                let rect = observation.boundingBox
                let imageRect = CGRect(
                    x: rect.origin.x * image.size.width,
                    y: (1 - rect.origin.y - rect.size.height) * image.size.height,
                    width: rect.size.width * image.size.width,
                    height: rect.size.height * image.size.height
                )

                textRegions.append(TextRegion(
                    text: topCandidate.string,
                    confidence: topCandidate.confidence,
                    boundingBox: imageRect
                ))
            }

            DispatchQueue.main.async {
                completion(textRegions)
            }
        }

        // Configure recognition level
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = true

        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([textRequest])
        }
    }

    // MARK: - Rectangle Detection

    /// Detect rectangular UI elements in an image
    /// - Parameters:
    ///   - image: The image to analyze
    ///   - completion: Callback with detected rectangles
    func detectRectangles(in image: NSImage, completion: @escaping ([CGRect]) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            DispatchQueue.main.async {
                completion([])
            }
            return
        }

        var rectangles: [CGRect] = []

        // Create rectangle detection request
        let rectRequest = VNDetectRectanglesRequest { request, error in
            if let error = error {
                #if DEBUG
                print("[VisionService] Rectangle detection error: \(error)")
                #endif
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            guard let observations = request.results as? [VNRectangleObservation] else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            for observation in observations {
                let rect = observation.boundingBox
                let imageRect = CGRect(
                    x: rect.origin.x * image.size.width,
                    y: (1 - rect.origin.y - rect.size.height) * image.size.height,
                    width: rect.size.width * image.size.width,
                    height: rect.size.height * image.size.height
                )

                rectangles.append(imageRect)
            }

            DispatchQueue.main.async {
                completion(rectangles)
            }
        }

        // Configure minimum confidence
        rectRequest.minimumConfidence = 0.7
        rectRequest.maximumObservations = 20

        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([rectRequest])
        }
    }

    // MARK: - Barcode/QR Code Detection

    /// Detect barcodes and QR codes in an image
    /// - Parameters:
    ///   - image: The image to analyze
    ///   - completion: Callback with detected codes
    func detectBarcodes(in image: NSImage, completion: @escaping ([BarcodeInfo]) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            DispatchQueue.main.async {
                completion([])
            }
            return
        }

        var barcodes: [BarcodeInfo] = []

        // Create barcode detection request
        let barcodeRequest = VNDetectBarcodesRequest { request, error in
            if let error = error {
                #if DEBUG
                print("[VisionService] Barcode detection error: \(error)")
                #endif
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            guard let observations = request.results as? [VNBarcodeObservation] else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            for observation in observations {
                let rect = observation.boundingBox
                let imageRect = CGRect(
                    x: rect.origin.x * image.size.width,
                    y: (1 - rect.origin.y - rect.size.height) * image.size.height,
                    width: rect.size.width * image.size.width,
                    height: rect.size.height * image.size.height
                )

                barcodes.append(BarcodeInfo(
                    payload: observation.payloadStringValue ?? "Unknown",
                    symbology: observation.symbology,
                    boundingBox: imageRect
                ))
            }

            DispatchQueue.main.async {
                completion(barcodes)
            }
        }

        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([barcodeRequest])
        }
    }

    // MARK: - Face Detection

    /// Detect faces in an image
    /// - Parameters:
    ///   - image: The image to analyze
    ///   - completion: Callback with detected face regions
    func detectFaces(in image: NSImage, completion: @escaping ([CGRect]) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            DispatchQueue.main.async {
                completion([])
            }
            return
        }

        var faces: [CGRect] = []

        // Create face detection request
        let faceRequest = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                #if DEBUG
                print("[VisionService] Face detection error: \(error)")
                #endif
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            guard let observations = request.results as? [VNFaceObservation] else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            for observation in observations {
                let rect = observation.boundingBox
                let imageRect = CGRect(
                    x: rect.origin.x * image.size.width,
                    y: (1 - rect.origin.y - rect.size.height) * image.size.height,
                    width: rect.size.width * image.size.width,
                    height: rect.size.height * image.size.height
                )

                faces.append(imageRect)
            }

            DispatchQueue.main.async {
                completion(faces)
            }
        }

        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([faceRequest])
        }
    }
}

// MARK: - Supporting Types

/// Represents a detected text region
struct TextRegion: Identifiable {
    let id = UUID()
    let text: String
    let confidence: VNConfidence
    let boundingBox: CGRect
}

/// Represents a detected barcode/QR code
struct BarcodeInfo: Identifiable {
    let id = UUID()
    let payload: String
    let symbology: VNBarcodeSymbology
    let boundingBox: CGRect
}

// MARK: - Vision Framework Availability

extension VisionService {
    /// Check if Vision Framework features are available (macOS 13+)
    static var isAvailable: Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return true // Basic vision features work on earlier macOS
    }
}
