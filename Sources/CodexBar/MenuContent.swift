#if os(macOS)
import SwiftUI
import CodexBarCore

/// SwiftUI view showing provider usage details in a menu popover.
struct MenuCardView: View {
    let provider: UsageProvider
    let snapshot: UsageSnapshot?
    let errorMessage: String?
    let metadata: ProviderMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(metadata?.displayName ?? provider.rawValue.capitalized)
                    .font(.headline)
                Spacer()
                if let snapshot = snapshot, snapshot.isStale {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }

            if let error = errorMessage {
                Label(error, systemImage: "xmark.circle")
                    .foregroundStyle(.red)
                    .font(.caption)
            } else if let snapshot = snapshot {
                // Session window
                if let session = snapshot.sessionWindow {
                    UsageProgressBar(
                        label: session.label ?? "Session",
                        percentage: session.usedPercentage,
                        resetsAt: session.resetsAt,
                        remaining: session.remaining,
                        total: session.total
                    )
                }

                // Periodic window
                if let periodic = snapshot.periodicWindow {
                    UsageProgressBar(
                        label: periodic.label ?? "Periodic",
                        percentage: periodic.usedPercentage,
                        resetsAt: periodic.resetsAt,
                        remaining: periodic.remaining,
                        total: periodic.total
                    )
                }

                // Identity info
                if let identity = snapshot.identity {
                    HStack {
                        if let email = identity.email {
                            Text(email)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if let plan = identity.plan {
                            Text("(\(UsageFormatter.cleanPlanName(plan)))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            // Dashboard link
            if let url = metadata?.dashboardURL {
                Link("Open Dashboard", destination: url)
                    .font(.caption)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A progress bar component for usage display.
struct UsageProgressBar: View {
    let label: String
    let percentage: Double
    let resetsAt: Date?
    let remaining: Int?
    let total: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(UsageFormatter.usageLine(usedPercentage: percentage, showRemaining: true))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: max(0, geo.size.width * CGFloat(percentage)), height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                if let remaining = remaining, let total = total {
                    Text("\(remaining)/\(total) remaining")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if let resetsAt = resetsAt {
                    Text("Resets \(UsageFormatter.resetCountdownDescription(until: resetsAt))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var progressColor: Color {
        if percentage >= 0.9 {
            return .red
        } else if percentage >= 0.7 {
            return .orange
        } else {
            return .primary
        }
    }
}
#endif
