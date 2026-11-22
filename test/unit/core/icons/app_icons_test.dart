import 'package:flutter_clean_architecture_riverpod/core/icons/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remixicon/remixicon.dart';

void main() {
  test('remix and material icons stay on their own fonts', () {
    const icon = Icon(AppIcons.dashboard);

    expect(icon.icon, AppIcons.dashboard);
    expect(AppIcons.dashboard, RemixIcons.dashboard_line);
    expect(AppIcons.layout, RemixIcons.layout_line);
    expect(AppIcons.menu, RemixIcons.menu_line);
    expect(AppIcons.layers, RemixIcons.stack_line);
    expect(AppIcons.darkMode, RemixIcons.moon_line);
    expect(AppIcons.lightMode, RemixIcons.sun_line);
    expect(AppIcons.systemMode, RemixIcons.contrast_2_line);
    expect(AppIcons.dashboard.fontPackage, 'remixicon');

    expect(AppIcons.close, Icons.close);
    expect(AppIcons.arrowBack, Icons.arrow_back);
    expect(AppIcons.add, Icons.add);
    expect(AppIcons.search, Icons.search);
    expect(AppIcons.check, Icons.check);
    expect(AppIcons.close.fontPackage, isNull);
  });
}
