{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at https://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2005-2023, Peter Johnson (gravatar.com/delphidabbler).
 *
 * Implements a class that is used to generate Pascal source code containing
 * specified database snippets.
}


unit USourceGen;


interface


uses
  // Delphi
  Classes,
  Generics.Collections,
  // Project
  ActiveText.UMain,
  DB.USnippet,
  UBaseObjects,
  UIStringList,
  UWarnings;


type
  ///  <summary>Enumeration of different styles of commenting used when
  ///  documenting snippets with their descriptions.</summary>
  TCommentStyle = (
    csNone,     // no documentation of snippets
    csAfter,    // description of snippet between prototype and body
    csBefore    // description of snippet immediatly preceeds code
  );

type
  ///  <summary>Static class that provides information about comment styles and
  ///  which formats comments in the appropriate style.</summary>
  TSourceComments = class(TNoConstructObject)
  strict private
    ///  <summary>Formats the given comment text into lines with a fixed
    ///  maximum width indented by the given number of spaces on the left,
    ///  optionally truncated to the first paragraph.</summary>
    class function FormatActiveTextCommentInner(ActiveText: IActiveText;
      const LineWidth: Cardinal; const Truncate: Boolean): string;
  public

    ///  <summary>Returns a description of the given comment style.</summary>
    ///  <remarks>The description is in a form uitable for use in the UI.
    ///  </remarks>
    class function CommentStyleDesc(const Style: TCommentStyle): string;

    ///  <summary>Formats a snippet's descriptive comment as a Pascal comment
    ///  with to a specified commenting style.</summary>
    ///  <param name="Style">TCommentStyle [in] Required commenting style.
    ///  </param>
    ///  <param name="TruncateComments">Boolean [in] Flag indicating whether or
    ///  not comment is to be truncated at the end of the first paragraph of
    ///  multi-paragraph text.</param>
    ///  <param name="Text">IActiveText [in] Active text of comment.</param>
    ///  <returns>string.Formatted comment or empty string if Style = csNone.
    ///  </returns>
    class function FormatSnippetComment(const Style: TCommentStyle;
      const TruncateComments: Boolean; Text: IActiveText): string;

    ///  <summary>Formats document's header text as a Pascal comment.</summary>
    ///  <param name="Comments">IStringList [in] List of paragraphs of header
    ///  text.</param>
    ///  <returns>string. Formatted comments.</returns>
    class function FormatHeaderComments(const Comments: IStringList): string;
  end;

type
  ///  <summary>Class that receives snippets for which source is to be
  ///  generated, determines dependencies and pulls in any required snippets.
  ///  Data structures are created that can be used to emit source code with all
  ///  dependencies resolved.</summary>
  TSourceAnalyser = class(TObject)
  strict private
    var
      ///  <summary>Value of TypesAndConsts property.</summary>
      fTypesAndConsts: TObjectList<TSnippet>;
      ///  <summary>Value of IntfRoutines property.</summary>
      fIntfRoutines: TSnippetList;
      ///  <summary>Value of AllRoutines property.</summary>
      fAllRoutines: TSnippetList;
      ///  <summary>Value of ForwardRoutines property.</summary>
      fForwardRoutines: TSnippetList;
      ///  <summary>Value of RequiredRoutines property.</summary>
      fRequiredRoutines: TSnippetList;
      ///  <summary>Value of Units property.</summary>
      fUnits: TStringList;

    ///  <summary>Adds given user-specified routine to the analysis.</summary>
    ///  <remarks>Duplicates are ignored.</remarks>
    procedure AddIntfRoutine(const Routine: TSnippet);

    ///  <summary>Adds the given type or constant to the analysis.</summary>
    ///  <remarks>Duplicates are ignored.</remarks>
    procedure AddTypeOrConst(const TypeOrConst: TSnippet);

    ///  <summary>Adds all snippets in given list to a list of required
    ///  snippets, according to type.</summary>
    procedure RequireSnippets(const Snips: TSnippetList);

    ///  <summary>Adds given snippet to appropriate list of required snippets,
    ///  according to type.</summary>
    procedure RequireSnippet(const Snippet: TSnippet);

    ///  <summary>Adds each unit in given list to list of required units.
    ///  </summary>
    ///  <remarks>Duplicates are ignored.</remarks>
    procedure RequireUnits(const Units: TStringList);

    ///  <summary>Adds given unit to list of required units.</summary>
    ///  <remarks>Duplicates are ignored.</remarks>
    procedure RequireUnit(const UnitName: string);

    ///  <summary>Adds given routine, that has not been directly required by
    ///  user, to the analysis.</summary>
    ///  <remarks>Duplicates are ignored.</remarks>
    procedure RequireRoutine(const Routine: TSnippet);

  public

    ///  <summary>Constructs new object instance.</summary>
    constructor Create;

    ///  <summary>Destroys object instance.</summary>
    destructor Destroy; override;

    ///  <summary>Adds the given user-defined snippet to the analysis.</summary>
    ///  <remarks>Freeform snippets are ignored.</remarks>
    procedure AddSnippet(const Snippet: TSnippet);

    ///  <summary>Performs analysis and generates data structures that are
    ///  exposed via the object's properties.</summary>
    ///  <remarks>Must be called after last snippet has been added to the
    ///  analysis.</remarks>
    procedure Generate;

    ///  <summary>List of types and constants that have either been added by the
    ///  user or required by other snippets.</summary>
    property TypesAndConsts: TObjectList<TSnippet> read fTypesAndConsts;

    ///  <summary>List of routines added by the user.</summary>
    ///  <remarks>These routines are those which would appear in a unit's
    ///  interface section.</remarks>
    property IntfRoutines: TSnippetList read fIntfRoutines;

    ///  <summary>List of routines that have been required by other snippets.
    ///  </summary>
    property RequiredRoutines: TSnippetList read fRequiredRoutines;

    ///  <summary>List of all routines, both added and required.</summary>
    ///  <remarks>Not valid until Generate has been called. Invalidated if
    ///  further snippets are added without calling Generate again.</remarks>
    property AllRoutines: TSnippetList read fAllRoutines;

    ///  <summary>List of required routines that have not also been added by the
    ///  user.</summary>
    ///  <remarks>
    ///  <para>These routines are those that would appear as 'forward' routines
    ///  in a unit's implementation section.</para>
    ///  <para>Not valid until Generate has been called. Invalidated if further
    ///  snippets are added without calling Generate again.</para>
    ///  </remarks>
    property ForwardRoutines: TSnippetList read fForwardRoutines;

    ///  <summary>List of required units.</summary>
    property Units: TStringList read fUnits;
  end;

