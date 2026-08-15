struct AppTabNavigationState: Equatable {
    private(set) var selectedTab: Int
    private(set) var filesNavigationPath: [FileBrowserDestination]

    init(
        selectedTab: Int = 0,
        filesNavigationPath: [FileBrowserDestination] = []
    ) {
        self.selectedTab = selectedTab
        self.filesNavigationPath = filesNavigationPath
    }

    mutating func select(_ tab: Int) {
        selectedTab = tab
    }

    mutating func setFilesNavigationPath(_ path: [FileBrowserDestination]) {
        filesNavigationPath = path
    }
}

struct FileBrowserDestination: Hashable {
    let containerPath: String
    let startPath: String
    let title: String
    let bundleID: String?
}
