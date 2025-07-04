{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at https://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2005-2022, Peter Johnson (gravatar.com/delphidabbler).
 *
 * Classes that help create and manage cascading style sheet code.
}


unit UCSSBuilder;


interface


uses
  // Delphi
  Generics.Collections,
  // Project
  UIStringList;


type

  {
  TCSSSelector:
    Class that encapsulates a CSS selector and outputs its CSS code.
  }
  TCSSSelector = class(TObject)
  strict private
    var
      fProperties: IStringList; // List of properties for this selector
      fSelector: string;        // Name of selector
  public
    constructor Create(const Selector: string);
      {Constructor. Creates a CSS selector object with given name.
        @param Selector [in] Name of selector.
      }
    function AsString: string;
      {Generates the CSS code representing the selector.
        @return Required CSS code.
      }
    function IsEmpty: Boolean;
      {Checks whether the selector is empty, i.e. contains no code.
        @return True if selector is empty and false if not.
      }
    ///  <summary>Adds a new CSS property to the selector.</summary>
    ///  <param name="CSSProp">string [in] Property definition.</param>
    ///  <returns>TCSSSelector. Class instance returned to enable the method to
    ///  be chained.</returns>
    function AddProperty(const CSSProp: string): TCSSSelector;
    ///  <summary>Adds a new CSS property to the selector depending on a given
    ///  condition.</summary>
    ///  <param name="Condition">Boolean [in] Condition that determines which
    ///  CSS property is added.</param>
    ///  <param name="CSSPropTrue">string [in] CSS property that is added when
    ///  Condition is True.</param>
    ///  <param name="CSSPropFalse">string [in] CSS property that is added when
    ///  Condition is False.</param>
    ///  <returns>TCSSSelector. Class instance returned to enable the method to
    ///  be chained.</returns>
    function AddPropertyIf(const Condition: Boolean;
      const CSSPropTrue: string; const CSSPropFalse: string = ''): TCSSSelector;
    ///  <summary>Name of selector.</summary>
    property Selector: string read fSelector;
  end;

  {
  TCSSBuilder:
    Class that creates a CSS style sheet and outputs its CSS code.
  }
  TCSSBuilder = class(TObject)
  strict private
    type
      // Class that maps CSS selector names to selector objects
      TCSSSelectorMap = TObjectDictionary<string,TCSSSelector>;
    var
      fSelectors: TCSSSelectorMap;    // Maps selector names to selector objects
      fSelectorNames: TList<string>;  // Lists selector names in order created
    function GetSelector(const Selector: string): TCSSSelector;
      {Read access method for Selectors property. Returns selector object with
      given name.
        @param Selector [in] Name of required selector.
        @return Selector object with given name or nil if not found.
      }
  public
    constructor Create;
      {Constructor. Sets up object.
      }
    destructor Destroy; override;
      {Destructor. Tears down object.
      }
    function AddSelector(const Selector: string): TCSSSelector;
      {Adds a new empty selector with given name to style sheet.
        @param Selector [in] Name of new selector.
        @return New empty selector object.
      }
    function EnsureSelector(const Selector: string): TCSSSelector;
      {Returns selector object with given name or adds a new selector with the
      given name if no such selector exists.
        @parm Selector [in] Name of selector.
        @return Reference to new or pre-existing selector.
      }
    procedure Clear;
      {Clears all selectors from style sheet and frees selector objects.
      }

    ///  <summary>Generates CSS code representing the style sheet.</summary>
    ///  <returns><c>string</c>. The required CSS.</returns>
    ///  <remarks>The selectors are returned in the order they were created.
    ///  </remarks>
    function AsString: string;

    property Selectors[const Selector: string]: TCSSSelector
      read GetSelector;
      {Array of CSS selectors in style sheet, indexed by selector name}
  end;


implementation


uses
  // Project
  UComparers, UConsts;


{ TCSSSelector }