type
  ///  <summary>Generates Pascal source code containing all specified snippets
  ///  along with any other snippets that are required by the specified
  ///  snippets.</summary>
  TSourceGen = class(TObject)
  strict private
    var
      ///  <summary>Object that analyses specified snippets and their
      ///  dependencies.</summary>
      fSourceAnalyser: TSourceAnalyser;

  public
    ///  <summary>Constructs new object instance.</summary>
    constructor Create;

    ///  <summary>Destroys object instance.</summary>
    destructor Destroy; override;

    ///  <summary>Includes the given snippet in the source code.</summary>
    procedure IncludeSnippet(const Snippet: TSnippet);

    ///  <summary>Includes all snippets from the given list in the source code.
    ///  </summary>
    procedure IncludeSnippets(const Snips: TSnippetList);

    ///  <summary>Generates source code of a Pascal unit containing all the
    ///  specified snippets along with any other snippets that are required to
    ///  compile the code.</summary>
    ///  <param name="UnitName"><c>string</c> [in] Name of unit.</param>
    ///  <param name="CommentStyle"><c>TCommentStyle</c> [in] Style of
    ///  commenting used in documenting snippets.</param>
    ///  <param name="TruncateComments"><c>Boolean</c> [in] Flag indicating
    ///  whether or not documentation comments are to be truncated at the end of
    ///  the first paragraph of multi-paragraph text.</param>
    ///  <param name="UseCommentsInImplmentation"><c>Boolean</c> [in] Flag
    ///  indicating whether or not comments are to be included in the
    ///  implementation section. Has no effect when <c>CommentStyle</c> =
    ///  <c>csNone</c>.</param>
    ///  <param name="HeaderComments"><c>IStringList</c> [in] List of comments
    ///  to be included at top of unit.</param>
    ///  <returns><c>string</c>. Unit source code.</returns>
    function UnitAsString(const UnitName: string; const Warnings: IWarnings;
      const CommentStyle: TCommentStyle = csNone;
      const TruncateComments: Boolean = False;
      const UseCommentsInImplementation: Boolean = False;
      const HeaderComments: IStringList = nil): string;

    ///  <summary>Generates source code of a Pascal include file containing all
    ///  the specified snippets. Also writes comments that note which units,
    ///  types, consts and other routines are required to compile the specified
    ///  snippets.</summary>
    ///  <param name="CommentStyle">TCommentStyle [in] Style of commenting used
    ///  in documenting snippets.</param>
    ///  <param name="TruncateComments">Boolean [in] Flag indicating whether or
    ///  not documentation comments are to be truncated at the end of the first
    ///  paragraph of multi-paragraph text.</param>
    ///  <param name="HeaderComments">IStringList [in] List of comments to be
    ///  included at top of unit.</param>
    ///  <returns>string. Source code of include file.</returns>
    function IncFileAsString(const CommentStyle: TCommentStyle = csNone;
      const TruncateComments: Boolean = False;
      const HeaderComments: IStringList = nil): string;

    ///  <summary>Creates and returns a unit name based on the given file name.
    ///  </summary>
    ///  <remarks>
    ///  <para>The unit name is the base file name with any extension removed.
    ///  </para>
    ///  <para>NOTE: not all file names are suitable for creating unit names:
    ///  use the IsFileNameValidUnitName method to check a file name for
    ///  validity.</para>
    ///  </remarks>
    class function UnitNameFromFileName(const FileName: string): string;

    ///  <summary>Checks if the given file name is valid as the basis for a
    ///  unit name.</summary>
    class function IsFileNameValidUnitName(const FileName: string): Boolean;
  end;


implementation


uses
  // Delphi
  SysUtils,
  Character,
  // Project
  ActiveText.UTextRenderer,
  DB.USnippetKind,
  UConsts,
  UExceptions,
  USnippetValidator,
  UStrUtils,
  Hiliter.UPasLexer;


const
  ///  <summary>Maximum number of characters on a source code line.</summary>
  cLineWidth = 80;
  ///  <summary>Size of indenting used for source code, in characters.</summary>
  cIndent = 2;
  ///  <summary>Size of indenting used for rendering comments from active text.
  ///  </summary>
  cCommentIndent = 4;


type
  ///  <summary>Static class that can format a routine to include descriptive
  ///  comments.</summary>
  TRoutineFormatter = class(TNoConstructObject)
  strict private

    ///  <summary>Splits source code of a routine snippet into the head (routine
    ///  prototype) and body.</summary>
    ///  <param name="Routine">TSnippet [in3] Routine whose source code is to be
    ///  split.</param>
    ///  <param name="Head">string [out] Set to routine prototype.</param>
    ///  <param name="Body">string [out] Body of routine that follows the
    ///  prototype.</param>
    class procedure Split(const Routine: TSnippet; out Head, Body: string);

    ///  <summary>Creates and returns a comment containing a routine's
    ///  description.</summary>
    ///  <param name="CommentStyle">TCommentStyle [in] Required commenting
    ///  style.</param>
    ///  <param name="TruncateComments">Boolean [in] Flag indicating whether or
    ///  not comment is to be truncated at the end of the first paragraph of
    ///  multi-paragraph text.</param>
    ///  <param name="Routine">TSnippet [in] Routine for which comments are to
    ///  be rendered. Snippet kind must be skRoutine.</param>
    ///  <returns>string. Formatted comments.</returns>
    class function RenderDescComment(CommentStyle: TCommentStyle;
      const TruncateComments: Boolean; const Routine: TSnippet): string;

  public
    ///  <summary>Extracts and returns the given routine snippet's prototype
    ///  from its source code.</summary>
    class function ExtractPrototype(const Routine: TSnippet): string;

    ///  <summary>Format's a routine snippet's prototype, including a comment
    ///  containing its description if required.</summary>
    ///  <param name="Routine">TSnippet [in] Routine whose prototype is to be
    ///  formatted. Snippet kind must be skRoutine.</param>
    ///  <param name="CommentStyle">TCommentStyle [in] Style of commenting to
    ///  be used for routine's description.</param>
    ///  <param name="TruncateComments">Boolean [in] Flag indicating whether or
    ///  not description comment is to be truncated at the end of the first
    ///  paragraph of multi-paragraph text.</param>
    ///  <returns>string. Formatted prototype.</returns>
    class function FormatRoutinePrototype(const Routine: TSnippet;
      CommentStyle: TCommentStyle; const TruncateComments: Boolean): string;

    ///  <summary>Formats the whole source code of a routine snippet, including
    ///  a comment containing its description if required.</summary>
    ///  <param name="CommentStyle">TCommentStyle [in] Style of commenting to
    ///  be used for routine's description.</param>
    ///  <param name="TruncateComments">Boolean [in] Flag indicating whether or
    ///  not description comment is to be truncated at the end of the first
    ///  paragraph of multi-paragraph text.</param>
    ///  <param name="Routine">TSnippet [in] Routine whose source code is to be
    ///  formatted.</param>
    ///  <returns>string. Formatted source code.</returns>
    class function FormatRoutine(CommentStyle: TCommentStyle;
      const TruncateComments: Boolean; const Routine: TSnippet): string;
  end;

