import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PromptStore

    @State private var searchText = ""
    @State private var expandedPromptIDs: Set<Prompt.ID> = []
    @State private var showAddPrompt = false
    @State private var showSearch = false
    @State private var copiedPromptID: Prompt.ID?

    private var filteredPrompts: [Prompt] {
        store.filteredPrompts(matching: searchText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if showSearch {
                TextField("Search prompts", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.black)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .foregroundStyle(.white)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if filteredPrompts.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPrompts) { prompt in
                            promptCard(prompt)
                        }
                    }
                    .padding(.bottom, 4)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(16)
        .frame(width: 430, height: 560)
        .background(Color.black)
        .sheet(isPresented: $showAddPrompt) {
            AddPromptView { title, content in
                store.addPrompt(title: title, content: content)
            }
        }
        .animation(.smooth(duration: 0.2), value: filteredPrompts)
        .animation(.smooth(duration: 0.2), value: expandedPromptIDs)
        .animation(.smooth(duration: 0.2), value: showSearch)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("PopPrompt")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            Spacer()

            headerIcon(systemName: "magnifyingglass", isActive: showSearch) {
                withAnimation {
                    showSearch.toggle()
                    if !showSearch {
                        searchText = ""
                    }
                }
            }

            headerIcon(systemName: "plus") {
                showAddPrompt = true
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))

            Text(searchText.isEmpty ? "No prompts yet" : "No matching prompts")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Text(searchText.isEmpty ? "Tap the plus button to save your first prompt." : "Try a different title or keyword.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)

            if searchText.isEmpty {
                Button("Add Prompt") {
                    showAddPrompt = true
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func headerIcon(systemName: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? .black : .white)
                .frame(width: 36, height: 36)
                .background(isActive ? Color.white : Color.white.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func promptCard(_ prompt: Prompt) -> some View {
        let isExpanded = expandedPromptIDs.contains(prompt.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(prompt.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer(minLength: 12)

                cardIcon(systemName: copiedPromptID == prompt.id ? "checkmark" : "doc.on.doc") {
                    copy(prompt)
                }

                cardIcon(systemName: "trash") {
                    expandedPromptIDs.remove(prompt.id)
                    store.deletePrompt(prompt)
                }

                cardIcon(systemName: "chevron.down", rotation: isExpanded ? 180 : 0) {
                    toggleExpansion(for: prompt.id)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    Text(prompt.content)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(prompt.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.white.opacity(0.03), radius: 2, x: 0, y: 0)
    }

    private func cardIcon(systemName: String, rotation: Double = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
                .rotationEffect(.degrees(rotation))
        }
        .buttonStyle(.plain)
    }

    private func toggleExpansion(for promptID: Prompt.ID) {
        if expandedPromptIDs.contains(promptID) {
            expandedPromptIDs.remove(promptID)
        } else {
            expandedPromptIDs.insert(promptID)
        }
    }

    private func copy(_ prompt: Prompt) {
        ClipboardManager.copy(prompt.content)
        copiedPromptID = prompt.id

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            if copiedPromptID == prompt.id {
                copiedPromptID = nil
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PromptStore())
}
