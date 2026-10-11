{*********************************************************}
{*                   OPMACRO.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
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

unit OpMacro;
  {-Macro processing/recording routines.}

interface

{ FPC port: the INT $16 keyboard handler of the original is replaced by a hook
  (OpKeyHk.KeyHook) that OPCRT's ReadKeyWord/CheckKbd call. The macro engine
  (MacroKeyHook below) is a port of the INT16 routine in OPMACRO.ASM. }

uses
  Dos, OpKeyHk;

const
  MaxMacros = 100;
  MaxKeysInMacro = 1000;
  EndOfMacro = $0FFFF;       {signals end of a macro}
  Int16Handle = 12;          {Number assigned to the INT $16 handler}
  PlaybackDelay : Word = 0;  {milliseconds to delay during playback}

const
  {Macro file identification values.  These values are stored at
   the beginning of any valid macro file to insure validity.}
  MacroFileID : LongInt = $04001087;

type
  MacroRecPtr = ^MacroRec;
  MacroRec =
    record
      NumKeys : Word;        {number of keys except the last, always $0FFFF}
      KeyArray : array[1..MaxKeysInMacro] of Word;
      Overflow : Word;       {may be needed to mark end of macro}
    end;
  StringPointer = ^string;
var
  MacrosAreOn : Boolean;     {macro processing enabled}
  MacroRecording : Boolean;  {macro recording enabled}
  MacroInProgress : Boolean; {macro is being played back}
  MacroPointers : array[1..MaxMacros] of Pointer; {Pointers to defined macros}
  MacroNames : array[1..MaxMacros] of Pointer; {Pointers to macro names}
  DefinedKeys : array[1..MaxMacros] of Word; {Defined macro keys}
  ScrapMacro : MacroRec;     {used when recording macros, etc.}
  ScrapMacroKey : Word;      {"}
  ScrapMacroName : string;   {"}

function DefineMacro(Key : Word; var Macro) : Boolean;
  {-Define a new macro or delete an existing one.}

function MacroAddress(Key : Word) : Pointer;
  {-Returns a pointer to the macro for a key, or nil if key is not defined.}

function MacroCount : Word;
  {-Returns the number of macros that have been defined}

function AllocateMacro(Key : Word; var Macro; var Name : string) : Byte;
  {-Allocates a macro on the heap, and returns one of the following values:
     0 : Macro allocated
     1 : Macro table full
     2 : Out of heap space
     3 : Macro was blank }

function DeallocateMacro(Key : Word) : Boolean;
  {-If the macro exists, this routine erases it and deallocates its memory.
    Returns False if the macro was not found.}

function AssignMacroName(Key : Word; var Name : string) : Boolean;
  {-Assign a Name to a macro, deleting the existing name assigned to the
    macro, if any. Returns false if insufficient memory exists or macro
    not found.}

function ReadMacroFile(FName : string; Merge : Boolean) : Byte;
  {-Read a macro file. Returns 0 if successful, $FF if not a valid macro
    file, $FE if we ran out of memory, else IOresult. If Merge is false, any
    existing macros are deleted before the file is read.}

function WriteMacroFile(FName : string) : Byte;
  {-Write a macro file. Returns 0 if successful, else IOresult.}

procedure ClearMacros;
  {-Clears out the current macros.}

procedure MacrosOn;
  {-Turns macro processing on}

procedure MacrosOff;
  {-Turns macro processing off}

procedure MacroRecordingOn;
  {-Turns macro recording on}

procedure MacroRecordingOff;
  {-Turns macro recording off}

procedure StartMacro(Macro : Pointer);
  {-Starts execution of the specified macro. If a macro is already in
    progress it will immediately be replaced by the macro passed.}

procedure StartMacroByKey(Key : Word);
  {-Starts execution of the macro attached to key, if any. If a macro is
    already in progress it will immediately be replaced by the macro passed.}

procedure RemoveMacros;
  {-Restores all vectors associated with macros.}

procedure SetEndOfMacroProc(P : Pointer);
  {-Set pointer to procedure to call when end of macro reached}

function FindMacroIndex(Key : Word) : Word;
  {-Find the array index for the macro assigned to Key. Returns 0 if not
    found.}

function InitMacros : Boolean;
  {-Initializes macros. After this routine is called, no macros will be
    defined and both macro processing and macro recording will be turned off.
    Returns false if INT $16 cannot be taken over.}

function CharToMacro(MacroChar : Char) : Word;
  {-Converts a character to a keyboard code/char representation. This table
    holds all scan code values for ASCII characters from 0 to 63. All alpha
    characters can be mapped to this table by subtracting a number divisible
    by 32 that would put that alpha in the range of 0..63.}

procedure StringToMacro(S : string; MRP : MacroRecPtr; MaxKeys : Word);
  {-Initialize MRP^ from a string}

procedure StringToScrapMacro(S : string);
  {-Initialize ScrapMacro from a string}

procedure KeyToString(Key : Word; var S : string; var Special : Boolean);
  {-Returns a string (S) representing a Key. Special is set to False if
    a simple character is being returned.}

procedure SetWaitCount(Count : Byte); {!!.20}
  {-Set a wait count. This count is the number of times int 16 function 1 will
    pause before returning the next character in the macro. This fixes
    compatibility problems with some applications, such as Clipper programs.
    The default wait count is 0. A Wait count of 5 is recommended for Clipper
    based programs.}

{.Z+}
{+++ for internal use -- needed by OPMACED +++}
function EscapeSequence(B : Byte) : StringPointer;
  {-Return a pointer to a string representing extended scan code B}
{.Z-}

  {==========================================================================}

implementation

uses
  SysUtils;

const
  Initialized : Boolean = False; {true if key hook installed}
  EndOfMacroProc : Pointer = nil;

  OurMaxMacros : Word = MaxMacros;
  OurMaxKeys : Word = MaxKeysInMacro;
type
  WordPtr = ^Word;
  EndProc = procedure;
var
  CurrentMacro : Pointer;    {Address of the macro in progress}
  WaitCount : Byte; {!!.20}
  WaitFlag : Byte;  {!!.20}
  SavedKeyHook : KeyHookFunc;

  procedure RecordKey(K : Word);
    {-Add K to ScrapMacro if recording and there is room}
  begin
    with ScrapMacro do
      if NumKeys < OurMaxKeys then begin
        Inc(NumKeys);
        KeyArray[NumKeys] := K;
        KeyArray[NumKeys+1] := EndOfMacro;
      end;
  end;

  function MacroKeyHook(Peek : Boolean; var Key : Word) : Boolean; far;
    {-The macro engine. It takes over for BIOS INT $16 (function 0/1).
      Peek = True behaves like "character ready", False like "read next".}
  var
    K : Word;
    Consumed : Boolean;
    I : Word;
    P : WordPtr;
    Proc : EndProc;
  begin
    Consumed := False;
    K := 0;
    repeat
      if MacroInProgress then begin
        P := WordPtr(CurrentMacro);
        K := P^;
        if K = EndOfMacro then begin
          {at end of macro: stop it and call the user's procedure, if any}
          MacroInProgress := False;
          if EndOfMacroProc <> nil then begin
            Proc := EndProc(EndOfMacroProc);
            Proc;
          end;
          Continue;
        end;

        if Peek then begin
          {pause WaitCount times before returning the next macro key}
          if WaitCount <> 0 then begin
            Inc(WaitFlag);
            if WaitFlag <= WaitCount then begin
              MacroKeyHook := False;
              Exit;
            end;
            WaitFlag := 0;
          end;
          Key := K;
          MacroKeyHook := True;
          Exit;
        end;

        {remove the key from the macro}
        CurrentMacro := Pointer(PtrUInt(CurrentMacro)+SizeOf(Word));
        if PlaybackDelay <> 0 then
          SysUtils.Sleep(PlaybackDelay);
        if MacroRecording then
          RecordKey(K);
        Key := K;
        MacroKeyHook := True;
        Exit;
      end;

      {not in a macro: look at the real keyboard}
      if not Consumed then begin
        if Assigned(RawCheckKbdProc) and RawCheckKbdProc(K) then
          {key waiting}
        else if Peek then begin
          MacroKeyHook := False;
          Exit;
        end
        else begin
          {nothing waiting: block for the next key}
          K := RawReadKeyWordProc;
          Consumed := True;
        end;
      end;

      {see if the key starts a macro}
      I := 0;
      if MacrosAreOn and (K <> EndOfMacro) then
        I := FindMacroIndex(K);
      if I <> 0 then begin
        {get rid of the key that caused the macro, then start the macro}
        if not Consumed then
          K := RawReadKeyWordProc;
        Consumed := False;
        CurrentMacro := Pointer(PtrUInt(MacroPointers[I])+SizeOf(Word));
        MacroInProgress := True;
        Continue;
      end;

      {ordinary key}
      if not Peek then begin
        if not Consumed then
          K := RawReadKeyWordProc;
        if MacroRecording then
          RecordKey(K);
      end;
      Key := K;
      MacroKeyHook := True;
      Exit;
    until False;
  end;

  procedure SetWaitCount(Count : Byte);
    {-Set a wait count for CharReady calls during macro playback}
  begin
    if Count = 255 then
      Dec(Count);               {255 reduced to 254 to avoid byte overflow}
    WaitCount := Count;
  end;

  procedure SetEndOfMacroProc(P : Pointer);
    {-Set pointer to procedure to call when end of macro reached}
  begin
    EndOfMacroProc := P;
  end;

  function FindMacroIndex(Key : Word) : Word;
    {-Find the array index for the macro assigned to Key. Returns 0 if not
      found.}
  var
    I : Word;
  begin
    FindMacroIndex := 0;

    {search for key}
    for I := 1 to MaxMacros do
      if DefinedKeys[I] = Key then begin
        {found it}
        FindMacroIndex := I;
        Exit;
      end;
  end;

  function DefineMacro(Key : Word; var Macro) : Boolean;
  {-Define a new macro or delete an existing one. To define: Key is the key to
    associate with Macro. Function will return False if the table is full or
    the macro is blank. To delete: Key is the key to delete and Macro is a
    blank macro (length word of 0). Function returns false if the macro was
    not found.}
  var
    I : Word;
    MacroLength : Word absolute Macro;
  begin
    {assume success}
    DefineMacro := True;

    {see if Key matches an existing macro}
    I := FindMacroIndex(Key);
    if I <> 0 then begin
      {see if we should delete the macro}
      if MacroLength = 0 then begin
        {erase the existing macro}
        DefinedKeys[I] := EndOfMacro;
        MacroPointers[I] := nil;
      end
      else
        MacroPointers[I] := @Macro;
      Exit;
    end;

    {if macro not empty, search for empty slot in table}
    if MacroLength > 0 then
      for I := 1 to MaxMacros do
        if DefinedKeys[I] = EndOfMacro then begin
          {slot found, store Macro and exit}
          MacroPointers[I] := @Macro;
          DefinedKeys[I] := Key;
          Exit;
        end;

    {if we get here we failed}
    DefineMacro := False;
  end;

  function MacroAddress(Key : Word) : Pointer;
    {-Returns a pointer to the macro for a key, or nil if key is not defined.}
  var
    I : Word;
  begin
    {search for the macro}
    I := FindMacroIndex(Key);
    if I = 0 then
      {not found}
      MacroAddress := nil
    else
      MacroAddress := MacroPointers[I];
  end;

  function MacroCount : Word;
    {-Returns the number of macros that have been defined}
  var
    Count, I : Word;
  begin
    {count the number of macros}
    Count := 0;
    for I := 1 to MaxMacros do
      if DefinedKeys[I] <> EndOfMacro then
        Inc(Count);
    MacroCount := Count;
  end;

  {FPC port: the FPC heap manager has no MaxAvail; allocation failure is
   not detectable beforehand, so report "plenty"}
  function MaxAvail : LongInt;
  begin
    MaxAvail := High(LongInt);
  end;

  function AllocateMacro(Key : Word; var Macro; var Name : string) : Byte;
    {-Allocates a macro on the heap, and returns one of the following values:
       0 : Macro allocated
       1 : Macro table full
       2 : Out of heap space
       3 : Macro was blank }
  var
    MacroLength : Word absolute Macro;
    NameLen : Byte absolute Name;
    P, OldMP, OldName : Pointer;
    Index, I, N : Word;
  begin                                             {!!.12} {rewritten}
    {check for a blank macro}
    if MacroLength = 0 then
      AllocateMacro := 3
    else begin
      {FPC port: the old macro and name are released only after the new one
       is safely defined, instead of being recovered afterwards}
      Index := FindMacroIndex(Key);
      if Index <> 0 then begin
        OldMP := MacroPointers[Index];
        OldName := MacroNames[Index];
      end
      else begin
        OldMP := nil;
        OldName := nil;
      end;

      {the macro has a length word and an end word of $FFFF, so we need 4
       bytes more space than MacroLength}
      N := (MacroLength shl 1)+4;

      {need space for name too, if any}
      if NameLen = 0 then
        I := 0
      else
        I := Succ(NameLen);

      {see if there's enough memory}
      if MaxAvail >= LongInt(N)+LongInt(I) then begin
        {move the macro onto the heap}
        GetMem(P, N);
        Move(Macro, P^, N);

        {try to define it}
        if DefineMacro(Key, P^) then begin
          AllocateMacro := 0;

          {release the old macro and name, if any}
          if OldMP <> nil then
            FreeMem(OldMP, (Word(OldMP^) shl 1)+4);
          if OldName <> nil then begin
            FreeMem(OldName, Succ(Byte(OldName^)));
            MacroNames[Index] := nil;
          end;

          {add the name, if any}
          if I <> 0 then begin
            {move the name onto the heap}
            GetMem(P, I);
            Move(Name, P^, I);
            MacroNames[FindMacroIndex(Key)] := P;
          end;
        end
        else begin
          AllocateMacro := 1;
          {recover the heap space}
          FreeMem(P, N);
        end;
      end
      else
        {insufficient memory; any existing macro is left untouched}
        AllocateMacro := 2;
    end;
  end;

  function DeallocateMacro(Key : Word) : Boolean;
  {-If the macro exists, this routine erases it and deallocates its memory.
    Returns False if the macro was not found.}
  const
    {this is a macro with a length of 0 and the proper $FFFF at end}
    Blank : array[0..1] of Word = (0, EndOfMacro);
  var
    P : Pointer;
    N : Word;
  begin
    DeallocateMacro := False;

    {DefineMacro deletes macros if you pass a length of 0}
    P := MacroAddress(Key);
    N := FindMacroIndex(Key);
    if DefineMacro(Key, Blank) then begin
      if P <> nil then
        FreeMem(P, (Word(P^) shl 1)+4);
      DeallocateMacro := True;

      {deallocate macro name, if any}
      P := MacroNames[N];
      if P <> nil then begin
        FreeMem(P, Succ(Byte(P^)));
        MacroNames[N] := nil;
      end;
    end;
  end;

  function AssignMacroName(Key : Word; var Name : string) : Boolean;
  {-Assign a name to a macro, deleting the existing name assigned to the
    macro, if any. Returns false if insufficient memory exists or macro
    not found.}
  var
    I, J : Word;
    P : ^Byte;
    NLen : Byte absolute Name;
  begin
    AssignMacroName := False;

    {find the macro}
    I := FindMacroIndex(Key);
    if I = 0 then
      Exit;

    {delete existing name, if any}
    P := MacroNames[I];
    if P <> nil then begin
      FreeMem(P, Succ(P^));
      MacroNames[I] := nil;
    end;

    {define new name, if any}
    if NLen <> 0 then begin
      J := Succ(NLen);
      if MaxAvail >= LongInt(J) then begin
        GetMem(P, J);
        Move(Name, P^, J);
        MacroNames[I] := P;
      end
      else
        Exit;
    end;

    AssignMacroName := True;
  end;

  function ReadMacroFile(FName : string; Merge : Boolean) : Byte;
  {-Read a macro file. Returns 0 if successful, $FF if not a valid macro
    file, $FE if we ran out of memory, else IOresult. If Merge is false, any
    existing macros are deleted before the file is read. Note: Can't use
    ReadMacroFile in a TSR.}
  var
    F : file;
    IoStatus : Byte;
    Signature : LongInt;
    I, N : Word;
    SMLen : Byte absolute ScrapMacroName;
  label
    ExitPoint;
  begin
    {Open file}
    Assign(F, FName);
    Reset(F, 1);

    {check for error}
    IoStatus := IoResult;
    if IoStatus <> 0 then
      goto ExitPoint;

    {read the signature}
    BlockRead(F, Signature, SizeOf(Signature), N);
    if N <> SizeOf(Signature) then begin
      IoStatus := 30;        {read error}
      goto ExitPoint;
    end;

    {check the signature}
    if Signature <> MacroFileID then begin
      IoStatus := $FF;
      goto ExitPoint;
    end;

    {clear existing macros if we're not merging}
    if not Merge then
      ClearMacros;

    with ScrapMacro do
      while not Eof(F) do begin
        {read the macro key}
        BlockRead(F, ScrapMacroKey, 2, N);
        if N <> 2 then begin
          IoStatus := 30;    {read error}
          goto ExitPoint;
        end;

        {read the macro length word}
        BlockRead(F, NumKeys, 2, N);
        if N <> 2 then begin
          IoStatus := 30;    {read error}
          goto ExitPoint;
        end;

        {read the macro}
        I := (NumKeys shl 1)+2;
        BlockRead(F, KeyArray, I, N);
        if N <> I then begin
          IoStatus := 30;    {read error}
          goto ExitPoint;
        end;

        {read the length of the macro name}
        BlockRead(F, SMLen, 1, N);
        if N <> 1 then begin
          IoStatus := 30;    {read error}
          goto ExitPoint;
        end;

        {if length not 0, read the name}
        if SMLen <> 0 then begin
          BlockRead(F, ScrapMacroName[1], SMLen, N);
          if N <> SMLen then begin
            IoStatus := 30;  {read error}
            goto ExitPoint;
          end;
        end;

        {define the macro and move it onto the heap}
        N := AllocateMacro(ScrapMacroKey, ScrapMacro, ScrapMacroName);
        if N <> 0 then begin
          IoStatus := $FE;
          goto ExitPoint;
        end;
      end;

ExitPoint:
    ReadMacroFile := IoStatus;
    Close(F);
    IoStatus := IoResult;
  end;

  function WriteMacroFile(FName : string) : Byte;
  {-Write a macro file. Returns 0 if successful, else IOresult.
    Note: Can't use WriteMacroFile in a TSR.}
  var
    F : file;
    IoStatus : Byte;
    I, J, N : Word;
    P : ^MacroRec;
    PName : ^Byte;
  const
    Null : Char = #0;
  label
    ExitPoint;
  begin
    {Open file}
    Assign(F, FName);
    Rewrite(F, 1);

    {check for error}
    IoStatus := IoResult;
    if IoStatus <> 0 then
      goto ExitPoint;

    {write the signature}
    BlockWrite(F, MacroFileID, SizeOf(MacroFileID), N);
    if N <> SizeOf(MacroFileID) then begin
      IoStatus := 29;        {write error}
      goto ExitPoint;
    end;

    for I := 1 to MaxMacros do
      if DefinedKeys[I] <> EndOfMacro then begin
        {write the key}
        BlockWrite(F, DefinedKeys[I], 2, N);
        if N <> 2 then begin
          IoStatus := 29;    {write error}
          goto ExitPoint;
        end;

        {write the macro}
        P := MacroPointers[I];
        J := (P^.NumKeys shl 1)+4;
        BlockWrite(F, P^, J, N);
        if N <> J then begin
          IoStatus := 29;    {write error}
          goto ExitPoint;
        end;

        {write the macro name}
        PName := MacroNames[I];
        if PName = nil then
          PName := @Null;
        J := Succ(Byte(PName^));
        BlockWrite(F, PName^, J, N);
        if N <> J then begin
          IoStatus := 29;    {write error}
          goto ExitPoint;
        end;
      end;

ExitPoint:
    WriteMacroFile := IoStatus;
    Close(F);
    IoStatus := IoResult;
  end;

  procedure ClearMacros;
    {-Clears out the current macros.}
  var
    I : Word;
  begin
    for I := 1 to MaxMacros do
      if DefinedKeys[I] <> EndOfMacro then
        if DeallocateMacro(DefinedKeys[I]) then {do nothing} ;
    ScrapMacro.NumKeys := 0;
    ScrapMacro.KeyArray[1] := EndOfMacro;
  end;

  procedure MacrosOn;
    {-Turns macro processing on}
  begin
    MacrosAreOn := True;
  end;

  procedure MacrosOff;
    {-Turns macro processing off}
  begin
    MacrosAreOn := False;
  end;

  procedure MacroRecordingOn;
    {-Turns macro recording on}
  begin
    {set the recording flag}
    MacroRecording := True;

    {make sure the scrap macro is empty}
    ScrapMacro.NumKeys := 0;
    ScrapMacro.KeyArray[1] := EndOfMacro;
  end;

  procedure MacroRecordingOff;
    {-Turns macro recording off}
  begin
    MacroRecording := False;
  end;

  procedure StartMacro(Macro : Pointer);
    {-Starts execution of the specified macro. If a macro is already in
      progress it will immediately be replaced by the macro passed.}
  begin
    if Macro <> nil then begin
      {make this macro the current macro, skipping past the length word}
      CurrentMacro := Pointer(PtrUInt(Macro)+SizeOf(Word));

      {Turn this macro on}
      MacroInProgress := True;

      {Start the wait cycle over again} {!!.20}
      WaitFlag := 0;  {!!.20}
    end;
  end;

  procedure StartMacroByKey(Key : Word);
  {-Starts execution of the macro attached to Key, if any. If a macro is
    already in progress it will immediately be replaced by the macro passed.}
  begin
    {!!.20 simplified}
    StartMacro(MacroAddress(Key));
  end;

  procedure RemoveMacros;
    {-Restores vector associated with macros.}
  begin
    MacroInProgress := False;
    MacrosAreOn := False;
    MacroRecording := False;
    if Initialized then
      KeyHook := SavedKeyHook;
    Initialized := False;
  end;

  function CharToMacro(MacroChar : Char) : Word;
  {-Converts a character to a keyboard code/char representation. This table
    holds all scan code values for ASCII characters from 0 to 63. All alpha
    characters can be mapped to this table by subtracting a number divisible
    by 32 that would put that alpha in the range of 0..63.}
  const
    ScanCodes : array[0..63] of Byte =
    (
      $03, {@} $1E, {A} $30, {B} $2E, {C} $20, {D} $12, {E} $21, {F} $22, {G}
      $23, {H} $17, {I} $24, {J} $25, {K} $26, {L} $32, {M} $31, {N} $18, {O}
      $19, {P} $10, {Q} $13, {R} $1f, {S} $14, {T} $16, {U} $2f, {V} $11, {W}
      $2d, {X} $15, {Y} $2c, {Z} $1a, {[} $2b, {\} $1b, {]} $07, {^} $0c, {_}
      $39, { } $02, {!} $28, {"} $04, {#} $5, { $} $06, {%} $08, {&} $28, {'}
      $0A, {(} $0b, {)} $09, {*} $0d, {+} $33, {,} $0c, {-} $34, {.} $35, {/}
      $0b, {0} $02, {1} $03, {2} $04, {3} $05, {4} $06, {5} $07, {6} $08, {7}
      $09, {8} $0A, {9} $27, {:} $27, {;} $33, {<} $0d, {=} $34, {>} $35 {?}
      );
  var
    CharCode : Byte absolute MacroChar;
  begin
    {FPC port: ^M and ^[ handled first, FPC rejects overlapping case labels}
    if MacroChar = ^M then
      CharToMacro := $1C0D
    else if MacroChar = ^[ then
      CharToMacro := $011B  {!!.13}
    else
      case MacroChar of
        #0..'?' : CharToMacro := (ScanCodes[CharCode] shl 8) or CharCode;
        '@'..'_' : CharToMacro := (ScanCodes[CharCode-64] shl 8) or CharCode;
        '`', '~' : CharToMacro := $2900 or CharCode;
        'a'..'}' : CharToMacro := (ScanCodes[CharCode-96] shl 8) or CharCode;
        #127 : CharToMacro := $0EFF;
      else CharToMacro := CharCode;
      end;
  end;

  function EscapeSequence(B : Byte) : StringPointer;
    {-Return a pointer to a string representing extended scan code B}
  const
    Keys : array[0..165] of string[9] = (
      '^Break',
      'AltEsc',
      '?',
      '^@',
      '?',
      '?',
      '?',
      '?',
      '?',
      '?',
      '?',
      '?',
      '?',
      '?',
      'AltBksp',
      'ShTab',
      'AltQ',
      'AltW',
      'AltE',
      'AltR',
      'AltT',
      'AltY',
      'AltU',
      'AltI',
      'AltO',
      'AltP',
      'Alt[',
      'Alt]',
      'AltEnter',
      'Ctrl',
      'AltA',
      'AltS',
      'AltD',
      'AltF',
      'AltG',
      'AltH',
      'AltJ',
      'AltK',
      'AltL',
      'Alt;',
      'Alt''',
      'Alt`',
      'LShift',
      'Alt\',
      'AltZ',
      'AltX',
      'AltC',
      'AltV',
      'AltB',
      'AltN',
      'AltM',
      'Alt,',
      'Alt.',
      'Alt/',
      'RShift',
      'PrtSc',
      'Alt',
      'Space',
      'CapLock',
      'F1',
      'F2',
      'F3',
      'F4',
      'F5',
      'F6',
      'F7',
      'F8',
      'F9',
      'F10',
      'NumLock',
      'ScrLock',
      'Home',
      'Up',
      'PgUp',
      'Minus',
      'Left',
      'Center',
      'Right',
      'Plus',
      'End',
      'Down',
      'PgDn',
      'Ins',
      'Del',
      'ShF1',
      'ShF2',
      'ShF3',
      'ShF4',
      'ShF5',
      'ShF6',
      'ShF7',
      'ShF8',
      'ShF9',
      'ShF10',
      '^F1',
      '^F2',
      '^F3',
      '^F4',
      '^F5',
      '^F6',
      '^F7',
      '^F8',
      '^F9',
      '^F10',
      'AltF1',
      'AltF2',
      'AltF3',
      'AltF4',
      'AltF5',
      'AltF6',
      'AltF7',
      'AltF8',
      'AltF9',
      'AltF10',
      '^PrtSc',
      '^Left',
      '^Right',
      '^End',
      '^PgDn',
      '^Home',
      'Alt1',
      'Alt2',
      'Alt3',
      'Alt4',
      'Alt5',
      'Alt6',
      'Alt7',
      'Alt8',
      'Alt9',
      'Alt0',
      'Alt-',
      'Alt=',
      '^PgUp',
      'F11',
      'F12',
      'ShF11',
      'ShF12',
      '^F11',
      '^F12',
      'AltF11',
      'AltF12',
      '^Up',
      '^Minus',
      '^Center',
      '^Plus',
      '^Down',
      '^Ins',
      '^Del',
      '^Tab',
      '?',
      '?',
      'AltHome',
      'AltUp',
      'AltPgUp',
      '?',
      'AltLeft',
      'AltCenter',
      'AltRight',
      '?',
      'AltEnd',
      'AltDown',
      'AltPgDn',
      'AltIns',
      'AltDel',
      '?',
      'AltTab'
    );
  begin
    {FPC port: B > 165 returns the "?" entry, as in OPMACRO.ASM}
    if B > 165 then
      B := 2;
    EscapeSequence := @Keys[B];
  end;

  procedure KeyToString(Key : Word; var S : string; var Special : Boolean);
    {-Returns a string (S) representing a Key. Special is set to False if
      a simple character is being returned.}
  begin                                       {!!.11} {rewritten}
    Special := True;
    if (Lo(Key) = 0) or (Lo(Key) = $E0) then
      S := '<'+EscapeSequence(Hi(Key))^+'>'
    else
      case Lo(Key) of
        1..31 :              {Control characters}
          case Key of
            $0E08 : S := '<BkSp>';   {Backspace}
            $0F09 : S := '<Tab>';    {Tab}
            $1C0A : S := '<^Enter>'; {^Enter}
            $1C0D : S := '<Enter>';  {Enter}
            $011B : S := '<Esc>';    {Escape}
            else    S := '<^'+Chr(Lo(Key)+64)+'>';
          end;
        127 : S := '<^BkSp>'; {ASCII DEL}
        255 : S := '<#255>'; {#255}
      else
        {Normal character}
        S := Char(Lo(Key));
        Special := False;
      end;
  end;

  function InitMacros : Boolean;
    {-Initializes macros. After this routine is called, no macros will be
      defined and both macro processing and macro recording will be turned off.
      Returns false if INT $16 cannot be taken over.}
  begin
    {don't do this twice}
    if Initialized then begin
      {return success flag to indicate we're initialized}
      InitMacros := True;
      Exit;
    end;

    {turn everything off}
    MacroRecording := False;
    MacroInProgress := False;
    MacrosAreOn := False;
    WaitCount := 0; {!!.20}
    WaitFlag := 0;  {!!.20}

    {initialize the segment of our key pointer}
    FillChar(DefinedKeys, SizeOf(DefinedKeys), $FF);

    {initialize other arrays}
    FillChar(MacroPointers, SizeOf(MacroPointers), 0);
    FillChar(MacroNames, SizeOf(MacroNames), 0);

    {initialize the scrap macro}
    ScrapMacro.NumKeys := 0;
    ScrapMacro.KeyArray[1] := EndOfMacro;

    {we're initialized once the key hook is installed}
    SavedKeyHook := KeyHook;
    KeyHook := KeyHookFunc(@MacroKeyHook);
    Initialized := True;

    InitMacros := Initialized;
  end;

  procedure StringToMacro(S : string; MRP : MacroRecPtr; MaxKeys : Word);
    {-Initialize MRP^ from a string}
  var
    SLen : Byte absolute S;
    I : Word;
  begin
    if SLen > MaxKeys then
      SLen := MaxKeys;
    with MRP^ do begin
      NumKeys := SLen;
      for I := 1 to SLen do
        KeyArray[I] := CharToMacro(S[I]);
      KeyArray[SLen+1] := EndOfMacro;
    end;
  end;

  procedure StringToScrapMacro(S : string);
    {-Initialize ScrapMacro from a string}
  begin
    StringToMacro(S, @ScrapMacro, MaxKeysInMacro);
  end;

begin
  {install key hook and initialize data structures}
  if not InitMacros then
    Halt(1);
end.
