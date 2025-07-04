{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at https://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2006-2021, Peter Johnson (gravatar.com/delphidabbler).
 *
 * Static method record that assists in generating CSS properties.
}


unit UCSSUtils;


interface


uses
  // Delphi
  Graphics;


type
  ///  <summary>Enumeration of values of CSS font-weight property.</summary>
  TCSSFontWeight = (
    cfwNormal,                              // absolute: normal (same as cfw400)
    cfwBold,                                // absolute: bold (same as cfw700)
    cfwBolder,                              // relative: heavier than current
    cfwLighter,                             // relative: lighter than current
    cfw100, cfw200, cfw300, cfw400,         // ordered sequence of weights
    cfw500, cfw600, cfw700, cfw800, cfw900  // .. each heavier than predecessor
  );

type
  ///  <summary>Enumeration of values of CSS font-style property.</summary>
  TCSSFontStyle = (
    cfsNormal,        // normal, upright, font
    cfsItalic,        // uses font labelled "italic" or failing that "oblique"
    cfsOblique        // uses font labelled "oblique"
  );

type
  ///  <summary>Enumeration of values of CSS text-decoration property.</summary>
  ///  <remarks>Property takes a combination of one or more of these values.
  ///  </remarks>
  TCSSTextDecoration = (
    ctdNone,          // no decoration
    ctdUnderline,     // text is underlines
    ctdOverline,      // text has overline
    ctdLineThrough,   // text is stirck through
    ctdBlink          // text is blinking
  );

type
  ///  <summary>Set of values of CSS text-decoration property.</summary>
  TCSSTextDecorations = set of TCSSTextDecoration;

type
  ///  <summary>Enumeration of generic font families recognised by CSS
  ///  font-family property.</summary>
  TCSSFontGeneric = (
    cfgDontCare,      // no generic family specified
    cfgSerif,         // serif font (e.g. Times New Roman)
    cfgSansSerif,     // sans-serif font (e.g. Arial)
    cfgCursive,       // scripting font
    cfgFantasy,       // decorative font
    cfgMonoSpace      // fixed pitch font
  );

type
  ///  <summary>Enumeration of border styles used in the CSS border property and
  ///  its derivatives.</summary>
  TCSSBorderStyle = (
    cbsNone,          // no border
    cbsDotted,        // dotted line border
    cbsDashed,        // dashed line border
    cbsSolid,         // solid line border
    cbsDouble,        // double line border
    cbsGroove,        // 3D groove: colours based on color property
    cbsRidge,         // 3D ridge: colours based on color property
    cbsInset,         // 3D inset: colours based on color property
    cbsOutset         // 3D outset: colours based on color property
  );

type
  ///  <summary>Enumeration of values of CSS text-align property.</summary>
  TCSSTextAlign = (
    ctaLeft,          // text is left aligned: ragged right margin
    ctaRight,         // text is right aligned: ragged left margin
    ctaCenter,        // text is centred
    ctaJustify        // text is justified flush with right and left margins
  );

type
  ///  <summary>Enumeration of values of CSS vertical-align property.</summary>
  TCSSVerticalAlign = (
    cvaBaseline,      // align element baseline with parent's baseline
    cvaSub,           // subscript the element
    cvaSuper,         // superscript the element
    cvaTop,           // align top of element with tallest element on line
    cvaTextTop,       // align top of element with top of parent's font
    cvaMiddle,        // align vertical middle with baseline + 1/2 parent height
    cvaBottom,        // align bottom of element with lowest element on line
    cvaTextBottom     // align bottom of element with bottom of parent's font
  );

type
  ///  <summary>Enumeration of sides that apply to various CSS properties that
  ///  apply to an element's bounding box.</summary>
  ///  <remarks>Used to specify a variant of a property, e.g. padding-top.
  ///  </remarks>
  TCSSSide = (
    cssAll,           // refers to all sides of an element
    cssTop,           // top of element
    cssLeft,          // left of element
    cssBottom,        // bottom of element
    cssRight          // right of element
  );

type
  ///  <summary>Enumeration of display styles used in CSS display property.
  ///  </summary>
  TCSSDisplayStyle = (
    cdsNone,          // element not displayed
    cdsBlock,         // element displayed as a block
    cdsInline         // element displayed inline
  );

type
  ///  <summary>Enumeration of units that apply to measurements of length used
  ///  in CSS.</summary>
  TCSSLengthUnit = (
    cluAuto,          // "auto"
    cluPixels,        // pixels
    cluEm,            // "em" values
    cluPercent        // percentage values
  );

