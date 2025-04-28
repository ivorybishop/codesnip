{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at https://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2025, Peter Johnson (gravatar.com/delphidabbler).
 *
 * Saves information about a snippet to disk in various, user specifed, formats.
 * Only routine snippet kinds are supported.
}


unit USaveInfoMgr;

interface

uses
  // Project
  UBaseObjects,
  UEncodings,
  UHTMLSnippetDoc,
  USaveSourceDlg,
  USourceFileInfo,
  UView;


type
  ///  <summary>Class that saves information about a snippet to file a user
  ///  specified format. The snippet is obtained from a view. Only snippet views
  ///  are supported.</summary>
  TSaveInfoMgr = class(TNoPublicConstructObject)
  strict private
    var
      fView: IView;
      fSaveDlg: TSaveSourceDlg;
      fSourceFileInfo: TSourceFileInfo;

    ///  <summary>Returns encoded data containing a RTF representation of
    ///  information about the snippet represented by the given view.</summary>
    class function GenerateRichText(View: IView; const AUseHiliting: Boolean):
      TEncodedData; static;

    ///  <summary>Returns encoded data containing a HTML representation of the
    ///  required snippet information.</summary>
    ///  <param name="AUseHiliting"><c>Boolean</c> [in] Determines whether
    ///  source code is syntax highlighted or not.</param>
    ///  <param name="GeneratorClass"><c>THTMLSnippetDocClass</c> [in] Class of
    ///  object used to generate the required flavour of HTML.</param>
    ///  <returns><c>TEncodedData</c>. Required HTML document, encoded as UTF-8.
    ///  </returns>
    function GenerateHTML(const AUseHiliting: Boolean;
      const GeneratorClass: THTMLSnippetDocClass): TEncodedData;

    ///  <summary>Returns encoded data containing a plain text representation of
    ///  information about the snippet represented by the given view.</summary>
    function GeneratePlainText: TEncodedData;

    ///  <summary>Returns encoded data containing a Markdown representation of
    ///  information about the snippet represented by the given view.</summary>
    ///  <returns><c>TEncodedData</c>. Required Markdown document, encoded as
    ///  UTF-16.</returns>
    function GenerateMarkdown: TEncodedData;

    ///  <summary>Returns type of file selected in the associated save dialogue
    ///  box.</summary>
    function SelectedFileType: TSourceFileType;

    ///  <summary>Handles the custom save dialogue's <c>OnPreview</c> event.
    ///  Displays the required snippet information, appropriately formatted, in
    ///  a preview dialogues box.</summary>
    ///  <param name="Sender"><c>TObject</c> [in] Reference to the object that
    ///  triggered the event.</param>
    procedure PreviewHandler(Sender: TObject);

    ///  <summary>Handles the custom save dialogue's <c>OnHiliteQuery</c> event.
    ///  Determines whether syntax highlighting is supported for the source code
    ///  section of the required snippet information..</summary>
    ///  <param name="Sender"><c>TObject</c> [in] Reference to the object that
    ///  triggered the event.</param>
    ///  <param name="CanHilite"><c>Boolean</c> [in/out] Set to <c>False</c>
    ///  when called. Should be set to <c>True</c> iff highlighting is
    ///  supported.</param>
    procedure HighlightQueryHandler(Sender: TObject; var CanHilite: Boolean);

    ///  <summary>Handles the custom save dialogue's <c>OnEncodingQuery</c>
    ///  event.</summary>
    ///  <param name="Sender"><c>TObject</c> [in] Reference to the object that
    ///  triggered the event.</param>
    ///  <param name="Encodings"><c>TSourceFileEncodings</c> [in/out] Called
    ///  with an empty array which the event handler must be set to contain the
    ///  encodings supported by the currently selected file type.</param>
    procedure EncodingQueryHandler(Sender: TObject;
      var Encodings: TSourceFileEncodings);

    ///  <summary>Generates the required snippet information in the requested
    ///  format.</summary>
    ///  <param name="FileType"><c>TSourceFileType</c> [in] Type of file to be
    ///  generated.</param>
    ///  <returns><c>TEncodedData</c>. The formatted snippet information, syntax
    ///  highlighted if required.</returns>
    function GenerateOutput(const FileType: TSourceFileType): TEncodedData;

    ///  <summary>Displays the save dialogue box and creates required type of
    ///  snippet information file if the user OKs.</summary>
    procedure DoExecute;

  strict protected

    ///  <summary>Internal constructor. Initialises managed save source dialogue
    ///  box and records information about supported file types.</summary>
    constructor InternalCreate(AView: IView);

  public

    ///  <summary>Object descructor. Tears down object.</summary>
    destructor Destroy; override;

    ///  <summary>Saves information about the snippet referenced by the a given
    ///  view to file.</summary>
    ///  <remarks>The view must be a snippet view.</remarks>
    class procedure Execute(View: IView); static;

    ///  <summary>Checks if the given view can be saved to file. Returns
    ///  <c>True</c> if the view represents a snippet.</summary>
    class function CanHandleView(View: IView): Boolean; static;

  end;

