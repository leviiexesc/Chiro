import SwiftUI

enum AppTheme {
    static let accent = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1.00, green: 0.64, blue: 0.42, alpha: 1.00)
                : UIColor(red: 0.85, green: 0.42, blue: 0.20, alpha: 1.00)
        }
    )
    static let pageBackground = Color(uiColor: .systemBackground)
    static let consoleBackground = Color(uiColor: .secondarySystemBackground)
    static let pageInset: CGFloat = 16
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 36)
        .background(
            Color(uiColor: .secondarySystemFill),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon = UIImage(named: "AppIcon60x60")
                ?? Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png").flatMap(UIImage.init(contentsOfFile:))
                ?? UIImage(named: "AppIcon") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.accent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }
}
