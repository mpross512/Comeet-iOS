import SwiftUI

@main
struct ComeetApp: App {
    @Namespace private var matchCard
    @State private var session = SessionStore.shared
    @State private var userService = UserService()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if session.restored {
                    if session.authenticated && session.needsProfile {
                        ProfileCreationView()
                    } else {
                        MasterView(authenticated: session.authenticated)
                    }
                } else {
                    Color.orange.ignoresSafeArea()
                    if let error = session.errorMessage {
                        VStack {
                            Text(error)
                            Button("Retry") { Task { await session.restore() } }
                        }.padding()
                    }
                }
            }
            .environment(session)
            .environment(session.currentUser)
            .environment(userService)
            .environment(NamespaceController(matchCard: matchCard))
            .task { await session.restore() }
        }
    }
}
