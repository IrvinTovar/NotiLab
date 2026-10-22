import SwiftUI

struct NotificationPreview: View {
    let template: NotificationTemplate
    let payload: NotificationPayload
    var timeLabel: String = "ahora"

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(icon: template.icon, tint: template.tint.color, size: 38)

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
