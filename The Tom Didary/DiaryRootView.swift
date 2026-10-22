import SwiftUI

/// Kořen obrazovky drží intro jen v paměti aktuálního spuštění aplikace.
/// Návrat z pozadí nevytváří nový kořen, a proto se intro znovu nepřehrává.
struct DiaryRootView: View {
    @State private var showsIntroduction = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Zápisník zůstává připojený i během intra: načítá odpovědi, zálohu
            // a platnost podpisu. Intro nepřepisuje jeho stav ani databázi.
            ContentView()
                .allowsHitTesting(!showsIntroduction)
                .accessibilityHidden(showsIntroduction)

            if showsIntroduction {
                LaunchIntroductionView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        // Logo má světlý podklad; po intru se znovu použije systémový vzhled.
        .preferredColorScheme(showsIntroduction ? .light : nil)
        .task {
            // Jde o krátké uvítání, nikoli měření načítání či uploadu zálohy.
            // Asynchronní čekání neblokuje hlavní vlákno a SwiftUI je při
            // zrušení obrazovky ukončí. Délku lze změnit na tomto jediném místě.
            do {
                try await Task.sleep(for: .milliseconds(2_500))
            } catch {
                return
            }
            withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.35)) {
                showsIntroduction = false
            }
        }
    }
}

/// Celostránkové uvítání používá stejný originál jako systémová ikona.
/// Neostrý podklad vyplní i vysoký displej, zatímco ostrý obrázek zachová
/// celý deník i nápis bez ořezu. Rozložení respektuje také menší displeje.
struct LaunchIntroductionView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("DiaryLaunchArtwork")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .blur(radius: 55, opaque: true)
                    .clipped()

                Image("DiaryLaunchArtwork")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width)
                    // Měkké horní a spodní okraje spojí čtvercový podklad
                    // s pozadím; nevzniknou pruhy kolem obrázku na výšku.
                    .mask {
                        LinearGradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.10),
                            .init(color: .black, location: 0.90),
                            .init(color: .clear, location: 1)
                        ], startPoint: .top, endPoint: .bottom)
                    }
                    .accessibilityHidden(true)

                VStack {
                    Spacer()
                    ProgressView()
                        .tint(Color(red: 0.20, green: 0.32, blue: 0.45))
                        .padding(.bottom, max(geometry.size.height * 0.12, 36))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The Tom Diary")
        .accessibilityValue("Otevírám zápisník")
        .accessibilityIdentifier("launchIntroduction")
    }
}

#Preview("Úvodní obrazovka") {
    LaunchIntroductionView()
}
