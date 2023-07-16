import 'package:flutter/material.dart';

class PlutoScaledCheckbox extends StatelessWidget {
  final bool? value;

  final Function(bool? changed) handleOnChanged;

  final bool tristate;

  final double scale;

  final Color unselectedColor;

  final Color? activeColor;

  final Color checkColor;

  const PlutoScaledCheckbox({
    Key? key,
    required this.value,
    required this.handleOnChanged,
    this.tristate = false,
    this.scale = 1.0,
    this.unselectedColor = Colors.black26,
    this.activeColor = Colors.lightBlue,
    this.checkColor = const Color(0xFFDCF5FF),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Theme(
        data: ThemeData(
          unselectedWidgetColor: unselectedColor,
        ),
        child: Checkbox(
          value: value,
          tristate: tristate,
          onChanged: handleOnChanged,
          activeColor: value == null ? unselectedColor : activeColor,
          checkColor: checkColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}

class PlutoCustomCheckbox extends StatelessWidget {
  final bool? value;
  final Function(bool? changed) handleOnChanged;
  final bool tristate;
  final double scale;
  final Color unselectedColor;
  final Color? activeColor;
  final Color checkColor;
  final Widget? customCheckboxIcon;
  final double? containerWidth;
  final double? containerHeight;

  const PlutoCustomCheckbox({
    Key? key,
    required this.value,
    required this.handleOnChanged,
    this.tristate = false,
    this.scale = 1.0,
    this.unselectedColor = const Color(0xffc7d0dc),
    this.activeColor = Colors.lightBlue,
    this.checkColor = const Color(0xFFDCF5FF),
    this.customCheckboxIcon,
    this.containerWidth = 16,
    this.containerHeight = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Theme(
        data: ThemeData(
          unselectedWidgetColor: unselectedColor,
        ),
        child: tristate
            ? Checkbox(
                value: value,
                tristate: tristate,
                onChanged: handleOnChanged,
                activeColor: value == null ? unselectedColor : activeColor,
                checkColor: checkColor,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: unselectedColor, width: 1),
                    borderRadius: BorderRadius.circular(4)),
              )
            : _CustomCheckbox(
                containerWidth: containerWidth,
                containerHeight: containerHeight,
                isChecked: value,
                onChanged: handleOnChanged,
                customCheckboxIcon: customCheckboxIcon,
              ),
      ),
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  final bool? isChecked;
  final void Function(bool value)? onChanged;
  final double radius;
  final Widget? customCheckboxIcon;
  final double? containerWidth;
  final double? containerHeight;

  const _CustomCheckbox({
    Key? key,
    required this.isChecked,
    required this.onChanged,
    this.radius = 4,
    this.customCheckboxIcon,
    this.containerWidth,
    this.containerHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color appColorGreyBorder = const Color(0xffc7d0dc);
    Color appColorPrimary100 = const Color(0xff0078ff);

    if (onChanged == null || isChecked == null) {
      return InkWell(
        onTap: () => onChanged!(isChecked ?? false),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: containerWidth,
                  height: containerHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(radius)),
                    border: Border.fromBorderSide(
                      BorderSide(
                        width: 1,
                        color: appColorGreyBorder,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => onChanged!(!isChecked!),
      child: Row(
        /// Cell Selecting 영역 셀 전체로 확장
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            /// Cell Selecting 영역 셀 전체로 확장
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: containerWidth,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: isChecked! ? appColorPrimary100 : Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(radius),
                  ),
                  border: isChecked!
                      ? null
                      : Border.fromBorderSide(
                          BorderSide(
                            width: 1,
                            color: appColorGreyBorder,
                          ),
                        ),
                ),
                alignment: Alignment.center,
                child: isChecked! ? customCheckboxIcon : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
