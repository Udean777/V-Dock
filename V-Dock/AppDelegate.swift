import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        NotificationManager.shared.requestPermission()
        
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        
        NSApp.mainMenu = mainMenu
        
        UserDefaults.standard.set(true, forKey: "ApplePersistenceIgnoreState")
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        UserDefaults.standard.set(false, forKey: "shouldTerminate")
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let commandDown = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command)
            if commandDown, let chars = event.charactersIgnoringModifiers {
                if chars == "q" {
                    NSApplication.shared.terminate(nil)
                    return nil
                } else if chars == "w" {
                    NSApp.keyWindow?.close()
                    return nil
                } else if chars == "," {
                    NotificationCenter.default.post(name: Notification.Name("OpenSettings"), object: nil)
                    return nil
                }
            }
            return event
        }
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // If they click the Quit button in the menu bar, quit the whole app.
        if UserDefaults.standard.bool(forKey: "shouldTerminate") {
            return .terminateNow
        }
        
        // If Cmd+Q is pressed, close the Dashboard and Settings windows.
        // The willCloseNotification observer will detect this and automatically
        // switch the app back to .accessory mode (hiding the Dock icon).
        for window in NSApp.windows {
            // Note: SwiftUI's .navigationTitle("Devices") renames the "Dashboard" window!
            if window.title == "Dashboard" || window.title == "Devices" || window.title == "Settings" || window.title.hasPrefix("Logcat: ") {
                window.close()
            }
        }
        
        return .terminateCancel
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }
    
    func applicationSupportsRestorableState(_ app: NSApplication) -> Bool {
        return false
    }
}

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