type
  ///  <summary>Static class that can format a constant or simple type
  ///  definition to include descriptive comments.</summary>
  TConstAndTypeFormatter = class(TNoConstructObject)
  strict private
    ///  <summary>Splits source code of a constant or simple type snippet into
    ///  the prefix (text up to 'const' or 'type' and the following definition.
    ///  </summary>
    ///  <param name="ConstOrType">TSnippet [in] Constant or simple type snippet
    ///  whose source code is to be split.</param>
    ///  <param name="Prefix">string [out] Text up to 'const' or 'type' keyword.
    ///  </param>
    ///  <param name="Body">string [out] Remainder of source code without
    ///  prefix.</param>
    class procedure Split(const ConstOrType: TSnippet; out Prefix,
      Body: string);

    ///  <summary>Creates and returns a comment containing a constant or simple
    ///  type's description.</summary>
    ///  <param name="CommentStyle">TCommentStyle [in] Required commenting
    ///  style.</param>
    ///  <param name="TruncateComments">Boolean [in] Flag indicating whether or
    ///  not comment is to be truncated at the end of the first paragraph of
    ///  multi-paragraph text.</param>
    ///  <param name="ConstOrType">TSnippet [in] Constant or simple type for
    ///  which comments are to be rendered. Snippet kind must be skConstant or
    ///  skTypeDef.</param>
    ///  <returns>string. Formatted comments.</returns>
    class function RenderDescComment(CommentStyle: TCommentStyle;
      const TruncateComments: Boolean; const ConstOrType: TSnippet): string;

  public
    ///  <summary>Formats the source code of a constant or simple type snippet,
    ///  including a comment containing its description if required.</summary>
    ///  <param name="CommentStyle">TCommentStyle [in] Style of commenting to
    ///  be used for snippet's description.</param>
    ///  <param name="TruncateComments">Boolean [in] Flag indicating whether or
    ///  not description comment is to be truncated at the end of the first
    ///  paragraph of multi-paragraph text.</param>
    ///  <param name="ConstOrType">TSnippet [in] Constant or simple type whose
    ///  source code is to be formatted.</param>
    ///  <returns>string. Formatted source code.</returns>
    class function FormatConstOrType(CommentStyle: TCommentStyle;
      const TruncateComments: Boolean; const ConstOrType: TSnippet): string;
  end;

type
  ///  <summary>Static class that can format a class or advanced record type
  ///  definition to include descriptive comments.</summary>
  TClassFormatter = class(TNoConstructObject)
  strict private
    class var
      ///  <summary>List of directive names that are valid for use as method
      ///  names.</summary>
      fValidDirsInMethodNames: IStringList;

    ///  <summary>Creates and returns a comment containing a class or advanced
    ///  record type's description.</summary>
    ///  <param name="CommentStyle">TCommentStyle [in] Required commenting
    ///  style.</param>
    ///  <param name="TruncateComments">Boolean [in] Flag indicating whether or
    ///  not comment is to be truncated at the end of the first paragraph of
    ///  multi-paragraph text.</param>
    ///  <param name="Snippet">TSnippet [in] Class or advanced record type for
    ///  which comments are to be rendered.</param>
    ///  <returns>string. Formatted comments.</returns>
    class function RenderDescComment(CommentStyle: TCommentStyle;
      const TruncateComments: Boolean; const Snippet: TSnippet): string;

    ///  <summary>Removes any introductory 'type' keyword from a class or
    ///  advanced record type declaration, if possible.</summary>
    ///  <param name="Decl">string [in] Type declaration to be processed.
    ///  </param>
    ///  <param name="DeclBody">string [out] Source code that follows 'type'
    ///  keyword if found, otherwise set to Decl.</param>
    ///  <returns>Boolean. True if 'type' keyword was removed, False if not.
    ///  </returns>
    class function RemoveKeywordFromDecl(const Decl: string;
      out DeclBody: string): Boolean;

    ///  <summary>Parses complete class or advanced record source code and
    ///  splits declaration from definition.</summary>
    ///  <param name="Source">string [in] Source code to be parsed.</param>
    ///  <param name="Decl">string [out] Set to declaration section.</param>
    ///  <param name="Defn">string [out] Set to definition section.</param>
    class procedure SplitDeclFromDefn(const Source: string; out Decl,
      Defn: string);

  public

    ///  <summary>Instantiates class objects.</summary>
    class constructor Create;

    ///  <summary>Formats source code of a class or advanced record snippet's
    ///  declaration, including a comment containing its description if
    ///  required.</summary>
    ///  <param name="CommentStyle">TCommentStyle [in] Style of commenting to
    ///  be used for snippet's description.</param>
    ///  <param name="TruncateComments">Boolean [in] Flag indicating whether or
    ///  not description comment is to be truncated at the end of the first
    ///  paragraph of multi-paragraph text.</param>
    ///  <param name="Snippet">TSnippet [in] Class or advanced record type whose
    ///  declaration is to be formatted.</param>
    ///  <returns>string. Formatted declaration source code.</returns>
    class function FormatClassDeclaration(CommentStyle: TCommentStyle;
      const TruncateComments: Boolean; const Snippet: TSnippet): string;

    ///  <summary>Formats source code of a class or advanced record snippet's
    ///  definition, including a comment containing its description if required.
    ///  </summary>
    ///  <param name="CommentStyle">TCommentStyle [in] Style of commenting to
    ///  be used for snippet's description.</param>
    ///  <param name="TruncateComments">Boolean [in] Flag indicating whether or
    ///  not description comment is to be truncated at the end of the first
    ///  paragraph of multi-paragraph text.</param>
    ///  <param name="Snippet">TSnippet [in] Class or advanced record type whose
    ///  definition is to be formatted.</param>
    ///  <returns>string. Formatted definition source code.</returns>
    class function FormatClassDefinition(const Snippet: TSnippet): string;
  end;

{ TSourceGen }

constructor TSourceGen.Create;
begin
  inherited;
  fSourceAnalyser := TSourceAnalyser.Create;
end;

destructor TSourceGen.Destroy;
begin
  fSourceAnalyser.Free;
  inherited;
end;

function TSourceGen.IncFileAsString(const CommentStyle: TCommentStyle;
  const TruncateComments: Boolean; const HeaderComments: IStringList): string;
resourcestring
  // Comment text
  sReqUnits           = 'Required unit(s):';
  sReqRoutines        = 'Additional required routine(s):';
  sReqConstsAndTypes  = 'Required constant(s) and / or type(s):';
  sXRefRoutines       = 'Cross referenced routine(s):';
