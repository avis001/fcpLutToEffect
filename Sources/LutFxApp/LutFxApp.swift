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

    private enum Tab: Hashable { case install, manage }
    @State private var selectedTab = Tab.install

    var body: some View {
        // Explicit selection keeps the TabView from snapping back to the
        // first tab when a model publish rebuilds the view mid-switch.
        TabView(selection: $selectedTab) {
            InstallView()
                .tabItem { Label("Install", systemImage: "square.and.arrow.down") }
                .tag(Tab.install)
            ManageView()
                .tabItem { Label("Manage", systemImage: "slider.horizontal.3") }
                .tag(Tab.manage)
        }
        .padding(.top, 4)
    }
}
