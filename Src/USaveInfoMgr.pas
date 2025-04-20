{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at https://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2025, Peter Johnson (gravatar.com/delphidabbler).
 *
 * Saves information about a snippet to disk in rich text format. Only routine
 * snippet kinds are supported.
}


unit USaveInfoMgr;

interface

uses
  // Project
  UBaseObjects,
  UEncodings,
  USaveSourceDlg,
  USourceFileInfo,
  UView;


type
  ///  <summary>Class that saves information about a snippet to file in rich
  ///  text format. The snippet is obtained from a view. Only snippet views are
  ///  supported.</summary>
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
  FmPreviewDlg,
  Hiliter.UAttrs,
  Hiliter.UFileHiliter,
  Hiliter.UGlobals,
  UIOUtils,
  UOpenDialogHelper,
  UPreferences,
  URTFSnippetDoc,
  URTFUtils,
  USourceGen;

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
    FileContent := GenerateOutput(FileType).ToString;
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

function TSaveInfoMgr.GenerateOutput(const FileType: TSourceFileType):
  TEncodedData;
var
  UseHiliting: Boolean;
begin
  UseHiliting := fSaveDlg.UseSyntaxHiliting and
    TFileHiliter.IsHilitingSupported(FileType);
  case FileType of
    sfRTF: Result := GenerateRichText(fView, UseHiliting);
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
  // descriptions of supported file filter strings
  sRTFDesc = 'Rich text file';
begin
  inherited InternalCreate;
  fView := AView;
  fSourceFileInfo := TSourceFileInfo.Create;
  // only RTF file type supported at present
  fSourceFileInfo.FileTypeInfo[sfRTF] := TSourceFileTypeInfo.Create(
    '.rtf',
    sRTFDesc,
    [
      TSourceFileEncoding.Create(etASCII, sASCIIEncoding)
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
begin
  // Display preview dialog box. We use save dialog as owner to ensure preview
  // dialog box is aligned over save dialog box
  TPreviewDlg.Execute(
    fSaveDlg,
    GenerateOutput(sfRTF),
    dtRTF,
    Format(sDocTitle, [fView.Description])
  );
end;

function TSaveInfoMgr.SelectedFileType: TSourceFileType;
begin
  Result := fSourceFileInfo.FileTypeFromFilterIdx(fSaveDlg.FilterIndex);
end;

end.
