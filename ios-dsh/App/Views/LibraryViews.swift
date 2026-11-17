import SwiftUI
import Foundation

struct WorkspacesView: View {
    @EnvironmentObject private var demo: DemoStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(demo.workspaces) { workspace in
                        card(workspace)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ink.ignoresSafeArea())
            .navigationTitle("工作区")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func card(_ workspace: Workspace) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ArtworkView(
                index: workspace.artworkIndex,
                initial: String(workspace.name.prefix(1)),
                cornerRadius: 18
            )
            .frame(height: 200)

            HStack(spacing: 6) {
                Text(workspace.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if workspace.running > 0 {
                    StatusDot()
                }
                Spacer(minLength: 0)
            }

            Text(workspace.path)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)

            Text("\(workspace.total) 个会话")
                .font(.system(size: 11))
                .foregroundStyle(Theme.dim)
        }
    }
}

struct ScheduleView: View {
    @EnvironmentObject private var demo: DemoStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(demo.schedules) { item in
                        row(item)
                    }

                    if demo.schedules.isEmpty {
                        EmptyHint(text: "还没有定时任务。")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ink.ignoresSafeArea())
            .navigationTitle("定时")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func row(_ item: ScheduleItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "clock")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(item.enabled ? Theme.mint : Color.white.opacity(0.5))
                .frame(width: 36, height: 36)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text("\(item.cadence) · 下次 \(nextText(item.nextRun))")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: .constant(item.enabled))
                .labelsHidden()
                .tint(Theme.mint)
                .disabled(true)
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func nextText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}
