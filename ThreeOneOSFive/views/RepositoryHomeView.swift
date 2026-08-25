import SwiftUI

struct RepositoryHomeView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    @State private var feed: [RepositoryPackageRecord] = []

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    if feed.isEmpty {
                        emptyContent
                    } else {
                        featuredFeed
                        recentPackages
                    }

                }
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppTheme.contentCardInset)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .refreshable {
                await store.refreshAllAndWait()
                rebuildFeed()
            }
            .navigationTitle("3105")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppUtilityToolbar(
                    language: language,
                    onOpenSettings: onOpenSettings,
                    onOpenLogs: onOpenLogs
                )
            }
            .navigationDestination(for: RepositoryPackageRecord.self) { record in
                RepositoryPackageDetailView(record: record)
            }
            .onAppear {
                store.refreshAllIfNeeded()
                if feed.isEmpty {
                    rebuildFeed()
                }
            }
            .onChange(of: store.packages) { _ in
                rebuildFeed()
            }
        }
    }

    private var emptyContent: some View {
        marketplaceEmpty(
            systemImage: store.sources.isEmpty
                ? "shippingbox.and.arrow.backward"
                : "shippingbox",
            titleKey: store.sources.isEmpty
                ? "repository.no_sources_title"
                : "repository.no_packages_title",
            messageKey: store.sources.isEmpty
                ? "repository.home_no_sources_message"
                : "repository.no_packages_message"
        )
    }

    private var featuredFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("repository.for_you")

            LazyVStack(spacing: 12) {
                ForEach(Array(feed.prefix(featuredPackageCount))) { record in
                    NavigationLink(value: record) {
                        RepositoryFeedCard(record: record)
                    }
                    .buttonStyle(RepositoryCardButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var recentPackages: some View {
        let remaining = Array(feed.dropFirst(featuredPackageCount))
        if !remaining.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("repository.more_patches")

                VStack(spacing: 0) {
                    ForEach(
                        Array(remaining.enumerated()),
                        id: \.element.id
                    ) { index, record in
                        NavigationLink(value: record) {
                            HStack(spacing: 12) {
                                RepositoryPackageRow(record: record)
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                            .padding(.horizontal, AppTheme.contentCardPadding)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(RepositoryCardButtonStyle())

                        if index < remaining.count - 1 {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(
                    Color(uiColor: .systemBackground),
                    in: RoundedRectangle(
                        cornerRadius: AppTheme.contentCardCornerRadius,
                        style: .continuous
                    )
                )
                .overlay {
                    AppCardBorder()
                }
            }
        }
    }

    private func sectionHeader(_ key: String) -> some View {
        Text(language.text(key))
            .font(.title3.weight(.bold))
            .foregroundStyle(.primary)
            .textCase(nil)
    }

    private func marketplaceEmpty(
        systemImage: String,
        titleKey: String,
        messageKey: String
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: AppTheme.emptyIconSize, weight: .light))
                .foregroundStyle(AppTheme.accent)
            Text(language.text(titleKey))
                .font(.headline)
            Text(language.text(messageKey))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 48)
        .background(
            Color(uiColor: .systemBackground),
            in: RoundedRectangle(
                cornerRadius: AppTheme.contentCardCornerRadius,
                style: .continuous
            )
        )
        .overlay {
            AppCardBorder()
        }
    }

    private func rebuildFeed() {
        feed = PackageRepositoryFeedPolicy.home(store.packages)
    }

    private var featuredPackageCount: Int {
        min(feed.count, 3)
    }
}

struct RepositoryNewView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    @State private var packages: [RepositoryPackageRecord] = []
    @State private var showSimulatedPackageDetail = false
    @State private var simulatedPackageDetailGate = OneShotPresentationGate()

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if packages.isEmpty {
                    Section {
                        emptyState
                    }
                } else {
                    Section {
                        ForEach(packages) { record in
                            NavigationLink(value: record) {
                                RepositoryNewPackageRow(record: record)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(language.text("tab.new"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppUtilityToolbar(
                    language: language,
                    onOpenSettings: onOpenSettings,
                    onOpenLogs: onOpenLogs
                )
            }
            .navigationDestination(for: RepositoryPackageRecord.self) { record in
                RepositoryPackageDetailView(record: record)
            }
            .navigationDestination(isPresented: $showSimulatedPackageDetail) {
                if let record = packages.first {
                    RepositoryPackageDetailView(record: record)
                }
            }
            .refreshable {
                await store.refreshAllAndWait()
                rebuildPackages()
            }
            .onAppear {
                store.refreshAllIfNeeded()
                rebuildPackages()
                openSimulatedPackageDetailIfNeeded()
            }
            .onChange(of: store.packages) { _ in
                rebuildPackages()
                openSimulatedPackageDetailIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if store.isRefreshing && !store.sources.isEmpty {
            HStack(spacing: 10) {
                ProgressView()
                Text(language.text("repository.refreshing"))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        } else {
            VStack(spacing: 12) {
                Image(systemName: store.sources.isEmpty ? "shippingbox" : "clock")
                    .font(.system(size: AppTheme.emptyIconSize, weight: .light))
                    .foregroundStyle(AppTheme.accent)
                Text(language.text(
                    store.sources.isEmpty
                        ? "repository.no_sources_title"
                        : "repository.new_empty_title"
                ))
                .font(.headline)
                Text(language.text(
                    store.sources.isEmpty
                        ? "repository.no_sources_message"
                        : "repository.new_empty_message"
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
        }
    }

    private func rebuildPackages() {
        packages = PackageRepositoryFeedPolicy.newest(store.packages)
    }

    private func openSimulatedPackageDetailIfNeeded() {
#if targetEnvironment(simulator)
        guard ProcessInfo.processInfo.arguments.contains(
            "--simulate-package-detail"
        ), !packages.isEmpty, simulatedPackageDetailGate.claim() else {
            return
        }
        DispatchQueue.main.async {
            showSimulatedPackageDetail = true
        }
#endif
    }
}

struct RepositorySearchView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    @State private var searchText = ""

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [RepositoryPackageRecord] {
        guard !query.isEmpty else { return [] }
        return store.packages.filter { record in
            let package = record.package
            return package.name.localizedCaseInsensitiveContains(query)
                || package.author.localizedCaseInsensitiveContains(query)
                || package.summary.localizedCaseInsensitiveContains(query)
                || package.identifier.localizedCaseInsensitiveContains(query)
                || record.sourceName.localizedCaseInsensitiveContains(query)
                || (package.category?.localizedCaseInsensitiveContains(query) ?? false)
                || package.tags.contains {
                    $0.localizedCaseInsensitiveContains(query)
                }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppSearchField(
                    text: $searchText,
                    prompt: language.text("repository.search_prompt"),
                    clearLabel: language.text("common.clear")
                )
                Divider()
                List {
                    if query.isEmpty {
                        searchPrompt
                            .listRowSeparator(.hidden)
                    } else if results.isEmpty {
                        searchEmpty
                            .listRowSeparator(.hidden)
                    } else {
                        Section(language.text(
                            "repository.search_results",
                            Int64(results.count)
                        )) {
                            ForEach(results) { record in
                                NavigationLink(value: record) {
                                    RepositoryPackageRow(record: record)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    await store.refreshAllAndWait()
                }
            }
            .navigationTitle(language.text("repository.search"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppUtilityToolbar(
                    language: language,
                    onOpenSettings: onOpenSettings,
                    onOpenLogs: onOpenLogs
                )
            }
            .navigationDestination(for: RepositoryPackageRecord.self) { record in
                RepositoryPackageDetailView(record: record)
            }
            .onAppear {
                store.refreshAllIfNeeded()
            }
        }
    }

    private var searchPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: AppTheme.emptyIconSize, weight: .light))
                .foregroundStyle(AppTheme.accent)
            Text(language.text("repository.search_title"))
                .font(.headline)
            Text(language.text("repository.search_message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }

    private var searchEmpty: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: AppTheme.emptyIconSize, weight: .light))
                .foregroundStyle(.secondary)
            Text(language.text("repository.search_empty"))
                .font(.headline)
            Text(language.text("repository.search_empty_message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }
}

private struct RepositoryFeedCard: View {
    @Environment(\.appLanguage) private var language
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let record: RepositoryPackageRecord

    var body: some View {
        Group {
            if dynamicTypeSize >= .xxLarge {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 14) {
                        RepositoryPackageIcon(
                            package: record.package,
                            size: 60
                        )
                        Text(record.package.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        disclosureIndicator
                    }

                    Text(record.package.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    packageMeta
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(alignment: .center, spacing: 14) {
                    RepositoryPackageIcon(package: record.package, size: 60)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(record.package.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Text(record.package.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        packageMeta
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)
                    disclosureIndicator
                }
            }
        }
        .padding(AppTheme.contentCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .systemBackground),
            in: RoundedRectangle(
                cornerRadius: AppTheme.contentCardCornerRadius,
                style: .continuous
            )
        )
        .overlay {
            AppCardBorder()
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var packageMeta: some View {
        Text(language.text(
            "repository.home_package_meta",
            record.package.author,
            record.sourceName
        ))
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var disclosureIndicator: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

private struct RepositoryCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private struct RepositoryNewPackageRow: View {
    @Environment(\.appLanguage) private var language
    let record: RepositoryPackageRecord

    var body: some View {
        HStack(spacing: 12) {
            RepositoryPackageIcon(package: record.package, size: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(record.package.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(language.text(
                    "repository.home_package_meta",
                    record.package.author,
                    record.sourceName
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let publishedAt = record.package.publishedAt {
                Text(
                    publishedAt,
                    format: .dateTime.day().month(.abbreviated)
                )
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}
