import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlutoGrid Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PlutoGridExamplePage(),
    );
  }
}

/// PlutoGrid Example
//
/// For more examples, go to the demo web link on the github below.
class PlutoGridExamplePage extends StatefulWidget {
  const PlutoGridExamplePage({Key? key}) : super(key: key);

  @override
  State<PlutoGridExamplePage> createState() => _PlutoGridExamplePageState();
}

class _PlutoGridExamplePageState extends State<PlutoGridExamplePage> {
  final List<PlutoColumn> columns = <PlutoColumn>[
    PlutoColumn(
      title: 'header',
      field: 'header',
      type: PlutoColumnType.custom(),
      enableEditingMode: true,
      enableAutoEditing: true,
      customCell: (stateManager, cell, column, row) {
        return const TextField(
          autofocus: true,
        );
      },
    ),
    PlutoColumn(
      enableEditingMode: true,
      enableAutoEditing: true,
      title: 'autocomplete',
      field: 'autocomplete',
      type: PlutoColumnType.autoComplete(items: ["jacks", "jsoncon", "sks"]),
    ),
    PlutoColumn(
      enableEditingMode: true,
      enableAutoEditing: true,
      title: 'dropdown',
      field: 'dropdown',
      type: PlutoColumnType.dropdown(
          items: ["jacks", "jsoncon", "sks"],
          defaulticon: const Icon(Icons.arrow_downward),
          focusedIcon: const Icon(Icons.arrow_back)),
    ),
    PlutoColumn(
      title: 'Buy',
      field: 'buy',
      type: PlutoColumnType.bool(),
    ),
    PlutoColumn(
        title: 'Id',
        field: 'id',
        type: PlutoColumnType.text(),
        enableEditingMode: true,
        enableAutoEditing: true),
    PlutoColumn(
        title: 'Name',
        field: 'name',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        enableAutoEditing: false),
  ];

  final List<PlutoRow> rows = [
    for (int i = 0; i <= 30; i++)
      PlutoRow(
        cells: {
          'id': PlutoCell(value: ''),
          'autocomplete': PlutoCell(value: ''),
          'dropdown': PlutoCell(value: ''),
          'header': PlutoCell(value: ''),
          'name': PlutoCell(value: ''),
          'buy': PlutoCell(value: false),
        },
      ),
  ];

  /// columnGroups that can group columns can be omitted.
  final List<PlutoColumnGroup> columnGroups = [
    PlutoColumnGroup(title: 'Id', fields: ['id'], expandedColumn: true),
    PlutoColumnGroup(title: 'name', fields: ['name'], expandedColumn: true),
  ];

  /// [PlutoGridStateManager] has many methods and properties to dynamically manipulate the grid.
  /// You can manipulate the grid dynamically at runtime by passing this through the [onLoaded] callback.
  late final PlutoGridStateManager stateManager;
  final focusNode = FocusNode(
    onKey: (node, event) {
      if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.f1): () {
            FocusScope.of(context).requestFocus(FocusNode());
            final snackBar = SnackBar(
              content: const Text('Yay! A SnackBar!'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // Some code to undo the change.
                },
              ),
            );

            // Find the ScaffoldMessenger in the widget tree
            // and use it to show a SnackBar.
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
        },
        child: Focus(
            child: Scaffold(
          body: Container(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                          width: 200,
                          child: TextField(
                            focusNode: focusNode,
                            autofocus: true,
                          )),
                      TextButton(
                          onPressed: () {
                            var cells = stateManager.rows.first.cells.entries;
                            var cell = cells
                                .where((e) => e.value.initialized)
                                .firstOrNull
                                ?.value;
                            if (cell != null) {
                              stateManager.setKeepFocus(true);
                              stateManager.setCurrentCell(
                                cell,
                                0,
                              );
                              stateManager.setEditing(true);
                            }
                          },
                          child: const Text('focus'))
                    ],
                  ),
                  Expanded(
                    child: PlutoGrid(
                      columns: columns,
                      rows: rows,
                      onLoaded: (PlutoGridOnLoadedEvent event) {
                        stateManager = event.stateManager;
                        event.stateManager
                            .setSelectingMode(PlutoGridSelectingMode.cell);
                        // stateManager.setShowColumnFilter(true);
                        // stateManager.setShowColumnTitle(false);
                      },
                      onChanged: (PlutoGridOnChangedEvent event) {
                        print(event);
                      },
                      configuration: const PlutoGridConfiguration(
                          enterKeyAction:
                              PlutoGridEnterKeyAction.editingAndMoveRight,
                          enableMoveHorizontalInEditing: true,
                          style: PlutoGridStyleConfig(
                              enableHover: true,
                              activatedColor: Colors.purple,
                              activatedTextColor: Colors.white,
                              cellColorInReadOnlyState: Colors.white,
                              activatedBorderColor: Colors.purple)),
                    ),
                  ),
                ],
              )),
        )));
  }
}
