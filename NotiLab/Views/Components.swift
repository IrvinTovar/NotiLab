import SwiftUI

struct NotificationPreview: View {
    let template: NotificationTemplate
    let payload: NotificationPayload
    var timeLabel: String = "ahora"

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TemplateIconView(template: template, size: 38)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text("NotiLab")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(timeLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(payload.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(payload.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}

struct TemplateIconView: View {
    let template: NotificationTemplate
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            if let image = TemplateImageStore.shared.image(named: template.imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [template.tint.color, template.tint.color.opacity(0.62)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: template.icon)
                    .font(.system(size: size * 0.40, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: template.tint.color.opacity(0.25), radius: 8, y: 4)
    }
}
