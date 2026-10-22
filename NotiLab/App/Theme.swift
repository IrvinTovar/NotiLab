import SwiftUI
import UIKit

// MARK: - Palette

extension Color {
    static let nlBackground = Color(uiColor: .systemBackground)
    static let nlSurface = Color(uiColor: .secondarySystemBackground)
    static let nlSurfaceRaised = Color(uiColor: .tertiarySystemBackground)
    static let nlStroke = Color(uiColor: .separator)
    static let nlAccent = Color(uiColor: .systemGreen)
    static let nlAccentDeep = Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.290, green: 0.871, blue: 0.502, alpha: 1)
            : UIColor(red: 0.071, green: 0.494, blue: 0.263, alpha: 1)
    }))
    static let nlAccent2 = Color(uiColor: UIColor(dynamicProvider: { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.400, green: 0.890, blue: 0.553, alpha: 1)
            : UIColor(red: 0.055, green: 0.561, blue: 0.282, alpha: 1)
    }))
    static let nlInk = Color(red: 0.016, green: 0.071, blue: 0.031)
    static let nlRed = Color(uiColor: .systemRed)
    static let nlBlue = Color(uiColor: .systemBlue)
    static let nlOrange = Color(uiColor: .systemOrange)
    static let nlPurple = Color(uiColor: .systemPurple)
    static let nlPink = Color(uiColor: .systemPink)
    static let nlTeal = Color(uiColor: .systemTeal)
    static let nlGray = Color(uiColor: .systemGray)
}

// MARK: - Background

struct NLBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.nlBackground

            if colorScheme == .dark {
                RadialGradient(
                    colors: [Color.nlAccent.opacity(0.16), .clear],
                    center: .topTrailing,
                    startRadius: 30,
                    endRadius: 540
                )
                RadialGradient(
                    colors: [Color.nlBlue.opacity(0.07), .clear],
                    center: .bottomLeading,
                    startRadius: 20,
                    endRadius: 480
                )
            } else {
                LinearGradient(
                    colors: [Color.nlAccent.opacity(0.10), .clear, Color.nlBlue.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Cards

struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = 18
    var radius: CGFloat = 26

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.14), radius: 18, y: 10)
    }
}

extension View {
    func nlCard(padding: CGFloat = 18, radius: CGFloat = 26) -> some View {
        modifier(GlassCardModifier(padding: padding, radius: radius))
    }
}

// MARK: - Common labels

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct IconBadge: View {
    let icon: String
    let tint: Color
    var size: CGFloat = 44

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(tint.gradient)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: size * 0.40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: tint.opacity(0.25), radius: 8, y: 4)
    }
}

struct TagPill: View {
    let text: String
    let icon: String?

    init(_ text: String, icon: String? = nil) {
        self.text = text
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var detail: String? = nil
    var tint: Color = .nlAccent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(title)
                .font(.subheadline.weight(.medium))

            Spacer(minLength: 8)

            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Toast

struct ToastView: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
            .shadow(color: .black.opacity(0.22), radius: 16, y: 8)
            .padding(.horizontal, 20)
    }
}

// MARK: - Formatters

enum DurationText {
    static func seconds(_ value: Int) -> String {
        guard value >= 60 else { return "\(value) s" }
        guard value >= 3600 else {
            let minutes = value / 60
            let seconds = value % 60
            return seconds == 0 ? "\(minutes) min" : "\(minutes) min \(seconds) s"
        }

        let hours = value / 3600
        let minutes = (value % 3600) / 60
        if minutes == 0 {
            return "\(hours) h"
        }
        return "\(hours) h \(minutes) min"
    }

    static func minutes(_ value: Int) -> String {
        seconds(value * 60)
    }

    static func short(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE d, HH:mm"
        return formatter.string(from: date)
    }
}

func nlHideKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
