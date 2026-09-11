import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @AppStorage(FeatureVisibility.developerModeStorageKey)
    private var developerModeEnabled = false
    @State private var tabNavigation: AppTabNavigationState
    @State private var compactTab: CompactTab = .home
    @State private var showSettings = false
    @State private var showLogs = false

    init() {
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: Int
        if arguments.contains("--simulate-new-tab") {
            initialTab = 1
        } else if arguments.contains("--simulate-sources-tab") {
            initialTab = 2
        } else if arguments.contains("--simulate-installed-tab")
                    || arguments.contains("--simulate-patch-tab")
                    || arguments.contains("--simulate-wallpaper-tab") {
            initialTab = 3
        } else if arguments.contains("--simulate-files-tab") {
            initialTab = 4
        } else if arguments.contains("--simulate-search-tab") {
            initialTab = 5
        } else {
            initialTab = 0
        }
        _tabNavigation = State(initialValue: AppTabNavigationState(selectedTab: initialTab))
        _showSettings = State(
            initialValue: arguments.contains("--simulate-settings")
        )
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
#endif
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .tint(AppTheme.accent)
        .imageScale(.small)
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil {
                tabNavigation.select(AppSection.installed.rawValue)
                compactTab = .patches
            }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { requestID in
            if requestID != nil {
                tabNavigation.select(AppSection.installed.rawValue)
                compactTab = .patches
            }
        }
        .onChange(of: developerModeEnabled) { _ in
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
        .patchStorePresentation(patchStore)
        .repositoryStorePresentation(repositoryStore, patchStore: patchStore)
    }

    private var compactLayout: some View {
        ZStack(alignment: .bottom) {
            compactSectionContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            CompactFloatingTabBar(selection: $compactTab)
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .safeAreaPadding(.bottom, 72)
    }

    @ViewBuilder
    private var compactSectionContent: some View {
        switch compactTab {
        case .home:
            ChiroHomeView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        case .files:
            AppDataBrowserView(
                tabSession: filesTabSession,
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .patches:
            PatchProjectsView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        case .cleaner:
            CleanerView()
        case .wallpapers:
            WallpaperLabView(onOpenSettings: openSettings, onOpenLogs: openLogs)
        }
    }

    private enum CompactTab: CaseIterable, Hashable {
        case home, files, patches, cleaner, wallpapers

        var titleKey: String {
            switch self {
            case .home: return "tab.home"
            case .files: return "tab.files"
            case .patches: return "tab.patches"
            case .cleaner: return "tab.cleaner"
            case .wallpapers: return "tab.wallpapers"
            }
        }

        var systemImage: String {
            switch self {
            case .home: return "house.fill"
            case .files: return "folder.fill"
            case .patches: return "shippingbox.fill"
            case .cleaner: return "sparkles"
            case .wallpapers: return "photo.on.rectangle.angled"
            }
            }
        }
    }

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(featureVisibility.visibleSections) { section in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            tabNavigation.select(section.rawValue)
                        }
                    } label: {
                        Label(language.text(section.titleKey), systemImage: section.systemImage)
                            .fontWeight(section.rawValue == tabNavigation.selectedTab ? .semibold : .regular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        section.rawValue == tabNavigation.selectedTab
                            ? AppTheme.accent.opacity(0.14)
                            : Color.clear
                    )
                    .accessibilityAddTraits(
                        section.rawValue == tabNavigation.selectedTab ? .isSelected : []
                    )
                }
            }
            .navigationTitle("Chiro")
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 300)
        } detail: {
            sectionContent(selectedVisibleSection)
                .id(selectedVisibleSection.rawValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func sectionContent(_ section: AppSection) -> some View {
        switch section {
        case .home:
            RepositoryHomeView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .new:
            RepositoryNewView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .sources:
            RepositorySourcesView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .installed:
            PatchProjectsView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .files:
            AppDataBrowserView(
                tabSession: filesTabSession,
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        case .search:
            RepositorySearchView(
                onOpenSettings: openSettings,
                onOpenLogs: openLogs
            )
        }
    }

    private var tabSelection: Binding<Int> {
        Binding(
            get: { tabNavigation.selectedTab },
            set: { tabNavigation.select($0) }
        )
    }

    private var filesTabSession: Binding<FilesTabSession> {
        Binding(
            get: { tabNavigation.filesTabs },
            set: { tabNavigation.setFilesTabs($0) }
        )
    }

    private var featureVisibility: FeatureVisibility {
        FeatureVisibility(developerModeEnabled: developerModeActive)
    }

    private var developerModeActive: Bool {
#if targetEnvironment(simulator)
        developerModeEnabled
            || ProcessInfo.processInfo.arguments.contains("--simulate-developer-mode")
            || ProcessInfo.processInfo.arguments.contains("--simulate-files-tab")
#else
        developerModeEnabled
#endif
    }

    private var selectedVisibleSection: AppSection {
        let selected = AppSection(rawValue: tabNavigation.selectedTab)
        return selected.flatMap {
            featureVisibility.isVisible($0) ? $0 : nil
        } ?? .home
    }

    private func openSettings() {
        showSettings = true
    }

    private func openLogs() {
        showLogs = true
    }
}

private struct CompactFloatingTabBar: View {
    @Environment(\.appLanguage) private var language
    @Binding var selection: ContentView.CompactTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.CompactTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 24, weight: .semibold))
                            .frame(height: 28)
                        Text(language.text(tab.titleKey))
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selection == tab ? AppTheme.accent : .primary)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(
                        selection == tab
                            ? AppTheme.accent.opacity(0.10)
                            : Color.clear,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 18, y: 8)
    }
}

private struct ChiroHomeView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    homeSection(title: language.text("common.device")) {
                        homeRow(title: language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
                        Divider()
                        homeRow(title: language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                        Divider()
                        HStack {
                            Text(language.text("settings.compatibility"))
                            Spacer()
                            Label(
                                language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"),
                                systemImage: appState.isSupported ? "checkmark.circle.fill" : "xmark.circle.fill"
                            )
                            .foregroundStyle(appState.isSupported ? .green : .red)
                        }
                    }

                    Text(language.text("settings.supported_range_summary"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)

                    homeSection(title: language.text("dashboard.installation")) {
                        Label(language.text("dashboard.enterprise_signing"), systemImage: "checkmark.seal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .labelStyle(AlignedIconLabelStyle())
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 22)
                .padding(.bottom, 30)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Chiro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppUtilityToolbar(language: language, onOpenSettings: onOpenSettings, onOpenLogs: onOpenLogs)
            }
        }
    }

    private func homeSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.secondary)
            VStack(spacing: 0, content: content)
                .padding(.horizontal, 16)
                .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func homeRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(.secondary)
                .monospaced()
                .lineLimit(1)
        }
        .padding(.vertical, 17)
    }
}

private struct AlignedIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 18) {
            configuration.icon
                .foregroundStyle(AppTheme.accent)
            configuration.title
        }
    }
}

private struct CompactTabLabel: View {
    let title: String
    let systemImage: String

    @ViewBuilder
    var body: some View {
        if let image = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        )?.withRenderingMode(.alwaysTemplate) {
            Image(uiImage: image)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
        }
        Text(title)
    }
}

private extension AppSection {
    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .new: return "tab.new"
        case .sources: return "tab.sources"
        case .installed: return "tab.installed"
        case .files: return "tab.files"
        case .search: return "tab.search"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .new: return "clock.fill"
        case .sources: return "shippingbox.fill"
        case .installed: return "tray.full.fill"
        case .files: return "folder.fill"
        case .search: return "magnifyingglass"
        }
    }
}
