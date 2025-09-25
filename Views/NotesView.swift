import SwiftUI

struct NotesView: View {
    struct ReaderRoute: Hashable {
        let surah: Int
        let ayah: Int
    }

    @ObservedObject var viewModel: NotesViewModel
    let translationStore: TranslationStore

    @EnvironmentObject private var notesStore: NotesStore
    @EnvironmentObject private var authManager: AuthManager

    @State private var path: [ReaderRoute] = []
    @State private var showingSignInSheet = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if authManager.userId == nil {
                    VStack(spacing: 24) {
                        BrandHeader(titleKey: "notes.title", subtitle: "notes.signinRequired")
                        Button {
                            showingSignInSheet = true
                        } label: {
                            Text(LocalizedStringKey("action.signin"))
                                .frame(maxWidth: 200)
                        }
                        .buttonStyle(GradientButtonStyle())
                        Spacer()
                    }
                    .padding()
                } else if notesStore.isLoading {
                    VStack(spacing: 16) {
                        ProgressView(LocalizedStringKey("notes.loading"))
                            .progressViewStyle(.circular)
                            .tint(.accentBrand)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.sortedSurahNumbers.isEmpty {
                    VStack(spacing: 16) {
                        BrandHeader(titleKey: "notes.title", subtitle: "notes.empty")
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        Section {
                            BrandHeader(titleKey: "notes.title", subtitle: "notes.openReader")
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }

                        ForEach(viewModel.sortedSurahNumbers, id: \.self) { surahNumber in
                            Section(header: Text(sectionTitle(for: surahNumber))) {
                                ForEach(viewModel.notes(for: surahNumber)) { note in
                                    Button {
                                        path.append(ReaderRoute(surah: note.surah, ayah: note.ayah))
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(note.text)
                                                .font(.system(.body, design: .rounded))
                                                .foregroundColor(.textPrimary)
                                                .lineLimit(3)
                                            Text(String(format: NSLocalizedString("notes.lastUpdated", comment: "updated"), formatted(date: note.updatedAt)))
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundColor(.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .listRowBackground(Color.primarySurface)
                                }
                            }
                            .listRowBackground(Color.primarySurface)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.darkBackground)
                }
            }
            .background(Color.darkBackground.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("notes.title"))
            .sheet(isPresented: $showingSignInSheet) {
                SignInPromptView()
                    .environmentObject(authManager)
            }
            .navigationDestination(for: ReaderRoute.self) { route in
                ReaderView(
                    viewModel: ReaderViewModel(surahNumber: route.surah, translationStore: translationStore, notesStore: notesStore),
                    startingAyah: route.ayah,
                    openNotesTab: { path = [] }
                )
                .environmentObject(authManager)
            }
        }
    }

    private func sectionTitle(for surah: Int) -> String {
        String(format: NSLocalizedString("notes.section", comment: "section"), translationStore.title(for: surah))
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
