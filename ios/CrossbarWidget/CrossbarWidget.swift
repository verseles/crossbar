import WidgetKit
import SwiftUI

// MARK: - Widget Data Model

struct CrossbarPluginData: Identifiable {
    let id: String
    let icon: String
    let text: String
    let title: String
    let color: String?
    let tooltip: String?
    
    static func from(dictionary: [String: Any]) -> CrossbarPluginData? {
        guard let pluginId = dictionary["pluginId"] as? String else { return nil }
        return CrossbarPluginData(
            id: pluginId,
            icon: dictionary["icon"] as? String ?? "📊",
            text: dictionary["text"] as? String ?? "--",
            title: (dictionary["pluginId"] as? String)?.components(separatedBy: ".").first?.capitalized ?? "Plugin",
            color: dictionary["color"] as? String,
            tooltip: dictionary["tooltip"] as? String
        )
    }
}

// MARK: - Timeline Provider

struct CrossbarProvider: TimelineProvider {
    typealias Entry = CrossbarEntry
    
    /// App Group ID - must match the Flutter app
    static let appGroupId = "group.crossbar.widgets"
    
    func placeholder(in context: Context) -> CrossbarEntry {
        CrossbarEntry(date: Date(), plugins: [
            CrossbarPluginData(id: "cpu", icon: "⚡", text: "45%", title: "CPU", color: nil, tooltip: nil)
        ])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CrossbarEntry) -> Void) {
        let plugins = loadPlugins()
        completion(CrossbarEntry(date: Date(), plugins: plugins))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CrossbarEntry>) -> Void) {
        let plugins = loadPlugins()
        let entry = CrossbarEntry(date: Date(), plugins: plugins)
        
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadPlugins() -> [CrossbarPluginData] {
        guard let userDefaults = UserDefaults(suiteName: CrossbarProvider.appGroupId) else {
            return []
        }
        
        // Get list of plugin IDs
        guard let pluginIdsJson = userDefaults.string(forKey: "plugin_ids"),
              let pluginIdsData = pluginIdsJson.data(using: .utf8),
              let pluginIds = try? JSONSerialization.jsonObject(with: pluginIdsData) as? [String] else {
            return []
        }
        
        // Load data for each plugin
        var plugins: [CrossbarPluginData] = []
        for pluginId in pluginIds {
            if let pluginJson = userDefaults.string(forKey: "plugin_\(pluginId)"),
               let pluginData = pluginJson.data(using: .utf8),
               let pluginDict = try? JSONSerialization.jsonObject(with: pluginData) as? [String: Any],
               let plugin = CrossbarPluginData.from(dictionary: pluginDict) {
                plugins.append(plugin)
            }
        }
        
        return plugins
    }
}

// MARK: - Timeline Entry

struct CrossbarEntry: TimelineEntry {
    let date: Date
    let plugins: [CrossbarPluginData]
}

// MARK: - Widget Views

struct CrossbarWidgetSmallView: View {
    let entry: CrossbarEntry
    
    var body: some View {
        if let plugin = entry.plugins.first {
            VStack(spacing: 4) {
                Text(plugin.icon)
                    .font(.title)
                Text(plugin.text)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding()
        } else {
            VStack(spacing: 4) {
                Text("📊")
                    .font(.title)
                Text("--")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct CrossbarWidgetMediumView: View {
    let entry: CrossbarEntry
    
    var body: some View {
        HStack(spacing: 12) {
            if let plugin = entry.plugins.first {
                Text(plugin.icon)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(plugin.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(plugin.text)
                        .font(.title2)
                        .fontWeight(.bold)
                    if let tooltip = plugin.tooltip, !tooltip.isEmpty {
                        Text(tooltip)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            } else {
                Text("📊")
                    .font(.largeTitle)
                
                VStack(alignment: .leading) {
                    Text("Crossbar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("--")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Widget Configuration

@main
struct CrossbarWidget: Widget {
    let kind: String = "CrossbarWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CrossbarProvider()) { entry in
            CrossbarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Crossbar Plugin")
        .description("Display plugin output on your home screen")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CrossbarWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CrossbarEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            CrossbarWidgetSmallView(entry: entry)
        case .systemMedium:
            CrossbarWidgetMediumView(entry: entry)
        default:
            CrossbarWidgetMediumView(entry: entry)
        }
    }
}

// MARK: - Preview

struct CrossbarWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntry = CrossbarEntry(date: Date(), plugins: [
            CrossbarPluginData(id: "cpu.10s.sh", icon: "⚡", text: "45%", title: "CPU", color: nil, tooltip: "Current usage")
        ])
        
        CrossbarWidgetEntryView(entry: sampleEntry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        CrossbarWidgetEntryView(entry: sampleEntry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