var
  Idx: Integer;             // loops thru snippets list
  Writer: TStringBuilder;   // used to build source code string
  ForwardWritten: Boolean;  // flag true if forward decls have been written
  FirstForward: Boolean;    // flag true when first forward decl to be written
  Snippet: TSnippet;        // accesses various snippet objects
  UnitName: string;         // accesses unit names from a list
begin
  // Generate the unit data
  fSourceAnalyser.Generate;

  // Create writer used to build source code
  Writer := TStringBuilder.Create;
  try

    // Write header comment
    Writer.Append(TSourceComments.FormatHeaderComments(HeaderComments));

    // Write required units, additional routines, types and consts
    if (fSourceAnalyser.Units.Count > 0) or
      (fSourceAnalyser.ForwardRoutines.Count > 0) or
      (fSourceAnalyser.TypesAndConsts.Count > 0) then
    begin
      Writer.AppendLine('{');
      if fSourceAnalyser.Units.Count > 0 then
      begin
        // list of required units
        Writer.AppendLine('  ' + sReqUnits);
        for UnitName in fSourceAnalyser.Units do
          Writer.AppendLine('    ' + UnitName);
      end;
      if fSourceAnalyser.TypesAndConsts.Count > 0 then
      begin
        // list of types and consts
        if (fSourceAnalyser.Units.Count > 0) then
          Writer.AppendLine;
        Writer.AppendLine('  ' + sReqConstsAndTypes);
        for Snippet in fSourceAnalyser.TypesAndConsts do
          Writer.AppendLine('    ' + Snippet.DisplayName);
      end;
      if fSourceAnalyser.ForwardRoutines.Count > 0 then
      begin
        // list of other routines required to compile
        if (fSourceAnalyser.Units.Count > 0) or
          (fSourceAnalyser.TypesAndConsts.Count > 0) then
          Writer.AppendLine;
        Writer.AppendLine('  ' + sReqRoutines);
        for Snippet in fSourceAnalyser.ForwardRoutines do
          Writer.AppendLine('    ' + Snippet.DisplayName);
      end;
      Writer.AppendLine('}');
      Writer.AppendLine;
    end;

    // Write out forward declarations for included routines required by others
    FirstForward := True;
    ForwardWritten := False;
    for Snippet in fSourceAnalyser.IntfRoutines do
    begin
      if fSourceAnalyser.RequiredRoutines.Contains(Snippet) then
      begin
        if FirstForward then
        begin
          Writer.AppendLine('// ' + sXRefRoutines);
          FirstForward := False;
        end;
        Writer.AppendLine(
          TRoutineFormatter.FormatRoutinePrototype(Snippet, csNone, False)
        );
        Writer.AppendLine('  forward;');
        ForwardWritten := True;
      end;
    end;
    if ForwardWritten then
      Writer.AppendLine;

    // Write routines
    for Idx := 0 to Pred(fSourceAnalyser.IntfRoutines.Count) do
    begin
      Snippet := fSourceAnalyser.IntfRoutines[Idx];
      Writer.AppendLine(
        TRoutineFormatter.FormatRoutine(CommentStyle, TruncateComments, Snippet)
      );
      if Idx < Pred(fSourceAnalyser.IntfRoutines.Count) then
        Writer.AppendLine;
    end;

    // Return string containing source code
    Result := Writer.ToString;
  finally
    Writer.Free;
  end;
end;

procedure TSourceGen.IncludeSnippet(const Snippet: TSnippet);
begin
  fSourceAnalyser.AddSnippet(Snippet);
end;

procedure TSourceGen.IncludeSnippets(const Snips: TSnippetList);
var
  Snippet: TSnippet;  // iterates through snippets to be added
begin
  for Snippet in Snips do
    IncludeSnippet(Snippet);
end;

class function TSourceGen.IsFileNameValidUnitName(const FileName: string):
  Boolean;
begin
  Result := IsValidIdent(UnitNameFromFileName(FileName));
end;

function TSourceGen.UnitAsString(const UnitName: string;
  const Warnings: IWarnings;
  const CommentStyle: TCommentStyle = csNone;
  const TruncateComments: Boolean = False;
  const UseCommentsInImplementation: Boolean = False;
  const HeaderComments: IStringList = nil): string;
var
  Writer: TStringBuilder;                    // used to build source code string
  Snippet: TSnippet;                            // reference to a snippet object
  ImplCommentStyle: TCommentStyle;        // style of comments in implementation
begin
  // Set comment style for implementation section
  if UseCommentsInImplementation then
    ImplCommentStyle := CommentStyle
  else
    ImplCommentStyle := csNone;

  // Generate the unit data
  fSourceAnalyser.Generate;

  // Create writer object onto string stream that receives output
  Writer := TStringBuilder.Create;
  try
    // Write unit

    // heading comment
    Writer.Append(TSourceComments.FormatHeaderComments(HeaderComments));

    // unit name
    Writer.AppendFormat('unit %s;', [UnitName]).AppendLine;
    Writer.AppendLine;

    // any conditional compilation symbols
    if Warnings.Enabled and not Warnings.IsEmpty then
    begin
      Writer.Append(Warnings.Render);
      Writer.AppendLine;
    end;

    // open interface section
    Writer.AppendLine('interface');
    Writer.AppendLine;

    // uses statement
    if fSourceAnalyser.Units.Count > 0 then
    begin
      Writer.AppendLine('uses');
      Writer.AppendLine(
        StrWrap(
          StrJoin(fSourceAnalyser.Units, ', ') + ';',
          cLineWidth - cIndent,
          cIndent
        )
      );
      Writer.AppendLine;
    end;

    // consts and types
    for Snippet in fSourceAnalyser.TypesAndConsts do
    begin
      case Snippet.Kind of
        skTypeDef, skConstant:
          Writer.AppendLine(
            TConstAndTypeFormatter.FormatConstOrType(
              CommentStyle, TruncateComments, Snippet
            )
          );
        skClass:
          Writer.AppendLine(
            TClassFormatter.FormatClassDeclaration(
              CommentStyle, TruncateComments, Snippet
            )
          );
      end;
      Writer.AppendLine;
    end;

    // routine prototypes
    for Snippet in fSourceAnalyser.IntfRoutines do
    begin
      Writer.AppendLine(
        TRoutineFormatter.FormatRoutinePrototype(
          Snippet, CommentStyle, TruncateComments
        )
      );
      Writer.AppendLine;
    end;

    // open implementation section
    Writer.AppendLine('implementation');
    Writer.AppendLine;

    // forward declarations
    if fSourceAnalyser.ForwardRoutines.Count > 0 then
    begin
      for Snippet in fSourceAnalyser.ForwardRoutines do
      begin
        Writer.AppendLine(TRoutineFormatter.ExtractPrototype(Snippet));
        Writer.AppendLine('  forward;');
      end;
      Writer.AppendLine;
    end;

    // routine source code
    for Snippet in fSourceAnalyser.AllRoutines do
    begin
      Writer.AppendLine(
        TRoutineFormatter.FormatRoutine(
          ImplCommentStyle, TruncateComments, Snippet
        )
      );
      Writer.AppendLine;
    end;

    // class & records-with-methods implementation source code
    for Snippet in fSourceAnalyser.TypesAndConsts do
    begin
      if Snippet.Kind = skClass then
      begin
        Writer.AppendLine(TClassFormatter.FormatClassDefinition(Snippet));
        Writer.AppendLine;
      end;
    end;

    // close unit
    Writer.AppendLine('end.');

    // Return string built in string stream
    Result := Writer.ToString;
  finally
    Writer.Free;
  end;