implementation

uses
  // Delphi
  SysUtils,
  Dialogs,
  // Project
  DB.USnippetKind,
  FmPreviewDlg,
  Hiliter.UAttrs,
  Hiliter.UFileHiliter,
  Hiliter.UGlobals,
  UIOUtils,
  UMarkdownSnippetDoc,
  UOpenDialogHelper,
  UPreferences,
  URTFSnippetDoc,
  URTFUtils,
  USourceGen,
  UTextSnippetDoc;

{ TSaveInfoMgr }

class function TSaveInfoMgr.CanHandleView(View: IView): Boolean;
begin
  Result := Supports(View, ISnippetView);
end;

destructor TSaveInfoMgr.Destroy;
begin
  fSourceFileInfo.Free;
  fSaveDlg.Free;
  inherited;
end;

procedure TSaveInfoMgr.DoExecute;
var
  Encoding: TEncoding;        // encoding to use for output file
  FileContent: string;        // output file content before encoding
  FileType: TSourceFileType;  // type of source file
begin
  // Set up dialog box
  fSaveDlg.Filter := fSourceFileInfo.FilterString;
  fSaveDlg.FilterIndex := FilterDescToIndex(
    fSaveDlg.Filter,
    fSourceFileInfo.FileTypeInfo[Preferences.SourceDefaultFileType].DisplayName,
    1
  );
  fSaveDlg.FileName := fSourceFileInfo.DefaultFileName;
  // Display dialog box and save file if user OKs
  if fSaveDlg.Execute then
  begin
    FileType := SelectedFileType;
    Encoding := TEncodingHelper.GetEncoding(fSaveDlg.SelectedEncoding);
    try
      FileContent := GenerateOutput(FileType).ToString;
      TFileIO.WriteAllText(fSaveDlg.FileName, FileContent, Encoding, True);
    finally
      TEncodingHelper.FreeEncoding(Encoding);
    end;
  end;
end;

procedure TSaveInfoMgr.EncodingQueryHandler(Sender: TObject;
  var Encodings: TSourceFileEncodings);
begin
  Encodings := fSourceFileInfo.FileTypeInfo[SelectedFileType].Encodings;
end;

class procedure TSaveInfoMgr.Execute(View: IView);
var
  Instance: TSaveInfoMgr;
begin
  Assert(Assigned(View), 'TSaveInfoMgr.Execute: View is nil');
  Assert(CanHandleView(View), 'TSaveInfoMgr.Execute: View not supported');

  Instance := TSaveInfoMgr.InternalCreate(View);
  try
    Instance.DoExecute;
  finally
    Instance.Free;
  end;
end;

function TSaveInfoMgr.GenerateHTML(const AUseHiliting: Boolean;
  const GeneratorClass: THTMLSnippetDocClass): TEncodedData;
var
  Doc: THTMLSnippetDoc;      // object that generates RTF document
  HiliteAttrs: IHiliteAttrs;  // syntax highlighter formatting attributes
begin
  if (fView as ISnippetView).Snippet.HiliteSource and AUseHiliting then
    HiliteAttrs := THiliteAttrsFactory.CreateUserAttrs
  else
    HiliteAttrs := THiliteAttrsFactory.CreateNulAttrs;
  Doc := GeneratorClass.Create(HiliteAttrs);
  try
    Result := Doc.Generate((fView as ISnippetView).Snippet);
  finally
    Doc.Free;
  end;
end;

function TSaveInfoMgr.GenerateMarkdown: TEncodedData;
var
  Doc: TMarkdownSnippetDoc;
