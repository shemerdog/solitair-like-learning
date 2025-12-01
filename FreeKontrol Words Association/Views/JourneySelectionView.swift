import SwiftUI

struct JourneySelectionView: View {
    @EnvironmentObject var gameState: GameState
    @State private var selectedDifficulty: Difficulty = .easy
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.08, blue: 0.15),
                    Color(red: 0.01, green: 0.12, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                header
                
                difficultyPicker
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(JourneyType.allCases, id: \.self) { journey in
                            NavigationLink {
                                GameBoardView(journey: journey, difficulty: selectedDifficulty)
                                    .environmentObject(gameState)
                                    .onAppear {
                                        // Sync difficulty in settings & start level
                                        gameState.settings.difficulty = selectedDifficulty
                                        gameState.start(journey: journey)
                                    }
                            } label: {
                                JourneyCardView(journey: journey, difficulty: selectedDifficulty)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("בחר מסע")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            Text("התאם את הקלפים לפי הקשר ורעיון")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private var difficultyPicker: some View {
        HStack(spacing: 8) {
            Spacer()
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedDifficulty = difficulty
                    }
                } label: {
                    Text(difficulty.displayNameHebrew) // assuming you have this
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedDifficulty == difficulty {
                                    Color.white.opacity(0.9)
                                } else {
                                    Color.white.opacity(0.08)
                                }
                            }
                        )
                        .foregroundColor(selectedDifficulty == difficulty ? .black : .white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Journey Card

struct JourneyCardView: View {
    let journey: JourneyType
    let difficulty: Difficulty
    
    var body: some View {
        ZStack {
            journey.backgroundGradient
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 8)
            
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Spacer()
                    Text(journey.emoji)
                        .font(.system(size: 40))
                        .padding(8)
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(journey.displayNameHebrew)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text(journey.subtitleHebrew)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
                
                Spacer()
                
                HStack {
                    // Left side: difficulty label
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                        Text(difficulty.displayNameHebrew)
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Capsule())
                    .foregroundColor(.white.opacity(0.95))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("שחק")
                            .font(.subheadline.bold())
                        Image(systemName: "chevron.left")
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.92))
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .padding(16)
        }
        .frame(height: 140)
        .padding(.vertical, 2)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: difficulty)
    }
}
