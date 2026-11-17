import SwiftUI

struct MainShell: View {
    @EnvironmentObject private var store: HostStore
    @EnvironmentObject private var demo: DemoStore

    @State private var tab: Tab = .home

    enum Tab: Hashable {
        case home
        case workspaces
        case schedule
        case settings
    }

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tabItem { Label("会话", systemImage: "play.rectangle.on.rectangle") }
                .tag(Tab.home)

            WorkspacesView()
                .tabItem { Label("工作区", systemImage: "square.grid.2x2") }
                .tag(Tab.workspaces)

            ScheduleView()
                .tabItem { Label("定时", systemImage: "clock") }
                .tag(Tab.schedule)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
        .background(Theme.ink.ignoresSafeArea())
    }
}
