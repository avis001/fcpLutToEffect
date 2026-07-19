import SwiftUI

@main
struct LutFxApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("LutFx") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 680, minHeight: 500)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView {
            InstallView()
                .tabItem { Label("Install", systemImage: "square.and.arrow.down") }
            ManageView()
                .tabItem { Label("Manage", systemImage: "slider.horizontal.3") }
        }
        .padding(.top, 4)
    }
}