end;

class function TSourceGen.UnitNameFromFileName(const FileName: string): string;
var
  BaseFileName: string; // base file name (i.e. file name without path)
  Ext: string;          // file's extension
begin
  BaseFileName := ExtractFileName(FileName);
  Ext := ExtractFileExt(FileName);
  Result := StrSliceLeft(BaseFileName, Length(BaseFileName) - Length(Ext));
end;

{ TSourceAnalyser }

procedure TSourceAnalyser.AddIntfRoutine(const Routine: TSnippet);
begin
  Assert(Routine.Kind = skRoutine,
    ClassName + '.AddIntfRoutine: Routine must have kind skRoutine');
  if not fIntfRoutines.Contains(Routine) then
  begin
    fIntfRoutines.Add(Routine);         // add to user-specified list
    RequireUnits(Routine.Units);        // add all routine's required units
    RequireSnippets(Routine.Depends);   // add all routine's required snippets
  end;
end;

procedure TSourceAnalyser.AddSnippet(const Snippet: TSnippet);
var
  ErrorMsg: string;       // any error message
begin
  // NOTE: this method must not be called from any other method of this class
  // Validate the snippet
  if not TSnippetValidator.Validate(Snippet, ErrorMsg) then
    raise ECodeSnip.Create(ErrorMsg);
  // Process the snippet
  case Snippet.Kind of
    skRoutine:
      AddIntfRoutine(Snippet);
    skTypeDef, skConstant:
      AddTypeOrConst(Snippet);
    skFreeform:
      {Ignore};
    skUnit:
      {Ignore};
    skClass:
      AddTypeOrConst(Snippet);
  end;
end;

procedure TSourceAnalyser.AddTypeOrConst(const TypeOrConst: TSnippet);
var
  ErrorMsg: string;       // any error message
begin
  Assert(Assigned(TypeOrConst), ClassName + '.Add: ConstOrType in nil');
  Assert(TypeOrConst.Kind in [skTypeDef, skConstant, skClass],
    ClassName + '.Add: ConstOrType.Kind is not valid');
  // Ignore if already in list
  if fTypesAndConsts.Contains(TypeOrConst) then
    Exit;
  // Validate dependency list
  if not TSnippetValidator.ValidateDependsList(TypeOrConst, ErrorMsg) then
    raise ECodeSnip.Create(ErrorMsg);
  // Add all required snippets to list before adding this one: this ensures
  // required snippets preceed those that depend on them
  RequireSnippets(TypeOrConst.Depends);
  RequireUnits(TypeOrConst.Units);
  fTypesAndConsts.Add(TypeOrConst)
end;

constructor TSourceAnalyser.Create;
begin
  inherited;
  fTypesAndConsts := TObjectList<TSnippet>.Create(False);
  fIntfRoutines := TSnippetList.Create;
  fAllRoutines := TSnippetList.Create;
  fForwardRoutines := TSnippetList.Create;
  fRequiredRoutines := TSnippetList.Create;
  fUnits := TStringList.Create;
end;

destructor TSourceAnalyser.Destroy;
begin
  fTypesAndConsts.Free;
  fIntfRoutines.Free;
  fAllRoutines.Free;
  fForwardRoutines.Free;
  fRequiredRoutines.Free;
  fUnits.Free;
  inherited;
end;

procedure TSourceAnalyser.Generate;
var
  Routine: TSnippet;  // iterates through various routine lists
begin
  fForwardRoutines.Clear;
  fAllRoutines.Clear;
  // Build forward routines list
  for Routine in fRequiredRoutines do
    if not fIntfRoutines.Contains(Routine)
      and not fForwardRoutines.Contains(Routine) then
      fForwardRoutines.Add(Routine);
  // Build all routines list
  for Routine in fIntfRoutines do
    fAllRoutines.Add(Routine);
  for Routine in fForwardRoutines do
    fAllRoutines.Add(Routine);
end;

procedure TSourceAnalyser.RequireRoutine(const Routine: TSnippet);
begin
  if not fRequiredRoutines.Contains(Routine) then
  begin
    fRequiredRoutines.Add(Routine);   // add routine to required list
    RequireUnits(Routine.Units);      // add all routine's required unit
    RequireSnippets(Routine.Depends); // require all snippets in depends list
  end;
end;

procedure TSourceAnalyser.RequireSnippet(const Snippet: TSnippet);
resourcestring
  // Error message
  sCantDependOnFreeform = 'Can''t depend on "%s" - it is freeform code';
begin
  case Snippet.Kind of
    skRoutine:                      // require routine
      RequireRoutine(Snippet);
    skConstant, skTypeDef, skClass: // add type/const allowing for dependencies
      AddTypeOrConst(Snippet);
    skFreeform:                     // can't require a freeform snippet
      raise ECodeSnip.CreateFmt(sCantDependOnFreeform, [Snippet.DisplayName]);
  end;
end;

procedure TSourceAnalyser.RequireSnippets(const Snips: TSnippetList);
var
  Snippet: TSnippet;  // iterates through snippets list
begin
  for Snippet in Snips do
    RequireSnippet(Snippet);
end;

procedure TSourceAnalyser.RequireUnit(const UnitName: string);
begin
  if fUnits.IndexOf(UnitName) = -1 then
    fUnits.Add(UnitName);
end;

procedure TSourceAnalyser.RequireUnits(const Units: TStringList);
var
  UnitName: string; // iterates through list of units.
begin
  for UnitName in Units do
    RequireUnit(UnitName);
end;

{ TRoutineFormatter }

class function TRoutineFormatter.ExtractPrototype(const
  Routine: TSnippet): string;
var
  DummyBody: string;  // stores unused routine body retrieved from Split
begin
  Split(Routine, Result, DummyBody);
  Result := StrTrim(Result);
end;

class function TRoutineFormatter.FormatRoutine(CommentStyle: TCommentStyle;
  const TruncateComments: Boolean; const Routine: TSnippet): string;
var
  Prototype, Body: string;  // prototype and body of routine