function TCSSSelector.AddProperty(const CSSProp: string): TCSSSelector;
begin
  fProperties.Add(CSSProp);
  Result := Self;
end;

function TCSSSelector.AddPropertyIf(const Condition: Boolean;
  const CSSPropTrue: string; const CSSPropFalse: string): TCSSSelector;
begin
  if Condition then
    AddProperty(CSSPropTrue)
  else if CSSPropFalse <> '' then
    AddProperty(CSSPropFalse);
  Result := Self;
end;

function TCSSSelector.AsString: string;
  {Generates the CSS code representing the selector.
    @return Required CSS code.
  }
var
  Lines: IStringList;   // lines of CSS
begin
  Lines := TIStringList.Create;
  // Compose CSS selector statement
  Lines.Add(Selector + ' {');
  if fProperties.Count > 0 then
    Lines.Add(fProperties);
  Lines.Add('}');
  // Write CSS in string
  Result := Lines.GetText(EOL, False) + EOL;
end;

constructor TCSSSelector.Create(const Selector: string);
  {Constructor. Creates a CSS selector object with given name.
    @param Selector [in] Name of selector.
  }
begin
  Assert(Selector <> '', ClassName + '.Create: selector is empty string');
  inherited Create;
  fSelector := Selector;
  fProperties := TIStringList.Create;
end;

function TCSSSelector.IsEmpty: Boolean;
  {Checks whether the selector is empty, i.e. contains no code.
    @return True if selector is empty and false if not.
  }
begin
  // Selector is empty if background colour not set, there is no font,
  // margin is not defined and there is no extra CSS
  Result := fProperties.Count = 0;
end;

{ TCSSBuilder }

function TCSSBuilder.AddSelector(const Selector: string): TCSSSelector;
  {Adds a new empty selector with given name to style sheet.
    @param Selector [in] Name of new selector.
    @return New empty selector object.
  }
begin
  Result := TCSSSelector.Create(Selector);
  fSelectors.Add(Selector, Result);
  fSelectorNames.Add(Selector);
end;

function TCSSBuilder.AsString: string;
var
  SelectorName: string;   // name of each selector
  Selector: TCSSSelector; // reference to each selector in map
begin
  Result := '';
  for SelectorName in fSelectorNames do
  begin
    Selector := fSelectors[SelectorName];
    if not Selector.IsEmpty then
      Result := Result + Selector.AsString;
  end;
end;

procedure TCSSBuilder.Clear;
  {Clears all selectors from style sheet and frees selector objects.
  }
begin
  fSelectorNames.Clear;
  fSelectors.Clear;       // frees owened selector objects in dictionary
end;

constructor TCSSBuilder.Create;
  {Constructor. Sets up object.
  }
begin
  inherited;
  // fSelectors treats selector names are not case sensitive
  // fSelectors owns value objects and frees them when they are removed from map
  fSelectors := TCSSSelectorMap.Create(
    [doOwnsValues], TTextEqualityComparer.Create
  );
  fSelectorNames := TList<string>.Create;
end;

destructor TCSSBuilder.Destroy;
  {Destructor. Tears down object.
  }
begin
  fSelectorNames.Free;
  fSelectors.Free;    // frees owened selector objects in dictionary
  inherited;
end;

function TCSSBuilder.EnsureSelector(const Selector: string): TCSSSelector;
  {Returns selector object with given name or adds a new selector with the given
  name if no such selector exists.
    @parm Selector [in] Name of selector.
    @return Reference to new or pre-existing selector.
  }
begin
  Result := GetSelector(Selector);
  if not Assigned(Result) then
    Result := AddSelector(Selector);
end;

function TCSSBuilder.GetSelector(const Selector: string): TCSSSelector;
  {Read access method for Selectors property. Returns selector object with given
  name.
    @param Selector [in] Name of required selector.
    @return Selector object with given name or nil if not found.
  }
begin
  if fSelectors.ContainsKey(Selector) then
    Result := fSelectors[Selector]
  else
    Result := nil;
end;

end.

