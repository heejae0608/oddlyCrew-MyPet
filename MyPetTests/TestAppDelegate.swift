import SwiftUI
import FirebaseCore
import Testing

@main
struct TestApp: App {
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            Text("Test")
        }
    }
}