begin
  Assert(Supports(fView, ISnippetView),
    ClassName + '.GeneratePlainText: View is not a snippet view');
  Doc := TMarkdownSnippetDoc.Create(
    (fView as ISnippetView).Snippet.Kind <> skFreeform
  );
  try
    Result := Doc.Generate((fView as ISnippetView).Snippet);
  finally
    Doc.Free;
  end;
end;

function TSaveInfoMgr.GenerateOutput(const FileType: TSourceFileType):
  TEncodedData;
var
  UseHiliting: Boolean;
begin
  UseHiliting := fSaveDlg.UseSyntaxHiliting and
    TFileHiliter.IsHilitingSupported(FileType);
  case FileType of
    sfRTF: Result := GenerateRichText(fView, UseHiliting);
    sfText: Result := GeneratePlainText;
    sfHTML5: Result := GenerateHTML(UseHiliting, THTML5SnippetDoc);
    sfXHTML: Result := GenerateHTML(UseHiliting, TXHTMLSnippetDoc);
    sfMarkdown: Result := GenerateMarkdown;
  end;
end;

function TSaveInfoMgr.GeneratePlainText: TEncodedData;
var
  Doc: TTextSnippetDoc;        // object that generates RTF document
  HiliteAttrs: IHiliteAttrs;  // syntax highlighter formatting attributes
begin
  Assert(Supports(fView, ISnippetView),
    ClassName + '.GeneratePlainText: View is not a snippet view');
  HiliteAttrs := THiliteAttrsFactory.CreateNulAttrs;
  Doc := TTextSnippetDoc.Create;
  try
    Result := Doc.Generate((fView as ISnippetView).Snippet);
  finally
    Doc.Free;
  end;
end;

class function TSaveInfoMgr.GenerateRichText(View: IView;
  const AUseHiliting: Boolean): TEncodedData;
var
  Doc: TRTFSnippetDoc;        // object that generates RTF document
  HiliteAttrs: IHiliteAttrs;  // syntax highlighter formatting attributes
begin
  Assert(Supports(View, ISnippetView),
    'TSaveInfoMgr.GenerateRichText: View is not a snippet view');
  if (View as ISnippetView).Snippet.HiliteSource and AUseHiliting then
    HiliteAttrs := THiliteAttrsFactory.CreateUserAttrs
  else
    HiliteAttrs := THiliteAttrsFactory.CreateNulAttrs;
  Doc := TRTFSnippetDoc.Create(HiliteAttrs);
  try
    // TRTFSnippetDoc generates stream of ASCII bytes
    Result := Doc.Generate((View as ISnippetView).Snippet);
    Assert(Result.EncodingType = etASCII,
      'TSaveInfoMgr.GenerateRichText: ASCII encoded data expected');
  finally
    Doc.Free;
  end;
end;

procedure TSaveInfoMgr.HighlightQueryHandler(Sender: TObject;
  var CanHilite: Boolean);
begin
  CanHilite := TFileHiliter.IsHilitingSupported(SelectedFileType);
end;

constructor TSaveInfoMgr.InternalCreate(AView: IView);
const
  DlgHelpKeyword = 'SnippetInfoFileDlg';
resourcestring
  sDefFileName = 'SnippetInfo';
  sDlgCaption = 'Save Snippet Information';
  // descriptions of supported encodings
  sASCIIEncoding = 'ASCII';
  sANSIDefaultEncoding = 'ANSI (Default)';
  sUTF8Encoding = 'UTF-8';
  sUTF16LEEncoding = 'Unicode (Little Endian)';
  sUTF16BEEncoding = 'Unicode (Big Endian)';
  // descriptions of supported file filter strings
  sRTFDesc = 'Rich text file';
  sTextDesc = 'Plain text file';
  sHTML5Desc = 'HTML 5 file';
  sXHTMLDesc = 'XHTML file';
  sMarkdownDesc = 'Markdown file';
