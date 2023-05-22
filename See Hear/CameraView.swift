import SwiftUI
import UIKit
import AVFoundation
import CoreML
import Vision

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var detectionRequest: VNCoreMLRequest!
    private var handler: VNSequenceRequestHandler!

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
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return
        }
        for result in results {
            print("Detected object: \(result.labels[0].identifier), confidence: \(result.labels[0].confidence)")
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
    }
}