type
  ///  <summary>Enumeration of CSS overflow property values.</summary>
  TCSSOverflowValue = (
    covVisible,     // overflow is not clipped and overflows
    covHidden,      // overflow is clipped, rest of the content invisible
    covScroll,      // overflow is clipped, scroll-bar is added
    covAuto,        // if overflow is clipped a scroll-bar is added
    covInherit      // value inherited from the parent element
  );

type
  ///  <summary>Enumeration of different directions of overflow to be controlled
  ///  by an "overflow" property.</summary>
  TCSSOverflowDirection = (
    codBoth,        // overflow in both directions: "overflow" property
    codX,           // overflow in x direction only: "overflow-x" property
    codY            // overflow in y direction only: "overflow-y" property
  );

type
  ///  <summary>Enumeration of different list markers.</summary>
  ///  <remarks>This is not a complete list. Additional values are defined in
  ///  CSS.</remarks>
  TCSSListStyleType = (
    clstNone,       // no marker
    clstInitial,    // default marker
    clstInherit,    // inherit from parent
    clstDisc,       // filled circle
    clstCircle,     // un-filled circle
    clstSquare,     // filled square
    clstDecimal,    // decimal number (1, 2, 3...)
    clstDecimal0,   // decimal number padding with leading zeros (01, 02, 03...)
    clstLowerRoman, // lower case roman numeral (i, ii, iii, iv...)
    clstUpperRoman, // upper case roman numeral (I, II, III, IV...)
    clstLowerAlpha, // lower case letter (a, b, c, d...)
    clstUpperAlpha  // upper case letter (A, B, C, D...)
  );

type
  ///  <summary>Enumeration of possible list item markers.</summary>
  TCSSListStylePosition = (
    clspOutside,    // list marker outside the list item
    clspInside      // list marker inside the list item
  );

