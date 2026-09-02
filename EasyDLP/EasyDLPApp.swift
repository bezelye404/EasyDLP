import SwiftUI

@main
struct EasyDLPApp: App {
    @State private var downloadManager = DownloadManager()

    var body: some Scene {
        WindowGroup {
            MainView(downloadManager: downloadManager)
                .frame(minWidth: 800, minHeight: 500)
        }
        .defaultSize(width: 960, height: 640)

        Settings {
            SettingsView(downloadManager: downloadManager)
                .frame(width: 500, height: 400)
        }
    }
}
