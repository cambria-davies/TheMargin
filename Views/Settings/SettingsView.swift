import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    let csv: String

    init(csv: String) { self.csv = csv }

    init(configuration: ReadConfiguration) throws {
        csv = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: csv.data(using: .utf8) ?? Data())
    }
}

struct SettingsView: View {
    @Environment(\.marginTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Session.date, order: .reverse) private var allSessions: [Session]

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 9
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var reminderTime = Date.now
    @State private var exportDocument: CSVExportDocument?
    @State private var showExporter = false
    @State private var reminderErrorMessage: String?

    private var csvString: String {
        CSVExportService.generate(sessions: allSessions)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Reminder") {
                    Toggle("Enabled", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    let granted = await NotificationService.requestPermission()
                                    if granted {
                                        try? await NotificationService.scheduleDailyReminder(
                                            at: reminderHour, minute: reminderMinute
                                        )
                                    } else {
                                        reminderEnabled = false
                                        reminderErrorMessage = "Notifications are disabled for The Margin."
                                    }
                                }
                            } else {
                                NotificationService.cancelDailyReminder()
                            }
                        }

                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, newTime in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                reminderHour = components.hour ?? 9
                                reminderMinute = components.minute ?? 0
                                Task {
                                    try? await NotificationService.scheduleDailyReminder(
                                        at: reminderHour, minute: reminderMinute
                                    )
                                }
                            }
                    }
                }

                Section("Data") {
                    Button {
                        exportDocument = CSVExportDocument(csv: csvString)
                        showExporter = true
                    } label: {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(allSessions.isEmpty)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                let state = await NotificationService.currentReminderState()
                reminderEnabled = state.isScheduled
                reminderHour = state.hour ?? reminderHour
                reminderMinute = state.minute ?? reminderMinute
                reminderTime = Calendar.current.date(
                    from: DateComponents(hour: reminderHour, minute: reminderMinute)
                ) ?? reminderTime
            }
            .fileExporter(
                isPresented: $showExporter,
                document: exportDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "the-margin-export"
            ) { _ in
                exportDocument = nil
            }
            .alert("Reminder Unavailable", isPresented: Binding(
                get: { reminderErrorMessage != nil },
                set: { if !$0 { reminderErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(reminderErrorMessage ?? "Notification state is unavailable.")
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
