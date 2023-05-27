import SwiftUI
import AVFoundation

struct SettingsView: View {
    @State private var showVoicePicker = false
    @State private var selectedVoiceName: String = UserDefaults.standard.string(forKey: "selectedVoiceName") ?? "Ses Seç"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ayarlar")) {
                    Button(action: {
                        showVoicePicker = true
                    }) {
                        Text(selectedVoiceName)
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .sheet(isPresented: $showVoicePicker) {
                VoicePickerView(selectedVoiceName: $selectedVoiceName)
            }
        }
    }
}

struct VoicePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    let voices = AVSpeechSynthesisVoice.speechVoices()
    @Binding var selectedVoiceName: String

    var body: some View {
        NavigationView {
            List(voices, id: \.identifier) { voice in
                VStack(alignment: .leading) {
                    Text(voice.name)
                    Text(voice.language ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    UserDefaults.standard.set(voice.identifier, forKey: "selectedVoice")
                    UserDefaults.standard.set(voice.name, forKey: "selectedVoiceName")
                    UserDefaults.standard.synchronize()  // Synchronize immediately
                    selectedVoiceName = voice.name
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Ses Seç")
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