type
  ///  <summary>
  ///  Container for static methods that return CSS properties as text.
  ///  </summary>
  TCSS = record
  strict private
    ///  <summary>Converts a Delphi TColor to a CSS compatible colour string.
    ///  </summary>
    ///  <param name="Color">TColor [in] Colour to map to CSS colour.</param>
    ///  <returns>string. CSS code for Color.</returns>
    ///  <remarks>Any system colors (like clBtnFace) are mapped to the actual
    ///  colour according to the current Windows settings.</remarks>
    class function ColorToCSS(const Color: TColor): string; static;

    ///  <summary>Gets the text representing the given unit of length.</summary>
    ///  <param name="LU">TCSSLengthUnit [in] Required length unit.</param>
    ///  <returns>string. Required length unit as text.</returns>
    class function LengthUnit(const LU: TCSSLengthUnit): string; static;

    ///  <summary>Builds a space separated list of lengths using the specified
    ///  unit.</summary>
    ///  <param name="List"><c>array of Single</c> [in] List of lengths.</param>
    ///  <param name="LU"><c>TCSSLengthUnit</c> [in] Specifies length unit to
    ///  apply to each length.</param>
    ///  <returns><c>string</c>. Required spaced separated list.</returns>
    ///  <remarks>Note that lengths are rounded to a maximum of 2 decimal
    ///  places.</remarks>
    class function LengthList(const List: array of Single;
      const LU: TCSSLengthUnit = cluPixels): string; static;

    ///  <summary>Creates a CSS "margin" property.</summary>
    ///  <param name="Margin"><c>array of Single</c> [in] Array of margin
    ///  widths. Must contain either 1, 2 or 4 values.</param>
    ///  <param name="LU"><c>TCSSLengthUnit</c> [in] Optional length unit to use
    ///  for each margin width. Defaults to <c>cluPixels</c>.</param>
    ///  <returns><c>string</c>. Required CSS property.</returns>
    ///  <remarks>Note that margin values are rounded to a maximum of 2 decimal
    ///  places.</remarks>
    class function MarginProp(const Margin: array of Single;
      const LU: TCSSLengthUnit = cluPixels): string; overload; static;

    ///  <summary>Creates a CSS "padding" property.</summary>
    ///  <param name="Padding"><c>array of Single</c> [in] Array of padding
    ///  widths. Must contain either 1, 2 or 4 values.</param>
    ///  <param name="LU"><c>TCSSLengthUnit</c> [in] Optional length unit to use
    ///  for each padding width. Defaults to <c>cluPixels</c>.</param>
    ///  <returns><c>string</c>. Required CSS property.</returns>
    ///  <remarks>Note that padding values are rounded to a maximum of 2 decimal
    ///  places.</remarks>
    class function PaddingProp(const Padding: array of Single;
      const LU: TCSSLengthUnit = cluPixels): string; overload; static;

  public
    ///  <summary>Creates a CSS "color" property.</summary>
    ///  <param name="Color">TColor [in] Desired foreground colour.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function ColorProp(const Color: TColor): string; static;

    ///  <summary>Creates a CSS "background color" property.</summary>
    ///  <param name="Color">TColor [in] Desired background colour.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function BackgroundColorProp(const Color: TColor): string; static;

    ///  <summary>Creates a string of CSS properties that fully describe a font.
    ///  </summary>
    ///  <param name="Font">TFont [in] Font for which properties are required.
    ///  </param>
    ///  <returns>string. Space separated list of required CSS properties.
    ///  </returns>
    class function FontProps(const Font: TFont): string; static;

    ///  <summary>Creates a CSS "font-family" property for a named font and a
    ///  generic font type.</summary>
    ///  <param name="FontName">string [in] Name of required font.</param>
    ///  <param name="Generic">TCSSFontGeneric [in] Generic font family to use
    ///  if font not available. Ignored if Generic=cfgDontCare.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function FontFamilyProp(const FontName: string;
      const Generic: TCSSFontGeneric): string; static;

    ///  <summary>Creates a CSS "font-size" property for a font sized in points.
    ///  </summary>
    ///  <param name="PtSize">Cardinal [in] Font's point size.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function FontSizeProp(const PtSize: Cardinal): string; static;

    ///  <summary>Creates a CSS "font-style" property.</summary>
    ///  <param name="FS">TCSSFontStyle [in] Required font style.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function FontStyleProp(const FS: TCSSFontStyle): string; overload;
      static;

    ///  <summary>Creates a CSS "font-style" property.</summary>
    ///  <param name="FS">TFontStyles [in] Set of font styles. If set contains
    ///  fsItalic the "italic" style it is used, otherwise "normal" style is
    ///  used.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function FontStyleProp(const FS: TFontStyles): string; overload;
      static;

    ///  <summary>Creates a CSS "font-weight" property.</summary>
    ///  <param name="FW">TCSSFontWeight [in] Required font weight.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function FontWeightProp(const FW: TCSSFontWeight): string; overload;
      static;

    ///  <summary>Creates a CSS "font-weight" property.</summary>
    ///  <param name="FS">TFontStyles [in] Set of font styles. If set contains
    ///  fsBold then "bold" weight is used, otherwise "normal" weight is used.
    ///  </param>
    ///  <returns>string. Required CSS property.</returns>
    class function FontWeightProp(const FS: TFontStyles): string; overload;
      static;
      {Creates a CSS "font-weight" property from set of styles.
        @param FS [in] Set of font styles.
        @return Required property.
      }

    ///  <summary>Creates CSS "border" or "border-xxx" property (where "xxx"
    ///  denotes a side).</summary>
    ///  <param name="Side">TCSSSide [in] Specifies side(s) of element where
    ///  border is to be drawn.</param>
    ///  <param name="WidthPx">Cardinal [in] Width of border in pixels. Value of
    ///  0 hides border.</param>
    ///  <param name="Style">TCSSBorderStyle [in] Border style. Value of cbsNone
    ///  hides border.</param>
    ///  <param name="Color">TColor [in] Border colour. Value of clNone hides
    ///  border.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function BorderProp(const Side: TCSSSide; const WidthPx: Cardinal;
      const Style: TCSSBorderStyle; const Color: TColor): string; static;

    ///  <summary>Creates CSS "border" or "border-xxx" property (where "xxx"
    ///  denotes a side) which hides any existing border.</summary>
    ///  <param name="Side">TCSSSide [in] Specifies side(s) of element where
    ///  border is to be hidden.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function HideBorderProp(const Side: TCSSSide): string; static;

    ///  <summary>Creates CSS "margin" property with same width on all edges.
    ///  </summary>
    ///  <param name="Margin"><c>Single</c> [in] Margin width.</param>
    ///  <param name="LU"><c>TCSSLengthUnit</c> [in] Optional length unit to use
    ///  for the margin width. Defaults to <c>cluPixels</c>.</param>
    ///  <returns><c>string</c>. Required CSS property.</returns>
    ///  <remarks>Note that the margin value is rounded to a maximum of 2
    ///  decimal places.</remarks>
    class function MarginProp(const Margin: Single;
      const LU: TCSSLengthUnit = cluPixels): string; overload; static;

    ///  <summary>Creates CSS "margin" property with potentially different
    ///  margin widths on each side.</summary>
    ///  <param name="Top"><c>Single</c> [in] Top margin.</param>
    ///  <param name="Right"><c>Single</c> [in] Right margin.</param>
    ///  <param name="Bottom"><c>Single</c> [in] Bottom margin.</param>
    ///  <param name="Left"><c>Single</c> [in] Left margin.</param>
    ///  <param name="LU"><c>TCSSLengthUnit</c> [in] Optional length unit to use
    ///  for each margin width. Defaults to <c>cluPixels</c>.</param>
    ///  <returns><c>string</c>. Required CSS property.</returns>
    ///  <remarks>Note that margin values are rounded to a maximum of 2 decimal
    ///  places.</remarks>
    class function MarginProp(const Top, Right, Bottom, Left: Single;
      const LU: TCSSLengthUnit = cluPixels): string; overload; static;

    ///  <summary>Creates CSS "margin" or "margin-xxx" property (where "xxx" is
    ///  a side).</summary>
    ///  <param name="Side"><c>TCSSSide</c> [in] Specifies the side(s) of the
    ///  element whose margin is to be set.</param>
    ///  <param name="Margin"><c>Single</c> [in] Width of margin in pixels.</param>
    ///  <returns><c>string</c>. Required CSS property.</returns>
    ///  <remarks>Note that the margin is rounded to a maximum of 2 decimal
    ///  places.</remarks>
    class function MarginProp(const Side: TCSSSide; const Margin: Single;
      const LU: TCSSLengthUnit = cluPixels): string; overload; static;

    ///  <summary>Creates CSS "padding" property with same width on all sides.
    ///  </summary>
    ///  <param name="Padding"><c>Single</c> [in] Padding width.</param>
    ///  <param name="LU"><c>TCSSLengthUnit</c> [in] Optional length unit to use
    ///  for the padding width. Defaults to <c>cluPixels</c>.</param>
    ///  <returns><c>string</c>. Required CSS property.</returns>
    ///  <remarks>Note that the padding value is rounded to a maximum of 2
    ///  decimal places.</remarks>
    class function PaddingProp(const Padding: Single;
      const LU: TCSSLengthUnit = cluPixels): string; overload; static;

    ///  <summary>Creates CSS "padding" property with potentially different
    ///  padding widths on each side.</summary>
    ///  <param name="Top"><c>Single</c> [in] Top margin.</param>
    ///  <param name="Right"><c>Single</c> [in] Right margin.</param>
    ///  <param name="Bottom"><c>Single</c> [in] Bottom margin.</param>
    ///  <param name="Left"><c>Single</c> [in] Left margin.</param>
    ///  <param name="LU"><c>TCSSLengthUnit</c> [in] Optional length unit to use
    ///  for each padding width. Defaults to <c>cluPixels</c>.</param>
    ///  <returns><c>string</c>. Required CSS property.</returns>
    ///  <remarks>Note that padding values are rounded to a maximum of 2 decimal
    ///  places.</remarks>
    class function PaddingProp(const Top, Right, Bottom, Left: Single;
      const LU: TCSSLengthUnit = cluPixels): string; overload; static;

    ///  <summary>Creates CSS "padding" or "padding-xxx" property (where "xxx"
    ///  is a side).</summary>
    ///  <param name="Side"><c>TCSSSide</c> [in] Specifies side(s) of element
    ///  whose padding is to be set.</param>
    ///  <param name="Padding"><c>Single</c> [in] Width of padding.</param>
    ///  <param name="LU"><c>TCSSLengthUnit</c> [in] Optional length unit to use
    ///  for the padding width. Defaults to <c>cluPixels</c>.</param>
    ///  <returns><c>string</c>. Required CSS property.</returns>
    ///  <remarks>Note that the padding value is rounded to a maximum of 2
    ///  decimal places.</remarks>
    class function PaddingProp(const Side: TCSSSide; const Padding: Single;
      const LU: TCSSLengthUnit = cluPixels): string; overload; static;

    ///  <summary>Creates a CSS "text-decoration" property.</summary>
    ///  <returns>string. Required CSS property.</returns>
    ///  <param name="Decorations">TCSSTextDecorations [in] Set of decorations
    ///  to include in property. Can either be [ctdNone], empty set, or any
    ///  combination of other ctdXXX values. Empty set is equivalent to
    ///  [ctdNone].</param>
    ///  <returns>string. Required CSS property.</returns>
    class function TextDecorationProp(Decorations: TCSSTextDecorations): string;
      overload; static;

    ///  <summary>Creates a CSS "text-decoration" property.</summary>
    ///  <returns>string. Required CSS property.</returns>
    ///  <param name="FS">TFontStyles [in] Set of font styles. If set contains
    ///  fsStrikeOut or fsUnderline appropriate "line-through" and/or
    ///  "underline" decoration is used, otherwise "none" is used.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function TextDecorationProp(const FS: TFontStyles): string; overload;
      static;

    ///  <summary>Creates a CSS "text-align" property.</summary>
    ///  <param name="TA">TCSSTextAlign [in] Required text alignment.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function TextAlignProp(const TA: TCSSTextAlign): string; static;

    ///  <summary>Creates a CSS "vertical-align" property.</summary>
    ///  <param name="VA">TCSSVerticalAlign [in] Required vertical alignment.
    ///  </param>
    ///  <returns>string. Required CSS property.</returns>
    class function VerticalAlignProp(const VA: TCSSVerticalAlign): string;
      static;

    ///  <summary>Creates a CSS "max-height" property.</summary>
    ///  <param name="HeightPx">Integer [in] Required height in pixels.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function MaxHeightProp(const HeightPx: Integer): string; static;

    ///  <summary>Creates a CSS "height" property.</summary>
    ///  <param name="HeightPx">Integer [in] Required height in pixels.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function HeightProp(const HeightPx: Integer): string; static;

    ///  <summary>Creates a CSS "width" property.</summary>
    ///  <param name="WidthPx">Integer [in] Required width in pixels.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function WidthProp(const WidthPx: Integer): string; overload; static;

    ///  <summary>Creates a CSS "width" property.</summary>
    ///  <param name="LengthUnit">TCSSLengthUnit [in] Units used to specify
    ///  width. If cltAuto then Width is ignored.</param>
    ///  <param name="Width">Integer [in] Required width in specified units.
    ///  </param>
    ///  <returns>string. Required CSS property.</returns>
    class function WidthProp(const LengthUnit: TCSSLengthUnit;
      const Width: Integer): string; overload; static;

    ///  <summary>Creates a CSS "display" property.</summary>
    ///  <param name="Style">TCSSDisplayStyle [in] Required display style.
    ///  </param>
    ///  <returns>string. Required CSS property.</returns>
    class function DisplayProp(const Style: TCSSDisplayStyle): string; static;

    ///  <summary>Creates a CSS "display" property that causes its element to be
    ///  either hidden or displayed as a "block".</summary>
    ///  <param name="Show">Boolean [in] Flag indicating if block is to be
    ///  displayed (True) or hidden (False).</param>
    ///  <returns>string. Required CSS property.</returns>
    class function BlockDisplayProp(const Show: Boolean): string; static;

    ///  <summary>Creates a CSS "display" property that causes its element to be
    ///  either hidden or displayed as "inline".</summary>
    ///  <param name="Show">Boolean [in] Flag indicating if block is to be
    ///  displayed (True) or hidden (False).</param>
    ///  <returns>string. Required CSS property.</returns>
    class function InlineDisplayProp(const Show: Boolean): string; static;

    ///  <summary>Creates a CSS "overflow", "overflow-x" or overflow-y"
    ///  property.</summary>
    ///  <param name="Value">TCSSOverflowValue [in] Required overflow handling.
    ///  </param>
    ///  <param name="Direction">TCSSOverflowDirection [in] "Direction" for
    ///  which overflow is being set. Determines whether an "overflow"
    ///  (codBoth), "overflow-x" (codX) or "overflow-y" (codY) property is
    ///  created.</param>
    ///  <returns>string. Required CSS property.</returns>
    class function OverflowProp(const Value: TCSSOverflowValue;
      const Direction: TCSSOverflowDirection = codBoth): string; static;

    ///  <summary>Creates a CSS "line-height" property.</summary>
    ///  <param name="Percentage">UInt16 [in] Line height as a percentage of
    ///  font size.</param>
    ///  <returns>string. Required CSS property.</returns>
    ///  <remarks>Only the percentage version of line height is supported.
    ///  </remarks>
    class function LineHeightProp(const Percentage: UInt16): string; static;

    ///  <summary>Creates a CSS "list-style-type" property.</summary>
    ///  <param name="Value">TCSSListStyleType [in] Required property value.
    ///  </param>
    ///  <returns>string. Required CSS property.</returns>
    class function ListStyleTypeProp(const Value: TCSSListStyleType): string;
      static;

    ///  <summary>Creates a CSS "list-style-position" property.</summary>
    ///  <param name="Value">TCSSListStylePosition [in] Required property value.
    ///  </param>
    ///  <returns>string. Required CSS property.</returns>
    class function ListStylePositionProp(const Value: TCSSListStylePosition):
      string; static;
  end;


