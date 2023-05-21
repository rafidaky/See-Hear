import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject var camera = CameraModel()

    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea(.all, edges: .all)

            VStack {
                Spacer()

                HStack {
                    Spacer()
                    // Button or any other controls you want can be added here
                    Spacer()
                }
                .frame(height: 100)
                .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
            }
        }
        .onAppear(perform: {
            camera.Check()
        })
        .alert(isPresented: $camera.alert) {
            Alert(title: Text("Error"), message: Text(camera.alertMsg), dismissButton: .default(Text("Ok")))
        }
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var alertMsg = "" // Here is the new line
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!

    // Check for camera permissions
    func Check() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setup()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status {
                    self.setup()
                }
            }
        case .denied:
            self.alertMsg = "You have denied camera access. You need to change your settings!"
            self.alert.toggle()
        default:
            return
        }
    }

    func setup() {
        do {
            self.session.beginConfiguration()
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

            let input = try AVCaptureDeviceInput(device: device!)

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }

            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }

            self.session.commitConfiguration()
        }
        catch {
            self.alertMsg = error.localizedDescription
            self.alert.toggle()
        }
    }

    func takePic() {
        self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()

            DispatchQueue.main.async {
                withAnimation{self.isTaken.toggle()}
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera : CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)

        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame

        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)

        camera.session.startRunning()

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
