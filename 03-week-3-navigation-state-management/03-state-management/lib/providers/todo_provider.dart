import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  Todo(this.title, {this.done = false});
  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done);
}

class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  void add(String title) => state = [...state, Todo(title)];

  void toggle(int index) {
    final todos = [...state];
    todos[index] = todos[index].copyWith(done: !todos[index].done);
    state = todos;
  }

  // Mengubah status tugas berdasarkan objek yang dipilih dari daftar filter.
  void toggleTodo(Todo todo) => toggle(state.indexOf(todo));

  void remove(int index) => state = [...state]..removeAt(index);

  // Menghapus tugas berdasarkan objek yang dipilih dari daftar filter.
  void removeTodo(Todo todo) => remove(state.indexOf(todo));
}

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

// Membaca daftar utama dan mengambil hanya tugas yang belum selesai
final incompleteTodosProvider = Provider<List<Todo>>((ref) {
  // watch membuat provider ini diperbarui saat daftar tugas berubah
  final todos = ref.watch(todoListProvider);
  // where menyaring tugas dengan status done=false, lalu toList membuat daftar baru
  return todos.where((todo) => !todo.done).toList();
});