implementation


uses
  // Delphi
  SysUtils, Windows, Math,
  // Project
  UIStringList, UStrUtils;


{ TCSS }

class function TCSS.BackgroundColorProp(const Color: TColor): string;
begin
  Result := Format('background-color: %s;', [ColorToCSS(Color)]);
end;

class function TCSS.BlockDisplayProp(const Show: Boolean): string;
const
  // Map of flag onto required display style
  BlockDisplayStyles: array[Boolean] of TCSSDisplayStyle = (cdsNone, cdsBlock);
begin
  Result := DisplayProp(BlockDisplayStyles[Show]);
end;

class function TCSS.BorderProp(const Side: TCSSSide; const WidthPx: Cardinal;
  const Style: TCSSBorderStyle; const Color: TColor): string;
const
  // Map of element sides to associated border properties
  BorderSides: array[TCSSSide] of string = (
    'border', 'border-top', 'border-left', 'border-bottom', 'border-right'
  );
  // Map of border styles to property values
  BorderStyles: array[TCSSBorderStyle] of string = (
    'none', 'dotted', 'dashed', 'solid', 'double',
    'groove', 'ridge', 'inset', 'outset'
  );
begin
  if (WidthPx > 0) and (Style <> cbsNone) and (Color <> clNone) then
    // Displaying border
    Result := Format(
      '%s: %s %s %s;',
      [BorderSides[Side], ColorToCSS(Color), BorderStyles[Style],
      LengthList([WidthPx])]
    )
  else
    // Hiding border
    Result := Format('%s: %s;', [BorderSides[Side], LengthList([0])]);
