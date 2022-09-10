import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:rxdart/rxdart.dart';

import '../../helper/pluto_widget_test_helper.dart';
import 'pluto_aggregate_column_footer_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<PlutoGridStateManager>(returnNullOnMissingStub: true),
])
void main() {
  late MockPlutoGridStateManager stateManager;

  late PublishSubject<PlutoNotifierEvent> subject;

  buildWidget({
    required PlutoColumn column,
    required FilteredList<PlutoRow> rows,
    required PlutoAggregateColumnType type,
    PlutoAggregateFilter? filter,
    String? locale,
    String? format,
    List<InlineSpan> Function(String)? titleSpanBuilder,
    AlignmentGeometry? alignment,
    EdgeInsets? padding,
  }) {
    return PlutoWidgetTestHelper('PlutoAggregateColumnFooter : ',
        (tester) async {
      stateManager = MockPlutoGridStateManager();

      subject = PublishSubject<PlutoNotifierEvent>();

      when(stateManager.streamNotifier).thenAnswer((_) => subject);

      when(stateManager.configuration)
          .thenReturn(const PlutoGridConfiguration());

      when(stateManager.refRows).thenReturn(rows);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoAggregateColumnFooter(
              rendererContext: PlutoColumnFooterRendererContext(
                stateManager: stateManager,
                column: column,
              ),
              type: type,
              filter: filter,
              format: format ?? '#,###',
              locale: locale,
              titleSpanBuilder: titleSpanBuilder,
              alignment: alignment,
              padding: padding,
            ),
          ),
        ),
      );
    });
  }

  group('number 컬럼.', () {
    final columns = [
      PlutoColumn(
        title: 'column',
        field: 'column',
        type: PlutoColumnType.number(),
      ),
    ];

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: []),
      type: PlutoAggregateColumnType.sum,
    ).test('행이 없는 경우 sum 값은 0이 되어야 한다.', (tester) async {
      final found = find.text('0');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: []),
      type: PlutoAggregateColumnType.average,
    ).test('행이 없는 경우 average 값은 0이 되어야 한다.', (tester) async {
      final found = find.text('0');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: []),
      type: PlutoAggregateColumnType.min,
    ).test('행이 없는 경우 min 값은 빈문자열이 출력되어야 한다.', (tester) async {
      final found = find.text('');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: []),
      type: PlutoAggregateColumnType.max,
    ).test('행이 없는 경우 max 값은 빈문자열이 출력되어야 한다.', (tester) async {
      final found = find.text('');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: []),
      type: PlutoAggregateColumnType.count,
    ).test('행이 없는 경우 max 값은 0이 출력되어야 한다.', (tester) async {
      final found = find.text('0');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: [
        PlutoRow(cells: {'column': PlutoCell(value: 1000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 2000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 3000)}),
      ]),
      type: PlutoAggregateColumnType.sum,
    ).test('행이 있는 경우 sum 값은 포멧에 맞게 6,000이 출력 되어야 한다.', (tester) async {
      final found = find.text('6,000');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: [
        PlutoRow(cells: {'column': PlutoCell(value: 1000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 2000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 3000)}),
      ]),
      type: PlutoAggregateColumnType.average,
    ).test('행이 있는 경우 average 값은 포멧에 맞게 2,000이 출력 되어야 한다.', (tester) async {
      final found = find.text('2,000');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: [
        PlutoRow(cells: {'column': PlutoCell(value: 1000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 2000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 3000)}),
      ]),
      type: PlutoAggregateColumnType.min,
    ).test('행이 있는 경우 min 값은 포멧에 맞게 1,000이 출력 되어야 한다.', (tester) async {
      final found = find.text('1,000');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: [
        PlutoRow(cells: {'column': PlutoCell(value: 1000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 2000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 3000)}),
      ]),
      type: PlutoAggregateColumnType.max,
    ).test('행이 있는 경우 max 값은 포멧에 맞게 3,000이 출력 되어야 한다.', (tester) async {
      final found = find.text('3,000');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: [
        PlutoRow(cells: {'column': PlutoCell(value: 1000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 2000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 3000)}),
      ]),
      type: PlutoAggregateColumnType.count,
    ).test('행이 있는 경우 count 값은 포멧에 맞게 3이 출력 되어야 한다.', (tester) async {
      final found = find.text('3');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: [
        PlutoRow(cells: {'column': PlutoCell(value: 1000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 2000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 3000)}),
      ]),
      type: PlutoAggregateColumnType.count,
      filter: (cell) => cell.value > 1000,
    ).test('filter 가 설정 된 경우 count 값은 필터 조건에 맞게 2이 출력 되어야 한다.', (tester) async {
      final found = find.text('2');

      expect(found, findsOneWidget);
    });

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: [
        PlutoRow(cells: {'column': PlutoCell(value: 1000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 2000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 3000)}),
      ]),
      type: PlutoAggregateColumnType.count,
      format: 'Total : #,###',
    ).test(
      '행이 있는 경우 count 값은 설정한 포멧에 맞게 Total : 3이 출력 되어야 한다.',
      (tester) async {
        final found = find.text('Total : 3');

        expect(found, findsOneWidget);
      },
    );

    buildWidget(
      column: columns.first,
      rows: FilteredList<PlutoRow>(initialList: [
        PlutoRow(cells: {'column': PlutoCell(value: 1000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 2000)}),
        PlutoRow(cells: {'column': PlutoCell(value: 3000)}),
      ]),
      type: PlutoAggregateColumnType.sum,
      titleSpanBuilder: (text) {
        return [
          const WidgetSpan(child: Text('Left ')),
          WidgetSpan(child: Text('Value : $text')),
          const WidgetSpan(child: Text(' Right')),
        ];
      },
    ).test(
      'titleSpanBuilder 이 있는 경우 sum 값은 설정한 위젯에 맞게 '
      'Left Value : 6,000 Right 이 출력 되어야 한다.',
      (tester) async {
        expect(find.text('Left '), findsOneWidget);
        expect(find.text('Value : 6,000'), findsOneWidget);
        expect(find.text(' Right'), findsOneWidget);
      },
    );
  });
}
