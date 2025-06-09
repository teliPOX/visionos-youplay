import SwiftUI
import AVFoundation

@main
struct YouPlayApp: App {
    @State private var appModel = AppModel()
    @State private var audioPlayer: AVAudioPlayer?
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    
    @AppStorage("isIntro") private var isIntro = true
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .aspectRatio(16.0/9.0, contentMode: .fit)
                .onAppear {
                    if (isIntro) {
                        playIntroSound()
                    }
                }
        }
        .defaultSize(width: 1280, height: 720)
        .windowResizability(.contentMinSize)
        .onChange(of: isDarkMode) { _, newValue in
            if let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {
                windowScene.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .light : .dark
            }
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }

    private func playIntroSound() {
        guard let path = Bundle.main.path(forResource: "intro", ofType: "mp3"),
              let url = URL(string: "file://\(path)") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing intro sound: \(error)")
        }
    }
}
