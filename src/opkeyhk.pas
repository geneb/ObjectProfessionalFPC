{*********************************************************}
{*                   OPKEYHK.PAS (FPC port)              *}
{*  Keyboard hook shared by OPCRT, OPMACRO and OPREPLAY  *}
{*********************************************************}

{$I opdefine.inc}

unit OpKeyHk;
  {-FPC port: replacement for the INT $16 chain used by the original
    OPMACRO/OPREPLAY macro engines.

    OPCRT must route its lowest-level key functions through KeyHook when it
    is assigned:

      function ReadKeyWord : Word;
        var K : Word;
        begin
          if @KeyHook <> nil then begin
            KeyHook(False, K);     (blocks until a key is available)
            ReadKeyWord := K;
          end
          else ReadKeyWord := <native blocking read>;
        end;

      function CheckKbd(var KeyCode : Word) : Boolean;   (KeyPressed too)
        begin
          if @KeyHook <> nil then
            CheckKbd := KeyHook(True, KeyCode)   (peek, does not consume)
          else
            CheckKbd := <native peek>;
        end;

    and, at its initialization, must assign RawCheckKbdProc (native peek that
    does not call the hook) and RawReadKeyWordProc (native blocking read that
    does not call the hook).}

interface

type
  KeyHookFunc = function(Peek : Boolean; var Key : Word) : Boolean;
  RawCheckKbdFunc = function(var Key : Word) : Boolean;
  RawReadKeyWordFunc = function : Word;

var
  KeyHook : KeyHookFunc;                  {nil if no hook is installed}
  RawCheckKbdProc : RawCheckKbdFunc;      {set by OPCRT}
  RawReadKeyWordProc : RawReadKeyWordFunc; {set by OPCRT}

implementation

begin
  KeyHook := nil;
  RawCheckKbdProc := nil;
  RawReadKeyWordProc := nil;
end.
