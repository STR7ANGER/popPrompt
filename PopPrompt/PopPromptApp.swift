import SwiftUI

@main
struct PopPromptApp: App {
    @StateObject private var store = PromptStore()

    var body: some Scene {
        MenuBarExtra("PopPrompt", systemImage: "text.bubble") {
            ContentView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}
