import SwiftUI
import UIKit
import AVFoundation
import CoreML
import Vision






class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var detectionRequest: VNCoreMLRequest!
    private var handler: VNSequenceRequestHandler!
    private var detectionInProgress = false
    var detectedObject: String?
    private var speechSynthesizer = AVSpeechSynthesizer()
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCaptureSession()
        stopSpeechSynthesizer()
    }
    
    private func stopCaptureSession() {
        if let captureSession = previewLayer.session {
            captureSession.stopRunning()
        }
    }
    
    private func stopSpeechSynthesizer() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let model = try? VNCoreMLModel(for: YOLOv3().model) else {
            fatalError("Failed to load model")
        }
        detectionRequest = VNCoreMLRequest(model: model, completionHandler: handleDetection)
        handler = VNSequenceRequestHandler()
        
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("Failed to get capture device")
            return
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Failed to create input from capture device")
            return
        }
        
        captureSession.addInput(input)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get pixel buffer from sample buffer")
            return
        }
        
        do {
            try handler.perform([detectionRequest], on: pixelBuffer)
        } catch {
            print("Failed to perform object detection: \(error)")
        }
    }
    
    func handleDetection(request: VNRequest, error: Error?) {
        guard !detectionInProgress else { return }
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            print("Failed to get results from VNRequest")
            return
        }
        
        let minimumConfidence: Float = 0.9
        let maximumFrequency: TimeInterval = 3.5 // Adjust the frequency here (in seconds)
        
        for result in results {
            if result.confidence > minimumConfidence {
                if let detectedObject = result.labels.first?.identifier {
                    let currentTime = Date.timeIntervalSinceReferenceDate
                    let lastVoicingTime = UserDefaults.standard.object(forKey: "lastVoicingTime") as? TimeInterval ?? 0.0
                    let timeSinceLastVoicing = currentTime - lastVoicingTime
                    if timeSinceLastVoicing >= maximumFrequency {
                        speakDetectedObject(detectedObject: detectedObject)
                        UserDefaults.standard.set(currentTime, forKey: "lastVoicingTime")
                    }
                }
            }
        }
    }
    
    func speakDetectedObject(detectedObject: String) {
        self.detectedObject = detectedObject
        let defaultLanguage = "tr-TR"
        let selectedVoiceIdentifier = UserDefaults.standard.string(forKey: "selectedVoice")
        let selectedVoice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier ?? "")
        let selectedLanguage = selectedVoice?.language ?? defaultLanguage
        
        // Create a mutable copy of translations
        var updatedTranslations = translations
        
        // Update translations for all languages
        for (languageCode, _) in updatedTranslations {
            if languageCode.hasPrefix("en-") { // English
                updatedTranslations[languageCode] = translations["en-US"]
            } else if languageCode.hasPrefix("tr-") { // Turkish
                updatedTranslations[languageCode] = translations["tr-TR"]
            } else if languageCode.hasPrefix("fr-") { // French
                updatedTranslations[languageCode] = translations["fr-FR"]
            } else if languageCode.hasPrefix("de-") { // German
                updatedTranslations[languageCode] = translations["de-DE"]
            } else if languageCode.hasPrefix("it-") { // Italian
                updatedTranslations[languageCode] = translations["it-IT"]
            }
        }
        
        let languageTranslations = updatedTranslations[selectedLanguage] ?? updatedTranslations[defaultLanguage]!
        
        let translatedObject = languageTranslations[self.detectedObject ?? ""] ?? self.detectedObject ?? ""
        
        var detectionPhrase: String
        
        switch selectedLanguage {
        case "en-US":
            detectionPhrase = "Detected Object"
        case "tr-TR":
            detectionPhrase = "Görülen Nesne"
        case "fr-FR":
            detectionPhrase = "Objet Détecté"
        case "de-DE":
            detectionPhrase = "Erkanntes Objekt"
        case "it-IT":
            detectionPhrase = "Oggetto Rilevato"
        default:
            detectionPhrase = "Detected Object"
        }
        
        let speechUtterance = AVSpeechUtterance(string: "\(detectionPhrase): \(translatedObject)")
        speechUtterance.voice = AVSpeechSynthesisVoice(language: selectedLanguage)

        if let selectedVoiceIdentifier = UserDefaults.standard.string(forKey: "selectedVoice") {
            speechUtterance.voice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier)
        } else {
            // Use default voice if no voice is selected
            speechUtterance.voice = AVSpeechSynthesisVoice(language: selectedLanguage)
        }
        speechSynthesizer.speak(speechUtterance)

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .objectDetected, object: nil)
        }
    }
}

extension Notification.Name {
    static let objectDetected = Notification.Name("objectDetected")
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var detectedObject: String?
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        NotificationCenter.default.addObserver(forName: .objectDetected, object: nil, queue: .main) { _ in
            self.detectedObject = viewController.detectedObject
        }
        viewController.detectedObject = self.detectedObject // Assign the value to the view controller
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
    }
}
