import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../ui/ui.dart';

/// {@template pluto_aggregate_filter}
/// Returns whether to be filtered according to the value of [PlutoCell.value].
/// {@endtemplate}
typedef PlutoAggregateFilter = bool Function(PlutoCell);

/// {@template pluto_aggregate_column_type}
/// Determine the aggregate type.
///
/// [sum] Returns the sum of all values.
///
/// [average] Returns the result of adding up all values and dividing by the number of elements.
///
/// [min] Returns the smallest value among all values.
///
/// [max] Returns the largest value out of all values.
///
/// [count] Returns the total count.
/// {@endtemplate}
enum PlutoAggregateColumnType {
  sum,
  average,
  min,
  max,
  count,
}

/// Widget for outputting the sum, average, minimum,
/// and maximum values of all values in a column.
///
/// Example) [PlutoColumn.footerRenderer] Implement column footer as return value of callback
/// ```dart
/// PlutoColumn(
///   title: 'column',
///   field: 'column',
///   type: PlutoColumnType.number(format: '#,###.###'),
///   textAlign: PlutoColumnTextAlign.right,
///   footerRenderer: (rendererContext) {
///     return PlutoAggregateColumnFooter(
///       rendererContext: rendererContext,
///       type: PlutoAggregateColumnType.sum,
///       format: 'Sum : #,###.###',
///       alignment: Alignment.center,
///     );
///   },
/// ),
/// ```
///
/// [PlutoAggregateColumnFooter]
/// You can also return a [Widget] you wrote yourself instead of a widget.
/// However, you must implement the process
/// of updating according to the value change yourself.
class PlutoAggregateColumnFooter extends PlutoStatefulWidget {
  /// Contains information needed to implement the widget.
  final PlutoColumnFooterRendererContext rendererContext;

  /// {@macro pluto_aggregate_column_type}
  final PlutoAggregateColumnType type;

  /// {@macro pluto_aggregate_filter}
  ///
  /// Example) Only when the value of [PlutoCell.value] is Android,
  /// it is included in the aggregate list.
  /// ```dart
  /// filter: (cell) => cell.value == 'Android',
  /// ```
  final PlutoAggregateFilter? filter;

  /// Set the format of aggregated result values.
  ///
  /// Example)
  /// ```dart
  /// format: 'Android: #,###', // Android: 100 (if the result is 100)
  /// format: '#,###.###', // 1,000,000.123 (expressed to 3 decimal places)
  /// ```
  final String format;

  /// Setting the locale of the resulting value.
  ///
  /// Example)
  /// ```dart
  /// locale: 'da_DK',
  /// ```
  final String? locale;

  /// You can customize the resulting values.
  ///
  /// Example)
  /// ```dart
  /// titleSpanBuilder: (text) {
  ///   return [
  ///     const TextSpan(
  ///       text: 'Sum',
  ///       style: TextStyle(color: Colors.red),
  ///     ),
  ///     const TextSpan(text: ' : '),
  ///     TextSpan(text: text),
  ///   ];
  /// },
  /// ```
  final List<InlineSpan> Function(String)? titleSpanBuilder;

  final AlignmentGeometry? alignment;

  final EdgeInsets? padding;

  const PlutoAggregateColumnFooter({
    required this.rendererContext,
    required this.type,
    this.filter,
    this.format = '#,###',
    this.locale,
    this.titleSpanBuilder,
    this.alignment,
    this.padding,
    super.key,
  });

  @override
  PlutoAggregateColumnFooterState createState() =>
      PlutoAggregateColumnFooterState();
}

class PlutoAggregateColumnFooterState
    extends PlutoStateWithChange<PlutoAggregateColumnFooter> {
  @override
  PlutoGridStateManager get stateManager => widget.rendererContext.stateManager;

  PlutoColumn get column => widget.rendererContext.column;

  num? _aggregatedValue;

  late final NumberFormat _numberFormat;

  late final num? Function({
    required List<PlutoRow> rows,
    required PlutoColumn column,
    PlutoAggregateFilter? filter,
  }) _aggregator;

  @override
  void initState() {
    super.initState();

    _numberFormat = NumberFormat(widget.format, widget.locale);

    _setAggregator();

    updateState();
  }

  void _setAggregator() {
    switch (widget.type) {
      case PlutoAggregateColumnType.sum:
        _aggregator = PlutoAggregateHelper.sum;
        break;
      case PlutoAggregateColumnType.average:
        _aggregator = PlutoAggregateHelper.average;
        break;
      case PlutoAggregateColumnType.min:
        _aggregator = PlutoAggregateHelper.min;
        break;
      case PlutoAggregateColumnType.max:
        _aggregator = PlutoAggregateHelper.max;
        break;
      case PlutoAggregateColumnType.count:
        _aggregator = PlutoAggregateHelper.count;
        break;
    }
  }

  @override
  void updateState() {
    _aggregatedValue = update<num?>(
      _aggregatedValue,
      _aggregator(
        rows: stateManager.refRows,
        column: column,
        filter: widget.filter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTitleSpan = widget.titleSpanBuilder != null;

    final formattedValue =
        _aggregatedValue == null ? '' : _numberFormat.format(_aggregatedValue);

    final text = hasTitleSpan ? null : formattedValue;

    final children =
        hasTitleSpan ? widget.titleSpanBuilder!(formattedValue) : null;

    return Container(
      padding: widget.padding ?? PlutoGridSettings.columnTitlePadding,
      alignment: widget.alignment ?? AlignmentDirectional.centerStart,
      child: Text.rich(
        TextSpan(
          text: text,
          children: children,
        ),
        style: stateManager.configuration!.style.cellTextStyle.copyWith(
          decoration: TextDecoration.none,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