begin
  Assert(Routine.Kind = skRoutine,
    ClassName + '.FormatRoutine: Routine must have kind skRoutine');
  case CommentStyle of
    csAfter:
    begin
      // Format is: routine prototype - comment - routine body
      Split(Routine, Prototype, Body);
      Result := StrTrim(Prototype)
        + EOL
        + RenderDescComment(CommentStyle, TruncateComments, Routine)
        + EOL
        + StrTrim(Body);
    end;
    csBefore:
      // Format is: comment - routine
      Result := RenderDescComment(CommentStyle, TruncateComments, Routine)
        + EOL
        + StrTrim(Routine.SourceCode);
    else
      // No commenting: just return source code
      Result := StrTrim(Routine.SourceCode);
  end;
end;

class function TRoutineFormatter.FormatRoutinePrototype(const Routine: TSnippet;
  CommentStyle: TCommentStyle; const TruncateComments: Boolean): string;
var
  Prototype: string;  // prototype of given routine
begin
  Assert(Routine.Kind = skRoutine,
    ClassName + '.FormatRoutinePrototype: Routine must have kind skRoutine');
  // Get prototype
  Prototype := ExtractPrototype(Routine);
  // Write comment depending on style
  case CommentStyle of
    csAfter:
      // comments follow prototype
      Result := Prototype
        + EOL
        + RenderDescComment(CommentStyle, TruncateComments, Routine);
    csBefore:
      // comments preceed prototype
      Result := RenderDescComment(CommentStyle, TruncateComments, Routine)
        + EOL
        + Prototype;
    else
      // no comments: just return prototype
      Result := Prototype;
  end;
end;

class function TRoutineFormatter.RenderDescComment(
  CommentStyle: TCommentStyle; const TruncateComments: Boolean;
  const Routine: TSnippet): string;
begin
  Assert(Routine.Kind = skRoutine,
    ClassName + '.RenderDescComment: Routine must have kind skRoutine');
  // Format the output
  Result := TSourceComments.FormatSnippetComment(
    CommentStyle, TruncateComments, Routine.Description
  );
end;

class procedure TRoutineFormatter.Split(const Routine: TSnippet; out Head,
  Body: string);

  // Checks if given symbol is a calling convention directive.
  function IsDirective(const Symbol: string): Boolean;
  const
    // list of calling convention directives
    cCallConventions: array[0..4] of string = (
      'register', 'pascal', 'cdecl', 'stdcall', 'safecall'
    );
  var
    ConventionList: IStringList;  // list of calling conventions
  begin
    ConventionList := TIStringList.Create(cCallConventions);
    ConventionList.CaseSensitive := False;
    Result := ConventionList.Contains(Symbol);
  end;

var
  SourceCode: string;         // routine's source code
  StartParam: Integer;        // possible position of start of any parameters
  AfterParams: Integer;       // possible position of end of any parameters
  EndDeclaration: Integer;    // position of end of routine declaration
  StartCodeBody: Integer;     // position of start of body of routine
  SemiColonPos: Integer;      // position of a semi colon
  Fragment: string;           // a fragment of code
const
  cOverload = 'overload';     // overload directive
begin
  // Record code without any surrounding white space
  SourceCode := StrTrim(Routine.SourceCode);
  // Find relative positions of first key characters
  StartParam := StrPos('(', SourceCode);
  AfterParams := StrPos(')', SourceCode) + 1;
  SemiColonPos := StrPos(';', SourceCode);
  // Determine end of head section
  if SemiColonPos > StartParam then
  begin
    // semi colon after param => we have params: skip them before looking for
    // ending ';'
    EndDeclaration := StrPos(
      ';',
      Copy(SourceCode, AfterParams, Length(SourceCode) - AfterParams + 1)
    ) + AfterParams - 1;
  end
  else
  begin
    // semi colon before "params" => no params and ';' ends header
    EndDeclaration := SemiColonPos;
  end;
  // Look for directives that are part of prototype
  // first look for calling conventions
  SemiColonPos := StrPos(';', SourceCode, EndDeclaration + 1);
  if SemiColonPos > 0 then
  begin
    Fragment := StrTrim(
      Copy(SourceCode, EndDeclaration + 1, SemiColonPos - EndDeclaration - 1)
    );
    if IsDirective(Fragment) then
      EndDeclaration := SemiColonPos + 1;
  end;
  // now look for 'overload' directive
  SemiColonPos := StrPos(';', SourceCode, EndDeclaration + 1);
  if SemiColonPos > 0 then
  begin
    Fragment := StrTrim(
      Copy(SourceCode, EndDeclaration + 1, SemiColonPos - EndDeclaration - 1)
    );
    if StrToLower(Fragment) = cOverload then
      EndDeclaration := SemiColonPos + 1;
  end;
  // Record declaration (i.e. prototype)
  Head := Copy(SourceCode, 1, EndDeclaration);
  // Get code body
  StartCodeBody := EndDeclaration + 1;
  Body := StrTrim(Copy(SourceCode, StartCodeBody, MaxInt));
end;

{ TConstAndTypeFormatter }

class function TConstAndTypeFormatter.FormatConstOrType(
  CommentStyle: TCommentStyle; const TruncateComments: Boolean;
  const ConstOrType: TSnippet): string;
var
  Keyword: string;  // keyword that preceeds source code body
  Body: string;     // source code that follows keyword
begin
  Assert(ConstOrType.Kind in [skConstant, skTypeDef],
    ClassName + '.FormatConstOrType: ConstOrType must have kind skTypeDef or '
    + 'skConstant');
  Result := '';
  case CommentStyle of
    csNone:
      Result := StrTrim(ConstOrType.SourceCode);
    csBefore:
      Result := RenderDescComment(CommentStyle, TruncateComments, ConstOrType)
        + EOL
        + StrTrim(ConstOrType.SourceCode);
    csAfter:
    begin
      Split(ConstOrType, Keyword, Body);
      if Keyword <> '' then
        Result := Keyword
          + EOL
          + RenderDescComment(CommentStyle, TruncateComments, ConstOrType)
          + EOL
          + Body
      else
        Result := ConstOrType.SourceCode;
    end;
  end;
end;

class function TConstAndTypeFormatter.RenderDescComment(
  CommentStyle: TCommentStyle; const TruncateComments: Boolean;
  const ConstOrType: TSnippet): string;
begin
  Assert(ConstOrType.Kind in [skConstant, skTypeDef],
    ClassName + '.RenderDescComment: ConstOrType must have kind skTypeDef or '
      + 'skConstant');
  Result := TSourceComments.FormatSnippetComment(
    CommentStyle, TruncateComments, ConstOrType.Description
  );
end;

