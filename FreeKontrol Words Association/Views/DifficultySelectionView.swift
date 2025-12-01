import SwiftUI

struct DifficultySelectionView: View {
    let journey: JourneyType
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        let theme = gameState.currentTheme
        
        ZStack {
            LinearGradient(
                colors: [
                    theme.backgroundColor.swiftUIColor.opacity(0.9),
                    theme.backgroundColor.swiftUIColor.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(alignment: .trailing, spacing: 24) {
                VStack(alignment: .trailing, spacing: 8) {
                    Text(journey.displayNameHebrew)
                        .font(.largeTitle.bold())
                    Text("בחר רמת קושי למסע")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                VStack(spacing: 16) {
                    ForEach(Difficulty.allCases) { difficulty in
                        NavigationLink {
                            GameBoardView(journey: journey, difficulty: difficulty)
                                .onAppear {
                                    gameState.settings.difficulty = difficulty
                                    gameState.start(journey: journey)
                                }
                        } label: {
                            HStack {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(difficulty.displayNameHebrew)
                                        .font(.headline)
                                    Text(description(for: difficulty))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .center, spacing: 4) {
                                    Text("\(difficulty.maxMoves)")
                                        .font(.headline)
                                    Text("מהלכים")
                                        .font(.caption2)
                                }
                                .padding(8)
                                .background(theme.cardBackColor.swiftUIColor.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .cornerRadius(18)
                            .shadow(radius: 3, y: 2)
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func description(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: return "פחות קטגוריות, יותר מהלכים"
        case .medium: return "איזון בין אתגר לנוחות"
        case .hard: return "הרבה קלפים, מעט מהלכים"
        }
    }
}
