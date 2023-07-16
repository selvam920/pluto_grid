import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';

import 'decimal_input_formatter.dart';
import 'text_cell.dart';

class PlutoTextCell extends StatefulWidget implements TextCell {
  @override
  final PlutoGridStateManager stateManager;

  @override
  final PlutoCell cell;

  @override
  final PlutoColumn column;

  @override
  final PlutoRow row;

  const PlutoTextCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    Key? key,
  }) : super(key: key);

  @override
  PlutoTextCellState createState() => PlutoTextCellState();
}

class PlutoTextCellState extends State<PlutoTextCell>
    with TextCellState<PlutoTextCell> {
  @override
  List<TextInputFormatter>? inputFormatters;

  @override
  late TextInputType keyboardType;

  @override
  void initState() {
    super.initState();
    final textColumn = widget.column.type.text;
    if (textColumn.isOnlyDigits) {
      inputFormatters = [
        DecimalTextInputFormatter(
          decimalRange: 10,
          activatedNegativeValues: false,
          allowFirstDot: false,
          decimalSeparator: "",
        ),
      ];
      keyboardType = TextInputType.number;
    } else {
      keyboardType = TextInputType.text;
    }
  }
}

class PlutoAutoCompleteTextCell extends StatefulWidget
    implements AutoCompleteTextCell {
  @override
  final PlutoGridStateManager stateManager;

  @override
  final PlutoCell cell;

  @override
  final PlutoColumn column;

  @override
  final PlutoRow row;

  const PlutoAutoCompleteTextCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    Key? key,
  }) : super(key: key);

  @override
  State<PlutoAutoCompleteTextCell> createState() =>
      _PlutoAutoCompleteTextCellState();
}

class _PlutoAutoCompleteTextCellState extends State<PlutoAutoCompleteTextCell>
    with AutoCompleteTextCellState<PlutoAutoCompleteTextCell> {
  @override
  List<TextInputFormatter>? inputFormatters;

  @override
  late TextInputType keyboardType;

  @override
  void initState() {
    super.initState();
    final textColumn = widget.column.type.autoComplete;
    if (textColumn.isOnlyDigits) {
      inputFormatters = [
        DecimalTextInputFormatter(
          decimalRange: 10,
          activatedNegativeValues: false,
          allowFirstDot: false,
          decimalSeparator: "",
        ),
      ];
      keyboardType = TextInputType.number;
    } else {
      keyboardType = TextInputType.text;
    }
  }
}