end;

class function TCSS.ColorProp(const Color: TColor): string;
begin
  Result := Format('color: %s;', [ColorToCSS(Color)]);
end;

class function TCSS.ColorToCSS(const Color: TColor): string;
var
  ColorRGB: Integer;  // RGB code for the colour
begin
  ColorRGB := ColorToRGB(Color);  // this translates system colours to actual
  Result := Format(
    '#%0.2X%0.2X%0.2X',
    [GetRValue(ColorRGB), GetGValue(ColorRGB), GetBValue(ColorRGB)]
  );
end;

class function TCSS.DisplayProp(const Style: TCSSDisplayStyle): string;
const
  // Map of display ids to associated property values
  DisplayStyles: array[TCSSDisplayStyle] of string = (
    'none', 'block', 'inline'
  );
begin
  Result := Format('display: %s;', [DisplayStyles[Style]]);
end;

class function TCSS.FontFamilyProp(const FontName: string;
  const Generic: TCSSFontGeneric): string;
const
  // Map of generic font families to font names
  Generics: array[TCSSFontGeneric] of string = (
    '', 'serif', 'sans-serif', 'cursive', 'fantasy', 'monospace'
  );
var
  Names: IStringList;   // used to build list of font names
begin
  Names := TIStringList.Create;
  Names.Add(StrQuoteSpaced(FontName));
  if Generic <> cfgDontCare then
    Names.Add(StrQuoteSpaced(Generics[Generic]));
  // Generate property
  Result := Format('font-family: %s;', [Names.GetText(', ', False)]);
