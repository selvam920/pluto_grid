import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:pluto_grid/src/helper/platform_helper.dart';

abstract class TextCell extends StatefulWidget {
  final PlutoGridStateManager stateManager;

  final PlutoCell cell;

  final PlutoColumn column;

  final PlutoRow row;

  const TextCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    Key? key,
  }) : super(key: key);
}

abstract class TextFieldProps {
  TextInputType get keyboardType;

  List<TextInputFormatter>? get inputFormatters;
}

mixin TextCellState<T extends TextCell> on State<T> implements TextFieldProps {
  dynamic _initialCellValue;

  final _textController = TextEditingController();

  final PlutoDebounceByHashCode _debounce = PlutoDebounceByHashCode();

  late final FocusNode cellFocus;

  late _CellEditingStatus _cellEditingStatus;

  @override
  TextInputType get keyboardType => TextInputType.text;

  @override
  List<TextInputFormatter>? get inputFormatters => [];

  String get formattedValue =>
      widget.column.formattedValueForDisplayInEditing(widget.cell.value);

  @override
  void initState() {
    super.initState();

    cellFocus = FocusNode(onKey: _handleOnKey);
    cellFocus.addListener(() {
      if (!cellFocus.hasFocus) _handleOnComplete();
    });

    widget.stateManager.setTextEditingController(_textController);

    _textController.text = formattedValue;

    _initialCellValue = _textController.text;

    _cellEditingStatus = _CellEditingStatus.init;

    _textController.addListener(() {
      _handleOnChanged(_textController.text.toString());
    });
  }

  @override
  void dispose() {
    /**
     * Saves the changed value when moving a cell while text is being input.
     * if user do not press enter key, onEditingComplete is not called and the value is not saved.
     */
    if (_cellEditingStatus.isChanged) {
      _changeValue();
    }

    if (!widget.stateManager.isEditing ||
        widget.stateManager.currentColumn?.enableEditingMode != true) {
      widget.stateManager.setTextEditingController(null);
    }

    _debounce.dispose();

    _textController.dispose();

    cellFocus.dispose();
    super.dispose();
  }

  void _restoreText() {
    if (_cellEditingStatus.isNotChanged) {
      return;
    }

    _textController.text = _initialCellValue.toString();

    widget.stateManager.changeCellValue(
      widget.stateManager.currentCell!,
      _initialCellValue,
      notify: false,
    );
  }

  bool _moveHorizontal(PlutoKeyManagerEvent keyManager) {
    if (!keyManager.isHorizontal) {
      return false;
    }

    if (widget.column.readOnly == true) {
      return true;
    }

    final selection = _textController.selection;

    if (selection.baseOffset != selection.extentOffset) {
      return false;
    }

    if (selection.baseOffset == 0 && keyManager.isLeft) {
      return true;
    }

    final textLength = _textController.text.length;

    if (selection.baseOffset == textLength && keyManager.isRight) {
      return true;
    }

    return false;
  }

  void _changeValue() {
    if (formattedValue == _textController.text) {
      return;
    }

    widget.stateManager.changeCellValue(widget.cell, _textController.text);

    _textController.text = formattedValue;

    _initialCellValue = _textController.text;

    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );

    _cellEditingStatus = _CellEditingStatus.updated;
  }

  void _handleOnChanged(String value) {
    _cellEditingStatus = formattedValue != value.toString()
        ? _CellEditingStatus.changed
        : _initialCellValue.toString() == value.toString()
            ? _CellEditingStatus.init
            : _CellEditingStatus.updated;
  }

  void _handleOnComplete() {
    final old = _textController.text;

    _changeValue();

    _handleOnChanged(old);
  }

  KeyEventResult _handleOnKey(FocusNode node, RawKeyEvent event) {
    var keyManager = PlutoKeyManagerEvent(
      focusNode: node,
      event: event,
    );

    if (keyManager.isKeyUpEvent) {
      return KeyEventResult.handled;
    }

    final skip = !(keyManager.isVertical ||
        _moveHorizontal(keyManager) ||
        keyManager.isEsc ||
        keyManager.isTab ||
        keyManager.isEnter);

    // handled means will ignore parent onkey, ignored means will run parent onkey event
    if (skip) {
      // if (!keyManager.isModifierPressed &&
      //     !keyManager.isCharacter &&
      //     !keyManager.isBackspace &&
      //     !keyManager.isDelete) {
      //   _handleOnComplete();
      //   return KeyEventResult.ignored;
      // } else {
      return widget.stateManager.keyManager!.eventResult.skip(
        KeyEventResult.ignored,
      );
      // }
    }

    if (_debounce.isDebounced(
      hashCode: _textController.text.hashCode,
      ignore: !kIsWeb,
    )) {
      return KeyEventResult.handled;
    }

    // 엔터키는 그리드 포커스 핸들러로 전파 한다.
    if (keyManager.isEnter) {
      _handleOnComplete();
      return KeyEventResult.ignored;
    }
    // ESC 는 편집된 문자열을 원래 문자열로 돌이킨다.
    else if (keyManager.isEsc) {
      _restoreText();
    }

    widget.stateManager.keyManager!.subject.add(keyManager);

    if (keyManager.isVertical || _moveHorizontal(keyManager))
      return KeyEventResult.ignored;

    // // 모든 이벤트를 처리 하고 이벤트 전파를 중단한다.
    return KeyEventResult.handled;
  }

  void _handleOnTap() {
    widget.stateManager.setKeepFocus(true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stateManager.keepFocus) {
      cellFocus.requestFocus();
    }

    return TextField(
      focusNode: cellFocus,
      controller: _textController,
      readOnly: widget.column.checkReadOnly(widget.row, widget.cell),
      onChanged: _handleOnChanged,
      onEditingComplete: _handleOnComplete,
      onSubmitted: (_) => _handleOnComplete(),
      onTap: _handleOnTap,
      style: widget.stateManager.configuration.style.cellTextStyle,
      decoration: const InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: 1,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlignVertical: TextAlignVertical.center,
      textAlign: widget.column.textAlign.value,
    );
  }
}

