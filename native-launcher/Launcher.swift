import AppKit
import Foundation

struct LauncherConfiguration {
  let cursorBinaryPath: String
  let userDataDir: String
  let extensionsDir: String

  init(bundle: Bundle = .main) throws {
    guard
      let info = bundle.infoDictionary,
      let cursorBinaryPath = info["CursorBinaryPath"] as? String,
      let userDataDir = info["CursorUserDataDir"] as? String,
      let extensionsDir = info["CursorExtensionsDir"] as? String
    else {
      throw NSError(
        domain: "CursorProfileLauncher",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Launcher configuration is missing from Info.plist."]
      )
    }

    self.cursorBinaryPath = cursorBinaryPath
    self.userDataDir = userDataDir
    self.extensionsDir = extensionsDir
  }
}

final class LauncherAppDelegate: NSObject, NSApplicationDelegate {
  private let configuration: LauncherConfiguration
  private var pendingURLs: [URL] = []
  private var launchedInitialCursorProcess = false
  private var runningProcesses: [pid_t: Process] = [:]

  init(configuration: LauncherConfiguration) {
    self.configuration = configuration
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    launchInitialProcessIfNeeded()
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    let fileURLs = urls.filter(\.isFileURL)
    guard !fileURLs.isEmpty else { return }

    if launchedInitialCursorProcess {
      launchCursor(with: fileURLs)
    } else {
      pendingURLs.append(contentsOf: fileURLs)
    }
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if let runningApp = mostRecentRunningApplication() {
      runningApp.activate(options: [.activateAllWindows])
    } else {
      launchCursor(with: [])
    }

    return false
  }

  private func launchInitialProcessIfNeeded() {
    guard !launchedInitialCursorProcess else { return }

    launchedInitialCursorProcess = true
    let urls = pendingURLs
    pendingURLs.removeAll()
    launchCursor(with: urls)
  }

  private func launchCursor(with urls: [URL]) {
    urls.forEach { NSDocumentController.shared.noteNewRecentDocumentURL($0) }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: configuration.cursorBinaryPath)
    process.arguments =
      [
        "--user-data-dir=\(configuration.userDataDir)",
        "--extensions-dir=\(configuration.extensionsDir)",
        "--new-window",
      ] + urls.map(\.path)

    process.standardInput = FileHandle.nullDevice

    process.terminationHandler = { [weak self] process in
      Task { @MainActor in
        self?.runningProcesses.removeValue(forKey: process.processIdentifier)
        if self?.runningProcesses.isEmpty == true {
          NSApp.terminate(nil)
        }
      }
    }

    do {
      try process.run()
      runningProcesses[process.processIdentifier] = process
      activateRunningApplication(for: process)
    } catch {
      showErrorAndTerminate(message: error.localizedDescription)
    }
  }

  private func activateRunningApplication(for process: Process) {
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
      guard let app = NSRunningApplication(processIdentifier: process.processIdentifier) else { return }
      app.activate(options: [.activateAllWindows])
    }
  }

  private func mostRecentRunningApplication() -> NSRunningApplication? {
    runningProcesses.values
      .sorted { $0.processIdentifier > $1.processIdentifier }
      .compactMap { NSRunningApplication(processIdentifier: $0.processIdentifier) }
      .first
  }

  private func showErrorAndTerminate(message: String) {
    let alert = NSAlert()
    alert.messageText = "Cursor profile launcher failed"
    alert.informativeText = message
    alert.runModal()
    NSApp.terminate(nil)
  }
}

do {
  let configuration = try LauncherConfiguration()
  let app = NSApplication.shared
  let delegate = LauncherAppDelegate(configuration: configuration)
  app.setActivationPolicy(.regular)
  app.delegate = delegate
  app.run()
} catch {
  let app = NSApplication.shared
  app.setActivationPolicy(.regular)
  let alert = NSAlert()
  alert.messageText = "Cursor profile launcher failed"
  alert.informativeText = error.localizedDescription
  alert.runModal()
}