end;

class function TCSS.FontProps(const Font: TFont): string;
var
  PropList: IStringList;  // list of font properties
begin
  PropList := TIStringList.Create(
    [
      FontFamilyProp(Font.Name, cfgDontCare),
      FontSizeProp(Font.Size),
      FontWeightProp(Font.Style),
      FontStyleProp(Font.Style),
      TCSS.TextDecorationProp(Font.Style),
      ColorProp(Font.Color)
    ]
  );
  Result := PropList.GetText(' ', False);
end;

class function TCSS.FontSizeProp(const PtSize: Cardinal): string;
begin
  Result := Format('font-size: %dpt;', [PtSize]);
end;

class function TCSS.FontStyleProp(const FS: TCSSFontStyle): string;
const
  // Maps font style to property value
  FontStyles: array[TCSSFontStyle] of string = ('normal', 'italic', 'oblique');
begin
  Result := Format('font-style: %s;', [FontStyles[FS]]);
end;

class function TCSS.FontStyleProp(const FS: TFontStyles): string;
begin
  if fsItalic in FS then
    Result := FontStyleProp(cfsItalic)
  else
    Result := FontStyleProp(cfsNormal);
end;

class function TCSS.FontWeightProp(const FW: TCSSFontWeight): string;
const
  // Map of font weights to property values
  FontWeights: array[TCSSFontWeight] of string = (
    'normal', 'bold', 'bolder', 'lighter',
    '100', '200', '300', '400', '500', '600', '700', '800', '900'
  );
