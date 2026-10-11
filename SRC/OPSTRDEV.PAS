{$S-,R-,V-,I-,B-,F+,O-,A-}

{$IFDEF Dpmi}                               {!!.20}
  {$C FIXED PRELOAD PERMANENT}              {!!.20}
{$ENDIF}                                    {!!.20}

{$I opdefine.inc}

{*********************************************************}
{*                  OPSTRDEV.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OPStrDev;
  {-Routines for reading and writing strings}

interface

var
  TPStr : Text;

procedure ReadStr(var S : string);
  {-'Read' a string into S from our string buffer}

function ReturnStr : string;
  {-Return the contents of our string buffer}

  {==========================================================================}

implementation

uses
  Dos;

var
  StrBuf : string;
  StrLen : Byte absolute StrBuf;

  {FPC port: the TP File Interface Block hack is replaced by an FPC text-file
   driver (TextRec with custom Open/InOut/Flush/Close functions)}

  procedure ReadStr(var S : string);
    {-'Read' a string into S from our string buffer}
  begin
    if TextRec(TPStr).BufPos > 0 then
      StrLen := TextRec(TPStr).BufPos;
    S := StrBuf;
    StrLen := 0;
    TextRec(TPStr).BufPos := 0;
  end;

  function ReturnStr : string;
    {-Return the contents of our string buffer}
  begin
    if TextRec(TPStr).BufPos > 0 then
      StrLen := TextRec(TPStr).BufPos;
    ReturnStr := StrBuf;
    StrLen := 0;
    TextRec(TPStr).BufPos := 0;
  end;

  function StrOut(var F : TextRec) : LongInt;
    {-Update the length byte of StrBuf}
  begin
    if F.BufPos > 0 then
      StrLen := F.BufPos;
    F.BufPos := 0;
    StrOut := 0;
  end;

  function StrZero(var F : TextRec) : LongInt;
    {-Return success flag, but do nothing}
  begin
    StrZero := 0;
  end;

  function StrOpen(var F : TextRec) : LongInt;
  begin
    F.Mode := fmOutput;
    F.InOutFunc := @StrOut;
    F.FlushFunc := @StrOut;
    F.CloseFunc := @StrZero;
    F.BufPtr := @StrBuf[1];
    F.BufSize := 255;
    F.BufPos := 0;
    F.BufEnd := 0;
    StrOpen := 0;
  end;

  procedure AssignStr(var F : Text);
    {-Initialize the text file driver}
  begin
    Assign(F, 'STRDEV');
    TextRec(F).Mode := fmClosed;
    TextRec(F).OpenFunc := @StrOpen;

    {start with an empty string buffer}
    StrLen := 0;
  end;

begin
  AssignStr(TPStr);
  Rewrite(TPStr);
end.
