import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

import 'popup_cell.dart';

class PlutoSelectCell extends StatefulWidget implements PopupCell {
  @override
  final PlutoGridStateManager stateManager;

  @override
  final PlutoCell cell;

  @override
  final PlutoColumn column;

  @override
  final PlutoRow row;

  const PlutoSelectCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    Key? key,
  }) : super(key: key);

  @override
  PlutoSelectCellState createState() => PlutoSelectCellState();
}

class PlutoSelectCellState extends State<PlutoSelectCell>
    with PopupCellState<PlutoSelectCell> {
  @override
  List<PlutoColumn> popupColumns = [];

  @override
  List<PlutoRow> popupRows = [];

  @override
  IconData? get icon => widget.column.type.select.popupIcon;

  late bool enableColumnFilter;

  @override
  void initState() {
    super.initState();

    enableColumnFilter = widget.column.type.select.enableColumnFilter;

    final columnFilterHeight = enableColumnFilter
        ? widget.stateManager.configuration.style.columnFilterHeight
        : 0;

    final rowsHeight = widget.column.type.select.items.length *
        widget.stateManager.rowTotalHeight;

    popupHeight = widget.stateManager.configuration.style.columnHeight +
        columnFilterHeight +
        rowsHeight +
        PlutoGridSettings.gridInnerSpacing +
        PlutoGridSettings.gridBorderWidth;

    fieldOnSelected = widget.column.title;

    popupColumns = [
      PlutoColumn(
        title: widget.column.title,
        field: widget.column.title,
        readOnly: true,
        type: PlutoColumnType.text(),
        formatter: widget.column.formatter,
        enableFilterMenuItem: enableColumnFilter,
        enableHideColumnMenuItem: false,
        enableSetColumnsMenuItem: false,
      )
    ];

    popupRows = widget.column.type.select.items.map((dynamic item) {
      return PlutoRow(
        cells: {
          widget.column.title: PlutoCell(value: item),
        },
      );
    }).toList();
  }

  @override
  void onLoaded(PlutoGridOnLoadedEvent event) {
    super.onLoaded(event);

    if (enableColumnFilter) {
      event.stateManager.setShowColumnFilter(true, notify: false);
    }

    event.stateManager.setSelectingMode(PlutoGridSelectingMode.none);
  }
}

class PlutoDropDownCell extends StatefulWidget {
  final PlutoGridStateManager stateManager;
  final PlutoCell cell;
  final PlutoColumn column;
  final PlutoRow row;

  const PlutoDropDownCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    Key? key,
  }) : super(key: key);

  @override
  State<PlutoDropDownCell> createState() => _PlutoDropDownCellState();
}

class _PlutoDropDownCellState extends State<PlutoDropDownCell> {
  final layerLink = LayerLink();
  final focusNode = FocusNode();
  final dropdownButtonKey = GlobalKey();

  late Size screenSize = MediaQuery.of(context).size;
  late RenderBox buttonRenderBox =
      dropdownButtonKey.currentContext!.findRenderObject() as RenderBox;
  late Offset buttonPosition = Offset(
    buttonRenderBox.localToGlobal(Offset.zero).dx,
    buttonRenderBox.localToGlobal(Offset.zero).dy,
  );
  late Size buttonSize = buttonRenderBox.size;

  bool prevFocus = false;
  bool isChangeFocus = true;

  late String selectedValue = widget.cell.value;

  final Color appColorPrimary20 = const Color(0xffd7eaff);
  final Color appColorPrimary100 = const Color(0xff0078ff);
  final Color appColorGreyPrimaryText = const Color(0xff7d8da6);
  final Color appColorGreySecondaryText = const Color(0xffa5b4cb);

  @override
  void initState() {
    super.initState();
    focusNode.onKeyEvent = (node, event) => _handleKeyboardEvent(node, event);
    focusNode.requestFocus();
  }

