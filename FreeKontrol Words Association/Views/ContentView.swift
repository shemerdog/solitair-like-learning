import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        NavigationStack {
            JourneySelectionView()
                .environment(\.layoutDirection, .rightToLeft) // Hebrew layout
        }
    }
}
