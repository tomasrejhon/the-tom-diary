# Ikonka aplikace

## Podklady a připojení

Uživatel dodal motiv krémového deníku s tmavě modrým páskem a nápisem **The Tom Diary**. Původní obrázek se zachoval v `Assets/app-icon-original.jpg`. Pro iOS se pouze připravilo pozadí do čtvercových rohů místo bílého okraje kolem již zaobleného náhledu; úprava zachovává motiv, nápis a barevnost.

Úprava byla vytvořená vestavěným nástrojem **imagegen**, nikoli ruční změnou motivu v kódu. Výstup je uložený v `Assets/app-icon-square-master.png`. Následná mechanická změna rozměru nástrojem macOS `sips` vytvořila finální neprůhledný PNG **1024 × 1024**:

`The Tom Didary/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`

`Contents.json` nyní používá režim All Sizes: přiřazuje 1024px podklad App Store a samostatné velikosti pro iPhone/iPad, včetně oznámení (20 bodů × 2 nebo × 3). Projekt má pro hlavní target `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`. Menší PNG varianty jsou odvozené ze stejného originálu nástrojem `sips`; rohy maskuje systém. Tento postup odpovídá [Apple — konfiguraci ikonky v asset katalogu](https://developer.apple.com/documentation/xcode/configuring-your-app-icon) a [pravidlům ikon](https://developer.apple.com/design/human-interface-guidelines/app-icons).

Současná verze má vlastní základní barevnou ikonu. Samostatné návrhy pro tmavý/tónovaný vzhled, vrstvený Icon Composer asset a hotová sada pro Mac zatím nejsou vytvořené. Systém může vzhled upravit podle svého nastavení.

Zobrazovaný název pod ikonkou je nastavený na **The Tom Diary** v Debug i Release. Bundle ID, názvy projektu a modulů zůstávají původní, aby tato úprava nezměnila identitu již nainstalované aplikace.

## Výměna v budoucnu

Otevři v Xcode `Assets.xcassets` → `AppIcon`. Při změně motivu nahraď `AppIcon-1024.png` a znovu vytvoř všech 14 malých PNG variant: režim All Sizes používá každou samostatně. Pouhá výměna 1024px podkladu nyní nezmění malé ikony. Potřebný pixelový rozměr je velikost v bodech × scale z `Contents.json`; například 20 × 3 = 60 pixelů.

Příklad z příkazové řádky spuštěné ve složce AppIcon.appiconset:

```sh
sips -z 60 60 AppIcon-1024.png --out AppIcon-20x20@3x.png
```

Zachovej neprůhledný čtvercový podklad a stávající přiřazení souborů v katalogu. Ikonku měníš bez změny bundle ID.

Sestav aplikaci a aktualizuj existující instalaci přes ⌘R. Ikonu nakonec zkontroluj na ploše telefonu v běžné velikosti: detailní nápis může být menší než v podkladovém obrázku. Tato verze zachovává nápis z uživatelova návrhu.

## Přesné zadání úpravy

Použitý režim: vestavěný imagegen, editace přiloženého obrázku, neprůhledné pozadí.

```text
Use case: precise-object-edit.
Asset type: final opaque iPhone app icon, square 1024 x 1024.
Input image: edit target, the user's finished cream journal with navy elastic band and the exact cover text "The" above "Tom Diary".
Primary request: change ONLY the outer background. Remove the white canvas/border around the rounded app-icon tile, and extend the existing cream-to-muted-blue gradient smoothly to all four edges and square corners. The output must be a full square with no white outside border and no baked-in rounded outer mask; iOS will apply its own corner mask.
Invariants: preserve the book exactly as shown: same central position, size, shape, pale leather cover, shadows, visible pages, navy vertical elastic on the right, typography, line below title. Keep text exactly "The" and "Tom Diary" in the original positions. Preserve original soft realistic 3D style and gradient colors. Do not redesign, crop the book, move it, add objects, add branding, or change lighting. Opaque background, no transparency.
```

Originál i výstup zůstávají součástí dokumentace, takže další úprava nemusí vycházet z malé systémové ikonky.

## Doplnění ikon oznámení — 12. 10. 2026

Uživatel potvrdil doručení připomínky na telefonu, ale oznámení ukazovalo náhradní ikonu. Předchozí sestavení mělo v Assets.car jediný univerzální 1024px podklad. Přidali jsme 14 menších PNG variant a explicitní položky pro iPhone/iPad, včetně 20bodových ikon oznámení. Prázdné varianty dark/tinted se odstranily; motiv se neměnil.

Kontrola výsledného balíčku pro fyzický iPhone již našla skutečnou 60px ikonu `AppIcon-20x20@3x.png` a další odpovídající velikosti v Assets.car. Tato kontrola ověřuje obsah sestavení. Vzhled na konkrétním telefonu následně potvrdil uživatel po restartu. Samotný obrázek se nepřidává jako příloha zprávy; systém používá ikonu aplikace.

Po aktualizaci existující instalace nastav novou připomínku na několik minut dopředu. Pokud zůstane stará náhradní ikona, zavři staré oznámení, restartuj telefon a ověř nové doručení. Možný vliv systémové cache je pracovní vysvětlení, nikoli potvrzená příčina tohoto konkrétního případu. Aplikaci kvůli tomu neodinstalovávej.

Skutečné doručení se správným logem bylo následně ověřené také v běžné instalaci simulátoru iPhone 17 / iOS 27.0 ve světlém vzhledu. Připomínka přišla ve 16:46 s aplikací na pozadí; [náhled](Assets/notifikace-logo-2026-10-12.png) zachycuje reálné oznámení. Po kontrole se testovací nastavení vrátilo na vypnuto / 20:00.

Uživatel 12. 10. potvrdil, že restart skutečného iPhonu problém se starou ikonkou vyřešil. Reinstalace nebyla k této opravě potřeba. Vliv cache zůstává vysvětlením vyvozeným z pozorovaného výsledku.
