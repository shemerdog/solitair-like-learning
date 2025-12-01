import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        Form {
            Section(header: Text("סוג הקלפים")) {
                Picker("תוכן קלפים", selection: $gameState.settings.cardContentType) {
                    ForEach(CardContentType.allCases) { type in
                        Text(type.displayNameHebrew).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text("ערכת נושא")) {
                Picker("ערכת נושא", selection: $gameState.settings.selectedThemeID) {
                    ForEach(gameState.availableThemes) { theme in
                        Text(theme.name).tag(theme.id as UUID?)
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationTitle("הגדרות")
    }
}
