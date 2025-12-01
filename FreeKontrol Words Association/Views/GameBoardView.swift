import SwiftUI
import UIKit   // for haptics on device

struct GameBoardView: View {
    let journey: JourneyType
    let difficulty: Difficulty
    
    @EnvironmentObject var gameState: GameState
    @State private var selectedCategoryID: UUID? = nil
    @State private var showEndAlert: Bool = false
    
    @State private var boardShake: Bool = false
    @State private var showSelectCategoryHint: Bool = false
    
    @Namespace private var cardNamespace   // for fly-to-category animation
    
    private let columnCount = 3   // tableau columns
    
    var body: some View {
        ZStack {
            // Solitaire-style green felt background
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.35, blue: 0.1),
                    Color(red: 0.0, green: 0.25, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if let level = gameState.currentLevel {
                VStack(spacing: 12) {
                    topBar(level: level)
                    
                    // Category slots row
                    categorySlotsRow(level: level)
                    
                    // Instruction
                    Text(instructionText)
                        .font(.subheadline)
                        .foregroundColor(instructionColor)
                        .padding(.horizontal)
                    
                    // Tableau (board stacks)
                    tableau()
                    
                    if showSelectCategoryHint {
                        Text("קודם בחר קטגוריה באחת המשבצות העליונות 😊")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(.easeOut) {
                                        showSelectCategoryHint = false
                                    }
                                }
                            }
                    }
                    
                    Spacer(minLength: 8)
                }
                .padding(.top, 6)
                .modifier(ShakeEffect(shakes: boardShake ? 2 : 0))
            } else {
                Text("אין שלבים זמינים למסע זה.")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
            }
        }
        .navigationTitle("לוח המשחק")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showEndAlert) {
            switch gameState.status {
            case .won:
                return Alert(
                    title: Text("ניצחון! 🎉"),
                    message: Text("הצלחת להתאים את כל הקלפים."),
                    dismissButton: .default(Text("שחק שוב")) {
                        gameState.start(journey: journey)
                        selectedCategoryID = nil
                    }
                )
            case .lost:
                return Alert(
                    title: Text("נגמרו המהלכים"),
                    message: Text("לא נורא, נסה שוב."),
                    dismissButton: .default(Text("נסה שוב")) {
                        gameState.start(journey: journey)
                        selectedCategoryID = nil
                    }
                )
            case .playing:
                return Alert(
                    title: Text(""),
                    message: Text(""),
                    dismissButton: .default(Text("אישור"))
                )
            }
        }
        // React to feedback for haptics + shake
        .onChange(of: gameState.lastMatchFeedback) { feedback in
            guard gameState.status == .playing else { return }
            switch feedback {
            case .correct:
                generateHaptic(.success)
            case .wrong:
                generateHaptic(.error)
                withAnimation(.default) {
                    boardShake = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    boardShake = false
                }
            case .none:
                break
            }
        }
    }
    
    // MARK: - Top bar with draw + waste + moves
    
    private func topBar(level: Level) -> some View {
        let theme = gameState.currentTheme
        let wasteItems = gameState.wasteItems
        let topWaste = wasteItems.last
        let extraWasteCount = max(wasteItems.count - 1, 0)
        
        return HStack(spacing: 12) {
            // Draw pile (card-sized)
            DrawPileView(count: gameState.drawPileCount) {
                gameState.dealFromDrawPile()
            }
            .disabled(gameState.drawPileCount == 0 || gameState.status != .playing)
            
            // Waste pile (top card + stack)
            WastePileView(
                topItem: topWaste,
                extraCount: extraWasteCount,
                theme: theme,
                namespace: cardNamespace
            ) {
                guard let item = topWaste else { return }
                guard gameState.status == .playing else { return }
                
                guard let catID = selectedCategoryID else {
                    withAnimation(.easeInOut) {
                        showSelectCategoryHint = true
                    }
                    return
                }
                
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    gameState.attemptMatch(itemID: item.id, categoryID: catID)
                }
                
                if gameState.status == .won || gameState.status == .lost {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showEndAlert = true
                    }
                }
            }
            
            // Moves pill
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                Text("\(gameState.movesLeft)")
                    .font(.headline)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 2, y: 1)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(journey.displayNameHebrew)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(difficulty.displayNameHebrew)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Category slots row – card-sized with latest matched card
    
    private func categorySlotsRow(level: Level) -> some View {
        let theme = gameState.currentTheme
        
        return HStack(spacing: 12) {
            ForEach(level.categories) { category in
                let matched = gameState.matchedItems(for: category.id)
                let topMatched = matched.last   // latest matched for this category
                
                CategorySlotView(
                    category: category,
                    isSelected: selectedCategoryID == category.id,
                    topMatchedItem: topMatched,
                    theme: theme,
                    namespace: cardNamespace
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategoryID = category.id
                        showSelectCategoryHint = false
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Tableau with 3 columns, face-down + face-up
    
    private func tableau() -> some View {
        let theme = gameState.currentTheme
        
        return ScrollView {
            HStack(alignment: .top, spacing: 12) {
                ForEach(0..<gameState.tableauColumns.count, id: \.self) { columnIndex in
                    let columnIDs = gameState.tableauColumns[columnIndex]
                    // Only unmatched cards remain on the board
                    let remainingIDs = columnIDs.filter { id in
                        !gameState.matchedItemIDs.contains(id)
                    }
                    
                    VStack(spacing: -70) { // overlap like solitaire fan
                        ForEach(Array(remainingIDs.enumerated()), id: \.element) { idx, id in
                            let isTop = idx == remainingIDs.count - 1
                            let isFaceUp = gameState.faceUpItemIDs.contains(id)
                            
                            if let item = gameState.item(for: id) {
                                if isFaceUp {
                                    // Face-up – playable
                                    Button {
                                        guard let catID = selectedCategoryID else {
                                            withAnimation(.easeInOut) {
                                                showSelectCategoryHint = true
                                            }
                                            return
                                        }
                                        
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                            gameState.attemptMatch(itemID: item.id, categoryID: catID)
                                        }
                                        
                                        if gameState.status == .won || gameState.status == .lost {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                showEndAlert = true
                                            }
                                        }
                                    } label: {
                                        ItemCardView(
                                            item: item,
                                            theme: theme,
                                            isTopOfPile: isTop
                                        )
                                        .matchedGeometryEffect(id: item.id, in: cardNamespace) // fly from tableau
                                    }
                                    .buttonStyle(PressedCardButtonStyle())
                                    .disabled(gameState.status != .playing)
                                } else {
                                    // Face-down – card back only
                                    CardBackView()
                                        .frame(width: 90, height: 120)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }
    
    // MARK: - UI helpers
    
    private var instructionText: String {
        switch gameState.lastMatchFeedback {
        case .correct:
            return "מצוין! הקלף עלה לקטגוריה המתאימה 👏"
        case .wrong:
            return "לא בדיוק... נסה קטגוריה אחרת"
        case .none:
            return "בחר משבצת קטגוריה למעלה ואז קלף מהלוח או מהקופה. ניתן לחשוף עוד קלפים מהקופה."
        }
    }
    
    private var instructionColor: Color {
        switch gameState.lastMatchFeedback {
        case .correct:
            return .green
        case .wrong:
            return .red
        case .none:
            return .white.opacity(0.8)
        }
    }
    
    private func generateHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if targetEnvironment(simulator)
        // No real haptics in simulator
        #else
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
        #endif
    }
}

// MARK: - Card back view

struct CardBackView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.9),
                        Color.blue.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(radius: 3, y: 2)
    }
}

// MARK: - Draw pile view (card-sized)

struct DrawPileView: View {
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                CardBackView()
                    .frame(width: 90, height: 120)
                
                if count > 0 {
                    VStack(spacing: 4) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                } else {
                    Text("ריק")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Waste pile view (top card + stack), card-sized

struct WastePileView: View {
    let topItem: ItemCard?
    let extraCount: Int
    let theme: GameAppearanceTheme
    let namespace: Namespace.ID
    let onTapTop: () -> Void
    
    var body: some View {
        ZStack {
            if let item = topItem {
                // Stack hint behind
                if extraCount > 0 {
                    ForEach(0..<min(extraCount, 2), id: \.self) { index in
                        CardBackView()
                            .frame(width: 90, height: 120)
                            .offset(x: CGFloat(-index * 4), y: CGFloat(index * 2))
                            .shadow(radius: 1, y: 1)
                    }
                }
                
                Button(action: onTapTop) {
                    ItemCardView(item: item, theme: theme, isTopOfPile: true)
                        .matchedGeometryEffect(id: item.id, in: namespace) // animate between waste and slot
                }
                .buttonStyle(PressedCardButtonStyle())
            } else {
                CardBackView()
                    .frame(width: 90, height: 120)
                
                Text("0")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(width: 90, height: 120)
    }
}

// MARK: - Category foundation slot (card-sized, shows latest matched card)

struct CategorySlotView: View {
    let category: CategoryCard
    let isSelected: Bool
    let topMatchedItem: ItemCard?
    let theme: GameAppearanceTheme
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Slot background (same size as card)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.yellow : Color.white.opacity(0.5),
                        style: StrokeStyle(lineWidth: isSelected ? 3 : 1.5, dash: isSelected ? [] : [6, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(isSelected ? 0.18 : 0.08))
                    )
                
                if let item = topMatchedItem {
                    ItemCardView(item: item, theme: theme, isTopOfPile: true)
                        .matchedGeometryEffect(id: item.id, in: namespace)  // animate into slot
                        .padding(4)
                } else {
                    Text(category.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(4)
                }
            }
            .frame(width: 90, height: 120)
        }
    }
}

// MARK: - Item card (playing card style)

struct ItemCardView: View {
    let item: ItemCard
    let theme: GameAppearanceTheme
    let isTopOfPile: Bool
    
    var body: some View {
        ZStack {
            // Card background – white like playing card
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(isTopOfPile ? 0.3 : 0.15),
                        radius: isTopOfPile ? 4 : 2,
                        x: 0, y: 2)
            
            VStack {
                switch item.content {
                case .word(let text):
                    Text(text)
                        .font(.headline)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 6)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                case .imageName(let name):
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                }
                
                Spacer(minLength: 0)
                
                // Tiny suit-like icons for solitaire flavor
                HStack {
                    Image(systemName: "diamond.fill")
                        .font(.caption2)
                    Spacer()
                    Image(systemName: "diamond.fill")
                        .font(.caption2)
                }
                .foregroundColor(.red.opacity(0.7))
                .padding(6)
            }
        }
        .frame(width: 90, height: 120)
    }
}

// MARK: - Button style

struct PressedCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Shake effect

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat = 0
    
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 8 * sin(shakes * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
