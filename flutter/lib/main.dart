import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StateNotifierProvider<TaskNotifier, TaskState>(
        create: (_) => TaskNotifier(),
        child: TaskListView(),
      ),
    );
  }
}

@immutable
class Task {
  Task({
    this.id,
    this.title,
    this.content,
  });

  final int id;
  final String title;
  final String content;

  Task copyWith({
    int id,
    String title,
    String content,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
    };
  }
}

@immutable
class TaskState {
  TaskState({
    this.selectedTask,
    this.taskList,
  });

  factory TaskState.initialize() {
    return TaskState(
      taskList: [],
    );
  }

  final Task selectedTask;
  final List<Task> taskList;

  TaskState copyWith({
    Task selectedTask,
    List<Task> todoList,
  }) {
    return TaskState(
      selectedTask: selectedTask ?? this.selectedTask,
      taskList: todoList ?? this.taskList,
    );
  }
}

class NewTaskNotifier extends StateNotifier<Task> {
  NewTaskNotifier() : super(Task());

  void handleTitleChange(String title) {
    state = state.copyWith(title: title);
  }

  void handleContentChange(String content) {
    state = state.copyWith(content: content);
  }

  Future<Task> enterTask() async {
    final response = await http.post(
      "http://localhost:8080/tasks",
      body: json.encode(state.toJson()),
    );
    final body = json.decode(response.body);
    return Task.fromJson(body);
  }
}

class TaskNotifier extends StateNotifier<TaskState> {
  TaskNotifier() : super(TaskState.initialize()) {
    fetchTask();
  }

  Future<void> fetchTask() async {
    final response = await http.get("http://localhost:8080/tasks");
    final body = json.decode(response.body);
    final list = body['task_list'] as List<dynamic>;
    final tasks = list?.map((json) {
      return Task.fromJson(json);
    })?.toList();

    state = state.copyWith(todoList: tasks ?? []);
  }

  void add(Task task) {
    final id = state.taskList.length + 1;
    final newList = [...state.taskList, task.copyWith(id: id)];
    state = state.copyWith(
      todoList: newList,
    );
  }

  void select(int id) {
    final selected = state.taskList.firstWhere(
      (element) => element.id == id,
      orElse: null,
    );
    state = state.copyWith(selectedTask: selected);
  }

  // TODO: Can't copy text
  Future<void> showAddTaskDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AddTaskDialog(
          onTapTask: add,
        );
      },
    );
  }
}

class AddTaskDialog extends StatelessWidget {
  AddTaskDialog({
    this.onTapTask,
  });

  final ValueChanged<Task> onTapTask;

  @override
  Widget build(BuildContext context) {
    return StateNotifierProvider<NewTaskNotifier, Task>(
      create: (_) => NewTaskNotifier(),
      child: Builder(
        builder: (context) {
          return AlertDialog(
            content: IntrinsicHeight(
              child: SizedBox(
                width: 500,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (title) => context
                          .read<NewTaskNotifier>()
                          .handleTitleChange(title),
                      decoration: InputDecoration(labelText: 'title'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      onChanged: (content) => context
                          .read<NewTaskNotifier>()
                          .handleContentChange(content),
                      decoration: InputDecoration(
                        labelText: 'content',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              FlatButton(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('キャンセル'),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              FlatButton(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('登録'),
                ),
                onPressed: () async {
                  final task =
                      await context.read<NewTaskNotifier>().enterTask();
                  onTapTask(task);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class TaskListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TASK'),
        centerTitle: false,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: context.select<TaskState, ListView>(
              (state) => ListView.builder(
                itemCount: state.taskList.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(state.taskList[index].title),
                  subtitle: Text(state.taskList[index].content),
                  onTap: () => context
                      .read<TaskNotifier>()
                      .select(state.taskList[index].id),
                ),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: 1,
            child: ColoredBox(
              color: Colors.grey,
            ),
          ),
          Expanded(
            flex: 5,
            child: context.select<TaskState, Widget>((state) {
              if (state.selectedTask == null) {
                return SizedBox();
              }
              return Column(
                children: [
                  Text(state.selectedTask.id.toString()),
                  Text(state.selectedTask.title),
                  Text(state.selectedTask.content),
                ],
              );
            }),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.read<TaskNotifier>().showAddTaskDialog(context),
      ),
    );
  }
}
