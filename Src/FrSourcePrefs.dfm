inherited SourcePrefsFrame: TSourcePrefsFrame
  Width = 393
  Height = 323
  ExplicitWidth = 393
  ExplicitHeight = 323
  DesignSize = (
    393
    323)
  object gbSourceCode: TGroupBox
    Left = 0
    Top = 0
    Width = 393
    Height = 219
    Anchors = [akLeft, akTop, akRight]
    Caption = ' Source code formatting '
    TabOrder = 0
    object lblCommentStyle: TLabel
      Left = 8
      Top = 24
      Width = 89
      Height = 13
      Caption = '&Commenting style:'
      FocusControl = cbCommentStyle
    end
    object cbCommentStyle: TComboBox
      Left = 122
      Top = 19
      Width = 198
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbCommentStyleChange
    end
    inline frmPreview: TRTFShowCaseFrame
      Left = 122
      Top = 46
      Width = 198
      Height = 123
      TabOrder = 1
      ExplicitLeft = 122
      ExplicitTop = 46
      ExplicitWidth = 198
      ExplicitHeight = 123
      inherited reView: TRichEdit
        Width = 198
        Height = 123
        ExplicitWidth = 198
        ExplicitHeight = 123
      end
    end
    object chkTruncateComments: TCheckBox
      Left = 8
      Top = 175
      Width = 233
      Height = 17
      Caption = '&Truncate comments to one paragraph'
      TabOrder = 2
    end
    object chkUnitImplComments: TCheckBox
      Left = 8
      Top = 195
      Width = 345
      Height = 17
      Caption = 'Repeat comments in &unit implemenation section'
      TabOrder = 3
    end
  end
  object gbFileFormat: TGroupBox
    Left = 0
    Top = 229
    Width = 393
    Height = 81
    Anchors = [akLeft, akTop, akRight]
    Caption = ' File formatting '
    TabOrder = 1
    object lblSnippetFileType: TLabel
      Left = 8
      Top = 24
      Width = 76
      Height = 13
      Caption = '&Ouput file type:'
      FocusControl = cbSnippetFileType
    end
    object chkSyntaxHighlighting: TCheckBox
      Left = 122
      Top = 47
      Width = 247
      Height = 21
      Caption = 'Enable &syntax highlighting'
      TabOrder = 1
    end
    object cbSnippetFileType: TComboBox
      Left = 122
      Top = 20
      Width = 81
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbSnippetFileTypeChange
    end
  end
end
