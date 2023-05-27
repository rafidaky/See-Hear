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
        

        
        let objectTranslations: [String: String] = [
            "person": "insan",
            "car": "araba",
            "bicycle": "bisiklet",
            "motorbike": "motosiklet",
            "bus": "otobüs",
            "truck": "kamyon",
            "traffic light": "trafik lambası",
            "stop sign": "dur işareti",
            "cat": "kedi",
            "dog": "köpek",
            "aeroplane": "uçak",
            "train": "tren",
            "boat": "tekne",
            "fire hydrant": "yangın musluğu",
            "parking meter": "parkmetre",
            "bench": "bank",
            "bird": "kuş",
            "horse": "at",
            "cow": "inek",
            "sheep": "koyun",
            "elephant": "fil",
            "bear": "ayı",
            "zebra": "zebra",
            "giraffe": "zürafa",
            "backpack": "sırt çantası",
            "umbrella": "şemsiye",
            "handbag": "el çantası",
            "tie": "kravat",
            "suitcase": "bavul",
            "frisbee": "frizbi",
            "skis": "kayaklar",
            "snowboard": "snowboard",
            "sports ball": "spor topu",
            "kite": "uçurtma",
            "baseball bat": "beyzbol sopası",
            "baseball glove": "beyzbol eldiveni",
            "skateboard": "kaykay",
            "surfboard": "sörf tahtası",
            "tennis racket": "tenis raketi",
            "bottle": "şişe",
            "wine glass": "şarap bardağı",
            "cup": "fincan",
            "fork": "çatal",
            "knife": "bıçak",
            "spoon": "kaşık",
            "bowl": "kase",
            "apple": "elma",
            "sandwich": "sandviç",
            "orange": "portakal",
            "broccoli": "brokoli",
            "carrot": "havuç",
            "hot dog": "sosisli",
            "pizza": "pizza",
            "donut": "çörek",
            "cake": "kek",
            "chair": "sandalye",
            "sofa": "kanepe",
            "pottedplant": "saksı bitkisi",
            "bed": "yatak",
            "diningtable": "yemek masası",
            "toilet": "tuvalet",
            "tvmonitor": "televizyon",
            "laptop": "dizüstü bilgisayar",
            "mouse": "fare",
            "remote": "uzaktan kumanda",
            "keyboard": "klavye",
            "cell phone": "cep telefonu",
            "microwave": "mikrodalga fırın",
            "oven": "fırın",
            "toaster": "tost makinesi",
            "sink": "lavabo",
            "refrigerator": "buzdolabı",
            "book": "kitap",
            "clock": "saat",
            "vase": "vazo",
            "scissors": "makas",
            "teddy bear": "oyuncak ayı",
            "hair drier": "saç kurutma makinesi",
            "toothbrush": "diş fırçası"
            
            // Add more translations as needed
        ]
        
        let translatedObject = objectTranslations[self.detectedObject ?? ""] ?? self.detectedObject ?? ""

        let speechUtterance = AVSpeechUtterance(string: "Görülen Nesne: \(translatedObject)")
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")

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