enum _CellEditingStatus {
  init,
  changed,
  updated;

  bool get isNotChanged {
    return _CellEditingStatus.changed != this;
  }

  bool get isChanged {
    return _CellEditingStatus.changed == this;
  }

  bool get isUpdated {
    return _CellEditingStatus.updated == this;
  }
}

abstract class AutoCompleteTextCell extends StatefulWidget {
  final PlutoGridStateManager stateManager;

  final PlutoCell cell;

  final PlutoColumn column;

  final PlutoRow row;

  const AutoCompleteTextCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    Key? key,
  }) : super(key: key);
}

abstract class AutoCompleteTextFieldProps {
  TextInputType get keyboardType;

  List<TextInputFormatter>? get inputFormatters;
}

mixin AutoCompleteTextCellState<T extends AutoCompleteTextCell> on State<T>
    implements AutoCompleteTextFieldProps {
  dynamic _initialCellValue;
  TextEditingController textController = TextEditingController();
  final PlutoDebounceByHashCode _debounce = PlutoDebounceByHashCode();
  late final FocusNode cellFocus;
  late _CellEditingStatus _cellEditingStatus;

  @override
  TextInputType get keyboardType => TextInputType.text;

  @override
  List<TextInputFormatter>? get inputFormatters => [];

  String get formattedValue =>
      widget.column.formattedValueForDisplayInEditing(widget.cell.value);

  /// ---- AutoComplete 관련 variables
  final LayerLink _optionsLayerLink = LayerLink();
  final ValueNotifier<int> _highlightedOptionIndex = ValueNotifier<int>(0);
  Iterable<String> _options = const Iterable<String>.empty();

  /// AutoCompleteItemList Container
  OverlayEntry? _floatingOptions;

  String? _selection;
  bool _userHidOptions = false;
  String _lastFieldText = '';
  bool _floatingOptionsUpdateScheduled = false;

  bool get _shouldShowOptions {
    return !_userHidOptions &&
        cellFocus.hasFocus &&
        _selection == null &&
        _options.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    cellFocus = FocusNode(onKey: _handleOnKey);
    widget.stateManager.setTextEditingController(textController);
    textController.text = formattedValue;
    _initialCellValue = textController.text;
    _cellEditingStatus = _CellEditingStatus.init;

    /// textController 의 _onChangedField Listen 은 반드시 필요. (오버레이 출력)
    textController
        .addListener(() => _onChangedField(textController.text.toString()));

    /// 오버레이 출력 상태에서 다른 셀 마우스 클릭시, 오버레이 사라지게 하는 역할.
    // cellFocus.addListener(_onChangedFocus);

    _updateOverlay();
  }

  @override
  void dispose() {
    /**
     * Saves the changed value when moving a cell while text is being input.
     * if user do not press enter key, onEditingComplete is not called and the value is not saved.
     */
    if (_cellEditingStatus.isChanged) {
      _changeValue();
    }

    if (!widget.stateManager.isEditing ||
        widget.stateManager.currentColumn?.enableEditingMode != true) {
      widget.stateManager.setTextEditingController(null);
    }

    _debounce.dispose();
    textController
        .removeListener(() => _onChangedField(textController.text.toString()));
    textController.dispose();
    cellFocus.removeListener(_onChangedFocus);
    cellFocus.dispose();

    /// overlay dispose
    _floatingOptions?.remove();
    _floatingOptions = null;

    super.dispose();
  }

  void _restoreText() {
    if (_cellEditingStatus.isNotChanged) {
      return;
    }

    textController.text = _initialCellValue.toString();

    widget.stateManager.changeCellValue(
      widget.stateManager.currentCell!,
      _initialCellValue,
      notify: false,
    );
  }

  bool _moveHorizontal(PlutoKeyManagerEvent keyManager) {
    if (!keyManager.isHorizontal) {
      return false;
    }

    if (widget.column.readOnly == true) {
      return true;
    }

    //final selection = textController.selection;

    // if (selection.baseOffset != selection.extentOffset) {
    //   return false;
    // }

    // if (selection.baseOffset == 0 && keyManager.isLeft) {
    //   return true;
    // }

    // final textLength = textController.text.length;

    // if (selection.baseOffset == textLength && keyManager.isRight) {
    //   return true;
    // }

    return false;
  }

  void _changeValue() {
    if (formattedValue == textController.text) {
      return;
    }

    widget.stateManager.changeCellValue(widget.cell, textController.text);

    textController.text = formattedValue;

    _initialCellValue = textController.text;

    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );

    _cellEditingStatus = _CellEditingStatus.updated;
  }

  // Called from fieldViewBuilder when the user submits the field.
  void _onFieldSubmitted() {
    if (_options.isEmpty || _userHidOptions) {
      return;
    }
    _select(_options.elementAt(_highlightedOptionIndex.value));
  }

  void _onChangedFocus() {
    // Options should no longer be hidden when the field is re-focused.
    _userHidOptions = !cellFocus.hasFocus;
    _updateOverlay();
  }

  /// 다이렉트 인풋 edit 시, 텍스트 블록잡히는 문제 해결위해 prevStatus, if 절 추가
  Future<void> _onChangedField(String value) async {
    final prevStatus = _cellEditingStatus;

    /// Pluto Lib 의 _handleOnChanged 내용
    _cellEditingStatus = formattedValue != value.toString()
        ? _CellEditingStatus.changed
        : _initialCellValue.toString() == value.toString()
            ? _CellEditingStatus.init
            : _CellEditingStatus.updated;

    if (prevStatus == _CellEditingStatus.init &&
        _cellEditingStatus == _CellEditingStatus.changed &&
        textController.text.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        textController.selection = TextSelection.fromPosition(
          TextPosition(offset: textController.text.length),
        );
      });
    }

    /// Autocomplete 위젯의 _onChangedField 내용
    final TextEditingValue textEditValue = textController.value;
    final Iterable<String> options =
        await _buildAutoCompleteListItems(textEditValue);

    _options = options;
    _updateHighlight(_highlightedOptionIndex.value);

    if (_selection != null &&
        textEditValue.text !=
            _buildDisplayStringForAutoCompleteListItem(_selection!)) {
      _selection = null;
    }

    // Make sure the options are no longer hidden if the content of the field
    // changes (ignore selection changes).
    if (textEditValue.text != _lastFieldText) {
      _userHidOptions = false;
      _lastFieldText = textEditValue.text;
    }
    _updateOverlay();
  }

  void _updateHighlight(int newIndex) {
    _highlightedOptionIndex.value =
        _options.isEmpty ? 0 : newIndex % _options.length;
  }

  void _updateOverlay() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (!_floatingOptionsUpdateScheduled) {
        _floatingOptionsUpdateScheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
          _floatingOptionsUpdateScheduled = false;
          _updateOverlay();
        });
      }
      return;
    }

    _floatingOptions?.remove();
    if (_shouldShowOptions) {
      final OverlayEntry newFloatingOptions = OverlayEntry(
        builder: (BuildContext context) {
          return CompositedTransformFollower(
              link: _optionsLayerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              child: AutocompleteHighlightedOption(
                  highlightIndexNotifier: _highlightedOptionIndex,
                  child: Builder(builder: (context) {
                    return _buildAutoCompleteListViewBuilder(
                        context, _select, _options);
                  })));
        },
      );
      Overlay.of(context, rootOverlay: true).insert(newFloatingOptions);
      _floatingOptions = newFloatingOptions;
    } else {
      _floatingOptions = null;
    }
  }

  void _select(String nextSelection) {
    if (nextSelection == _selection) {
      /// ValueNotifier 값 초기화 후 메소드 종료. (하이라이트 한 인덱스)
      _highlightedOptionIndex.value = 0;
      return;
    }

    _selection = nextSelection;

    final String selectionString =
        _buildDisplayStringForAutoCompleteListItem(nextSelection);

    textController.value = TextEditingValue(
      selection: TextSelection.collapsed(offset: selectionString.length),
      text: selectionString,
    );

    _updateOverlay();
    // _onSelectAutoCompleteListItem.call(_selection!);
  }

  void _handleOnComplete() {
    final old = textController.text;

    /// 이걸 해주어야 위,아래키 입력 포커스이동 및 엔터 입력으로 값 반영됨.
    _onFieldSubmitted();

    _changeValue();

    _onChangedField(old);

    PlatformHelper.onMobile(() {
      widget.stateManager.setKeepFocus(false);
      FocusScope.of(context).requestFocus(FocusNode());
    });

    /// 한 행의 끝에서 다음 행으로 포커스 이동 로직.
    bool isEndOfOneRow = widget.stateManager.currentCellPosition!.columnIdx! ==
        widget.stateManager.refColumns.length - 1;
    bool isLastRow = widget.stateManager.currentCellPosition!.rowIdx! ==
        widget.stateManager.rows.length - 1;

    if (isEndOfOneRow && !isLastRow) {
      widget.stateManager.setCurrentCell(
        widget
            .stateManager
            .refRows[widget.stateManager.currentCellPosition!.rowIdx! + 1]
            .cells
            .values
            .firstWhere((e) => e.isFirstOfRow == true),
        widget.stateManager.currentCellPosition!.rowIdx! + 1,
      );
    }
  }

  KeyEventResult _handleOnKey(FocusNode node, RawKeyEvent event) {
    var keyManager = PlutoKeyManagerEvent(
      focusNode: node,
      event: event,
    );

    if (keyManager.isKeyUpEvent) {
      return KeyEventResult.handled;
    }

    final skip = !(keyManager.isVertical ||
        _moveHorizontal(keyManager) ||
        keyManager.isEsc ||
        keyManager.isTab ||
        keyManager.isF3 ||
        keyManager.isEnter);

    // 이동 및 엔터키, 수정불가 셀의 좌우 이동을 제외한 문자열 입력 등의 키 입력은 텍스트 필드로 전파 한다.
    if (skip) {
      return widget.stateManager.keyManager!.eventResult.skip(
        KeyEventResult.ignored,
      );
    }

    if (_debounce.isDebounced(
      hashCode: textController.text.hashCode,
      ignore: !kIsWeb,
    )) {
      return KeyEventResult.handled;
    }

    // 엔터키는 그리드 포커스 핸들러로 전파 한다.
    if (keyManager.isEnter) {
      _handleOnComplete();
      return KeyEventResult.ignored;
    }

    // ESC 는 편집된 문자열을 원래 문자열로 돌이킨다.
    if (keyManager.isEsc) {
      _restoreText();
    }

    /// up, down key 시, AutoComplete List item 선택하도록.
    if (keyManager.isUp) {
      /// highlight prev list item
      if (_highlightedOptionIndex.value != 0) {
        if (_userHidOptions) {
          _userHidOptions = false;
          _updateOverlay();
          return KeyEventResult.ignored;
        }
        _updateHighlight(_highlightedOptionIndex.value - 1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (keyManager.isDown) {
      /// highlight next list item
      if (_options.length - 1 != _highlightedOptionIndex.value) {
        if (_userHidOptions) {
          _userHidOptions = false;
          _updateOverlay();
          return KeyEventResult.ignored;
        }
        _updateHighlight(_highlightedOptionIndex.value + 1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    // KeyManager 로 이벤트 처리를 위임 한다.
    widget.stateManager.keyManager!.subject.add(keyManager);

    // 모든 이벤트를 처리 하고 이벤트 전파를 중단한다.
    return KeyEventResult.handled;
  }

  void _handleOnTap() {
    widget.stateManager.setKeepFocus(true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stateManager.keepFocus) {
      cellFocus.requestFocus();
    }

    return Autocomplete<String>(
      fieldViewBuilder: (context, controller, autoCompleteFocusNode, onSubmit) {
        autoCompleteFocusNode = cellFocus;
        controller = textController;

        return _buildAutoCompleteTextField(autoCompleteFocusNode, controller);
      },
      optionsBuilder: _buildAutoCompleteListItems,
      optionsViewBuilder: _buildAutoCompleteListViewBuilder,

      displayStringForOption: _buildDisplayStringForAutoCompleteListItem,
      // onSelected: _onSelectAutoCompleteListItem,
    );
  }

  _buildAutoCompleteTextField(
      FocusNode autoCompleteFocusNode, TextEditingController controller) {
    return CompositedTransformTarget(
      link: _optionsLayerLink,
      child: TextField(
        focusNode: autoCompleteFocusNode,
        controller: controller,
        keyboardType: keyboardType,
        readOnly: widget.column.checkReadOnly(widget.row, widget.cell),
        onChanged: _onChangedField,
        onEditingComplete: _handleOnComplete,
        onSubmitted: (_) => _handleOnComplete(),
        onTap: _handleOnTap,
        maxLength: widget.column.type.autoComplete.maxLength,
        style: widget.stateManager.configuration.style.cellTextStyle,
        decoration: const InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        maxLines: 1,
        inputFormatters: inputFormatters,
        textAlignVertical: TextAlignVertical.center,
        textAlign: widget.column.textAlign.value,
      ),
    );
  }

  FutureOr<Iterable<String>> _buildAutoCompleteListItems(
      TextEditingValue textEditingValue) {
    if (textEditingValue.text == '') {
      return const Iterable<String>.empty();
    }
    return widget.column.type.autoComplete.items
        .where((item) => item.toString().startsWith(textEditingValue.text));
  }

  String _buildDisplayStringForAutoCompleteListItem(dynamic option) {
    return option.toString();
  }

  Widget _buildAutoCompleteListViewBuilder(BuildContext context,
      AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
    return _AutocompleteOptions<String>(
      displayStringForOption: _buildDisplayStringForAutoCompleteListItem,
      onSelected: onSelected,
      options: options,
      maxOptionsWidth: widget.column.width,
      maxOptionsHeight: widget.column.type.autoComplete.listHeight,
      itemHeight: widget.column.type.autoComplete.itemHeight,
    );
  }

  _onSelectAutoCompleteListItem(String selection) {
    print('-------- [AutoComplete] selected :: $selection --------');
  }
}

class _AutocompleteOptions<T extends Object> extends StatelessWidget {
  const _AutocompleteOptions({
    super.key,
    required this.displayStringForOption,
    required this.onSelected,
    required this.options,
    required this.maxOptionsWidth,
    required this.maxOptionsHeight,
    required this.itemHeight,
  });

  final AutocompleteOptionToString<T> displayStringForOption;

  final AutocompleteOnSelected<T> onSelected;

  final Iterable<T> options;
  final double maxOptionsWidth;
  final double maxOptionsHeight;
  final double itemHeight;

  final Color appColorPrimary20 = const Color(0xffd7eaff);
  final Color appColorPrimary100 = const Color(0xff0078ff);
  final Color appColorGreyBorder = const Color(0xffc7d0dc);
  final Color appColorGreyDisableButton = const Color(0xffe1e7ee);
  final Color appColorGreyPrimaryText = const Color(0xff7d8da6);

  final TextStyle itemDefaultTextStyle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black,
    height: 17.5 / 14,
    letterSpacing: -0.5,
  );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        /// ItemListContainer 외곽 Clipping.
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        elevation: 4.0,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: maxOptionsWidth, maxHeight: maxOptionsHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: appColorGreyBorder, width: 1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                spreadRadius: 2,
                color: appColorGreyDisableButton,
              )
            ],
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final T option = options.elementAt(index);
              return InkWell(
                onTap: () {
                  onSelected(option);
                },
                child: Builder(builder: (BuildContext context) {
                  final bool highlight =
                      AutocompleteHighlightedOption.of(context) == index;

                  if (highlight) {
                    SchedulerBinding.instance
                        .addPostFrameCallback((Duration timeStamp) {
                      Scrollable.ensureVisible(context, alignment: 0.5);
                    });
                  }

                  return Container(
                    color: highlight ? appColorPrimary20 : null,
                    height: itemHeight,
                    padding: const EdgeInsets.only(left: 10),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(displayStringForOption(option),
                            textAlign: TextAlign.center,
                            style: highlight
                                ? itemDefaultTextStyle.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: appColorPrimary100)
                                : itemDefaultTextStyle.copyWith(
                                    color: appColorGreyPrimaryText))),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
