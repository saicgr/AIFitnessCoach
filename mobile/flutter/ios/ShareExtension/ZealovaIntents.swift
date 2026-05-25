//
//  ZealovaIntents.swift
//  ShareExtension
//
//  iOS Shortcuts / App Intents surface for the Imports feature. Lets
//  power users build automations like "Send every video I add to the
//  'Gym' Photos album to Zealova".
//
//  This file is part of the ShareExtension target (same module so it
//  reuses the App Group plumbing). When Xcode creates the share-extension
//  target per SETUP.md, drop this file in alongside ShareViewController.
//

import Foundation
#if canImport(AppIntents)
import AppIntents
import UniformTypeIdentifiers

@available(iOS 16.0, *)
struct SendImageToZealovaIntent: AppIntent {
    static var title: LocalizedStringResource = "Send image to Zealova"
    static var description = IntentDescription(
        "Imports a photo into Zealova through the share funnel — auto-routes to food log, progress, menu scan, recipe card, or equipment."
    )

    @Parameter(title: "Image")
    var image: IntentFile

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let name = image.filename.isEmpty ? "image.jpg" : image.filename
        try ZealovaSharedInbox.append(
            kind: "image",
            filename: name,
            data: image.data
        )
        return .result()
    }
}

@available(iOS 16.0, *)
struct SendTextToZealovaIntent: AppIntent {
    static var title: LocalizedStringResource = "Send text to Zealova"
    static var description = IntentDescription(
        "Imports a snippet of text (workout from ChatGPT, recipe, tip) into Zealova."
    )

    @Parameter(title: "Text")
    var text: String

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        try ZealovaSharedInbox.appendText(text: text)
        return .result()
    }
}

@available(iOS 16.0, *)
struct SendURLToZealovaIntent: AppIntent {
    static var title: LocalizedStringResource = "Send link to Zealova"
    static var description = IntentDescription(
        "Imports a URL (YouTube, Instagram, recipe site, etc.) into Zealova."
    )

    @Parameter(title: "URL")
    var url: URL

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        try ZealovaSharedInbox.appendURL(url: url)
        return .result()
    }
}

/// AppShortcutsProvider — surfaces the intents in the Shortcuts app's
/// suggestions + Spotlight.
@available(iOS 16.0, *)
struct ZealovaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SendImageToZealovaIntent(),
            phrases: ["Send image to \(.applicationName)"],
            shortTitle: "Send image",
            systemImageName: "photo.on.rectangle"
        )
        AppShortcut(
            intent: SendTextToZealovaIntent(),
            phrases: ["Send text to \(.applicationName)"],
            shortTitle: "Send text",
            systemImageName: "text.alignleft"
        )
        AppShortcut(
            intent: SendURLToZealovaIntent(),
            phrases: ["Send link to \(.applicationName)"],
            shortTitle: "Send link",
            systemImageName: "link"
        )
    }
}

// ---------------------------------------------------------------------------
// Shared inbox helper — writes payloads into the App Group container
// in the SAME format the Share Extension uses, so the host app's
// IncomingShareService reads them through one code path.
// ---------------------------------------------------------------------------

@available(iOS 16.0, *)
enum ZealovaSharedInbox {
    static let appGroupId = "group.com.zealova.app.share"

    static func append(kind: String, filename: String, data: Data) throws {
        guard let container = container() else { throw SharedInboxError.noContainer }
        let inbox = container.appendingPathComponent("inbox", isDirectory: true)
        try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        let dest = inbox.appendingPathComponent("\(UUID().uuidString)-\(filename)")
        try data.write(to: dest)
        try writeManifest(items: [[
            "type": kind,
            "path": dest.path,
        ]])
    }

    static func appendText(text: String) throws {
        try writeManifest(items: [["type": "text", "value": text]])
    }

    static func appendURL(url: URL) throws {
        try writeManifest(items: [["type": "url", "value": url.absoluteString]])
    }

    private static func writeManifest(items: [[String: Any]]) throws {
        guard let container = container() else { throw SharedInboxError.noContainer }
        let payload: [String: Any] = [
            "version": 1,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "items": items,
        ]
        let manifestUrl = container.appendingPathComponent("ShareExtensionInbox.json")
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        try data.write(to: manifestUrl, options: .atomic)
    }

    private static func container() -> URL? {
        return FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        )
    }
}

enum SharedInboxError: Error { case noContainer }
#endif