begin
  inherited InternalCreate;
  fView := AView;
  fSourceFileInfo := TSourceFileInfo.Create;
  // RTF and plain text files supported at present
  fSourceFileInfo.FileTypeInfo[sfRTF] := TSourceFileTypeInfo.Create(
    '.rtf',
    sRTFDesc,
    [
      TSourceFileEncoding.Create(etASCII, sASCIIEncoding)
    ]
  );
  fSourceFileInfo.FileTypeInfo[sfText] := TSourceFileTypeInfo.Create(
    '.txt',
    sTextDesc,
    [
      TSourceFileEncoding.Create(etUTF8, sUTF8Encoding),
      TSourceFileEncoding.Create(etUTF16LE, sUTF16LEEncoding),
      TSourceFileEncoding.Create(etUTF16BE, sUTF16BEEncoding),
      TSourceFileEncoding.Create(etSysDefault, sANSIDefaultEncoding)
    ]
  );
  fSourceFileInfo.FileTypeInfo[sfHTML5] := TSourceFileTypeInfo.Create(
    '.html',
    sHTML5Desc,
    [
      TSourceFileEncoding.Create(etUTF8, sUTF8Encoding)
    ]
  );
  fSourceFileInfo.DefaultFileName := sDefFileName;
  fSourceFileInfo.FileTypeInfo[sfXHTML] := TSourceFileTypeInfo.Create(
    '.html',
    sXHTMLDesc,
    [
      TSourceFileEncoding.Create(etUTF8, sUTF8Encoding)
    ]
  );
  fSourceFileInfo.DefaultFileName := sDefFileName;
  fSourceFileInfo.FileTypeInfo[sfMarkdown] := TSourceFileTypeInfo.Create(
    '.md',
    sMarkdownDesc,
    [
      TSourceFileEncoding.Create(etUTF8, sUTF8Encoding),
      TSourceFileEncoding.Create(etUTF16LE, sUTF16LEEncoding),
      TSourceFileEncoding.Create(etUTF16BE, sUTF16BEEncoding),
      TSourceFileEncoding.Create(etSysDefault, sANSIDefaultEncoding)
    ]
  );
  fSourceFileInfo.DefaultFileName := sDefFileName;

  fSaveDlg := TSaveSourceDlg.Create(nil);
  fSaveDlg.Title := sDlgCaption;
  fSaveDlg.HelpKeyword := DlgHelpKeyword;
  fSaveDlg.CommentStyle := TCommentStyle.csNone;
  fSaveDlg.EnableCommentStyles := False;
  fSaveDlg.TruncateComments := Preferences.TruncateSourceComments;
  fSaveDlg.UseSyntaxHiliting := Preferences.SourceSyntaxHilited;
  fSaveDlg.OnPreview := PreviewHandler;
  fSaveDlg.OnHiliteQuery := HighlightQueryHandler;
  fSaveDlg.OnEncodingQuery := EncodingQueryHandler;
end;

procedure TSaveInfoMgr.PreviewHandler(Sender: TObject);
resourcestring
  sDocTitle = '"%0:s" snippet';
var
  // Type of snippet information document to preview: this is not always the
  // same as the selected file type, because preview dialogue box doesn't
  // support some types & we have to use an alternate.
  PreviewFileType: TSourceFileType;
  // Type of preview document supported by preview dialogue box
  PreviewDocType: TPreviewDocType;
begin
  case SelectedFileType of
    sfRTF:
    begin
      // RTF is previewed as is
      PreviewDocType := dtRTF;
      PreviewFileType := sfRTF;
    end;
    sfText:
    begin
      // Plain text us previewed as is
      PreviewDocType := dtPlainText;
      PreviewFileType := sfText;
    end;
    sfHTML5, sfXHTML:
    begin
      // Both HTML 5 and XHTML are previewed as XHTML
      PreviewDocType := dtHTML;
      PreviewFileType := sfXHTML;
    end;
    sfMarkdown:
    begin
      // Markdown is previewed as plain text
      PreviewDocType := dtPlainText;
      PreviewFileType := sfMarkdown;
    end;
    else
      raise Exception.Create(
        ClassName + '.PreviewHandler: unsupported file type'
      );
  end;
  // Display preview dialogue box aligned over the save dialogue
  TPreviewDlg.Execute(
    fSaveDlg,
    GenerateOutput(PreviewFileType),
    PreviewDocType,
    Format(sDocTitle, [fView.Description])
  );
end;

function TSaveInfoMgr.SelectedFileType: TSourceFileType;
begin
  Result := fSourceFileInfo.FileTypeFromFilterIdx(fSaveDlg.FilterIndex);
end;

end.
