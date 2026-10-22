import SwiftUI
import UIKit

final class TemplateImageStore {
    static let shared = TemplateImageStore()

    private let fileManager = FileManager.default

    private var imagesDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent("NotificationImages", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    func save(image: UIImage) -> String? {
        let normalized = image.squareThumbnail(maxDimension: 512)
        guard let data = normalized.pngData() else { return nil }

        let filename = "icon-\(UUID().uuidString).png"
        let url = imagesDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    func image(named filename: String?) -> UIImage? {
        guard let filename, !filename.isEmpty else { return nil }
        return UIImage(contentsOfFile: imagesDirectory.appendingPathComponent(filename).path)
    }

    func delete(named filename: String?) {
        guard let filename, !filename.isEmpty else { return }
        try? fileManager.removeItem(at: imagesDirectory.appendingPathComponent(filename))
    }

    func deleteGenerated(for templateID: UUID) {
        let url = imagesDirectory.appendingPathComponent("generated-\(templateID.uuidString).png")
        try? fileManager.removeItem(at: url)
    }

    func attachmentURL(for template: NotificationTemplate) -> URL? {
        if let filename = template.imageName {
            let url = imagesDirectory.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        return renderSymbol(for: template)
    }

    private func renderSymbol(for template: NotificationTemplate) -> URL? {
        let filename = "generated-\(template.id.uuidString).png"
        let url = imagesDirectory.appendingPathComponent(filename)
        let size = CGSize(width: 512, height: 512)
        let baseColor = UIColor(template.tint.color)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let image = renderer.image { context in
            let colors = [
                baseColor.cgColor,
                baseColor.withAlphaComponent(0.58).cgColor
            ] as CFArray

            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [CGFloat(0), CGFloat(1)]
            ) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            } else {
                context.cgContext.setFillColor(baseColor.cgColor)
                context.cgContext.fill(CGRect(origin: .zero, size: size))
            }

            let configuration = UIImage.SymbolConfiguration(pointSize: 280, weight: .semibold)
            if let symbol = UIImage(systemName: template.icon, withConfiguration: configuration)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let symbolSize = symbol.size
                let origin = CGPoint(
                    x: (size.width - symbolSize.width) / 2,
                    y: (size.height - symbolSize.height) / 2
                )
                symbol.draw(at: origin)
            }
        }

        guard let data = image.pngData() else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

private extension UIImage {
    func squareThumbnail(maxDimension: CGFloat) -> UIImage {
        let target = CGSize(width: maxDimension, height: maxDimension)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)

        return renderer.image { _ in
            let scale = max(target.width / size.width, target.height / size.height)
            let drawSize = CGSize(width: size.width * scale, height: size.height * scale)
            let origin = CGPoint(
                x: (target.width - drawSize.width) / 2,
                y: (target.height - drawSize.height) / 2
            )
            draw(in: CGRect(origin: origin, size: drawSize))
        }
    }
}