  @override
  dispose() {
    focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyboardEvent(FocusNode node, KeyEvent event) {
    var keyManager = PlutoKeyManagerEvent(focusNode: node, event: event);

    if (keyManager.isKeyDownEvent) {
      if (keyManager.isEnter) {
        openDropdownList();
        return KeyEventResult.handled;
      }
      if (keyManager.isLeft) {
        widget.stateManager
            .moveCurrentCell(PlutoMoveDirection.left, force: true);
        return KeyEventResult.handled;
      }
      if (keyManager.isRight) {
        widget.stateManager
            .moveCurrentCell(PlutoMoveDirection.right, force: true);
        return KeyEventResult.handled;
      }
    }

    widget.stateManager.keyManager!.subject.add(keyManager);

    return KeyEventResult.handled;
  }

  openDropdownList() async {
    final result = await showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => PlutoDropDownCellList(
              stateManager: widget.stateManager,
              offset: buttonPosition,
              width: buttonSize.width,
              isUpside: screenSize.height / 2 <= buttonPosition.dy,
              layerLink: layerLink,
              items: widget.column.type.dropdown.items,
              initialValue: widget.cell.value,
            ));
    if (result == null) {
      return;
    }

    if (widget.cell.value != result) {
      widget.stateManager.changeCellValue(widget.cell, result, notify: false);
    }
    widget.stateManager
        .moveCurrentCell(PlutoMoveDirection.right, force: true, notify: false);
    widget.stateManager.setKeepFocus(true, notify: false);
    widget.stateManager.setEditing(true);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      key: dropdownButtonKey,
      link: layerLink,
      child: SizedBox(
        width: widget.column.width,
        height: 40,
        child: ElevatedButton(
          focusNode: focusNode,
          onFocusChange: (hasFocus) => setState(() {
            if (isChangeFocus) {
              prevFocus = hasFocus;
            }
          }),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: const RoundedRectangleBorder(),
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor:
                prevFocus ? appColorPrimary20 : appColorGreySecondaryText,
            side: BorderSide.none,
          ),
          onPressed: () async {
            isChangeFocus = false;
            setState(() {
              prevFocus = true;

              /// 누른시점에 size.height, buttonPosition update.
              screenSize = MediaQuery.of(context).size;
              buttonPosition = Offset(
                buttonRenderBox.localToGlobal(Offset.zero).dx,
                buttonRenderBox.localToGlobal(Offset.zero).dy,
              );
            });

            openDropdownList();

            isChangeFocus = true;
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.cell.value.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: prevFocus
                        ? appColorPrimary100
                        : appColorGreyPrimaryText,
                    height: 17.5 / 14,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              prevFocus
                  ? widget.column.type.dropdown.focusedIcon!
                  : widget.column.type.dropdown.defaulticon!,
            ],
          ),
        ),
      ),
    );
  }
}

class PlutoDropDownCellList extends StatefulWidget {
  final PlutoGridStateManager stateManager;
  final Offset offset;
  final double width;
  final bool isUpside;
  final LayerLink layerLink;
  final List<dynamic> items;
  final dynamic initialValue;

  const PlutoDropDownCellList({
    required this.stateManager,
    required this.offset,
    required this.width,
    required this.isUpside,
    required this.layerLink,
    required this.items,
    required this.initialValue,
    Key? key,
  }) : super(key: key);

  @override
  State<PlutoDropDownCellList> createState() => _PlutoDropDownCellListState();
}

class _PlutoDropDownCellListState extends State<PlutoDropDownCellList> {
  late final List<FocusNode> focusNodes;
  int currentFocusedIdx = 0;
  dynamic selectedValue;
  final Color appColorPrimary20 = const Color(0xffd7eaff);
  final Color appColorPrimary100 = const Color(0xff0078ff);
  final Color appColorGreyBorder = const Color(0xffc7d0dc);
  final Color appColorGreyDisableButton = const Color(0xffe1e7ee);
  final Color appColorGreyPrimaryText = const Color(0xff7d8da6);

  bool showDropdownList = true;

  /// 셀 enter 키 조작으로 포커스 아웃시, 드랍다운 리스트 위젯 dispose 순간 position 날라감. 안보임 처리.