begin
  Result := Format('font-weight: %s;', [FontWeights[FW]]);
end;

class function TCSS.FontWeightProp(const FS: TFontStyles): string;
begin
  if fsBold in FS then
    Result := FontWeightProp(cfwBold)
  else
    Result := FontWeightProp(cfwNormal);
end;

class function TCSS.HeightProp(const HeightPx: Integer): string;
begin
  Result := Format('height: %s;', [LengthList([HeightPx])]);
end;

class function TCSS.HideBorderProp(const Side: TCSSSide): string;
begin
  Result := BorderProp(Side, 0, cbsNone, clNone);
end;

class function TCSS.InlineDisplayProp(const Show: Boolean): string;
const
  // Map of flag onto required display style
  BlockDisplayStyles: array[Boolean] of TCSSDisplayStyle = (cdsNone, cdsInline);
begin
  Result := DisplayProp(BlockDisplayStyles[Show]);
end;

class function TCSS.LengthList(const List: array of Single;
  const LU: TCSSLengthUnit): string;

  function FmtLength(const L: Single): string;
  var
    NumX100: Int64;
    WholePart, DecPart: Int64;
  begin
    Assert(not (L < 0), 'TCSS.LengthList: Length < 0'); // avoiding using >=
    NumX100 := Round(Abs(L) * 100);
    WholePart := NumX100 div 100;
    DecPart := NumX100 mod 100;
    Result := IntToStr(WholePart);
    if DecPart <> 0 then
    begin
      Result := Result + '.'; // TODO: check CSS spec re localisation of '.'
      if DecPart mod 10 = 0 then
        Result := Result + IntToStr(DecPart div 10)
      else
        Result := Result + IntToStr(DecPart);
    end;
  end;

var
  Idx: Integer;     // loops thru list of values
  ALength: Single;  // a length from list
begin
  Assert((LU <> cluAuto) or (Length(List) = 1),
    'TCSS.LengthList: List size may only be 1 when length type is cltAuto');
  if LU = cluAuto then
    Result := LengthUnit(LU)
  else
  begin
    Result := '';
    for Idx := Low(List) to High(List) do
    begin
      ALength := List[Idx];
      if Result <> '' then
        Result := Result + ' ';
      Result := Result + FmtLength(ALength);
      if ALength <> 0 then
        Result := Result + LengthUnit(LU);  // only add unit if length not 0
    end;
  end;
end;

class function TCSS.LengthUnit(const LU: TCSSLengthUnit): string;
const
  Units: array[TCSSLengthUnit] of string = (
    'auto', 'px', 'em', '%'
  );
begin
  Result := Units[LU];
end;

class function TCSS.LineHeightProp(const Percentage: UInt16): string;
begin
  Result := 'line-height: ' + IntToStr(Percentage) + '%';
end;

class function TCSS.ListStylePositionProp(
  const Value: TCSSListStylePosition): string;
const
  Positions: array[TCSSListStylePosition] of string = ('outside', 'inside');
begin
  Result := 'list-style-position: ' + Positions[Value] + ';';
end;

class function TCSS.ListStyleTypeProp(const Value: TCSSListStyleType): string;
const
  Types: array[TCSSListStyleType] of string = (
    'none', 'initial', 'inherit',
    'disc', 'circle', 'square',
    'decimal', 'decimal-leading-zero',
    'lower-roman', 'upper-roman',
    'lower-alpha', 'upper-alpha'
  );
begin
  Result := 'list-style-type: ' + Types[Value] + ';';
end;

class function TCSS.MarginProp(const Margin: array of Single;
  const LU: TCSSLengthUnit): string;
begin
  Assert(Length(Margin) in [1,2,4],
    'TCSS.MarginProp: Invalid margin parameters');
  Result := 'margin: ' + LengthList(Margin, LU) + ';';
end;

class function TCSS.MarginProp(const Top, Right, Bottom, Left: Single;
  const LU: TCSSLengthUnit): string;
begin
  Result := MarginProp([Top, Right, Bottom, Left], LU);
end;

class function TCSS.MarginProp(const Margin: Single; const LU: TCSSLengthUnit):
  string;
begin
  Result := MarginProp([Margin], LU);
end;

class function TCSS.MarginProp(const Side: TCSSSide; const Margin: Single;
  const LU: TCSSLengthUnit): string;
