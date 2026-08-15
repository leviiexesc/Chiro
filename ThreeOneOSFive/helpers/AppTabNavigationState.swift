struct AppTabNavigationState: Equatable {
    static let filesTab = 1

    private(set) var selectedTab: Int
    private(set) var filesNavigationRevision = 0

    init(selectedTab: Int = 0) {
        self.selectedTab = selectedTab
    }

    mutating func select(_ tab: Int) {
        guard tab != selectedTab else { return }

        if selectedTab == Self.filesTab {
            filesNavigationRevision &+= 1
        }
        selectedTab = tab
    }
}
