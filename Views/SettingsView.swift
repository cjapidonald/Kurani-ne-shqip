import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    @State private var toastVisible = false
    @State private var showingResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedStringKey("settings.account"))) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStringKey("settings.account.offline"))
                            .foregroundColor(.kuraniTextSecondary)
                    }
                    .appleCard()
                    .padding(.horizontal, 12)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section(header: Text(LocalizedStringKey("settings.notifications.title"))) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(
                                isOn: Binding(
                                    get: { viewModel.readingReminderEnabled },
                                    set: { viewModel.setReadingReminderEnabled($0) }
                                )
                            ) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStringKey("settings.notifications.readingReminder"))
                                        .foregroundColor(.kuraniTextPrimary)
                                    Text(LocalizedStringKey("settings.notifications.readingReminderDescription"))
                                        .font(.footnote)
                                        .foregroundColor(.kuraniTextSecondary)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color.kuraniAccentLight))

                            if viewModel.readingReminderEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(LocalizedStringKey("settings.notifications.timeLabel"))
                                        .font(.footnote)
                                        .foregroundColor(.kuraniTextSecondary)

                                    DatePicker(
                                        "",
                                        selection: Binding(
                                            get: { viewModel.readingReminderTime },
                                            set: { viewModel.updateReadingReminderTime($0) }
                                        ),
                                        displayedComponents: .hourAndMinute
                                    )
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                }
                            }
                        }

                        Divider()

                        Toggle(
                            isOn: Binding(
                                get: { viewModel.verseOfDayEnabled },
                                set: { viewModel.setVerseOfDayEnabled($0) }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(LocalizedStringKey("settings.notifications.verseOfDay"))
                                    .foregroundColor(.kuraniTextPrimary)
                                Text(LocalizedStringKey("settings.notifications.verseOfDayDescription"))
                                    .font(.footnote)
                                    .foregroundColor(.kuraniTextSecondary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Color.kuraniAccentLight))
                    }
                    .appleCard()
                    .padding(.horizontal, 12)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section(header: Text(LocalizedStringKey("settings.progress.title"))) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStringKey("settings.progress.description"))
                            .foregroundColor(.kuraniTextSecondary)

                        Button(role: .destructive) {
                            showingResetConfirmation = true
                        } label: {
                            Text(LocalizedStringKey("settings.progress.reset"))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GradientButtonStyle())
                    }
                    .appleCard()
                    .padding(.horizontal, 12)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section(header: Text(LocalizedStringKey("settings.about"))) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey("settings.about.disclaimer"))
                            .foregroundColor(.kuraniTextSecondary)
                        HStack {
                            Text(LocalizedStringKey("settings.version"))
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundColor(.kuraniTextSecondary)
                        }
                    }
                    .appleCard()
                    .padding(.horizontal, 12)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .listRowSeparator(.hidden)
            .background(KuraniTheme.background.ignoresSafeArea())
            .tint(Color.kuraniAccentLight)
            .navigationTitle(LocalizedStringKey("settings.title"))
            .toolbarBackground(Color.kuraniDarkBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .overlay(alignment: .bottom) {
                if toastVisible, let message = viewModel.toast {
                    ToastView(message: message)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .confirmationDialog(LocalizedStringKey("settings.progress.resetConfirm"), isPresented: $showingResetConfirmation, titleVisibility: .visible) {
                Button(LocalizedStringKey("action.cancel"), role: .cancel) {}
                Button(LocalizedStringKey("settings.progress.resetConfirmButton"), role: .destructive) {
                    viewModel.resetReadingProgress()
                }
            }
            .onChange(of: viewModel.toast) { _, newValue in
                guard newValue != nil else { return }
                withAnimation { toastVisible = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { toastVisible = false }
                    viewModel.toast = nil
                }
            }
        }
        .background(KuraniTheme.background.ignoresSafeArea())
    }
}
