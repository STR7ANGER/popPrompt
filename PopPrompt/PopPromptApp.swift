import SwiftUI

@main
struct PopPromptApp: App {
    @StateObject private var store = PromptStore()

    var body: some Scene {
        WindowGroup("PopPrompt") {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 420, height: 520)

        MenuBarExtra("PopPrompt", systemImage: "text.bubble") {
            ContentView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}
