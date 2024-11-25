import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4278596405),
      surfaceTint: Color(4282279271),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4281226583),
      onPrimaryContainer: Color(4291688184),
      secondary: Color(4283588962),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4292339688),
      onSecondaryContainer: Color(4282207308),
      tertiary: Color(4281673539),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4283910503),
      onTertiaryContainer: Color(4294437375),
      error: Color(4290386458),
      onError: Color(4294967295),
      errorContainer: Color(4294957782),
      onErrorContainer: Color(4282449922),
      surface: Color(4294572537),
      onSurface: Color(4279901212),
      onSurfaceVariant: Color(4282468424),
      outline: Color(4285626489),
      outlineVariant: Color(4290824392),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281282865),
      inversePrimary: Color(4289056464),
      primaryFixed: Color(4290898668),
      onPrimaryFixed: Color(4278198305),
      primaryFixedDim: Color(4289056464),
      onPrimaryFixedVariant: Color(4280634703),
      secondaryFixed: Color(4292273894),
      onSecondaryFixed: Color(4279246367),
      secondaryFixedDim: Color(4290431690),
      onSecondaryFixedVariant: Color(4282075466),
      tertiaryFixed: Color(4293909503),
      onTertiaryFixed: Color(4280423984),
      tertiaryFixedDim: Color(4292001763),
      onTertiaryFixedVariant: Color(4283384158),
      surfaceDim: Color(4292532953),
      surfaceBright: Color(4294572537),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294177779),
      surfaceContainer: Color(4293848813),
      surfaceContainerHigh: Color(4293454056),
      surfaceContainerHighest: Color(4293059298),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4278596405),
      surfaceTint: Color(4282279271),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4281226583),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4281812294),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4285036408),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4281673539),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4283910503),
      onTertiaryContainer: Color(4294967295),
      error: Color(4287365129),
      onError: Color(4294967295),
      errorContainer: Color(4292490286),
      onErrorContainer: Color(4294967295),
      surface: Color(4294572537),
      onSurface: Color(4279901212),
      onSurfaceVariant: Color(4282205252),
      outline: Color(4284047457),
      outlineVariant: Color(4285824124),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281282865),
      inversePrimary: Color(4289056464),
      primaryFixed: Color(4283726717),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4282081892),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4285036408),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4283457375),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4286475918),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4284831348),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292532953),
      surfaceBright: Color(4294572537),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294177779),
      surfaceContainer: Color(4293848813),
      surfaceContainerHigh: Color(4293454056),
      surfaceContainerHighest: Color(4293059298),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4278200105),
      surfaceTint: Color(4282279271),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4280371531),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4279641381),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4281812294),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4280884280),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4283120986),
      onTertiaryContainer: Color(4294967295),
      error: Color(4283301890),
      onError: Color(4294967295),
      errorContainer: Color(4287365129),
      onErrorContainer: Color(4294967295),
      surface: Color(4294572537),
      onSurface: Color(4278190080),
      onSurfaceVariant: Color(4280165670),
      outline: Color(4282205252),
      outlineVariant: Color(4282205252),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281282865),
      inversePrimary: Color(4291491062),
      primaryFixed: Color(4280371531),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4278530612),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4281812294),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4280364848),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4283120986),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4281608003),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292532953),
      surfaceBright: Color(4294572537),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294177779),
      surfaceContainer: Color(4293848813),
      surfaceContainerHigh: Color(4293454056),
      surfaceContainerHighest: Color(4293059298),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4289056464),
      surfaceTint: Color(4289056464),
      onPrimary: Color(4278859320),
      primaryContainer: Color(4279385150),
      onPrimaryContainer: Color(4289056464),
      secondary: Color(4290431690),
      onSecondary: Color(4280628020),
      secondaryContainer: Color(4281614915),
      onSecondaryContainer: Color(4291352792),
      tertiary: Color(4292001763),
      onTertiary: Color(4281871175),
      tertiaryContainer: Color(4282265933),
      onTertiaryContainer: Color(4292067556),
      error: Color(4294948011),
      onError: Color(4285071365),
      errorContainer: Color(4287823882),
      onErrorContainer: Color(4294957782),
      surface: Color(4279374868),
      onSurface: Color(4293059298),
      onSurfaceVariant: Color(4290824392),
      outline: Color(4287271570),
      outlineVariant: Color(4282468424),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293059298),
      inversePrimary: Color(4282279271),
      primaryFixed: Color(4290898668),
      onPrimaryFixed: Color(4278198305),
      primaryFixedDim: Color(4289056464),
      onPrimaryFixedVariant: Color(4280634703),
      secondaryFixed: Color(4292273894),
      onSecondaryFixed: Color(4279246367),
      secondaryFixedDim: Color(4290431690),
      onSecondaryFixedVariant: Color(4282075466),
      tertiaryFixed: Color(4293909503),
      onTertiaryFixed: Color(4280423984),
      tertiaryFixedDim: Color(4292001763),
      onTertiaryFixedVariant: Color(4283384158),
      surfaceDim: Color(4279374868),
      surfaceBright: Color(4281874745),
      surfaceContainerLowest: Color(4278980367),
      surfaceContainerLow: Color(4279901212),
      surfaceContainer: Color(4280164384),
      surfaceContainerHigh: Color(4280822314),
      surfaceContainerHighest: Color(4281546037),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4289319636),
      surfaceTint: Color(4289056464),
      onPrimary: Color(4278196763),
      primaryContainer: Color(4285569178),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4290694862),
      onSecondary: Color(4278851865),
      secondaryContainer: Color(4286878868),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4292330471),
      onTertiary: Color(4280094763),
      tertiaryContainer: Color(4288383659),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294949553),
      onError: Color(4281794561),
      errorContainer: Color(4294923337),
      onErrorContainer: Color(4278190080),
      surface: Color(4279374868),
      onSurface: Color(4294704122),
      onSurfaceVariant: Color(4291153100),
      outline: Color(4288521380),
      outlineVariant: Color(4286416261),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293059298),
      inversePrimary: Color(4280766032),
      primaryFixed: Color(4290898668),
      onPrimaryFixed: Color(4278195221),
      primaryFixedDim: Color(4289056464),
      onPrimaryFixedVariant: Color(4279385150),
      secondaryFixed: Color(4292273894),
      onSecondaryFixed: Color(4278522644),
      secondaryFixedDim: Color(4290431690),
      onSecondaryFixedVariant: Color(4280957241),
      tertiaryFixed: Color(4293909503),
      onTertiaryFixed: Color(4279700261),
      tertiaryFixedDim: Color(4292001763),
      onTertiaryFixedVariant: Color(4282265677),
      surfaceDim: Color(4279374868),
      surfaceBright: Color(4281874745),
      surfaceContainerLowest: Color(4278980367),
      surfaceContainerLow: Color(4279901212),
      surfaceContainer: Color(4280164384),
      surfaceContainerHigh: Color(4280822314),
      surfaceContainerHighest: Color(4281546037),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4293656319),
      surfaceTint: Color(4289056464),
      onPrimary: Color(4278190080),
      primaryContainer: Color(4289319636),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4293852926),
      onSecondary: Color(4278190080),
      secondaryContainer: Color(4290694862),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4294965756),
      onTertiary: Color(4278190080),
      tertiaryContainer: Color(4292330471),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294965753),
      onError: Color(4278190080),
      errorContainer: Color(4294949553),
      onErrorContainer: Color(4278190080),
      surface: Color(4279374868),
      onSurface: Color(4294967295),
      onSurfaceVariant: Color(4294311164),
      outline: Color(4291153100),
      outlineVariant: Color(4291153100),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4293059298),
      inversePrimary: Color(4278267697),
      primaryFixed: Color(4291162096),
      onPrimaryFixed: Color(4278190080),
      primaryFixedDim: Color(4289319636),
      onPrimaryFixedVariant: Color(4278196763),
      secondaryFixed: Color(4292537066),
      onSecondaryFixed: Color(4278190080),
      secondaryFixedDim: Color(4290694862),
      onSecondaryFixedVariant: Color(4278851865),
      tertiaryFixed: Color(4294107391),
      onTertiaryFixed: Color(4278190080),
      tertiaryFixedDim: Color(4292330471),
      onTertiaryFixedVariant: Color(4280094763),
      surfaceDim: Color(4279374868),
      surfaceBright: Color(4281874745),
      surfaceContainerLowest: Color(4278980367),
      surfaceContainerLow: Color(4279901212),
      surfaceContainer: Color(4280164384),
      surfaceContainerHigh: Color(4280822314),
      surfaceContainerHighest: Color(4281546037),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
