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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let model = try? VNCoreMLModel(for: YOLOv3().model) else {
            fatalError("Failed to load model")
        }
        detectionRequest = VNCoreMLRequest(model: model, completionHandler: handleDetection)
        handler = VNSequenceRequestHandler()
        
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
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
            return
        }
        try? handler.perform([detectionRequest], on: pixelBuffer)
    }
    
    func handleDetection(request: VNRequest, error: Error?) {
        guard !detectionInProgress else { return }
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return
        }
        for result in results {
            if result.confidence > 0.9 {
                print("Detected object: \(result.labels[0].identifier), confidence: \(result.labels[0].confidence)")
                detectionInProgress = true
                detectedObject = result.labels[0].identifier
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .objectDetected, object: nil)
                }
                break
            }
        }
    }
    
}
extension Notification.Name {
    static let objectDetected = Notification.Name("objectDetected")
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var detectedObject: String?
    @Binding var showAlert: Bool
    func makeUIViewController(context: Context) -> CameraViewController {
         let viewController = CameraViewController()
         NotificationCenter.default.addObserver(forName: .objectDetected, object: nil, queue: .main) { _ in
             if let object = viewController.detectedObject {
                 self.detectedObject = object
                 self.showAlert = true
             }
         }
         return viewController
     }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
    }
}
