{FPC port: helper for OPDATE.  Replaces the DOS "get country information"
 call (INT 21h/AH=38h) with the locale settings of the Free Pascal RTL.
 Kept in its own unit so that SysUtils does not clash with OPDATE's names
 (Date, Time, ...).}

{$mode objfpc}{$H+}

unit OpDtLoc;

interface

procedure GetLocaleDateInfo(var DateFmt : Word;
                            var DateSep, TimeSep, ThousandSep, DecimalSep : Char;
                            var Hour24 : Boolean;
                            var Currency : ShortString;
                            var CurrDecimals : Byte);
  {-DateFmt: 0=mdy, 1=dmy, 2=ymd}

implementation

uses
  SysUtils;

procedure GetLocaleDateInfo(var DateFmt : Word;
                            var DateSep, TimeSep, ThousandSep, DecimalSep : Char;
                            var Hour24 : Boolean;
                            var Currency : ShortString;
                            var CurrDecimals : Byte);
var
  I : Integer;
  S : string;
begin
  DateFmt := 0;
  S := UpperCase(DefaultFormatSettings.ShortDateFormat);
  for I := 1 to Length(S) do
    case S[I] of
      'M' : begin DateFmt := 0; Break; end;
      'D' : begin DateFmt := 1; Break; end;
      'Y' : begin DateFmt := 2; Break; end;
    end;
  DateSep := DefaultFormatSettings.DateSeparator;
  TimeSep := DefaultFormatSettings.TimeSeparator;
  ThousandSep := DefaultFormatSettings.ThousandSeparator;
  DecimalSep := DefaultFormatSettings.DecimalSeparator;
  if ThousandSep = #0 then
    ThousandSep := ',';
  S := UpperCase(DefaultFormatSettings.ShortTimeFormat+
                 DefaultFormatSettings.LongTimeFormat);
  Hour24 := (Pos('AM', S) = 0) and (Pos('A/P', S) = 0);
  Currency := DefaultFormatSettings.CurrencyString;
  CurrDecimals := DefaultFormatSettings.CurrencyDecimals;
end;

end.