  @override
  void initState() {
    super.initState();
    focusNodes = List.generate(widget.items.length,
        (index) => FocusNode(onKeyEvent: _handleKeyboardEvent));
    int initialSelectedValueIndex =
        widget.items.indexWhere((element) => element == widget.initialValue);
    if (initialSelectedValueIndex != -1) {
      currentFocusedIdx = initialSelectedValueIndex;
      focusNodes[currentFocusedIdx].requestFocus();
    }
  }

  @override
  void dispose() {
    for (FocusNode node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _handleKeyboardEvent(FocusNode node, KeyEvent event) {
    var keyManager = PlutoKeyManagerEvent(
      focusNode: node,
      event: event,
    );

    if (keyManager.isKeyDownEvent) {
      if (keyManager.isUp) {
        if (currentFocusedIdx > 0) {
          setState(() {
            currentFocusedIdx--;
            focusNodes[currentFocusedIdx].requestFocus();
          });
        }
        return KeyEventResult.handled;
      }

      if (keyManager.isDown) {
        if (currentFocusedIdx < focusNodes.length - 1) {
          setState(() {
            currentFocusedIdx++;
            focusNodes[currentFocusedIdx].requestFocus();
          });
        }
        return KeyEventResult.handled;
      }

      if (keyManager.isEnter) {
        setState(() => showDropdownList = false);
        Navigator.of(context).pop(selectedValue);
        return KeyEventResult.handled;
      }

      if (keyManager.isEsc) {
        setState(() => showDropdownList = false);
        Navigator.of(context).pop();
        widget.stateManager.setEditing(false);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Visibility(
            visible: showDropdownList,
            child: Positioned(
              top: widget.isUpside ? null : widget.offset.dy,
              left: widget.offset.dx,
              bottom: !widget.isUpside ? null : widget.offset.dy,
              child: CompositedTransformFollower(
                link: widget.layerLink,
                targetAnchor:
                    widget.isUpside ? Alignment.topLeft : Alignment.bottomLeft,
                followerAnchor:
                    widget.isUpside ? Alignment.bottomLeft : Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  height: widget.items.length >= 8
                      ? 8 * 36 + 22
                      : widget.items.length * 36 + 22,
                  width: widget.width,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: Colors.white,
                    border: Border.fromBorderSide(
                      BorderSide(
                        width: 1,
                        color: appColorGreyBorder,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        spreadRadius: 2,
                        color: appColorGreyDisableButton,
                      )
                    ],
                  ),
                  child: FocusTraversalGroup(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) => InkWell(
                        onTap: () => Navigator.of(context).pop(selectedValue),
                        child: SizedBox(
                          height: 36,
                          width: double.infinity,
                          child: ElevatedButton(
                            focusNode: focusNodes[index],
                            onFocusChange: (hasFocus) {
                              if (hasFocus) {
                                setState(() {
                                  selectedValue = widget.items[index];
                                });
                              }
                            },
                            onPressed: () =>
                                Navigator.of(context).pop(widget.items[index]),
                            style: _setButtonStyle(),
                            child: Text(widget.items[index]),
                            // child: Text(toValue(items[index])),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _setButtonStyle() {
    return ButtonStyle(
      shape: MaterialStateProperty.all(
        const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      backgroundColor: MaterialStateProperty.resolveWith(
        (states) {
          if (states.contains(MaterialState.hovered) ||
              states.contains(MaterialState.focused)) {
            return appColorPrimary20;
          }
          return Colors.white;
        },
      ),
      foregroundColor: MaterialStateProperty.resolveWith(
        (states) {
          if (states.contains(MaterialState.hovered) ||
              states.contains(MaterialState.focused)) {
            return appColorPrimary100;
          }
          return appColorGreyPrimaryText;
        },
      ),
      textStyle: MaterialStateProperty.resolveWith(
        (states) {
          if (states.contains(MaterialState.hovered) ||
              states.contains(MaterialState.focused)) {
            return TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: appColorGreyPrimaryText,
              height: 17.5 / 14,
              letterSpacing: -0.5,
            );
          }
          return TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: appColorGreyPrimaryText,
            height: 17.5 / 14,
            letterSpacing: -0.5,
          );
        },
      ),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      shadowColor: MaterialStateProperty.all(Colors.transparent),
    );
  }
}