class procedure TConstAndTypeFormatter.Split(const ConstOrType: TSnippet;
  out Prefix, Body: string);

  // Splits the given source code and the first occurence of keyword KW,
  // returning the code before the keyword in Prefix and the code following the
  // keyword in Body. If KW is not found, Prefix is set to the empty string and
  // Body is set to SourceCode.
  procedure SplitAtKeyword(const SourceCode, KW: string;
    out Prefix, Body: string);
  var
    Lexer: THilitePasLexer;       // parses Pascal code
    PrefixCode: TStringBuilder;   // records prefix code
  const
    SkipTokens = [tkComment, tkCompilerDir, tkWhitespace, tkEOL];
    WhiteSpaceTokens = [tkWhitespace, tkEOL];
  resourcestring
    sTypeKwdError = '"%s" must be first keyword in source code';
  begin
    Lexer := THilitePasLexer.Create(SourceCode);
    try
      PrefixCode := TStringBuilder.Create;
      try
        while Lexer.NextToken in SkipTokens do
          PrefixCode.Append(Lexer.TokenStr);
        if (Lexer.Token = tkKeyword) and StrSameText(Lexer.TokenStr, KW) then
        begin
          PrefixCode.Append(Lexer.TokenStr);
          Prefix := StrTrimRight(PrefixCode.ToString);
          while Lexer.NextToken in WhiteSpaceTokens do
            PrefixCode.Append(Lexer.TokenStr);
          Body := '  ' +
            StrTrim(
              StrSliceRight(
                SourceCode, Length(SourceCode) - Length(PrefixCode.ToString)
              )
            );
        end
        else
        begin
          Prefix := '';
          Body := SourceCode;
        end;
      finally
        PrefixCode.Free;
      end;
    finally
      Lexer.Free;
    end;
  end;

begin
  if ConstOrType.Kind = skConstant then
    SplitAtKeyword(ConstOrType.SourceCode, 'const', Prefix, Body)
  else // if ConstOrType.Kind = skTypeDef
    SplitAtKeyword(ConstOrType.SourceCode, 'type', Prefix, Body)
end;

{ TSourceComments }

class function TSourceComments.CommentStyleDesc(
  const Style: TCommentStyle): string;
resourcestring
  // Comment style descriptions
  sCSNone = 'No descriptive comments';
  sCSAfter = 'Comments after snippet header';
  sCSBefore = 'Comments before snippet';
const
  // Map of comment styles to descriptions
  sDescriptions: array[TCommentStyle] of string = (
    sCSNone, sCSAfter, sCSBefore
  );
begin
  Result := sDescriptions[Style];
end;

class function TSourceComments.FormatActiveTextCommentInner(
  ActiveText: IActiveText; const LineWidth: Cardinal;
  const Truncate: Boolean): string;
var
  Renderer: TActiveTextTextRenderer;
  ProcessedActiveText: IActiveText;
  Lines: IStringList;
  Line: string;
begin
  if Truncate then
    ProcessedActiveText := ActiveText.FirstBlock
  else
    ProcessedActiveText := ActiveText;
  Renderer := TActiveTextTextRenderer.Create;
  try
    Renderer.DisplayURLs := False;
    Renderer.IndentDelta := cCommentIndent;
    Result := '';
    Lines := TIStringList.Create(
      Renderer.RenderWrapped(ProcessedActiveText, LineWidth, 0),
      EOL,
      True,
      False
    );
    for Line in Lines do
      Result := Result + StringOfChar(' ', cLineWidth - LineWidth) + Line + EOL;
    Result := StrTrimRight(Result);
  finally
    Renderer.Free;
  end;
end;

class function TSourceComments.FormatHeaderComments(
  const Comments: IStringList): string;
var
  Line: string;         // loops thru each line of comments & exploded comments
  Lines: IStringList;   // comments after exploding multiple wrapped lines
const
  cLinePrefix = ' * ';  // prefixes each header omment line
begin
  // Only create comment if some comment text is provided
  if Assigned(Comments) and (Comments.Count > 0) then
  begin
    // text wrap each line of comments and exploded into separate lines
    Lines := TIStringList.Create;
    for Line in Comments do
      if Length(Line) > 0 then
        Lines.Add(
          StrWrap(Line, cLineWidth - Length(cLinePrefix), 0), EOL, True
        )
      else
        Lines.Add('');
    Result := '{';
    // write out each comment line
    for Line in Lines do
      Result := Result + EOL + cLinePrefix + Line;
    Result := Result + EOL + '}' + EOL2;
  end
  else
    Result := '';
end;

class function TSourceComments.FormatSnippetComment(const Style: TCommentStyle;
  const TruncateComments: Boolean; Text: IActiveText): string;
begin
  case Style of
    csNone:
      Result := '';
    csBefore:
    begin
      Result := '{' + EOL
        + FormatActiveTextCommentInner(
            Text, cLineWidth - cIndent, TruncateComments
          )
        + EOL + '}';
    end;
    csAfter:
    begin
      Result := StrOfChar(' ', cIndent) + '{' + EOL
        + FormatActiveTextCommentInner(
            Text, cLineWidth - 2 * cIndent, TruncateComments
          )
        + EOL + StringOfChar(' ', cIndent) + '}';
    end;
  end;
end;

{ TClassFormatter }

class constructor TClassFormatter.Create;
begin
  // record names of directives that are valid for use as method names
  fValidDirsInMethodNames := TIStringList.Create([
    'absolute', 'abstract', 'assembler', 'cdecl', 'contains', 'default',
    'delayed', 'deprecated', 'dispid', 'dynamic', 'experimental', 'export',
    'external', 'far', 'final', 'forward', 'helper', 'implements', 'index',
    'local', 'message', 'name', 'near', 'nodefault', 'overload', 'override',
    'package', 'pascal', 'platform', 'read', 'readonly', 'reference',
    'register', 'reintroduce', 'requires', 'resident', 'safecall', 'sealed',
    'static', 'stdcall', 'stored', 'strict', 'unsafe', 'varargs', 'virtual',
    'winapi', 'write', 'writeonly'
  ]);
  fValidDirsInMethodNames.CaseSensitive := False;
  fValidDirsInMethodNames.Sort;
end;

class function TClassFormatter.FormatClassDeclaration(
  CommentStyle: TCommentStyle; const TruncateComments: Boolean;
  const Snippet: TSnippet): string;
var
  Dummy: string;
  Decl: string;
  DeclBody: string;
begin
  SplitDeclFromDefn(Snippet.SourceCode, Decl, Dummy);
  Decl := StrTrim(Decl);
  case CommentStyle of
    csNone:
      Result := StrTrim(Decl);
    csBefore:
      Result := RenderDescComment(CommentStyle, TruncateComments, Snippet)
        + EOL
        + StrTrim(Decl);
    csAfter:
    begin
      if RemoveKeywordFromDecl(Decl, DeclBody) then
        Result := 'type'
          + EOL
          + RenderDescComment(CommentStyle, TruncateComments, Snippet)
          + EOL
          + DeclBody
      else
        Result := Decl;
    end;
  end;
