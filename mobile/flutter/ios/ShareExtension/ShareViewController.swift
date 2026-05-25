//
//  ShareViewController.swift
//  ShareExtension
//
//  Zealova Imports feature — iOS Share Extension entry point.
//
//  This view controller hands off every shared item (photos, videos,
//  audio, URLs, text, PDFs) to the host app via the App Group container
//  `group.com.zealova.app.share` and then opens the host app via the
//  `zealova://share/v1?ids=...` URL scheme. The `receive_sharing_intent`
//  Flutter plugin reads the App Group payload on the host side.
//
//  Compliance note: this extension NEVER persists the original media
//  outside the App Group. The host app uploads to S3 and is responsible
//  for cleanup. We do not re-surface downloaded media to the user
//  post-extraction.
//

import Social
import UIKit
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: SLComposeServiceViewController {

    // MARK: - Configuration

    /// App Group identifier — MUST match the one in Runner.entitlements
    /// AND the ShareExtension's own entitlements file.
    private let appGroupId = "group.com.zealova.app.share"

    /// URL scheme handler in the host app. The host app's
    /// IncomingLinkService picks `zealova://share/v1?...` up and routes to
    /// ShareRouterScreen.
    private let hostUrlScheme = "ZealovaShareMedia"

    override func isContentValid() -> Bool {
        // Accept all share types; the host app validates per-payload.
        return true
    }

    override func didSelectPost() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeSilently()
            return
        }

        Task {
            await handleItems(extensionItems)
            await MainActor.run {
                openHostApp()
                extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }

    // MARK: - Payload handoff

    private func handleItems(_ items: [NSExtensionItem]) async {
        let payload = SharedPayloadWriter(appGroupId: appGroupId)

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                await payload.absorb(provider: provider, contentText: item.attributedContentText?.string)
            }
        }
        payload.commit()
    }

    private func openHostApp() {
        // Open the host app via the custom URL scheme. The receive_sharing_intent
        // plugin on the host side reads the App Group payload on cold-start
        // (`getInitialMedia`) and warm-start (`getMediaStream`).
        guard let url = URL(string: "\(hostUrlScheme)://share/v1") else { return }
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.perform(#selector(openURL(_:)), with: url)
                return
            }
            responder = responder?.next
        }
    }

    @objc private func openURL(_ url: URL) -> Bool { return false }

    private func completeSilently() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

// ---------------------------------------------------------------------------
// SharedPayloadWriter — serializes incoming items into the App Group.
//
// receive_sharing_intent expects a JSON manifest at a known location in
// the App Group container. The Flutter plugin handles the read-side; this
// class produces the write-side per the plugin's contract.
// ---------------------------------------------------------------------------

final class SharedPayloadWriter {
    init(appGroupId: String) {
        self.appGroupId = appGroupId
        self.containerUrl = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    let appGroupId: String
    let containerUrl: URL?

    private var entries: [[String: Any]] = []

    func absorb(provider: NSItemProvider, contentText: String?) async {
        // Plain text
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let text = try? await loadString(
                provider: provider,
                typeIdentifier: UTType.plainText.identifier
            ) {
                entries.append([
                    "type": "text",
                    "value": text,
                ])
                return
            }
        }
        // URL
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = try? await loadUrl(
                provider: provider,
                typeIdentifier: UTType.url.identifier
            ) {
                entries.append([
                    "type": "url",
                    "value": url.absoluteString,
                ])
                return
            }
        }
        // Image
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            if let path = try? await loadFile(
                provider: provider,
                typeIdentifier: UTType.image.identifier
            ) {
                entries.append([
                    "type": "image",
                    "path": path,
                ])
                return
            }
        }
        // Movie / Video
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) ||
           provider.hasItemConformingToTypeIdentifier(UTType.video.identifier) {
            let id = provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
                ? UTType.movie.identifier : UTType.video.identifier
            if let path = try? await loadFile(provider: provider, typeIdentifier: id) {
                entries.append([
                    "type": "video",
                    "path": path,
                ])
                return
            }
        }
        // Audio
        if provider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
            if let path = try? await loadFile(
                provider: provider,
                typeIdentifier: UTType.audio.identifier
            ) {
                entries.append([
                    "type": "file",
                    "path": path,
                ])
                return
            }
        }
        // PDF
        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            if let path = try? await loadFile(
                provider: provider,
                typeIdentifier: UTType.pdf.identifier
            ) {
                entries.append([
                    "type": "file",
                    "path": path,
                ])
                return
            }
        }
        // Generic file
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            if let path = try? await loadFile(
                provider: provider,
                typeIdentifier: UTType.fileURL.identifier
            ) {
                entries.append([
                    "type": "file",
                    "path": path,
                ])
                return
            }
        }

        // Fallback — preserve any composed text the user typed in the
        // extension sheet, even if no specific UTI matched.
        if let txt = contentText, !txt.isEmpty {
            entries.append(["type": "text", "value": txt])
        }
    }

    func commit() {
        guard let container = containerUrl else { return }
        let url = container.appendingPathComponent("ShareExtensionInbox.json")
        let payload: [String: Any] = [
            "version": 1,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "items": entries,
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // ----- Loaders ---------------------------------------------------------

    private func loadString(provider: NSItemProvider, typeIdentifier: String) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                if let s = item as? String {
                    cont.resume(returning: s)
                } else if let data = item as? Data, let s = String(data: data, encoding: .utf8) {
                    cont.resume(returning: s)
                } else if let url = item as? URL {
                    cont.resume(returning: url.absoluteString)
                } else {
                    cont.resume(throwing: NSError(domain: "ShareExtension", code: -1))
                }
            }
        }
    }

    private func loadUrl(provider: NSItemProvider, typeIdentifier: String) async throws -> URL {
        try await withCheckedThrowingContinuation { cont in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                if let u = item as? URL {
                    cont.resume(returning: u)
                } else if let s = item as? String, let u = URL(string: s) {
                    cont.resume(returning: u)
                } else {
                    cont.resume(throwing: NSError(domain: "ShareExtension", code: -2))
                }
            }
        }
    }

    /// Copies the shared file into the App Group container and returns the
    /// new path. We never pass the original URL across — iOS sandboxes
    /// it to the extension's lifetime.
    private func loadFile(provider: NSItemProvider, typeIdentifier: String) async throws -> String {
        let sourceUrl: URL = try await withCheckedThrowingContinuation { cont in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error = error { cont.resume(throwing: error); return }
                if let u = item as? URL { cont.resume(returning: u) }
                else { cont.resume(throwing: NSError(domain: "ShareExtension", code: -3)) }
            }
        }
        guard let container = containerUrl else {
            throw NSError(domain: "ShareExtension", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "No App Group container"])
        }
        let inbox = container.appendingPathComponent("inbox", isDirectory: true)
        try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        let dest = inbox.appendingPathComponent(UUID().uuidString + "-" + sourceUrl.lastPathComponent)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: sourceUrl, to: dest)
        return dest.path
    }
}
