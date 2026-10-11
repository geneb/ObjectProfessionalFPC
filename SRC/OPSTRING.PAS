{$IFDEF OPWinTP}                {!!.20}
  {$S-,R-,V-,I-,B-,F-,A-}       {!!.20}
  {$DEFINE PMode}               {!!.20}
{$ELSE}                         {!!.20}
  {$S-,R-,V-,I-,B-,F-,O-,A-}    {!!.20}
  {$IFDEF Dpmi}                 {!!.20}
    {$DEFINE PMode}             {!!.20}
  {$ENDIF}                      {!!.20}
{$ENDIF}                        {!!.20}

{Conditional defines that may affect this unit}
{$I opdefine.inc}

{*********************************************************}
{*                  OPSTRING.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OPString;
  {-Basic string manipulation routines}

interface

{$IFDEF OPWinTP}         {!!.20 begin}
uses
  WinProcs,
  WsDpmi,
  WinDos;

const
  DpmiInUse : Boolean = True;
type
  ExtStr  = String[3];
{$ELSE}                  {!!.20 end}
uses
  Dpmi,                  {!!.20}
{$IFDEF Dpmi}            {!!.20}
  WinApi,                {!!.20}
{$ENDIF}                 {!!.20}
  Dos;                   {!!.01}
{$ENDIF}                 {!!.20}

const
  ExtLen = 3;
type
  StringPtr = ^String;
  {ExtStr = string[ExtLen];}   {!!.01}
  CharSet = set of Char;
  CompareType = (Less, Equal, Greater);
  BTable = array[0..255] of Byte; {For Boyer-Moore searching}
  {FPC port: Real is a Double in Free Pascal (not the 6-byte TP Real)}
  {$IFOPT N+}
   Float = Extended;
  {$ELSE}
   Float = Real;
  {$ENDIF}

type                            {!!.20 begin}
  {for International upcase support}
  CaseTable = Array[128..165] of Char;
const
  DefUCTable : CaseTable = (
      #$80, #$9A, 'E', 'A', #$8E, 'A', #$8F, #$80, 'E', 'E',
      'E', 'I', 'I', 'I', #$8E, #$8F, #$90, #$92, #$92, 'O',
      #$99, 'O', 'U', 'U', 'Y', #$99, #$9A, #$9B, #$9C, #$9D,
      #$9E, #$9F, 'A', 'I', 'O', 'U', #$A5, #$A5
    );

const
  LCTable : CaseTable = (
      #$87, #$81, #$82, #$83, #$84, #$85, #$86, #$87, #$88, #$89,
      #$8A, #$8B, #$8C, #$8D, #$84, #$86, #$82, #$91, #$91, #$93,
      #$94, #$95, #$96, #$97, #$98, #$94, #$81, #$9B, #$9C, #$9D,
      #$9E, #$9F, #$A0, #$A1, #$A2, #$A3, #$A4, #$A4
    );
var
  UCTable : CaseTable;
  UpcaseFunc : Pointer;         {!!.20 end}

const
  {used by CompareLetterSets for estimating word similarity}
  LetterValues : array['A'..'Z'] of Byte = (
    3 {A} , 6 {B} , 5 {C} , 4 {D} , 3 {E} , 5 {F} , 5 {G} , 4 {H} , 3 {I} ,
    8 {J} , 7 {K} , 4 {L} , 5 {M} , 3 {N} , 3 {O} , 5 {P} , 7 {Q} , 4 {R} ,
    3 {S} , 3 {T} , 4 {U} , 6 {V} , 5 {W} , 8 {X} , 8 {Y} , 9 {Z} );
const
  MoneySign : Char = '$';    {Used by Form for floating dollar sign}
  CommaForPeriod : Boolean = False; {replace '.' with ',' in Form masks}

  {-------- Numeric conversion -----------}

function HexB(B : Byte) : string;
  {-Return hex string for byte}

function HexW(W : Word) : string;
  {-Return hex string for word}

function HexL(L : LongInt) : string;
  {-Return hex string for longint}

function HexPtr(P : Pointer) : string;
  {-Return hex string for pointer}

function BinaryB(B : Byte) : string;
  {-Return binary string for byte}

function BinaryW(W : Word) : string;
  {-Return binary string for word}

function BinaryL(L : LongInt) : string;
  {-Return binary string for longint}

function OctalB(B : Byte) : string;
  {-Return octal string for byte}

function OctalW(W : Word) : string;
  {-Return octal string for word}

function OctalL(L : LongInt) : string;
  {-Return octal string for longint}

function Str2Int(S : string; var I : Integer) : Boolean;
  {-Convert a string to an integer, returning true if successful}

function Str2Word(S : string; var I : Word) : Boolean;
  {-Convert a string to a word, returning true if successful}

function Str2Long(S : string; var I : LongInt) : Boolean;
  {-Convert a string to an longint, returning true if successful}

function Str2Real(S : string; var R : Float) : Boolean;
  {-Convert a string to a real, returning true if successful}

function Long2Str(L : LongInt) : string;
  {-Convert a longint/word/integer/byte/shortint to a string}

function Real2Str(R : Float; Width : Byte; Places : ShortInt) : string;
  {-Convert a real to a string}

function Form(Mask : string; R : Float) : string;
  {-Returns a formatted string with digits from R merged into the Mask}

function LongIntForm(Mask : string; L : LongInt) : string;
  {-Returns a formatted string with digits from L merged into the Mask}

  {-------- General purpose string manipulation --------}

function UpCaseMac(Ch : Char) : Char;
  {-Uppercase character macro, no international character support}
  {FPC port: former inline macro, now an ordinary function}

function LoCaseMac(Ch : Char) : Char;
  {-Lowercase character macro, no international character support}
  {FPC port: former inline macro, now an ordinary function}

function Upcase(Ch : Char) : Char;
  {-Return uppercase of char, with international character support}

procedure SetInternationalUpcase; {!!.02}
  {-Activate DOS international uppercase function for current code page}
  {FPC port: there is no DOS country-info upcase routine; this simply
   selects the built-in CP437 table (same as SetDefaultUpcase)}

procedure SetDefaultUpcase; {!!.02}
  {-Activate default uppercase function}

function StUpcase(S : string) : string;
  {-Convert lower case letters in string to uppercase, with intl chars}

function LoCase(Ch : Char) : Char;
  {-Return lowercase of char, with international character support}

function StLocase(S : string) : string;
  {-Convert upper case letters in string to lowercase, with intl chars}

function CharStr(Ch : Char; Len : Byte) : string;
  {-Return a string of length len filled with ch}

function PadCh(S : string; Ch : Char; Len : Byte) : string;
  {-Return a string right-padded to length len with ch}

function Pad(S : string; Len : Byte) : string;
  {-Return a string right-padded to length len with blanks}

function LeftPadCh(S : string; Ch : Char; Len : Byte) : string;
  {-Return a string left-padded to length len with ch}

function LeftPad(S : string; Len : Byte) : string;
  {-Return a string left-padded to length len with blanks}

function TrimLead(S : string) : string;
  {-Return a string with leading white space removed}

function TrimTrail(S : string) : string;
  {-Return a string with trailing white space removed}

function Trim(S : string) : string;
  {-Return a string with leading and trailing white space removed}

function TrimSpaces(S : string) : string;
  {-Return a string with leading and trailing spaces removed}

function CenterCh(S : string; Ch : Char; Width : Byte) : string;
  {-Return a string centered in a string of Ch with specified width}

function Center(S : string; Width : Byte) : string;
  {-Return a string centered in a blank string of specified width}

function Entab(S : string; TabSize : Byte) : string;
  {-Convert blanks in a string to tabs on spacing TabSize}

function Detab(S : string; TabSize : Byte) : string;
  {-Expand tabs in a string to blanks on spacing TabSize}

procedure MoveFast(var Src, Dest; Count : Word); {!!.01}
  {-Move Count bytes from Src to Dest, moving by word where possible}

function Substitute(S, FromStr, ToStr : String) : String; {!!.02}
  {-Return string S after mapping characters found in FromStr to the
    corresponding ones in ToStr}

function Filter(S : String; CS : CharSet) : String; {!!.11}
  {-Return string S after removing all characters in CS from it}

  {--------------- Word manipulation -------------------------------}

function WordCount(S : string; WordDelims : CharSet) : Byte;
  {-Given a set of word delimiters, return number of words in S}

function WordPosition(N : Byte; S : string; WordDelims : CharSet) : Byte;
  {-Given a set of word delimiters, return start position of N'th word in S}

function ExtractWord(N : Byte; S : string; WordDelims : CharSet) : string;
  {-Given a set of word delimiters, return the N'th word in S}

function AsciiCount(S : string; WordDelims : CharSet; Quote : Char) : Byte;
  {!!.13-Given a set of word delimiters, return number of words in S}

function AsciiPosition(N : Byte; S : string; WordDelims : CharSet; Quote : Char) : Byte;
  {!!.13-Given a set of word delimiters, return start position of N'th word in S}

function ExtractAscii(N : Byte; S : string; WordDelims : CharSet; Quote : Char) : string;
  {!!.13-Given a set of word delimiters, return the N'th word in S}

procedure WordWrap(InSt : string; var OutSt, Overlap : string;
                   Margin : Byte; PadToMargin : Boolean);
 {-Wrap InSt at Margin, storing the result in OutSt and the remainder in
   Overlap}

  {--------------- String comparison and searching -----------------}

function CompString(S1, S2 : string) : CompareType;
  {-Return less, equal, greater if s1<s2, s1=s2, or s1>s2}

function CompUCString(S1, S2 : string) : CompareType;
  {-Compare two strings in a case insensitive manner}

function CompStruct(var S1, S2; Size : Word) : CompareType;
  {-Compare two fixed size structures}

function Search(var Buffer; BufLength : Word;
                var Match; MatLength : Word) : Word;
 {-Search through Buffer for Match. BufLength is length of range to search.
   MatLength is length of string to match. Returns number of bytes searched
   to find Match, $FFFF if not found.}

function SearchUC(var Buffer; BufLength : Word;
                  var Match; MatLength : Word) : Word;
 {-Search through Buffer for Match, CASE-INSENSITIVE.
   Otherwise same as Search.}

{!!.30 - New}
function Replace(var Buffer; BufLength : Word;
                 var Match; MatLength : Word;
                 var Repl; RepLength : Word;
                 var NewLength : Word;
                 MaxLength : Word; All : Boolean) : Word;
  {-Replace all occurrences of 'Match' in Buffer with the data
    in Repl }

{!!.30 - New}
function ReplaceUC(var Buffer; BufLength : Word;
                   var Match; MatLength : Word;
                   var Repl; RepLength : Word;
                   var NewLength : Word;
                   MaxLength : Word; All : Boolean) : Word;
  {-Replace all occurrences of 'Match' in Buffer with the data
    in Repl--case INsensitive }

procedure BMMakeTable(MatchString : string; var BT : BTable);
  {-Build Boyer-Moore link table}

function BMSearch(var Buffer; BufLength : Word;
                  BT : BTable; MatchString : string) : Word;
  {-Search Buffer for MatchString. BufLength is length of range to search.
    Returns number of bytes searched to find MatchString, $FFFF if not found}

function BMSearchUC(var Buffer; BufLength : Word;
                    BT : BTable; MatchString : string) : Word;
 {-Search Buffer for MatchString, CASE-INSENSITIVE.
   Assumes MatchString is already in uppercase.
   Otherwise same as BMSearch}

function Soundex(S : string) : string;
  {-Return 4 character soundex of input string}

function MakeLetterSet(S : string) : LongInt;
  {-Return a bit-mapped long storing the individual letters contained in S}

function CompareLetterSets(Set1, Set2 : LongInt) : Word;
  {-Returns the sum of the values of the letters common to Set1 and Set2}

  {----- Strings dynamically allocated on the heap ------}

function StringToHeap(S : string) : StringPtr;
  {-Allocate space for s and return pointer}

function StringFromHeap(P : StringPtr) : string;
  {-Return string at p}

procedure DisposeString(P : StringPtr);
  {-Deallocate space for string at p}

  {--------------- DOS pathname parsing -----------------}

function DefaultExtension(Name : string; Ext : ExtStr) : string;
  {-Return a file name with a default extension attached}

function ForceExtension(Name : string; Ext : ExtStr) : string;
  {-Force the specified extension onto the file name}

function JustFilename(PathName : string) : string;
  {-Return just the filename and extension of a pathname}

function JustName(PathName : string) : string;
  {-Return just the name (no extension, no path) of a pathname}

function JustExtension(Name : string) : ExtStr;
  {-Return just the extension of a pathname}

function JustPathname(PathName : string) : string;
  {-Return just the drive:directory portion of a pathname}

function AddBackSlash(DirName : string) : string;
  {-Add a default backslash to a directory name}

function CleanPathName(PathName : string) : string;
  {-Return a pathname cleaned up as DOS will do it}

function FullPathName(FName : string) : string;
  {-Given FName (known to exist), return a full pathname}

  {FPC port: UpCasePrim/LoCasePrim (register-calling-convention helpers for
   the assembler modules) were removed; use Upcase/LoCase instead.}

  {==========================================================================}

implementation

type
  OS =
    record
      O, S : Word;
    end;
  Long =
    record
      LowWord, HighWord : Word;
    end;
const
  Digits : array[0..$F] of Char = '0123456789ABCDEF';
const
  {FPC port: '/' accepted as a delimiter too; on Unix only '/' is a delimiter}
{$IFDEF UNIX}
  DosDelimSet : set of Char = ['/', #0];
  DirSepChar = '/';
{$ELSE}
  DosDelimSet : set of Char = ['\', '/', ':', #0];
  DirSepChar = '\';
{$ENDIF}
{const}                         {!!.21}
  {AssumeDP : Boolean = False;} {!!.21}

  {FPC port: the OPCASE/OPCOMP/OPSEARCH/OPTAB/OPBM assembler modules were
   ported to Pascal and live in this unit}

  function UpCaseMac(Ch : Char) : Char;
  begin
    if (Ch >= 'a') and (Ch <= 'z') then
      UpCaseMac := Chr(Ord(Ch) and $DF)
    else
      UpCaseMac := Ch;
  end;

  function LoCaseMac(Ch : Char) : Char;
  begin
    if (Ch >= 'A') and (Ch <= 'Z') then
      LoCaseMac := Chr(Ord(Ch) or $20)
    else
      LoCaseMac := Ch;
  end;

  function UpcaseTbl(Ch : Char) : Char;
    {-Port of UpcasePrim}
  begin
    if Ch < #128 then begin
      if (Ch >= 'a') and (Ch <= 'z') then
        UpcaseTbl := Chr(Ord(Ch)-32)
      else
        UpcaseTbl := Ch;
    end else if Ch <= #165 then
      UpcaseTbl := UCTable[Ord(Ch)]
    else
      UpcaseTbl := Ch;
  end;

  function LocaseTbl(Ch : Char) : Char;
    {-Port of LoCasePrim}
  begin
    if Ch < #128 then begin
      if (Ch >= 'A') and (Ch <= 'Z') then
        LocaseTbl := Chr(Ord(Ch)+32)
      else
        LocaseTbl := Ch;
    end else if Ch <= #165 then
      LocaseTbl := LCTable[Ord(Ch)]
    else
      LocaseTbl := Ch;
  end;

  function Upcase(Ch : Char) : Char;
    {-Return uppercase of char, with international character support}
  begin
    Upcase := UpcaseTbl(Ch);
  end;

  function LoCase(Ch : Char) : Char;
    {-Return lowercase of char, with international character support}
  begin
    LoCase := LocaseTbl(Ch);
  end;

  function StUpcase(S : string) : string;
    {-Convert lower case letters in string to uppercase, with intl chars}
  var
    I : Word;
  begin
    for I := 1 to Length(S) do
      S[I] := UpcaseTbl(S[I]);
    StUpcase := S;
  end;

  function StLocase(S : string) : string;
    {-Convert upper case letters in string to lowercase, with intl chars}
  var
    I : Word;
  begin
    for I := 1 to Length(S) do
      S[I] := LocaseTbl(S[I]);
    StLocase := S;
  end;

  procedure MoveFast(var Src, Dest; Count : Word);
    {-Move Count bytes from Src to Dest (Move handles overlap)}
  begin
    if Count <> 0 then
      Move(Src, Dest, Count);
  end;

  function HexB(B : Byte) : string;
    {-Return hex string for byte}
  begin
    HexB[0] := #2;
    HexB[1] := Digits[B shr 4];
    HexB[2] := Digits[B and $F];
  end;

  function HexW(W : Word) : string;
    {-Return hex string for word}
  begin
    HexW[0] := #4;
    HexW[1] := Digits[hi(W) shr 4];
    HexW[2] := Digits[hi(W) and $F];
    HexW[3] := Digits[lo(W) shr 4];
    HexW[4] := Digits[lo(W) and $F];
  end;

  function HexL(L : LongInt) : string;
    {-Return hex string for LongInt}
  begin
    with Long(L) do
      HexL := HexW(HighWord)+HexW(LowWord);
  end;

  function HexPtr(P : Pointer) : string;
    {-Return hex string for pointer}
  begin
    {FPC port: flat pointers; show the high and low halves of the address}
    if SizeOf(Pointer) > 4 then
      HexPtr := HexL(LongInt(Cardinal(PtrUInt(P) shr 32)))+':'+
                HexL(LongInt(Cardinal(PtrUInt(P) and $FFFFFFFF)))
    else
      HexPtr := HexW(Word(PtrUInt(P) shr 16))+':'+HexW(Word(PtrUInt(P) and $FFFF));
  end;

  function BinaryB(B : Byte) : string;
    {-Return binary string for byte}
  var
    I, N : Word;
  begin
    N := 1;
    BinaryB[0] := #8;
    for I := 7 downto 0 do begin
      BinaryB[N] := Digits[Ord(B and (1 shl I) <> 0)]; {0 or 1}
      Inc(N);
    end;
  end;

  function BinaryW(W : Word) : string;
    {-Return binary string for word}
  var
    I, N : Word;
  begin
    N := 1;
    BinaryW[0] := #16;
    for I := 15 downto 0 do begin
      BinaryW[N] := Digits[Ord(W and (1 shl I) <> 0)]; {0 or 1}
      Inc(N);
    end;
  end;

  function BinaryL(L : LongInt) : string;
    {-Return binary string for LongInt}
  var
    I : LongInt;
    N : Byte;
    U : Cardinal;
  begin
    N := 1;
    U := Cardinal(L);
    BinaryL[0] := #32;
    for I := 31 downto 0 do begin
      BinaryL[N] := Digits[Ord((U shr I) and 1)]; {0 or 1}
      Inc(N);
    end;
  end;

  function OctalB(B : Byte) : string;
    {-Return octal string for byte}
  var
    I : Word;
  begin
    OctalB[0] := #3;
    for I := 0 to 2 do begin
      OctalB[3-I] := Digits[B and 7];
      B := B shr 3;
    end;
  end;

  function OctalW(W : Word) : string;
    {-Return octal string for word}
  var
    I : Word;
  begin
    OctalW[0] := #6;
    for I := 0 to 5 do begin
      OctalW[6-I] := Digits[W and 7];
      W := W shr 3;
    end;
  end;

  function OctalL(L : LongInt) : string;
    {-Return octal string for word}
  var
    I : Word;
    U : Cardinal;
  begin
    U := Cardinal(L);
    OctalL[0] := #12;
    for I := 0 to 11 do begin
      OctalL[12-I] := Digits[U and 7];
      U := U shr 3;
    end;
  end;

  function Str2Int(S : string; var I : Integer) : Boolean;
    {-Convert a string to an integer, returning true if successful}
  var
    code : Word;
    SLen : Byte absolute S;
  begin
    while S[SLen] = ' ' do
      Dec(SLen);
    if (SLen > 1) and (Upcase(S[SLen]) = 'H') then begin          {!!.21 begin}
      Move(S[1], S[2], SLen-1);
      S[1] := '$';
    end
    else if (SLen > 2) and (S[1] = '0') and (Upcase(S[2]) = 'X') then begin
      Dec(SLen);
      Move(S[3], S[2], SLen-1);
      S[1] := '$';
    end;                                                          {!!.21 end}
    Val(S, I, code);
    if code <> 0 then begin
      I := code;
      Str2Int := False;
    end else
      Str2Int := True;
  end;

  function Str2Word(S : string; var I : Word) : Boolean;
    {-Convert a string to a word, returning true if successful}
  var
    code : Word;
    SLen : Byte absolute S;
  begin
    while S[SLen] = ' ' do
      Dec(SLen);
    if (SLen > 1) and (Upcase(S[SLen]) = 'H') then begin          {!!.21 begin}
      Move(S[1], S[2], SLen-1);
      S[1] := '$';
    end
    else if (SLen > 2) and (S[1] = '0') and (Upcase(S[2]) = 'X') then begin
      Dec(SLen);
      Move(S[3], S[2], SLen-1);
      S[1] := '$';
    end;                                                          {!!.21 end}
    Val(S, I, code);
    if code <> 0 then begin
      I := code;
      Str2Word := False;
    end else
      Str2Word := True;
  end;

  function Str2Long(S : string; var I : LongInt) : Boolean;
    {-Convert a string to a longint, returning true if successful}
  var
    code : Word;
    SLen : Byte absolute S;
  begin
    while S[SLen] = ' ' do
      Dec(SLen);
    if (SLen > 1) and (Upcase(S[SLen]) = 'H') then begin          {!!.21 begin}
      Move(S[1], S[2], SLen-1);
      S[1] := '$';
    end
    else if (SLen > 2) and (S[1] = '0') and (Upcase(S[2]) = 'X') then begin
      Dec(SLen);
      Move(S[3], S[2], SLen-1);
      S[1] := '$';
    end;                                                          {!!.21 end}
    Val(S, I, code);
    if code <> 0 then begin
      I := code;
      Str2Long := False;
    end else
      Str2Long := True;
  end;

  function Str2Real(S : string; var R : Float) : Boolean;
    {-Convert a string to a real, returning true if successful}
  var
    Code, I : Word;
    SLen : Byte absolute S;
  begin
    {trim trailing blanks}
    while S[SLen] = ' ' do
      Dec(SLen);

    Val(S, R, Code);
    if Code <> 0 then begin
      R := Code;
      Str2Real := False;
    end else
      Str2Real := True;
  end;

  function Long2Str(L : LongInt) : string;
    {-Convert a long/word/integer/byte/shortint to a string}
  var
    S : string;
  begin
    Str(L, S);
    Long2Str := S;
  end;

  function Real2Str(R : Float; Width : Byte; Places : ShortInt) : string;
    {-Convert a real to a string}
  var
    S : string;
  begin
    Str(R:Width:Places, S);
    Real2Str := S;
  end;

  function FormPrim(Mask : string; R : Float; AssumeDP : Boolean) : string; {!!.21}
    {-Returns a formatted string with digits from R merged into the Mask}
  type
    FillType = (Blank, Asterisk, Zero);
  const
  {$IFOPT N+}          {!!.22}
    MaxPlaces = 18;    {!!.22}
  {$ELSE}              {!!.22}
    MaxPlaces = 255;   {FPC port: Str honors any number of decimal places, so no zero fill is needed}
  {$ENDIF}             {!!.22}
    FormChars : string[8] = '#@*$-+,.';
    PlusArray : array[Boolean] of Char = ('+', '-');
    MinusArray : array[Boolean] of Char = (' ', '-');
    FillArray : array[FillType] of Char = (' ', '*', '0');
  var
    S : string;              {temporary string}
    Filler : FillType;       {char for unused digit slots: ' ', '*', '0'}
    WontFit,                 {true if number won't fit in the mask}
    AddMinus,                {true if minus sign needs to be added}
    Dollar,                  {true if floating dollar sign is desired}
    Negative : Boolean;      {true if B is negative}
    StartF,                  {starting point of the numeric field}
    EndF : Word;             {end of numeric field}
    DotPos,                  {position of '.' in Mask}
    Digits,                  {total # of digits}
    Places,                  {# of digits after the '.'}
    Blanks,                  {# of blanks returned by Str}
    FirstDigit,              {pos. of first digit returned by Str}
    Extras,                  {# of extra digits needed for special cases}
    DigitPtr : Byte;         {pointer into temporary string of digits}
    I : Word;
  label
    EndFound,
    RedoCase,
    Done;
  begin
    {assume decimal point at end?}
    if AssumeDP and (Mask <> '') and (Length(Mask) < 255) then begin
      Inc(Mask[0]);
      Mask[Length(Mask)] := '.';
    end;                      {!!.21}
    {else}                    {!!.21}
      {AssumeDP := False;}    {!!.21}

    {check for empty string}
    if Length(Mask) = 0 then
      goto Done;

    {initialize variables}
    Filler := Blank;
    DotPos := 0;
    Places := 0;
    Digits := 0;
    Dollar := False;
    AddMinus := True;
    StartF := 1;

    {store the sign of the real and make it positive}
    Negative := (R < 0);
    R := Abs(R);

    {find the starting point for the field}
    while (StartF <= Length(Mask)) and (Pos(Mask[StartF], FormChars) = 0) do
      Inc(StartF);
    if StartF > Length(Mask) then
      goto Done;

    {find the end point for the field}
    for EndF := StartF to Length(Mask) do
      case Mask[EndF] of
        '*' : Filler := Asterisk;
        '@' : Filler := Zero;
        '$' : Dollar := True;
        '-',
        '+' : AddMinus := False;
        '#' : {ignore} ;
        ',' :
          begin
            DotPos := EndF;
            if CommaForPeriod then
              Mask[EndF] := '.';
          end;
        '.' :
          begin
            DotPos := EndF;
            if CommaForPeriod then
              Mask[EndF] := ',';
          end;
      else
        goto EndFound;
      end;

    {if we get here at all, the last char was part of the field}
    Inc(EndF);

EndFound:
    {if we jumped to here instead, it wasn't}
    Dec(EndF);

    {disallow Dollar if Filler is Zero}
    if Filler = Zero then
      Dollar := False;

    {we need an extra slot if Dollar is True}
    Extras := Ord(Dollar);

    {get total # of digits and # after the decimal point}
    for I := StartF to EndF do
      case Mask[I] of
        '#', '@',
        '*', '$' :
          begin
            Inc(Digits);
            if (I > DotPos) and (DotPos <> 0) then
              Inc(Places);
          end;
      end;

    {need one more 'digit' if Places > 0}
    Inc(Digits, Ord(Places > 0));

    {also need an extra blank if (1) Negative is true, and (2) Filler is Blank,
     and (3) AddMinus is true}
    if Negative and AddMinus and (Filler = Blank) then
      Inc(Extras)
    else
      AddMinus := False;

    {translate the real to a string}
    Str(R:Digits:Places, S);

    {add zeros that Str may have left out}               {!!.22}
    if Places > MaxPlaces then begin                     {!!.22}
      FillChar(S[Length(S)+1], Places-MaxPlaces, '0');   {!!.22}
      inc(S[0], Places-MaxPlaces);                       {!!.22}
      while (Length(S) > Digits) and (S[1] = ' ') do     {!!.22}
        Delete(S, 1, 1);                                 {!!.22}
    end;                                                 {!!.22}

    {count number of initial blanks}
    Blanks := 1;
    while S[Blanks] = ' ' do
      Inc(Blanks);
    FirstDigit := Blanks;
    Dec(Blanks);

    {the number won't fit if (a) S is longer than Digits or (b) the number of
     initial blanks is less than Extras}
    WontFit := (Length(S) > Digits) or (Blanks < Extras);

    {if it won't fit, fill decimal slots with '*'}
    if WontFit then begin
      for I := StartF to EndF do
        case Mask[I] of
          '#', '@', '*', '$' : Mask[I] := '*';
          '+' : Mask[I] := PlusArray[Negative];
          '-' : Mask[I] := MinusArray[Negative];
        end;
      goto Done;
    end;

    {fill initial blanks in S with Filler; insert floating dollar sign}
    if Blanks > 0 then begin
      FillChar(S[1], Blanks, FillArray[Filler]);

      {put floating dollar sign in last blank slot if necessary}
      if Dollar then begin
        S[Blanks] := MoneySign;
        Dec(Extras);
        Dec(Blanks);
      end;

      {insert a minus sign if necessary}
      if AddMinus then
        S[Blanks] := '-';
    end;

    {put in the digits / signs}
    DigitPtr := Length(S);
    for I := EndF downto StartF do begin
RedoCase:
      case Mask[I] of
        '#', '@', '*', '$' :
          if DigitPtr <> 0 then begin
            Mask[I] := S[DigitPtr];
            Dec(DigitPtr);
            if (S[DigitPtr] = '.') and (DigitPtr <> 0) then
              Dec(DigitPtr);
          end
          else
            Mask[I] := FillArray[Filler];
        ',', '.' :
          if (I < DotPos) and (DigitPtr < FirstDigit) then begin
            Mask[I] := '#';
            goto RedoCase;
          end;
        '+' : Mask[I] := PlusArray[Negative];
        '-' : Mask[I] := MinusArray[Negative];
      end;
    end;

Done:
    if AssumeDP then
      Dec(Mask[0]);
    FormPrim := Mask; {!!.21}
  end;

  function LongIntForm(Mask : string; L : LongInt) : string;
    {-Returns a formatted string with digits from L merged into the Mask}
  begin
    {!!.21 AssumeDP now passed to FormPrim}
    LongIntForm := FormPrim(Mask, L, True);
  end;

  function Form(Mask : string; R : Float) : string;
  begin
    {!!.21 guts moved to FormPrim}
    Form := FormPrim(Mask, R, False);
  end;

  {FPC port: Upcase/LoCase/StUpcase/StLocase/MoveFast are defined near the
   top of this implementation section}

  function CharStr(Ch : Char; Len : Byte) : string;
    {-Return a string of length len filled with ch}
  var
    S : string;
  begin
    if Len = 0 then
      CharStr[0] := #0
    else begin
      S[0] := Chr(Len);
      FillChar(S[1], Len, Ch);
      CharStr := S;
    end;
  end;

  function PadCh(S : string; Ch : Char; Len : Byte) : string;
    {-Return a string right-padded to length len with ch}
  var
    o : string;
    SLen : Byte absolute S;
  begin
    if Length(S) >= Len then
      PadCh := S
    else begin
      o[0] := Chr(Len);
      MoveFast(S[1], o[1], SLen); {!!.01}
      if SLen < 255 then
        FillChar(o[Succ(SLen)], Len-SLen, Ch);
      PadCh := o;
    end;
  end;

  function Pad(S : string; Len : Byte) : string;
    {-Return a string right-padded to length len with blanks}
  begin
    Pad := PadCh(S, ' ', Len);
  end;

  function LeftPadCh(S : string; Ch : Char; Len : Byte) : string;
    {-Return a string left-padded to length len with ch}
  var
    o : string;
    SLen : Byte absolute S;
  begin
    if Length(S) >= Len then
      LeftPadCh := S
    else if SLen < 255 then begin
      o[0] := Chr(Len);
      MoveFast(S[1], o[Succ(Word(Len))-SLen], SLen); {!!.01}
      FillChar(o[1], Len-SLen, Ch);
      LeftPadCh := o;
    end;
  end;

  function LeftPad(S : string; Len : Byte) : string;
    {-Return a string left-padded to length len with blanks}
  begin
    LeftPad := LeftPadCh(S, ' ', Len);
  end;

  function TrimLead(S : string) : string;
    {-Return a string with leading white space removed}
  var
    I : Word;
  begin
    I := 1;
    while (I <= Length(S)) and (S[I] <= ' ') do
      Inc(I);
    Dec(I);
    if I > 0 then
      Delete(S, 1, I);
    TrimLead := S;
  end;

  function TrimTrail(S : string) : string;
    {-Return a string with trailing white space removed}
  var
    SLen : Byte absolute S;
  begin
    while (SLen > 0) and (S[SLen] <= ' ') do
      Dec(SLen);
    TrimTrail := S;
  end;

  function Trim(S : string) : string;
    {-Return a string with leading and trailing white space removed}
  var
    I : Word;
    SLen : Byte absolute S;
  begin
    while (SLen > 0) and (S[SLen] <= ' ') do
      Dec(SLen);

    I := 1;
    while (I <= SLen) and (S[I] <= ' ') do
      Inc(I);
    Dec(I);
    if I > 0 then
      Delete(S, 1, I);

    Trim := S;
  end;

  function TrimSpaces(S : string) : string;
    {-Return a string with leading and trailing spaces removed}
  var
    I : Word;
    SLen : Byte absolute S;
  begin
    while (SLen > 0) and (S[SLen] = ' ') do
      Dec(SLen);

    I := 1;
    while (I <= SLen) and (S[I] = ' ') do
      Inc(I);
    Dec(I);
    if I > 0 then
      Delete(S, 1, I);

    TrimSpaces := S;
  end;

  function CenterCh(S : string; Ch : Char; Width : Byte) : string;
    {-Return a string centered in a string of Ch with specified width}
  var
    o : string;
    SLen : Byte absolute S;
  begin
    if SLen >= Width then
      CenterCh := S
    else if SLen < 255 then begin
      o[0] := Chr(Width);
      FillChar(o[1], Width, Ch);
      MoveFast(S[1], o[Succ((Width-SLen) shr 1)], SLen); {!!.01}
      CenterCh := o;
    end;
  end;

  function Center(S : string; Width : Byte) : string;
    {-Return a string centered in a blank string of specified width}
  begin
    Center := CenterCh(S, ' ', Width);
  end;

  function Substitute(S, FromStr, ToStr : String) : String; {!!.02}
    {-Return string S after mapping characters found in FromStr to the
      corresponding ones in ToStr}
  var
    I : Byte;
    P : Byte;
  begin
    if Length(FromStr) = Length(ToStr) then
      for I := 1 to Length(S) do begin
        P := Pos(S[I], FromStr);
        if P <> 0 then
          S[I] := ToStr[P];
      end;
    Substitute := S;
  end;

  function Filter(S : String; CS : CharSet) : String; {!!.11}
    {-Return string S after removing all characters in CS from it}
  var
    I : Word;
    Len : Word;
  begin
    Len := 0;
    for I := 1 to Length(S) do
      if not(S[I] in CS) then begin
        inc(Len);
        Filter[Len] := S[I];
      end;
    Filter[0] := Char(Len);
  end;

  function WordCount(S : string; WordDelims : CharSet) : Byte;
    {-Given a set of word delimiters, return number of words in S}
  var
    {I,} Count : Byte;         {!!.02}
    I : Word;                  {!!.02}
    SLen : Byte absolute S;
  begin
    Count := 0;
    I := 1;

    while I <= SLen do begin
      {skip over delimiters}
      while (I <= SLen) and (S[I] in WordDelims) do
        Inc(I);

      {if we're not beyond end of S, we're at the start of a word}
      if I <= SLen then
        Inc(Count);

      {find the end of the current word}
      while (I <= SLen) and not(S[I] in WordDelims) do
        Inc(I);
    end;

    WordCount := Count;
  end;

  function WordPosition(N : Byte; S : string; WordDelims : CharSet) : Byte;
    {-Given a set of word delimiters, return start position of N'th word in S}
  var
    {I,} Count : Byte;         {!!.02}
    I : Word;                  {!!.02}
    SLen : Byte absolute S;
  begin
    Count := 0;
    I := 1;
    WordPosition := 0;

    while (I <= SLen) and (Count <> N) do begin
      {skip over delimiters}
      while (I <= SLen) and (S[I] in WordDelims) do
        Inc(I);

      {if we're not beyond end of S, we're at the start of a word}
      if I <= SLen then
        Inc(Count);

      {if not finished, find the end of the current word}
      if Count <> N then
        while (I <= SLen) and not(S[I] in WordDelims) do
          Inc(I)
      else
        WordPosition := I;
    end;
  end;

  function ExtractWord(N : Byte; S : string; WordDelims : CharSet) : string;
    {-Given a set of word delimiters, return the N'th word in S}
  var
    I : Word; {!!.12}
    Len : Byte;
    SLen : Byte absolute S;
  begin
    Len := 0;
    I := WordPosition(N, S, WordDelims);
    if I <> 0 then
      {find the end of the current word}
      while (I <= SLen) and not(S[I] in WordDelims) do begin
        {add the I'th character to result}
        Inc(Len);
        ExtractWord[Len] := S[I];
        Inc(I);
      end;
    ExtractWord[0] := Char(Len);
  end;

  function AsciiCount(S : string; WordDelims : CharSet; Quote : Char) : Byte;
    {!!.13-Given a set of word delimiters, return number of words in S}
  var
    {I,} Count : Byte;         {!!.02}
    I : Word;                  {!!.02}
    InQuote : Boolean;         {!!.13}
    SLen : Byte absolute S;
  begin
    Count := 0;
    I := 1;
    InQuote := False;

    while I <= SLen do begin
      {skip over delimiters}
      while (I <= SLen) and (S[i] <> Quote) and (S[I] in WordDelims) do begin
        if I = 1 then
          Inc(Count);
        Inc(I);
      end;

      {if we're not beyond end of S, we're at the start of a word}
      if I <= SLen then
        Inc(Count);

      {find the end of the current word}
      while (I <= SLen) and ((InQuote) or (not(S[I] in WordDelims))) do begin
        if S[I] = Quote then
          InQuote := not(InQuote);
        Inc(I);
      end;
    end;

    AsciiCount := Count;
  end;

  function AsciiPosition(N : Byte; S : string; WordDelims : CharSet; Quote : Char) : Byte;
    {!!.13-Given a set of word delimiters, return start position of N'th word in S}
  var
    {I,} Count : Byte;         {!!.02}
    I : Word;                  {!!.02}
    InQuote : Boolean;         {!!.13}
    SLen : Byte absolute S;
  begin
    Count := 0;
    I := 1;
    InQuote := False;
    AsciiPosition := 0;

    while (I <= SLen) and (Count <> N) do begin
      {skip over delimiters}
      if (I <= SLen) and (S[I] <> Quote) and (S[I] in WordDelims) then begin
        if I = 1 then
          Inc(Count);
        Inc(I);
      end;

      {if we're not beyond end of S, we're at the start of a word}
      if I <= SLen then
        Inc(Count);

      {if not finished, find the end of the current word}
      if Count <> N then
        while (I <= SLen) and ((InQuote) or (not(S[I] in WordDelims))) do begin
          if S[I] = Quote then
            InQuote := not(InQuote);
          Inc(I);
        end
      else
        AsciiPosition := I;
    end;
  end;

  function ExtractAscii(N : Byte; S : string; WordDelims : CharSet; Quote : Char) : string;
    {!!.13-Given a set of word delimiters, return the N'th word in S}
  var
    I : Word; {!!.12}
    Len : Byte;
    SLen : Byte absolute S;
    InQuote : Boolean;
  begin
    Len := 0;
    InQuote := False;
    I := AsciiPosition(N, S, WordDelims, Quote);
    if I <> 0 then
      {find the end of the current word}
      while (I <= SLen) and ((InQuote) or (not(S[I] in WordDelims))) do begin
        {add the I'th character to result}
        Inc(Len);
        if S[I] = Quote then
          InQuote := Not(InQuote);
        ExtractAscii[Len] := S[I];
        Inc(I);
      end;
    ExtractAscii[0] := Char(Len);
  end;

  procedure WordWrap(InSt : string; var OutSt, Overlap : string;
                     Margin : Byte; PadToMargin : Boolean);
    {-Wrap InSt at Margin, storing the result in OutSt and the remainder
      in Overlap}
  var
    InStLen : Byte absolute InSt;
    OutStLen : Byte absolute OutSt;
    OvrLen : Byte absolute Overlap;
    EOS, BOS : Word;
  begin
    {find the end of the output string}
    if InStLen > Margin then begin
      {find the end of the word at the margin, if any}
      EOS := Margin;
      while (EOS <= InStLen) and (InSt[EOS] <> ' ') do
        Inc(EOS);
      if EOS > InStLen then
        EOS := InStLen;

      {trim trailing blanks}
      while (InSt[EOS] = ' ') and (EOS > 0) do
        Dec(EOS);

      if EOS > Margin then begin
        {look for the space before the current word}
        while (EOS > 0) and (InSt[EOS] <> ' ') do
          Dec(EOS);

        {if EOS = 0 then we can't wrap it}
        if EOS = 0 then
          EOS := Margin
        else
          {trim trailing blanks}
          while (InSt[EOS] = ' ') and (EOS > 0) do
            Dec(EOS);
      end;
    end
    else
      EOS := InStLen;

    {copy the unwrapped portion of the line}
    OutStLen := EOS;
    MoveFast(InSt[1], OutSt[1], OutStLen); {!!.01}

    {find the start of the next word in the line}
    BOS := EOS+1;
    while (BOS <= InStLen) and (InSt[BOS] = ' ') do
      Inc(BOS);

    if BOS > InStLen then
      OvrLen := 0
    else begin
      {copy from the start of the next word to the end of the line}
      OvrLen := Succ(InStLen-BOS);
      MoveFast(InSt[BOS], Overlap[1], OvrLen); {!!.01}
    end;

    {pad the end of the output string if requested}
    if PadToMargin and (OutStLen < Margin) then begin
      FillChar(OutSt[OutStLen+1], Margin-OutStLen, ' ');
      OutStLen := Margin;
    end;
  end;

  {FPC port: ported from OPTAB.ASM}
  function Entab(S : string; TabSize : Byte) : string;
    {-Convert blanks in a string to tabs on spacing TabSize}
  var
    ILen, Ipos, OLen, SpaceCount, Op : Word;
    Ch, QCh : Char;
    R : string;
    Quoted : Boolean;
  begin
    R[0] := #0;
    ILen := Length(S);
    if (TabSize = 0) or (ILen = 0) then begin
      Entab := R;
      Exit;
    end;
    Ipos := 1;
    OLen := 0;
    SpaceCount := 0;
    Op := 1;
    repeat
      if (SpaceCount <> 0) and (Ipos mod TabSize = 1) then begin
        {replace the trailing blanks in the output by a tab}
        Dec(OLen, SpaceCount);
        Dec(Op, SpaceCount);
        R[Op] := #9;
        Inc(Op);
        Inc(OLen);
        SpaceCount := 0;
      end;
      Ch := S[Ipos];
      Quoted := False;
      if Ipos <> ILen then begin
        Inc(SpaceCount);
        if Ch <> ' ' then begin
          SpaceCount := 0;
          Quoted := (Ch = #39) or (Ch = '"');
        end;
      end;
      if Quoted then begin
        QCh := Ch;
        repeat
          R[Op] := Ch;
          Inc(Op);
          Inc(OLen);
          Inc(Ipos);
          Ch := S[Ipos];
          if Ipos >= ILen then
            Break;
          if Ch = QCh then begin
            if Ch = #39 then
              Break;
            if S[Ipos-1] <> '\' then
              Break;
          end;
        until False;
      end;
      R[Op] := Ch;
      Inc(Op);
      Inc(OLen);
      Inc(Ipos);
    until Ipos > ILen;
    R[0] := Chr(OLen);
    Entab := R;
  end;

  {FPC port: ported from OPTAB.ASM}
  function Detab(S : string; TabSize : Byte) : string;
    {-Expand tabs in a string to blanks on spacing TabSize}
  var
    I, OLen, NextStop : Word;
    R : string;
  begin
    R[0] := #0;
    OLen := 0;
    if TabSize <> 0 then
      for I := 1 to Length(S) do begin
        if OLen >= 255 then
          Break;
        if S[I] = #9 then begin
          NextStop := (OLen div TabSize + 1) * Word(TabSize);
          if NextStop > 255 then
            Break;
          FillChar(R[OLen+1], NextStop-OLen, ' ');
          OLen := NextStop;
        end else begin
          Inc(OLen);
          R[OLen] := S[I];
        end;
      end;
    R[0] := Chr(OLen);
    Detab := R;
  end;

  {FPC port: the following routines are ported from OPCOMP.ASM}
  function CompString(S1, S2 : string) : CompareType;
    {-Return less, equal, greater if s1<s2, s1=s2, or s1>s2}
  var
    I, N : Word;
  begin
    N := Length(S1);
    if Length(S2) < N then
      N := Length(S2);
    for I := 1 to N do
      if S1[I] <> S2[I] then begin
        if S1[I] < S2[I] then
          CompString := Less
        else
          CompString := Greater;
        Exit;
      end;
    if Length(S1) = Length(S2) then
      CompString := Equal
    else if Length(S1) < Length(S2) then
      CompString := Less
    else
      CompString := Greater;
  end;

  function CompUCString(S1, S2 : string) : CompareType;
    {-Compare two strings in a case insensitive manner}
  var
    I, N : Word;
    C1, C2 : Char;
  begin
    N := Length(S1);
    if Length(S2) < N then
      N := Length(S2);
    for I := 1 to N do begin
      C1 := UpcaseTbl(S1[I]);
      C2 := UpcaseTbl(S2[I]);
      if C1 <> C2 then begin
        if C1 < C2 then
          CompUCString := Less
        else
          CompUCString := Greater;
        Exit;
      end;
    end;
    if Length(S1) = Length(S2) then
      CompUCString := Equal
    else if Length(S1) < Length(S2) then
      CompUCString := Less
    else
      CompUCString := Greater;
  end;

  type
    BytesA = array[0..65534] of Byte;

  function CompStruct(var S1, S2; Size : Word) : CompareType;
    {-Compare two fixed size structures}
  var
    I : LongInt;
  begin
    CompStruct := Equal;
    for I := 0 to LongInt(Size)-1 do
      if BytesA(S1)[I] <> BytesA(S2)[I] then begin
        if BytesA(S1)[I] < BytesA(S2)[I] then
          CompStruct := Less
        else
          CompStruct := Greater;
        Exit;
      end;
  end;

  function Soundex(S : string) : string;
    {-Return 4 character soundex of input string}
  const
    {codes for 'A'..'Z'; other characters (including lower case in the
     original table, handled below) have no code}
    Codes : array['A'..'Z'] of Char =
      (#0, '1', '2', '3', #0, '1', '2', #0, #0, '2', '2', '4', '5',
       '5', #0, '1', '2', '6', '2', '3', #0, '1', #0, '2', #0, '2');
  var
    R : string;
    I, OLen : Word;
    Prev, Code, Ch : Char;
  begin
    R := '0000';
    if Length(S) > 0 then begin
      Prev := UpcaseTbl(S[1]);
      R[1] := Prev;
      OLen := 1;
      for I := 2 to Length(S) do begin
        Ch := S[I];
        if (Ch >= 'a') and (Ch <= 'z') then
          Ch := Chr(Ord(Ch)-32);
        if (Ch >= 'A') and (Ch <= 'Z') then
          Code := Codes[Ch]
        else
          Code := #0;
        if (Code <> #0) and (Code <> Prev) then begin
          Inc(OLen);
          R[OLen] := Code;
          if OLen >= 4 then
            Break;
          Prev := Code;
        end;
      end;
    end;
    Soundex := R;
  end;

  function MakeLetterSet(S : string) : LongInt;
    {-Return a bit-mapped long storing the individual letters contained in S}
  var
    I : Word;
    Ch : Char;
    L : Cardinal;
  begin
    L := 0;
    for I := 1 to Length(S) do begin
      Ch := UpcaseTbl(S[I]);
      if (Ch >= 'A') and (Ch <= 'Z') then
        L := L or (Cardinal(1) shl (Ord(Ch)-Ord('A')));
    end;
    MakeLetterSet := LongInt(L);
  end;

  function CompareLetterSets(Set1, Set2 : LongInt) : Word;
    {-Returns the sum of the values of the letters common to Set1 and Set2}
  var
    Common : Cardinal;
    I : Byte;
    Sum : Word;
  begin
    Common := Cardinal(Set1) and Cardinal(Set2);
    Sum := 0;
    for I := 0 to 25 do
      if (Common and (Cardinal(1) shl I)) <> 0 then
        Inc(Sum, LetterValues[Chr(Ord('A')+I)]);
    CompareLetterSets := Sum;
  end;

  {FPC port: the following routines are ported from OPSEARCH.ASM}
  function Search(var Buffer; BufLength : Word; var Match; MatLength : Word) : Word;
    {-Search through Buffer for Match. Returns number of bytes searched
      to find Match, $FFFF if not found.}
  var
    I, J, Last : LongInt;
  begin
    Search := $FFFF;
    if MatLength = 0 then
      Exit;
    Last := LongInt(BufLength)-LongInt(MatLength);
    for I := 0 to Last do
      if BytesA(Buffer)[I] = BytesA(Match)[0] then begin
        J := 1;
        while (J < MatLength) and (BytesA(Buffer)[I+J] = BytesA(Match)[J]) do
          Inc(J);
        if J >= MatLength then begin
          Search := Word(I);
          Exit;
        end;
      end;
  end;

  function SearchUC(var Buffer; BufLength : Word; var Match; MatLength : Word) : Word;
    {-Search through Buffer for Match, CASE-INSENSITIVE}
  var
    I, J, Last : LongInt;
    First : Char;
  begin
    SearchUC := $FFFF;
    if MatLength = 0 then
      Exit;
    First := UpcaseTbl(Chr(BytesA(Match)[0]));
    Last := LongInt(BufLength)-LongInt(MatLength);
    for I := 0 to Last do
      if UpcaseTbl(Chr(BytesA(Buffer)[I])) = First then begin
        J := 1;
        while (J < MatLength) and
              (UpcaseTbl(Chr(BytesA(Buffer)[I+J])) = UpcaseTbl(Chr(BytesA(Match)[J]))) do
          Inc(J);
        if J >= MatLength then begin
          SearchUC := Word(I);
          Exit;
        end;
      end;
  end;

  procedure ReplacePrim(var Buffer; BufLength, Posn, SrcLen : Word;
                        var Repl  ; RepLength : Word);
    {-Replace the SrcLen bytes of Buffer at Posn with the RepLength bytes
      in Repl}
  var
    Tail : LongInt;
  begin
    if SrcLen = 0 then
      Exit;
    {FPC port: the original assembler lost the last RepLength-SrcLen bytes
     when the buffer expanded; the tail is now moved intact}
    Tail := LongInt(BufLength)-Posn-SrcLen;
    if (SrcLen <> RepLength) and (Tail > 0) then
      Move(BytesA(Buffer)[Posn+SrcLen], BytesA(Buffer)[Posn+RepLength], Tail);
    if RepLength > 0 then
      Move(Repl, BytesA(Buffer)[Posn], RepLength);
  end;

  {FPC port: the following routines are ported from OPBM.ASM}
  procedure BMMakeTable(MatchString : string; var BT : BTable);
    {-Build Boyer-Moore link table}
  var
    I : LongInt;
  begin
    FillChar(BT, SizeOf(BT), Length(MatchString));
    for I := 1 to Length(MatchString)-1 do
      BT[Ord(MatchString[I])] := Length(MatchString)-I;
  end;

  function BMSearchPrim(var Buffer; BufLength : Word; var BT : BTable;
                        MatchString : string; UC : Boolean) : Word;
  var
    Len, Pos, J : LongInt;
    C, Last : Byte;
  begin
    BMSearchPrim := $FFFF;
    Len := Length(MatchString);
    if Len = 0 then
      Exit;
    Last := Ord(MatchString[Len]);
    Pos := Len-1;                    {index of last char of current window}
    while Pos < BufLength do begin
      C := BytesA(Buffer)[Pos];
      if UC then
        C := Ord(UpcaseTbl(Chr(C)));
      if C = Last then begin
        J := 1;
        while J < Len do begin
          C := BytesA(Buffer)[Pos-J];
          if UC then
            C := Ord(UpcaseTbl(Chr(C)));
          if C <> Ord(MatchString[Len-J]) then
            Break;
          Inc(J);
        end;
        if J >= Len then begin
          BMSearchPrim := Word(Pos-Len+1);
          Exit;
        end;
        C := Last;
      end;
      Inc(Pos, BT[C]);
    end;
  end;

  function BMSearch(var Buffer; BufLength : Word; BT : BTable; MatchString : string) : Word;
    {-Search Buffer for MatchString. Returns number of bytes searched to
      find MatchString, $FFFF if not found}
  begin
    BMSearch := BMSearchPrim(Buffer, BufLength, BT, MatchString, False);
  end;

  function BMSearchUC(var Buffer; BufLength : Word; BT : BTable; MatchString : string) : Word;
    {-Search Buffer for MatchString, CASE-INSENSITIVE.
      Assumes MatchString is already in uppercase.}
  begin
    BMSearchUC := BMSearchPrim(Buffer, BufLength, BT, MatchString, True);
  end;

  function StringToHeap(S : string) : StringPtr;
    {-Allocate space for s and return pointer}
  var
    L : Word;
    P : Pointer;
  begin
    L := Succ(Word(Length(S)));
    {FPC port: MaxAvail does not exist; GetMem raises a run-time error on failure}
    GetMem(P, L);
    MoveFast(S, P^, L); {!!.01}
    StringToHeap := P;
  end;

  function StringFromHeap(P : StringPtr) : string;
    {-Return string at p}
  begin
    if P = nil then
      StringFromHeap[0] := #0
    else
      StringFromHeap := P^;
  end;

  procedure DisposeString(P : StringPtr);
    {-Deallocate space for string at p}
  begin
    if P <> nil then
      FreeMem(P, Succ(Word(Byte(P^[0]))));
  end;

  function HasExtension(Name : string; var DotPos : Word) : Boolean;
    {-Return whether and position of extension separator dot in a pathname}
  var
    I : Word;
  begin
    DotPos := 0;
    for I := Length(Name) downto 1 do
      if (Name[I] = '.') and (DotPos = 0) then
        DotPos := I;
    HasExtension := (DotPos > 0) and
      (Pos('\', Copy(Name, Succ(DotPos), 64)) = 0) and
      (Pos('/', Copy(Name, Succ(DotPos), 64)) = 0);
  end;

  function DefaultExtension(Name : string; Ext : ExtStr) : string;
    {-Return a pathname with the specified extension attached}
  var
    DotPos : Word;
  begin
    if HasExtension(Name, DotPos) then
      DefaultExtension := Name
    else if Name = '' then
      DefaultExtension := ''
    else
      DefaultExtension := Name+'.'+Ext;
  end;

  function ForceExtension(Name : string; Ext : ExtStr) : string;
    {-Return a pathname with the specified extension attached}
  var
    DotPos : Word;
  begin
    if HasExtension(Name, DotPos) then
      ForceExtension := Copy(Name, 1, DotPos)+Ext
    else if Name = '' then
      ForceExtension := ''
    else
      ForceExtension := Name+'.'+Ext;
  end;

  function JustExtension(Name : string) : ExtStr;
    {-Return just the extension of a pathname}
  var
    DotPos : Word;
  begin
    if HasExtension(Name, DotPos) then
      JustExtension := Copy(Name, Succ(DotPos), ExtLen)
    else
      JustExtension := '';
  end;

  function JustFilename(PathName : string) : string;
    {-Return just the filename of a pathname}
  var
    I : Word;
  begin
    I := Succ(Word(Length(PathName)));
    repeat
      Dec(I);
    until (PathName[I] in DosDelimSet) or (I = 0);
    JustFilename := Copy(PathName, Succ(I), 64);
  end;

  function JustName(PathName : string) : string;
    {-Return just the name (no extension, no path) of a pathname}
  var
    DotPos : Byte;
  begin
    PathName := JustFileName(PathName);
    DotPos := Pos('.', PathName);
    if DotPos > 0 then
      PathName := Copy(PathName, 1, DotPos-1);
    JustName := PathName;
  end;

  function JustPathname(PathName : string) : string;
    {-Return just the drive:directory portion of a pathname}
  var
    I : Word;
  begin
    I := Succ(Word(Length(PathName)));
    repeat
      Dec(I);
    until (PathName[I] in DosDelimSet) or (I = 0);

    if I = 0 then
      {Had no drive or directory name}
      JustPathname[0] := #0
    else if I = 1 then
      {Either the root directory of default drive or invalid pathname}
      JustPathname := PathName[1]
    else if (PathName[I] = '\') or (PathName[I] = '/') then begin
      if (PathName[Pred(I)] = ':') and (PathName[I] = '\') then
        {Root directory of a drive, leave trailing backslash}
        JustPathname := Copy(PathName, 1, I)
      else
        {Subdirectory, remove the trailing backslash}
        JustPathname := Copy(PathName, 1, Pred(I));
    end else
      {Either the default directory of a drive or invalid pathname}
      JustPathname := Copy(PathName, 1, I);
  end;

  function AddBackSlash(DirName : string) : string;
    {-Add a default backslash to a directory name}
  begin
    if DirName[Length(DirName)] in DosDelimSet then
      AddBackSlash := DirName
    else
      AddBackSlash := DirName+DirSepChar;
  end;

  function CleanFileName(FileName : string) : string;
    {-Return filename with at most 8 chars of name and 3 of extension}
  var
    DotPos : Word;
    namelen : Word;
  begin
    if HasExtension(FileName, DotPos) then begin
      {Take the first 8 chars of name and first 3 chars of extension}
      namelen := Pred(DotPos);
      if namelen > 8 then
        namelen := 8;
      CleanFileName := Copy(FileName, 1, namelen)+Copy(FileName, DotPos, 4);
    end else
      {Take the first 8 chars of name}
      CleanFileName := Copy(FileName, 1, 8);
  end;

  function CleanPathName(PathName : string) : string;
    {-Return a pathname cleaned up as DOS will do it}
  var
    I : Word;
    oname : string;
  begin
    oname[0] := #0;

    {!!.03} {Remove repeated backslashes}
    I := Succ(Word(Length(PathName)));
    repeat
      dec(I);
      if I > 2 then
        if (PathName[I] = '\') and (PathName[I-1] = '\') then
          if (PathName[I-2] <> ':') then
            Delete(PathName, I, 1);
    until I <= 0;

    I := Succ(Word(Length(PathName)));
    repeat
      {Get the next directory or drive portion of pathname}
      repeat
        Dec(I);
      until (PathName[I] in DosDelimSet) or (I = 0);

      {Clean it up and prepend it to output string}
      oname := CleanFileName(Copy(PathName, Succ(I), 64))+oname;
      if I > 0 then begin
        oname := PathName[I]+oname;
        Delete(PathName, I, 255);
      end;
    until I <= 0;

    CleanPathName := oname;
  end;

  function FullPathName(FName : string) : string;
    {-Given FName (known to exist), return a full pathname}
  begin
    {FPC port: the DOS GetDir/drive logic is replaced by Dos.FExpand}
    FullPathName := FExpand(FName);
  end;

  procedure SetDefaultUpcase;   {!!.20}
  begin
    UCTable := DefUCTable;
  end;

  procedure SetInternationalUpcase;  {!!.20}
    {FPC port: stubbed because the DOS country-information upcase routine
     (INT 21h/3800h, called via real-mode far pointer) does not exist on
     Windows/Linux; the built-in CP437 table is used instead}
  begin
    SetDefaultUpcase;
    UpcaseFunc := Nil;
  end;

type                                                           {!!.30}
  FinditFunc = function(var Buffer; BufLength : Word;          {!!.30}
                        var Match ; MatLength : Word) : Word;  {!!.30}

  {!!.30 - New}
  function ReplaceIt(var Buffer; BufLength : Word;
                     var Match; MatLength : Word;
                     var Repl; RepLength : Word;
                     var NewLength : Word; MaxLength : Word;
                         FindFunc : FinditFunc; All : Boolean) : Word;
  type
    SearchBuf = array[0..$FFF0] of Byte;

  var
    FoundPos    : Word;
    TempPos     : Word;
    TempLength  : LongInt;
    BufferDelta : Integer;
    SearchStart : Word;
    Done        : Boolean;

  begin
    { calculate how much the buffer will grow or shrink with each replacement }
    BufferDelta := RepLength - MatLength;

    NewLength := BufLength;
    FoundPos  := FindFunc(Buffer, NewLength, Match, MatLength);
    Done      := False;
    ReplaceIt := $FFFF;
    while not Done and (FoundPos <> $FFFF) do begin
      ReplaceIt := FoundPos;
      TempLength := LongInt(BufferDelta) + NewLength;
      if (TempLength > MaxLength) then begin
        ReplaceIt := $FFFF;
        Exit;
      end;

      if not All then
        Done := True;

      ReplacePrim(Buffer, NewLength, FoundPos, MatLength, Repl, RepLength);
      NewLength   := TempLength;
      SearchStart := FoundPos + RepLength;
      TempPos     :=
        FindFunc( SearchBuf(Buffer)[SearchStart],
                  NewLength - SearchStart,
                  Match,
                  MatLength);
      if (TempPos <> $FFFF) then
        FoundPos := TempPos + SearchStart
      else
        FoundPos := $FFFF;
    end;
  end;

  {!!.30 - New}
  function Replace(var Buffer; BufLength : Word;
                   var Match; MatLength : Word;
                   var Repl; RepLength : Word;
                   var NewLength : Word;
                   MaxLength : Word;
                   All : Boolean) : Word;
  begin
    Replace := ReplaceIt( Buffer, BufLength, Match, MatLength, Repl,
                          RepLength, NewLength, MaxLength, Search, All);
  end;

  {!!.30 - New}
  function ReplaceUC(var Buffer; BufLength : Word;
                     var Match; MatLength : Word;
                     var Repl; RepLength : Word;
                     var NewLength : Word;
                     MaxLength : Word;
                     All : Boolean) : Word;
  begin
    ReplaceUC := ReplaceIt( Buffer, BufLength, Match, MatLength, Repl,
                            RepLength, NewLength, MaxLength, SearchUC, All);
  end;

begin
  {Initialize international uppercasing function for current code page} {!!.02}
  SetInternationalUpcase;   {!!.02}
end.
