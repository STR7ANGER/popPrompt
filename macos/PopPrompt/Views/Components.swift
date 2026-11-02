import SwiftUI

extension Animation {
    static let panel = Animation.smooth(duration: 0.2)
}

extension View {
    func cardSurface(cornerRadius: CGFloat = 20) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct HeaderIconButton: View {
    let systemName: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? .black : .white)
                .frame(width: 36, height: 36)
                .background(isActive ? Color.white : Color.white.opacity(0.08))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct CardIconButton: View {
    let systemName: String
    var rotation: Double = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
                .rotationEffect(.degrees(rotation))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Capsule button used for dialog and inline actions. `prominent` is the white primary style.
struct PillButtonStyle: ButtonStyle {
    var prominent = false
    var compact = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 12 : 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, compact ? 12 : 16)
            .padding(.vertical, compact ? 6 : 10)
            .background(background)
            .foregroundStyle(prominent ? Color.black : Color.white)
            .clipShape(Capsule())
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }

    private var background: Color {
        guard prominent else { return Color.white.opacity(0.08) }
        return isEnabled ? Color.white : Color.white.opacity(0.18)
    }
}

struct EmptyStateView: View {
    let systemName: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PillButtonStyle(prominent: true))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .cardSurface(cornerRadius: 24)
    }
}