end;

class function TClassFormatter.FormatClassDefinition(const Snippet: TSnippet):
  string;
var
  Dummy: string;
begin
  SplitDeclFromDefn(Snippet.SourceCode, Dummy, Result);
end;

class function TClassFormatter.RemoveKeywordFromDecl(const Decl: string;
  out DeclBody: string): Boolean;
const
  Keyword = 'type';
begin
  Result := StrStartsStr(Keyword, Decl);
  if Result then
    DeclBody := '  ' + StrTrim(Copy(Decl, Length(Keyword) + 1, MaxInt))
  else
    // "type" not found - can't remove
    DeclBody := Decl;
end;

class function TClassFormatter.RenderDescComment(CommentStyle: TCommentStyle;
  const TruncateComments: Boolean; const Snippet: TSnippet): string;
begin
  Result := TSourceComments.FormatSnippetComment(
    CommentStyle, TruncateComments, Snippet.Description
  );
end;

class procedure TClassFormatter.SplitDeclFromDefn(const Source: string;
  out Decl, Defn: string);
var
  Lexer: THilitePasLexer;
  SB: TStringBuilder;
  ClassTypeName: string;
  Temp: string;
const
  WhiteSpaceTokens = [tkComment, tkCompilerDir, tkWhitespace, tkEOL];

  ///  <summary>Checks if given token is one of the keywords used to introduce
  ///  a method.</summary>
  function IsMethodKwd(const Tok: string): Boolean;
  begin
    Result := StrSameText(Lexer.TokenStr, 'function')
      or StrSameText(Lexer.TokenStr, 'procedure')
      or StrSameText(Lexer.TokenStr, 'constructor')
      or StrSameText(Lexer.TokenStr, 'destructor')
      or StrSameText(Lexer.TokenStr, 'operator');
  end;

  ///  <summary>Checks if current lexer token can represent a method name.
  ///  </summary>
  function IsMethodName(const Lexer: THilitePasLexer): Boolean;
  begin
    // Either an identifier or one of a certain number of directives can be used
    // as the name of a method.
    if Lexer.Token = tkIdentifier then
      Exit(True);
    Result := (Lexer.Token = tkDirective)
      and fValidDirsInMethodNames.Contains(Lexer.TokenStr);
  end;

resourcestring
  sTypeKwdError = '"type" must be first keyword in source code';
  sClassTypeNameError = 'Class type name expected in source code';
  sBadTypeError = 'Invalid class or advanced record type';
  sImplementationKwdError = '"implementation" keyword not permitted in class '
    + 'or advanced record snippets.';
begin
  Lexer := THilitePasLexer.Create(Source);
  try
    SB := TStringBuilder.Create;
    try
      // skip any leading white space and comments to first Pascal token
      // this must be "type" keyword
      while Lexer.NextToken in WhiteSpaceTokens do
        SB.Append(Lexer.TokenStr);
      if (Lexer.Token <> tkKeyword)
        and not StrSameText(Lexer.TokenStr, 'type') then
        raise ECodeSnip.Create(sTypeKwdError);
      SB.Append(Lexer.TokenStr);

      // get name of class from following identifier
      while Lexer.NextToken in WhiteSpaceTokens do
        SB.Append(Lexer.TokenStr);
      if Lexer.Token <> tkIdentifier then
        raise ECodeSnip.Create(sClassTypeNameError);
      ClassTypeName := Lexer.TokenStr;
      SB.Append(Lexer.TokenStr);

      while True do
      begin
        // look for methods
        while not (Lexer.NextToken in [tkKeyword, tkEOF])
          and not (
            IsMethodKwd(Lexer.TokenStr)
            or StrSameText(Lexer.TokenStr, 'class')
            or StrSameText(Lexer.TokenStr, 'implementation')
          ) do
          SB.Append(Lexer.TokenStr);
        if Lexer.Token = tkEOF then
          raise ECodeSnip.Create(sBadTypeError);
        if (Lexer.Token = tkKeyword)
          and StrSameText(Lexer.TokenStr, 'implementation') then
          raise ECodeSnip.Create(sImplementationKwdError);
        // check if function is followed by ClassTypeName and a dot => start
        // of declaration
        Temp := '';
        if not IsMethodKwd(Lexer.TokenStr) then
        begin
          // token is not method keyword - we're only interested if token is
          // "class" so record token and go round again if not "class"
          if not StrSameText(Lexer.TokenStr, 'class') then
          begin
            SB.Append(Lexer.TokenStr);
            Continue;
          end;
          // must have "class" keyword: record it
          Temp := Lexer.TokenStr;
          // skip whitespace following "class"
          while Lexer.NextToken in WhiteSpaceTokens do
            Temp := Temp + Lexer.TokenStr;
          // now look for one of method keywords that can follow "class"
          if (Lexer.Token <> tkKeyword) and not IsMethodKwd(Lexer.TokenStr) then
          begin
            // didn't find method: record text read and go round again
            SB.Append(Temp);            // "class" and whitespace
            SB.Append(Lexer.TokenStr);  // token after whitespace
            Continue;
          end;
        end;
        // record method name
        Temp := Temp + Lexer.TokenStr;
        // record following white space
        while Lexer.NextToken in WhiteSpaceTokens do
          Temp := Temp + Lexer.TokenStr;
        // record item after white space
        Temp := Temp + Lexer.TokenStr;
        if not IsMethodName(Lexer)
          or not StrSameText(Lexer.TokenStr, ClassTypeName) then
        begin
          // not the required identifier: record text and go round again
          SB.Append(Temp);
          Continue;
        end;
        // check for following '.'
        while Lexer.NextToken in WhiteSpaceTokens do
          Temp := Temp + Lexer.TokenStr;
        Temp := Temp + Lexer.TokenStr;
        if (Lexer.Token <> tkSymbol) or (Lexer.TokenStr <> '.') then
        begin
          SB.Append(Temp);
          Continue;
        end;
        // check for following identifier
        while Lexer.NextToken in WhiteSpaceTokens do
          Temp := Temp + Lexer.TokenStr;
        Temp := Temp + Lexer.TokenStr;
        if not IsMethodName(Lexer) then
        begin
          SB.Append(Temp);
          Continue;
        end;
        Break;
      end;
      // Lexer replaces CRLF with LF, but we need CRLF to keep string length
      // same as original so that string slice below works
      Decl := StrReplace(SB.ToString, LF, CRLF);
    finally
      SB.Free;
    end;
    Defn := StrSliceRight(Source, Length(Source) - Length(Decl));
  finally
    Lexer.Free;
  end;
end;

end.

