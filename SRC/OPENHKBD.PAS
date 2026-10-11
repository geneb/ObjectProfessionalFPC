{$I opdefine.inc}

{*********************************************************}
{*                  OPENHKBD.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpEnhKbd;
  {-Enhanced keyboard routines}

  {FPC port: the BIOS interrupt hooks are gone. Enhanced keys are provided
   by the FPC Keyboard unit (initialised by OpCrt), so this unit only keeps
   its public interface and flags.}

interface

const
  EnableEnhanced : Boolean = True; {Set false to temporarily disable handlers}

var
  HasEnhancedKbd : Boolean;  {True when enhanced keyboard is detected}
  FiltersEnhanced : Boolean; {True when keyboard BIOS filters enhanced keys}

procedure RestoreKbdVectors;
  {-Restores original vectors for INT's $09 and $16}

procedure InitKbdVectors;
  {-Save and setup interrupt vectors. This routine should be called only if
    RestoreKbdVectors has been called first}

  {=========================================================================}

implementation

  procedure InitKbdVectors;
  begin
    {FPC port: stubbed because there are no interrupt vectors}
  end;

  procedure RestoreKbdVectors;
  begin
    {FPC port: stubbed because there are no interrupt vectors}
  end;

begin
  HasEnhancedKbd := True;
  FiltersEnhanced := False;
end.