const
  // Map of element sides to associated margin properties
  MarginSides: array[TCSSSide] of string = (
    'margin', 'margin-top', 'margin-left', 'margin-bottom', 'margin-right'
  );
begin
  Result := Format('%s: %s;', [MarginSides[Side], LengthList([Margin], LU)]);
end;

class function TCSS.MaxHeightProp(const HeightPx: Integer): string;
begin
  Result := Format('max-height: %s;', [LengthList([HeightPx])]);
end;

class function TCSS.OverflowProp(const Value: TCSSOverflowValue;
  const Direction: TCSSOverflowDirection): string;
const
  Values: array[TCSSOverflowValue] of string = (
    'visible', 'hidden', 'scroll', 'auto', 'inherit'
  );
  Props: array[TCSSOverflowDirection] of string = (
    'overflow', 'overflow-x', 'overflow-y'
  );
begin
  Result := Format('%0:s: %1:s;', [Props[Direction], Values[Value]]);
end;

class function TCSS.PaddingProp(const Padding: array of Single;
  const LU: TCSSLengthUnit): string;
begin
  Assert(Length(Padding) in [1,2,4],
    'TCSS.PaddingProp: Invalid padding parameters');
  Result := 'padding: ' + LengthList(Padding, LU) + ';';
end;

class function TCSS.PaddingProp(const Top, Right, Bottom, Left: Single;
  const LU: TCSSLengthUnit): string;
begin
  Result := PaddingProp([Top, Right, Bottom, Left], LU);
end;

class function TCSS.PaddingProp(const Padding: Single;
  const LU: TCSSLengthUnit): string;
begin
  Result := PaddingProp([Padding], LU);
end;

class function TCSS.PaddingProp(const Side: TCSSSide; const Padding: Single;
  const LU: TCSSLengthUnit): string;
const
  // Map of element sides to associated padding properties
  PaddingSides: array[TCSSSide] of string = (
    'padding', 'padding-top', 'padding-left', 'padding-bottom', 'padding-right'
  );
begin
  Result := Format('%s: %s;', [PaddingSides[Side], LengthList([Padding], LU)]);
end;

class function TCSS.TextAlignProp(const TA: TCSSTextAlign): string;
const
  // Map of text alignment to associated property values
  TextAligns: array[TCSSTextAlign] of string = (
    'left', 'right', 'center', 'justify'
  );
begin
  Result := Format('text-align: %s;', [TextAligns[TA]]);
end;

class function TCSS.TextDecorationProp(Decorations: TCSSTextDecorations):
  string;
const
  // Map of text decoration ids to associated property values
  TextDecorations: array[TCSSTextDecoration] of string =
    ('none', 'underline', 'overline', 'line-through', 'blink');
var
  D: TCSSTextDecoration;  // loops thru all decorations
  List: IStringList;      // list of decoration values
begin
  Assert((Decorations = []) or (Decorations = [ctdNone])
    or (Decorations * [ctdNone] = []),
    'TCSS.TextDecorationProp: Invalid combination of values'
  );
  if Decorations = [] then
    Decorations := [ctdNone];
  List := TIStringList.Create;
  for D := Low(TCSSTextDecoration) to High(TCSSTextDecoration) do
    if D in Decorations then
      List.Add(TextDecorations[D]);
  Result := Format('text-decoration: %s;', [List.GetText(' ', False)]);
end;

class function TCSS.TextDecorationProp(const FS: TFontStyles): string;
var
  Decorations: TCSSTextDecorations; // required text decorations
begin
  Decorations := [];
  if fsUnderline in FS then
    Include(Decorations, ctdUnderline);
  if fsStrikeOut in FS then
    Include(Decorations, ctdLineThrough);
  Result := TextDecorationProp(Decorations);
end;

class function TCSS.VerticalAlignProp(const VA: TCSSVerticalAlign): string;
const
  // Map of vertical alignement ids to associated property values
  VerticalAligns: array[TCSSVerticalAlign] of string = (
    'baseline', 'sub', 'super', 'top', 'text-top', 'middle', 'bottom',
    'text-bottom'
  );
begin
  Result := Format('vertical-align: %s;', [VerticalAligns[VA]]);
end;

class function TCSS.WidthProp(const WidthPx: Integer): string;
begin
  Result := WidthProp(cluPixels, WidthPx);
end;

class function TCSS.WidthProp(const LengthUnit: TCSSLengthUnit;
  const Width: Integer): string;
begin
  Result := Format('width: %s;', [LengthList([Width], LengthUnit)]);
end;

end.

