{*********************************************************}
{*                  OPSWITCH.PAS 1.30                    *}
{*                by TurboPower Software                 *}
{*********************************************************}

{$I opdefine.inc}

unit OpSwitch;
  {-Routine for switching screens on dual-display systems}

  { FPC port: dual-monitor switching (BIOS data area $40:xx, equipment flag,
    mono/color video segments) has no equivalent on Windows/Linux.  The
    interface is kept; HasDualDisplays is always False so SwitchScreens is a
    no-op. }

interface

uses
  OpCrt;

type
  WhichScreen = (Screen1, Screen2);
const
  MonoMode : Word = Mono;
  ColorMode : Word = CO80;
  SwitchedOnce : Boolean = False;
var
  CurrentScreen : WhichScreen;
  HasDualDisplays : Boolean;

procedure SwitchScreens(SC : WhichScreen);
  {-Switch from the current screen to the specified screen}

  {==================================================================}

implementation

  { FPC port: stubbed because there is no second display adapter to switch to }
  procedure SwitchScreens(SC : WhichScreen);
  begin
  end;

begin
  HasDualDisplays := False;
  CurrentScreen := Screen1;
end.
