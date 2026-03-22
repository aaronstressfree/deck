import SwiftUI

/// A simple to-do list panel in the sidebar.
struct TodoListView: View {
    @Environment(\.deckTheme) private var theme
    @Binding var todos: [TodoItem]

    @State private var newTodoText = ""
    @State private var isAdding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Text("TO-DO")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.text.secondary.swiftUIColor)

                Spacer()

                let completed = todos.filter(\.isCompleted).count
                if !todos.isEmpty {
                    Text("\(completed)/\(todos.count)")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.text.quaternary.swiftUIColor)
                }

                Button(action: { isAdding = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.text.tertiary.swiftUIColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.top, 4)

            // Todo items
            ForEach(todos) { todo in
                todoRow(todo)
            }

            // New todo input
            if isAdding {
                HStack(spacing: 6) {
                    Image(systemName: "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.text.quaternary.swiftUIColor)

                    TextField("New task...", text: $newTodoText, onCommit: addTodo)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.text.primary.swiftUIColor)
                        .onExitCommand {
                            isAdding = false
                            newTodoText = ""
                        }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
            }

            if todos.isEmpty && !isAdding {
                Text("No tasks yet")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.text.quaternary.swiftUIColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
            }
        }
    }

    private func todoRow(_ todo: TodoItem) -> some View {
        HStack(spacing: 6) {
            Button(action: { toggleTodo(todo.id) }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        todo.isCompleted
                            ? theme.status.success.primary.swiftUIColor
                            : theme.text.quaternary.swiftUIColor
                    )
            }
            .buttonStyle(.plain)

            Text(todo.text)
                .font(.system(size: 14))
                .foregroundStyle(
                    todo.isCompleted
                        ? theme.text.quaternary.swiftUIColor
                        : theme.text.primary.swiftUIColor
                )
                .strikethrough(todo.isCompleted)
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .contextMenu {
            Button("Delete", role: .destructive) {
                todos.removeAll(where: { $0.id == todo.id })
            }
        }
    }

    private func addTodo() {
        guard !newTodoText.isEmpty else {
            isAdding = false
            return
        }
        todos.append(TodoItem(text: newTodoText))
        newTodoText = ""
        isAdding = false
    }

    private func toggleTodo(_ id: UUID) {
        if let index = todos.firstIndex(where: { $0.id == id }) {
            todos[index].isCompleted.toggle()
        }
    }
}
