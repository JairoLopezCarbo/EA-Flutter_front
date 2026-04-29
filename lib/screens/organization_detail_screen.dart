import 'package:flutter/material.dart';
import '../models/organization.dart';
import '../models/task.dart';
import '../services/organization_service.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final Organization organization;

  const OrganizationDetailScreen({super.key, required this.organization});

  @override
  State<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  static const List<String> _taskStates = <String>['to do', 'in progress', 'done'];

  final OrganizationService _organizationService = OrganizationService();
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _organizationService.fetchTasksByOrganization(
      widget.organization.id,
    );
  }

  void _reloadTasks() {
    setState(() {
      _tasksFuture = _organizationService.fetchTasksByOrganization(
        widget.organization.id,
      );
    });
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  String _stateLabel(String state) {
    switch (state) {
      case 'in progress':
        return 'In progress';
      case 'done':
        return 'Done';
      case 'to do':
      default:
        return 'To do';
    }
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'in progress':
        return const Color(0xFFF59E0B);
      case 'done':
        return const Color(0xFF10B981);
      case 'to do':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Map<String, List<Task>> _groupTasksByState(List<Task> tasks) {
    final Map<String, List<Task>> grouped = <String, List<Task>>{
      for (final String state in _taskStates) state: <Task>[],
    };

    for (final Task task in tasks) {
      grouped.putIfAbsent(task.estado, () => <Task>[]).add(task);
    }

    return grouped;
  }

  Future<void> _changeTaskState(Task task, String newState) async {
    if (task.estado == newState) {
      return;
    }

    try {
      await _organizationService.updateTaskState(
        organizacionId: widget.organization.id,
        tareaId: task.id,
        estado: newState,
      );
      _reloadTasks();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar el estado: $e')),
      );
    }
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => TaskDetailScreen(task: task),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: task.estado,
                      isDense: true,
                      items: _taskStates
                          .map(
                            (String state) => DropdownMenuItem<String>(
                              value: state,
                              child: Text(_stateLabel(state)),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          _changeTaskState(task, value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Inicio: ${_formatDate(task.fechaInicio)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Fin: ${_formatDate(task.fechaFin)}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _stateColor(task.estado).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _stateLabel(task.estado),
                  style: TextStyle(
                    color: _stateColor(task.estado),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusColumn({
    required String state,
    required List<Task> tasks,
    required double height,
  }) {
    return SizedBox(
      width: 320,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _stateColor(state).withOpacity(0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _stateLabel(state),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _stateColor(state),
                  ),
                ),
                Chip(
                  label: Text('${tasks.length}'),
                  backgroundColor: _stateColor(state).withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: _stateColor(state),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'No hay tareas',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Task task = tasks[index];
                      return _buildTaskCard(task);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light premium background
      appBar: AppBar(
        title: Text(widget.organization.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.business, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.organization.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.organization.id}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'No se pudieron cargar las tareas. ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final List<Task> tasks = snapshot.data ?? <Task>[];
                final Map<String, List<Task>> groupedTasks = _groupTasksByState(tasks);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tablero de tareas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          Chip(
                            label: Text('${tasks.length} tareas'),
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStatusColumn(
                                    state: 'to do',
                                    tasks: groupedTasks['to do'] ?? <Task>[],
                                    height: constraints.maxHeight,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatusColumn(
                                    state: 'in progress',
                                    tasks: groupedTasks['in progress'] ?? <Task>[],
                                    height: constraints.maxHeight,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatusColumn(
                                    state: 'done',
                                    tasks: groupedTasks['done'] ?? <Task>[],
                                    height: constraints.maxHeight,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildCreateButton(context),
        ],
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final bool? created = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (BuildContext context) => CreateTaskScreen(
                  organizacionId: widget.organization.id,
                  usuarios: widget.organization.usuarios,
                ),
              ),
            );

            if (created == true) {
              _reloadTasks();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_task),
              SizedBox(width: 10),
              Text(
                'Crear tarea',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
