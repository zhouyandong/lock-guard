import Cocoa
import ServiceManagement

class StatusBarController: NSObject {

    private var statusItem: NSStatusItem!
    private var caffeinateProcess: Process?
    private var isActive: Bool = false
    private var pollTimer: Timer?
    private var wasLocked: Bool = false

    override init() {
        super.init()
        setupStatusBar()
        setupLockListeners()
        startCGSessionPolling()
        updateUI()
    }

    deinit {
        stopCaffeinate()
        pollTimer?.invalidate()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "LockGuard")
        }

        let menu = NSMenu()

        let statusTitle = NSMenuItem(title: "已就绪，锁屏后自动防休眠", action: nil, keyEquivalent: "")
        statusTitle.tag = 999
        menu.addItem(statusTitle)

        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(title: "开机自启动", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        loginItem.tag = 101
        if #available(macOS 13.0, *) {
            loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        } else {
            loginItem.isHidden = true
        }
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 LockGuard", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Lock Detection

    private func setupLockListeners() {
        let dc = DistributedNotificationCenter.default()
        dc.addObserver(self, selector: #selector(onScreenLockedNotification), name: NSNotification.Name("com.apple.screenIsLocked"), object: nil, suspensionBehavior: .deliverImmediately)
        dc.addObserver(self, selector: #selector(onScreenUnlockedNotification), name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, suspensionBehavior: .deliverImmediately)
    }

    private func startCGSessionPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkCGSessionLockState()
        }
    }

    private func checkCGSessionLockState() {
        let dict = CGSessionCopyCurrentDictionary() as? [String: Any]
        let currentlyLocked = (dict == nil)
        if currentlyLocked && !wasLocked {
            wasLocked = true
            onScreenLocked()
        } else if !currentlyLocked && wasLocked {
            wasLocked = false
            onScreenUnlocked()
        }
    }

    // MARK: - Event Handlers

    @objc private func onScreenLockedNotification() {
        onScreenLocked()
    }

    @objc private func onScreenUnlockedNotification() {
        onScreenUnlocked()
    }

    private func onScreenLocked() {
        startCaffeinate()
    }

    private func onScreenUnlocked() {
        stopCaffeinate()
    }

    // MARK: - Caffeinate

    private func startCaffeinate() {
        guard !isActive else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = ["-s", "-i"]
        do {
            try p.run()
            caffeinateProcess = p
            isActive = true
            updateUI()
        } catch {}
    }

    private func stopCaffeinate() {
        guard isActive, let p = caffeinateProcess else { return }
        p.terminate()
        caffeinateProcess = nil
        isActive = false
        updateUI()
    }

    // MARK: - Menu Actions

    @objc private func toggleLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
                if let item = statusItem.menu?.item(withTag: 101) {
                    item.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
                }
            } catch {}
        }
    }

    @objc private func quitApp() {
        stopCaffeinate()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - UI Update

    private func updateUI() {
        guard let button = statusItem.button, let menu = statusItem.menu else { return }

        let iconName = isActive ? "lock.shield.fill" : "lock.shield"
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)

        if let statusItem = menu.item(withTag: 999) {
            statusItem.title = isActive
                ? "防休眠中"
                : "已就绪，锁屏后自动防休眠"
        }
    }
}
