{*********************************************************}
{*                  OPREPLAY.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1989, 1992.     *}
{* Portions Copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows applications !!  {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F-,O-,A-}

{$IFDEF Dpmi}                                                         {!!.20}
  {$C FIXED PRELOAD PERMANENT}                                        {!!.20}
{$ENDIF}                                                              {!!.20}

{$I opdefine.inc}

unit OpReplay;
  {-Macro playback. FPC port: INT $16 hooking replaced by the OPKEYHK hook
    (see OPKEYHK.PAS); OPSCRAP.ASM/OPREPLAY.ASM ported to Pascal.}

interface

uses
  OpKeyHk;

const
  MaxKeysInMacro = 1000;     {arbitrary}
  EndOfMacro = $0FFFF;       {signals end of a macro}
type
  MacroRecPtr = ^MacroRec;
  MacroRec =
    record
      NumKeys  : Word;       {number of keys except the last, always $0FFFF}
      KeyArray : array[1..MaxKeysInMacro] of Word;
      Overflow : Word;       {may be needed to mark end of macro}
    end;
const
  ScrapMacroSize     : Word = 0;  {maximum # of keys in ScrapMacroPtr^}
  ScrapMacroPtr      : MacroRecPtr = nil; {pointer to scrap macro}
var
  MacroInProgressPtr : ^Boolean;  {macro is being played back}
  CurrentMacroPtr    : ^Pointer;  {pointer to address of current macro}

procedure StartMacro(Macro : MacroRecPtr);
  {-Starts execution of the specified macro}

function CharToMacro(MacroChar : Char) : Word;
  {-Converts a character to a keyboard code/char representation. This table
    holds all scan code values for ASCII characters from 0 to 63. All alpha
    characters can be mapped to this table by subtracting a number divisible
    by 32 that would put that alpha in the range of 0..63.}

procedure StringToScrapMacro(S : string);
  {-Initialize ScrapMacro from a string}

procedure StringToMacro(S : string; MRP : MacroRecPtr; MaxKeys : Word);
  {-Initialize MRP^ from a string}

procedure Int16;
  {-FPC port: stub (no INT $16 vector exists). Use InstallReplayHook.}

procedure InstallReplayHook;
  {-FPC port: install the macro playback engine into the OPKEYHK key hook
    chain (replaces SetIntVec($16, @Int16))}

procedure RemoveReplayHook;
  {-FPC port: remove the playback engine installed by InstallReplayHook}

procedure SetEndOfMacroProc(P : Pointer);
  {-Set pointer to procedure to call when end of macro reached}

procedure InitScrapMacroPtr;
  {-Initialize ScrapMacroPtr}

procedure SetWaitCount(Count : Byte);           {!!.13}
  {-Set a wait count. This count is the number of times int 16 function 1 will
    pause before returning the next character in the macro. This fixes
    compatibility problems with some applications, such as Clipper programs.
    The default wait count is 0. A Wait count of 5 is recommended for Clipper
    based programs.}
  {==========================================================================}

implementation

uses
  SysUtils;

const
  EndOfMacroProc : Pointer = nil;
type
  WordPtr = ^Word;
  EndProc = procedure;
var
  MacroInProgress : Boolean;
  CurrentMacro : Pointer;
  WaitCount : Byte;
  WaitFlag : Byte;
  ScrapBuf : array[0..MaxKeysInMacro+2] of Word;
  SavedKeyHook : KeyHookFunc;
  HookInstalled : Boolean;

  function ReplayKeyHook(Peek : Boolean; var Key : Word) : Boolean;
    {-Macro playback engine (port of INT16 in OPREPLAY.ASM). Keys come from
      the current macro while one is in progress, otherwise from the previous
      hook or the native keyboard.}
  var
    K : Word;
    Proc : EndProc;
  begin
    while MacroInProgress do begin
      K := WordPtr(CurrentMacro)^;
      if K = EndOfMacro then begin
        MacroInProgress := False;
        if EndOfMacroProc <> nil then begin
          Proc := EndProc(EndOfMacroProc);
          Proc;
        end;
      end
      else begin
        if Peek then begin
          if WaitCount <> 0 then begin
            Inc(WaitFlag);
            if WaitFlag <= WaitCount then begin
              ReplayKeyHook := False;
              Exit;
            end;
            WaitFlag := 0;
          end;
        end
        else
          CurrentMacro := Pointer(PtrUInt(CurrentMacro)+SizeOf(Word));
        Key := K;
        ReplayKeyHook := True;
        Exit;
      end;
    end;

    if Assigned(SavedKeyHook) then
      ReplayKeyHook := SavedKeyHook(Peek, Key)
    else if Peek then
      ReplayKeyHook := Assigned(RawCheckKbdProc) and RawCheckKbdProc(Key)
    else begin
      Key := RawReadKeyWordProc;
      ReplayKeyHook := True;
    end;
  end;

  procedure Int16;
    {FPC port: stubbed because there is no INT $16 vector to chain; use
     InstallReplayHook/RemoveReplayHook instead}
  begin
  end;

  procedure InstallReplayHook;
  begin
    if not HookInstalled then begin
      SavedKeyHook := KeyHook;
      KeyHook := KeyHookFunc(@ReplayKeyHook);
      HookInstalled := True;
    end;
  end;

  procedure RemoveReplayHook;
  begin
    if HookInstalled then begin
      KeyHook := SavedKeyHook;
      HookInstalled := False;
    end;
  end;

  procedure SetEndOfMacroProc(P : Pointer);
  begin
    EndOfMacroProc := P;
  end;

  procedure SetWaitCount(Count : Byte);
  begin
    if Count = 255 then
      Dec(Count);
    WaitCount := Count;
  end;

  procedure InitScrapMacroPtr;
  begin
    ScrapMacroSize := MaxKeysInMacro;
    ScrapMacroPtr := MacroRecPtr(@ScrapBuf);
    ScrapMacroPtr^.NumKeys := 0;
    ScrapMacroPtr^.KeyArray[1] := EndOfMacro;
  end;

  procedure StartMacro(Macro : MacroRecPtr);
    {-Starts execution of the specified macro. If a macro is already in
      progress it will immediately be replaced by the macro passed.}
  begin
    if Macro <> nil then begin
      {make this macro current, skipping past the length word}
      CurrentMacro := Pointer(PtrUInt(Macro)+SizeOf(Word));
      MacroInProgress := True;
      WaitFlag := 0;
    end;
  end;

  function CharToMacro(MacroChar : Char) : Word;
   {-Converts a character to a keyboard code/char representation. This table
     holds all scan code values for ASCII characters from 0 to 63. All alpha
     characters can be mapped to this table by subtracting a number divisible
     by 32 that would put that alpha in the range of 0..63.}
  const
    ScanCodes : array[0..63] of Byte = (
      $03, {@} $1E, {A} $30, {B} $2E, {C} $20, {D} $12, {E} $21, {F} $22, {G}
      $23, {H} $17, {I} $24, {J} $25, {K} $26, {L} $32, {M} $31, {N} $18, {O}
      $19, {P} $10, {Q} $13, {R} $1f, {S} $14, {T} $16, {U} $2f, {V} $11, {W}
      $2d, {X} $15, {Y} $2c, {Z} $1a, {[} $2b, {\} $1b, {]} $07, {^} $0c, {_}
      $39, { } $02, {!} $28, {"} $04, {#} $5, { $} $06, {%} $08, {&} $28, {'}
      $0A, {(} $0b, {)} $09, {*} $0d, {+} $33, {,} $0c, {-} $34, {.} $35, {/}
      $0b, {0} $02, {1} $03, {2} $04, {3} $05, {4} $06, {5} $07, {6} $08, {7}
      $09, {8} $0A, {9} $27, {:} $27, {;} $33, {<} $0d, {=} $34, {>} $35  {?}
    );
  var
    CharCode : Byte absolute MacroChar;
  begin
    {FPC port: ^M and ^[ tested first, FPC rejects overlapping case labels}
    if MacroChar = ^M then
      CharToMacro := $1C0D
    else if MacroChar = ^[ then
      CharToMacro := $011B  {!!.13}
    else
    case MacroChar of
      #0..'?' :
        CharToMacro := (ScanCodes[CharCode] shl 8) or CharCode;
      '@'..'_' :
        CharToMacro := (ScanCodes[CharCode-64] shl 8) or CharCode;
      '`', '~' :
        CharToMacro := $2900 or CharCode;
      'a'..'}' :
        CharToMacro := (ScanCodes[CharCode-96] shl 8) or CharCode;
      #127 :
        CharToMacro := $0EFF;
      else
        CharToMacro := CharCode;
    end;
  end;

  procedure StringToMacro(S : string; MRP : MacroRecPtr; MaxKeys : Word);
    {-Initialize MRP^ from a string}
  var
    SLen : Byte absolute S;
    I : Word;
  begin
    if (MaxKeys > 0) and (MRP <> nil) then begin
      if SLen > MaxKeys then
        SLen := MaxKeys;
      with MRP^ do begin
        NumKeys := SLen;
        for I := 1 to SLen do
          KeyArray[I] := CharToMacro(S[I]);
        KeyArray[SLen+1] := EndOfMacro;
      end;
    end;
  end;

  procedure StringToScrapMacro(S : string);
    {-Initialize ScrapMacro from a string}
  begin
    StringToMacro(S, ScrapMacroPtr, ScrapMacroSize);
  end;

begin
  MacroInProgress := False;
  CurrentMacro := nil;
  WaitCount := 0;
  WaitFlag := 0;
  HookInstalled := False;
  SavedKeyHook := nil;
  MacroInProgressPtr := @MacroInProgress;
  CurrentMacroPtr := @CurrentMacro;
end.
