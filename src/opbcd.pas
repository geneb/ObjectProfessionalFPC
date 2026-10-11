{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows applications !!  {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F+,O+,A-}

{Conditional defines that may affect this unit}
{$I opdefine.inc}

{*********************************************************}
{*                    OPBCD.PAS 1.30                     *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

{ FPC port: the BCD arithmetic was 8086 assembly; it is re-implemented in
  portable Pascal (see the note at the start of the implementation). }

unit OpBCD;
  {-Binary Coded Decimal routines}

interface

const
  BCDsize = 10;
type
  BCD = array[1..BCDsize] of Byte;
const
  {Pi in BCD format}
  PiBcd : BCD = ($40, $24, $93, $97, $58, $53, $26, $59, $41, $31);
const
  {0 in BCD format}
  ZeroBcd : BCD = ($0, $0, $0, $0, $0, $0, $0, $0, $0, $0);
const
  {minimum value for a BCD real}
  MinBCD : BCD = ($FF,$00,$00,$00,$00,$00,$00,$00,$00,$99); {-9.9e+63}
const
  {maximum value for a BCD real}
  MaxBCD : BCD = ($7F,$00,$00,$00,$00,$00,$00,$00,$00,$99); {+9.9e+63}
const
  MoneySign : Char = '$';    {Used by Form for floating dollar sign}
  CommaForPeriod : Boolean = False; {replace '.' with ',' in Form masks}

procedure RealToBCD(R : Real; var B : BCD);
  {-Convert a real to a BCD}

procedure LongintToBCD(L : LongInt; var B : BCD);
  {-Convert a Longint to a BCD}

function BCDtoReal(B : BCD) : Real;
  {-Convert a BCD to a real}

function StrBCD(B : BCD; Width, Places : Byte) : string;
  {-Return a BCD as a string}

function StrExpBCD(B : BCD; Width : Byte) : string;
  {-Return B as a string in exponential format}

procedure ValBCD(S : string; var B : BCD; var Code : Word);
  {-Convert a string to a BCD}

procedure AbsBCD(B1 : BCD; var B2 : BCD);
  {-Returns absolute value of B1 in B2}

procedure FracBCD(B1 : BCD; var B2 : BCD);
  {-Returns the fractional part of B1 in B2}

procedure IntBCD(B1 : BCD; var B2 : BCD);
  {-Returns the integer part of B1 in B2}

function RoundBCD(B1 : BCD) : LongInt;
  {-Returns the value of B1 rounded to the nearest long integer}

function TruncBCD(B1 : BCD) : LongInt;
  {-Returns the greatest long integer less than or equal to B1}

function Form(Mask : string; B : BCD) : string;
  {-Returns a formatted string with digits from B merged into the Mask}

procedure AddBCD(B1, B2 : BCD; var B3 : BCD);
  {-Add B1 to B2 and put result in B3}

procedure SubBCD(B1, B2 : BCD; var B3 : BCD);
  {-Subtract B2 from B1 and put result in B3}

procedure MultBCD(B1, B2 : BCD; var B3 : BCD);
  {-Multiply B1 by B2 and put result in B3}

procedure DivBCD(B1, B2 : BCD; var B3 : BCD);
  {-Divide B1 by B2 and put result in B3}

function EqualBCD(B1, B2 : BCD) : Boolean;
  {-Returns true if B1 = B2}

function NotEqualBCD(B1, B2 : BCD) : Boolean;
  {-Returns true if B1 <> B2}

function GreaterBCD(B1, B2 : BCD) : Boolean;
  {-Returns true if B1 > B2}

function GreaterEqualBCD(B1, B2 : BCD) : Boolean;
  {-Returns true if B1 >= B2}

function LessBCD(B1, B2 : BCD) : Boolean;
  {-Returns true if B1 < B2}

function LessEqualBCD(B1, B2 : BCD) : Boolean;
  {-Returns true if B1 <= B2}

  {** transcendental functions **}

procedure ArcTanBCD(B1 : BCD; var B2 : BCD);
  {-Returns arc tangent of B1 in B2}

procedure CosBCD(B1 : BCD; var B2 : BCD);
  {-Returns cosine of B1 in B2}

procedure ExpBCD(B1 : BCD; var B2 : BCD);
  {-Returns the exponential of B1 in B2}

procedure LnBCD(B1 : BCD; var B2 : BCD);
  {-Returns the natural log of B1 in B2}

procedure SinBCD(B1 : BCD; var B2 : BCD);
  {-Returns the sine of B1 in B2}

procedure SqrBCD(B1 : BCD; var B2 : BCD);
  {-Returns the square of B1 in B2}

procedure SqrtBCD(B1 : BCD; var B2 : BCD);
  {-Returns the square root of B1 in B2}

  {==========================================================================}

implementation
{ FPC port: the original implementation was 8086 assembly (OPBCD.ASM,
  BCDARITH.ASM, BCDCOMP.ASM, BCDCONV.ASM, BCDTRANS.ASM) linked with $L.  It has
  been re-implemented below in portable Pascal, keeping the packed BCD format,
  the digit-by-digit algorithms, the 18-digit precision, round-half-up rules,
  and the error behaviour (run-time error 200 where the original executed INT 0
  on overflow, divide by zero, or invalid arguments).  Differences:
    - results that are zero are always returned as ten zero bytes;
    - RealToBCD/BCDtoReal use all digits of the FPC Real (Double) instead of the
      11 digits of a Turbo Pascal 6-byte Real. }

const
  UnpMax = 79;
type
  Dig = array[0..UnpMax] of Byte;  {unpacked BCD: [0]=sign/exp, [1..18]=digits LSD first, [19]=overflow}
const
  MantDigits = 18;
var
  {temporary reals in packed format (same roles as in the original assembly)}
  T1, T2, T4, T5, T6 : BCD;

const
  {constants for the transcendental functions (from BCDTRANS.ASM)}
  c_MaxX : BCD = ($42,$23,$89,$61,$51,$59,$44,$65,$73,$14);   {0.147365445951618923e+3}
  c_MinX : BCD = ($C2,$78,$48,$62,$58,$08,$86,$62,$50,$14);   {-0.145062860858624878e+3}
  c_a1 : BCD = ($3F,$55,$36,$50,$06,$38,$96,$88,$85,$86);   {0.868588963806503655e+0}
  c_a2 : BCD = ($40,$33,$79,$83,$16,$60,$76,$27,$62,$31);   {0.316227766016837933e+1}
  c_a3 : BCD = ($3F,$00,$00,$00,$00,$00,$00,$00,$00,$50);   {0.500000000000000000e+0}
  c_a4 : BCD = ($40,$00,$00,$00,$00,$00,$00,$00,$00,$20);   {0.200000000000000000e+1}
  c_c1 : BCD = ($40,$00,$00,$00,$00,$00,$00,$00,$51,$11);   {0.115100000000000000e+1}
  c_c2 : BCD = ($3C,$09,$20,$84,$22,$70,$49,$46,$25,$29);   {0.292546497022842009e-3}
  c_p0 : BCD = ($45,$11,$16,$80,$26,$92,$02,$67,$32,$33);   {0.333267029226801611e+6}
  c_p1 : BCD = ($44,$18,$39,$27,$24,$87,$14,$74,$09,$10);   {0.100974148724273918e+5}
  c_p2 : BCD = ($41,$15,$03,$45,$37,$81,$26,$14,$04,$42);   {0.420414268137450315e+2}
  c_q0 : BCD = ($45,$23,$32,$60,$53,$84,$05,$34,$65,$66);   {0.666534058453603223e+6}
  c_q1 : BCD = ($44,$44,$34,$88,$59,$61,$34,$93,$73,$75);   {0.757393346159883444e+5}
  c_q2 : BCD = ($42,$45,$45,$15,$14,$45,$58,$43,$12,$84);   {0.841243584514154545e+3}
  c_d0 : BCD = ($C1,$17,$31,$03,$81,$78,$07,$52,$95,$89);   {-0.899552077881033117E+2}
  c_d1 : BCD = ($42,$48,$93,$48,$68,$88,$61,$47,$53,$24);   {0.245347618868489348E+3}
  c_d2 : BCD = ($C2,$42,$95,$82,$41,$53,$03,$03,$43,$24);   {-0.244303035341829542E+3}
  c_d3 : BCD = ($42,$09,$80,$66,$15,$91,$78,$09,$71,$10);   {0.107109789115668009E+3}
  c_d4 : BCD = ($C1,$86,$47,$85,$32,$58,$34,$32,$37,$19);   {-0.193732345832854786E+2}
  c_e0 : BCD = ($C1,$36,$76,$55,$05,$24,$00,$47,$04,$26);   {-0.260447002405557636E+2}
  c_e1 : BCD = ($41,$31,$59,$20,$41,$20,$91,$85,$40,$55);   {0.554085912041205931E+2}
  c_e2 : BCD = ($C1,$50,$62,$15,$03,$02,$41,$37,$27,$39);   {-0.392737410203156250E+2}
  c_e3 : BCD = ($41,$65,$38,$79,$14,$15,$57,$38,$33,$10);   {0.103338571514793865E+2}
  c_e4 : BCD = ($BF,$39,$92,$91,$61,$41,$78,$10,$10,$74);   {-0.741010784161919239E+0}
  c_f0 : BCD = ($3F,$33,$79,$83,$16,$60,$76,$27,$62,$31);   {0.316227766016837933E+0}
  c_f1 : BCD = ($3F,$55,$36,$50,$06,$38,$96,$88,$85,$86);   {0.868588963806503655E+0}
  c_f2 : BCD = ($40,$68,$45,$40,$99,$92,$50,$58,$02,$23);   {0.230258509299404568E+1}
  c_f3 : BCD = ($40,$00,$00,$00,$00,$00,$00,$00,$00,$10);   {0.100000000000000000E+1}
  c_s0 : BCD = ($3F,$00,$00,$00,$00,$00,$00,$07,$36,$22);   {0.223607}
  c_s1 : BCD = ($3F,$00,$00,$00,$00,$00,$00,$70,$44,$89);   {0.894470}
  c_s2 : BCD = ($3F,$33,$79,$83,$16,$60,$76,$27,$62,$31);   {0.316227766016837933 (SQRT(0.1))}
  c_MaxY : BCD = ($49,$00,$00,$00,$00,$54,$26,$59,$41,$31);   {0.314159265400000000e+10}
  c_onepi : BCD = ($3F,$72,$06,$79,$83,$61,$88,$09,$83,$31);   {0.318309886183790672e+0}
  c_b1 : BCD = ($40,$00,$00,$00,$00,$00,$00,$00,$41,$31);   {0.314100000000000000e+1}
  c_b2 : BCD = ($3C,$63,$84,$23,$93,$97,$58,$53,$26,$59);   {0.592653589793238463e-3}
  c_eps : BCD = ($37,$00,$00,$00,$00,$00,$00,$00,$00,$10);   {0.100000000000000000e-8}
  c_r1 : BCD = ($BF,$51,$66,$66,$66,$66,$66,$66,$66,$16);   {-0.166666666666666651e+0}
  c_r2 : BCD = ($3D,$03,$65,$31,$33,$33,$33,$33,$33,$83);   {0.833333333333316503e-2}
  c_r3 : BCD = ($BC,$05,$84,$01,$12,$84,$69,$12,$84,$19);   {-0.198412698412018405E-3}
  c_r4 : BCD = ($3A,$61,$75,$52,$01,$21,$19,$73,$55,$27);   {0.275573192101527561E-5}
  c_r5 : BCD = ($B8,$45,$58,$74,$82,$79,$06,$21,$05,$25);   {-0.250521067982745845E-7}
  c_r6 : BCD = ($36,$91,$58,$71,$03,$49,$36,$89,$05,$16);   {0.160589364903715891E-9}
  c_r7 : BCD = ($B3,$77,$46,$10,$89,$06,$78,$91,$42,$76);   {-0.764291780689104677E-12}
  c_r8 : BCD = ($31,$62,$84,$88,$78,$95,$90,$47,$20,$27);   {0.272047909578888462E-14}
  c_pi4 : BCD = ($3F,$10,$83,$44,$97,$33,$16,$98,$53,$78);   {0.785398163397448310e+0}
  c_g0 : BCD = ($43,$92,$03,$44,$40,$87,$75,$75,$57,$50);   {0.505775758740440392e+4}
  c_g1 : BCD = ($44,$73,$33,$32,$78,$31,$72,$77,$98,$14);   {0.149877723178323373e+5}
  c_g2 : BCD = ($44,$12,$09,$25,$08,$33,$11,$11,$03,$17);   {0.170311113308250912e+5}
  c_g3 : BCD = ($43,$40,$53,$28,$00,$94,$79,$59,$09,$93);   {0.930959799400285340e+4}
  c_g4 : BCD = ($43,$11,$41,$17,$88,$24,$63,$23,$13,$25);   {0.251323632488174111e+4}
  c_g5 : BCD = ($42,$77,$15,$67,$33,$97,$91,$55,$73,$30);   {0.307355919733671577e+3}
  c_g6 : BCD = ($41,$93,$63,$86,$60,$65,$10,$50,$20,$13);   {0.132050106560866393e+2}
  c_g7 : BCD = ($3E,$75,$68,$33,$93,$51,$74,$86,$97,$84);   {0.849786745193336875e-1}
  c_h0 : BCD = ($43,$92,$03,$44,$40,$87,$75,$75,$57,$50);   {0.505775758740440392e+4}
  c_h1 : BCD = ($44,$53,$80,$33,$36,$51,$91,$36,$67,$16);   {0.166736915136338053e+5}
  c_h2 : BCD = ($44,$26,$48,$55,$45,$98,$56,$74,$57,$21);   {0.215774569845554826e+5}
  c_h3 : BCD = ($44,$41,$06,$95,$09,$15,$82,$98,$88,$13);   {0.138898821509950641e+5}
  c_h4 : BCD = ($43,$45,$26,$42,$22,$10,$85,$68,$47,$46);   {0.464768851022422645e+4}
  c_h5 : BCD = ($42,$46,$14,$03,$42,$17,$60,$66,$82,$76);   {0.768266601742031446e+3}
  c_h6 : BCD = ($41,$51,$81,$84,$13,$09,$96,$16,$26,$53);   {0.532616960913848151e+2}
  c_h7 : BCD = ($40,$00,$00,$00,$00,$00,$00,$00,$00,$10);   {0.100000000000000000e+1}

  procedure MathError;
    {-The original executed INT 0 here: run-time error 200}
  begin
    RunError(200);
  end;

  procedure Unpack(const P : BCD; var U : Dig);
    {-Expand the packed mantissa into one digit per byte}
  var
    K : Integer;
  begin
    FillChar(U, SizeOf(U), 0);
    U[0] := P[1];
    for K := 1 to 9 do begin
      U[2*K-1] := P[K+1] and $0F;
      U[2*K] := P[K+1] shr 4;
    end;
  end;

  procedure PackMant(const U : Dig; var P : BCD);
    {-Pack digits 1..18 into bytes 2..10; sign/exponent byte is untouched}
  var
    K : Integer;
  begin
    for K := 1 to 9 do
      P[K+1] := U[2*K-1] or (U[2*K] shl 4);
  end;

  procedure SetUsers(var B : BCD);
    {-Store T2 in a user's variable; zero results are all zero bytes}
  begin
    if T2[1] = 0 then
      FillChar(B, SizeOf(B), 0)
    else
      B := T2;
  end;

  function RoundDig(var D : Dig; Pos : Integer) : Boolean;
    {-Round up the 18 digits above D[Pos] if D[Pos] >= 5. Returns True if the
      carry ran out of the top (a 1 is then stored above them).}
  var
    I, N : Integer;
  begin
    RoundDig := False;
    if D[Pos] < 5 then
      Exit;
    I := Pos + 1;
    for N := 1 to 18 do
      if D[I] >= 9 then begin
        D[I] := 0;
        Inc(I);
      end
      else begin
        Inc(D[I]);
        Exit;
      end;
    D[I] := 1;
    RoundDig := True;
  end;

  procedure ShiftDigitsLeft(var D : Dig);
    {-Move digits 2..19 down to 1..18}
  var
    I : Integer;
  begin
    for I := 1 to 18 do
      D[I] := D[I+1];
  end;

  function AddPrim : Boolean;
    {-T2 := T1 + T2; returns True (carry) on overflow}
  var
    U1, U2 : Dig;
    E1, E2, X1, X2, Diff, K, I, S, DL, DH, BL, P : Integer;
    Subtract, C : Boolean;
  begin
    AddPrim := False;
    if T1[1] = 0 then
      Exit;
    if T2[1] = 0 then begin
      T2 := T1;
      Exit;
    end;
    Unpack(T1, U1);
    Unpack(T2, U2);
    E1 := T1[1];
    E2 := T2[1];
    X1 := E1 and $7F;
    X2 := E2 and $7F;
    DH := E2 and $80;
    Subtract := ((E1 xor E2) and $80) <> 0;
    U1[0] := 0;
    U2[0] := 0;

    {align the mantissas (digits 0..18); the lowest digit is a guard digit}
    DL := X2;
    Diff := X2 - X1;
    if Diff <> 0 then begin
      if Diff > 0 then
        K := Diff
      else begin
        K := -Diff;
        DL := X1;
      end;
      if K > MantDigits then begin
        if Diff > 0 then FillChar(U1, 19, 0) else FillChar(U2, 19, 0);
      end
      else if Diff > 0 then begin
        for I := 0 to 18 - K do U1[I] := U1[I+K];
        for I := 19 - K to 18 do U1[I] := 0;
      end
      else begin
        for I := 0 to 18 - K do U2[I] := U2[I+K];
        for I := 19 - K to 18 do U2[I] := 0;
      end;
    end;

    C := False;
    if not Subtract then begin
      for I := 0 to 18 do begin
        S := U1[I] + U2[I] + Ord(C);
        C := S > 9;
        if C then Dec(S, 10);
        U2[I] := S;
      end;
      if C then begin
        Inc(U2[19]);
        Inc(DL);
      end;
    end
    else begin
      for I := 0 to 18 do begin
        S := U2[I] - U1[I] - Ord(C);
        C := S < 0;
        if C then Inc(S, 10);
        U2[I] := S;
      end;
      if C then begin
        C := False;
        for I := 0 to 18 do begin
          S := -U2[I] - Ord(C);
          C := S < 0;
          if C then Inc(S, 10);
          U2[I] := S;
        end;
        DH := DH xor $80;
      end;
    end;

    {normalize}
    BL := 0;
    P := 0;
    if U2[19] <> 0 then begin
      RoundDig(U2, 1);
      ShiftDigitsLeft(U2);
    end
    else if U2[18] <> 0 then begin
      RoundDig(U2, 0);
      if U2[19] <> 0 then begin
        ShiftDigitsLeft(U2);
        Inc(DL);
      end;
    end
    else begin
      P := 17;
      while (P >= 0) and (U2[P] = 0) do Dec(P);
      if P < 0 then
        DL := 0                       {all zero}
      else begin
        BL := 18 - P;
        for I := P downto 0 do U2[I + BL] := U2[I];
        for I := 0 to BL - 1 do U2[I] := 0;
      end;
    end;

    if P < 0 then
      DL := 0
    else
      DL := DL - BL;
    if DL <= 0 then begin
      T2[1] := 0;
      PackMant(U2, T2);
    end
    else if DL >= $80 then begin
      T2[1] := 0;
      PackMant(U2, T2);
      AddPrim := True;
    end
    else begin
      T2[1] := DL or DH;
      PackMant(U2, T2);
    end;
  end;

  procedure MultPrim;
    {-T2 := T1 * T2}
  var
    U1, U2, P3 : Dig;
    A1, A2, K, J, T, Carry, SI, DX, E : Integer;
  begin
    A2 := T2[1];
    T2[1] := 0;
    if A2 = 0 then
      Exit;
    A1 := T1[1];
    if A1 = 0 then
      Exit;
    Unpack(T1, U1);
    Unpack(T2, U2);
    FillChar(P3, SizeOf(P3), 0);
    for K := 1 to MantDigits do
      if U2[K] <> 0 then begin
        Carry := 0;
        for J := 1 to MantDigits do begin
          T := U1[J] * U2[K] + P3[K+J-1] + Carry;
          P3[K+J-1] := T mod 10;
          Carry := T div 10;
        end;
        P3[K+MantDigits] := Carry;
      end;
    SI := 2 * MantDigits;
    DX := 0;
    if P3[SI] = 0 then begin
      DX := -1;
      Dec(SI);
    end;
    if RoundDig(P3, SI - MantDigits) then begin
      Inc(DX);
      Inc(SI);
    end;
    for K := 0 to MantDigits - 1 do
      U2[MantDigits - K] := P3[SI - K];
    PackMant(U2, T2);
    {compute the exponent}
    E := ((A1 and $7F) + (A2 and $7F) + DX) and $FF;
    if E <= $3F then
      Exit                           {underflow: zero}
    else begin
      E := E - $3F;
      if E >= $80 then
        MathError
      else
        T2[1] := E xor (A1 and $80) xor (A2 and $80);
    end;
  end;

  procedure DivPrim;
    {-T2 := T2 / T1}
  var
    U1, U2, P3 : Dig;
    A1, A2, I, J, Q, DH, SI, R, Times, DX, E, S : Integer;
    Fits, Borrow : Boolean;
  begin
    if T1[1] = 0 then begin
      MathError;
      Exit;
    end;
    if T2[1] = 0 then
      Exit;
    A2 := T2[1];
    A1 := T1[1];
    Unpack(T1, U1);
    Unpack(T2, U2);
    FillChar(P3, SizeOf(P3), 0);
    for I := 1 to 19 do
      P3[19 + I] := U2[I];
    {number of significant digits in the divisor}
    Q := 1;
    while (Q <= 19) and (U1[Q] = 0) do Inc(Q);
    if Q > MantDigits then begin
      MathError;
      Exit;
    end;
    DH := 19 - Q;
    SI := 2 * MantDigits + 1;
    for R := MantDigits downto 0 do begin
      Times := 0;
      repeat
        if P3[SI+1] <> 0 then
          Fits := True
        else begin
          Fits := True;
          for J := 0 to DH - 1 do
            if P3[SI-J] > U1[MantDigits-J] then
              Break
            else if P3[SI-J] < U1[MantDigits-J] then begin
              Fits := False;
              Break;
            end;
        end;
        if Fits then begin
          Inc(Times);
          Borrow := False;
          for J := 0 to DH - 1 do begin
            S := P3[SI-DH+1+J] - U1[MantDigits-DH+1+J] - Ord(Borrow);
            Borrow := S < 0;
            if Borrow then Inc(S, 10);
            P3[SI-DH+1+J] := S;
          end;
          if Borrow then
            Dec(P3[SI+1]);
        end;
      until not Fits;
      U2[R] := Times;
      Dec(SI);
    end;
    {scale and round the result}
    if U2[MantDigits] = 0 then begin
      for I := MantDigits downto 1 do
        U2[I] := U2[I-1];
      DX := 1;
    end
    else begin
      DX := 0;
      if RoundDig(U2, 0) then begin
        {FPC port: the original lost the mantissa here; result is 1.0 * 10}
        FillChar(U2[1], MantDigits, 0);
        U2[MantDigits] := 1;
        DX := -1;
      end;
    end;
    PackMant(U2, T2);
    {compute the exponent}
    E := (A2 and $7F) + $40 - (A1 and $7F);
    if E <= 0 then
      T2[1] := 0
    else if E >= $80 then
      MathError
    else begin
      E := E - DX;
      if E <= 0 then
        T2[1] := 0
      else if E >= $80 then
        MathError
      else
        T2[1] := E xor (A1 and $80) xor (A2 and $80);
    end;
  end;

  function CompReals(const B1, B2 : BCD) : Integer;
    {-Returns -1, 0, or 1 if B1 <, =, or > B2}
  var
    A, B, EA, EB, I : Integer;
    Swap : Boolean;
  begin
    A := B1[1];
    B := B2[1];
    if ((A xor B) and $80) <> 0 then begin
      if A >= $80 then
        CompReals := -1
      else
        CompReals := 1;
      Exit;
    end;
    Swap := (B and $80) <> 0;            {both negative: reverse the comparison}
    EA := A and $7F;
    EB := B and $7F;
    if Swap then begin
      I := EA; EA := EB; EB := I;
    end;
    CompReals := 0;
    if (EA = 0) and (EB = 0) then
      Exit;
    if EA <> EB then begin
      if EA < EB then CompReals := -1 else CompReals := 1;
      Exit;
    end;
    for I := 10 downto 2 do
      if B1[I] <> B2[I] then begin
        if (B1[I] < B2[I]) <> Swap then
          CompReals := -1
        else
          CompReals := 1;
        Exit;
      end;
  end;

  procedure NegReal(var R : BCD);
  begin
    if R[1] <> 0 then
      R[1] := R[1] xor $80;
  end;

  procedure AbsReal(var R : BCD);
  begin
    R[1] := R[1] and $7F;
  end;

  procedure PartialSums(const Tab : array of BCD; Start, Count : Integer);
    {-x := (((t2+c0)*t5+c1)*t5+c2)*t5...; constants taken from Tab[Start-1]
      downward; T5 holds the repeated multiplier}
  var
    K : Integer;
  begin
    for K := 1 to Count do begin
      T1 := Tab[Start - K];
      AddPrim;
      T1 := T5;
      MultPrim;
    end;
  end;

  procedure ActualIntBCD;
    {-Integer part of T2, in T2}
  var
    U : Dig;
    E, I, N : Integer;
  begin
    E := T2[1] and $7F;
    if (E = 0) or (E >= $51) then
      Exit;
    if E < $40 then begin
      T2[1] := 0;
      Exit;
    end;
    Unpack(T2, U);
    N := $51 - E;
    for I := 1 to N do
      U[I] := 0;
    PackMant(U, T2);
  end;

  procedure LongintToBCD(L : LongInt; var B : BCD);
    {-Convert a Longint to a BCD}
  var
    U : Dig;
    M : Int64;
    N, E, I : Integer;
  begin
    FillChar(U, SizeOf(U), 0);
    FillChar(T2, SizeOf(T2), 0);
    if L <> 0 then begin
      if L < 0 then begin
        E := $CA;
        M := -Int64(L);
      end
      else begin
        E := $4A;
        M := L;
      end;
      N := 0;
      while M > 0 do begin
        Inc(N);
        U[N] := M mod 10;
        M := M div 10;
      end;
      {N digits: the digits are stored LSD first, the MSD must be at 18}
      for I := N downto 1 do
        U[MantDigits - N + I] := U[I];
      for I := 1 to MantDigits - N do
        U[I] := 0;
      T2[1] := E - (10 - N) - 1;
      PackMant(U, T2);
    end;
    SetUsers(B);
  end;

  procedure RealToBCD(R : Real; var B : BCD);
    {-Convert a real to a BCD}
  var
    S : string;
    Digs : string[20];
    I, P, Ex, Sign : Integer;
    U : Dig;
    Neg : Boolean;
  begin
    FillChar(B, SizeOf(B), 0);
    if R = 0 then
      Exit;
    Str(R:22, S);                    {15 significant digits}
    Neg := False;
    Digs := '';
    P := 1;
    while (P <= Length(S)) and (S[P] <> 'E') and (S[P] <> 'e') do begin
      if S[P] = '-' then
        Neg := True
      else if (S[P] >= '0') and (S[P] <= '9') then
        Digs := Digs + S[P];
      Inc(P);
    end;
    if (P > Length(S)) or (Digs = '') then begin
      MathError;                     {Inf or NaN}
      Exit;
    end;
    Inc(P);
    Sign := 1;
    Ex := 0;
    if S[P] = '-' then begin
      Sign := -1;
      Inc(P);
    end
    else if S[P] = '+' then
      Inc(P);
    while P <= Length(S) do begin
      Ex := Ex * 10 + Ord(S[P]) - 48;
      Inc(P);
    end;
    Ex := Sign * Ex + $40;
    if Ex <= 0 then
      Exit
    else if Ex >= $80 then begin
      MathError;
      Exit;
    end;
    FillChar(U, SizeOf(U), 0);
    for I := 1 to Length(Digs) do
      U[MantDigits + 1 - I] := Ord(Digs[I]) - 48;
    if Neg then
      Ex := Ex or $80;
    B[1] := Ex;
    PackMant(U, B);
  end;

  function BCDtoReal(B : BCD) : Real;
    {-Convert a BCD to a real}
  var
    U : Dig;
    S, T : string;
    I, Ex : Integer;
    R : Real;
    Code : Word;
  begin
    Unpack(B, U);
    S := '';
    if (B[1] and $80) <> 0 then
      S := '-';
    S := S + '0.';
    for I := MantDigits downto 1 do
      S := S + Chr(48 + U[I]);
    Ex := Integer(B[1] and $7F) - $3F;
    if Ex < 0 then
      S := S + 'E-'
    else
      S := S + 'E+';
    Str(Abs(Ex), T);
    S := S + T;
    Val(S, R, Code);
    BCDtoReal := R;
  end;

  function StrBCD(B : BCD; Width, Places : Byte) : string;
    {-Return a BCD as a string}
  var
    U : Dig;
    Buf : array[0..1023] of Char;
    Res : string;
    ExpB, Ex, DX, AX, CX, DI, BX, SIx, Tgt, Digits, I : Integer;
    Neg : Boolean;

    procedure Put(Ch : Char);
    begin
      Buf[DI] := Ch;
      Inc(DI);
    end;

  begin
    Unpack(B, U);
    ExpB := B[1];
    U[0] := 0;
    Neg := (ExpB and $80) <> 0;
    if ExpB = 0 then
      FillChar(U, SizeOf(U), 0);
    Ex := (ExpB and $7F) - $40;
    DX := 1;
    if Ex > 0 then
      Inc(DX, Ex);
    CX := Places;
    Inc(DX, CX);
    AX := DX;
    if CX <> 0 then
      Inc(DX);
    if Ex < 0 then begin
      AX := Ex + DX - 1;
      if AX < 0 then
        AX := 0;
    end;
    CX := AX;
    if CX >= MantDigits then
      CX := MantDigits
    else begin
      RoundDig(U, MantDigits - CX);
      if U[19] <> 0 then begin
        Inc(Ex);
        if Ex > 0 then
          Inc(DX)
        else if CX = 0 then
          CX := 1;
      end;
    end;
    Digits := CX;

    DI := 1;
    if Neg then
      Inc(DX);
    AX := Width;
    CX := AX - DX;
    if CX > 0 then begin
      for I := 1 to CX do
        Put(' ');
    end
    else
      AX := DX;
    if Neg then
      Put('-');
    if AX > 255 then
      AX := 255;
    Buf[0] := Chr(AX);
    Tgt := AX;                       {index of the last character}
    if Places <> 0 then
      BX := Tgt - Places             {index of the decimal point}
    else
      BX := 0;
    if Ex < 0 then begin
      CX := -Ex;
      Put('0');
      Dec(CX);
      if CX <> 0 then begin
        Put('.');
        for I := 1 to CX do
          Put('0');
      end;
    end;
    if Digits <> 0 then begin
      SIx := MantDigits;
      if U[19] <> 0 then
        SIx := 19;
      for I := 1 to Digits do begin
        if DI = BX then
          Put('.');
        Put(Chr(48 + U[SIx]));
        Dec(SIx);
      end;
    end;
    CX := Tgt + 1 - DI;
    if CX > 0 then
      for I := 1 to CX do begin
        if DI = BX then
          Put('.');
        Put('0');
      end;
    SetLength(Res, AX);
    Move(Buf[1], Res[1], AX);
    StrBCD := Res;
  end;

  function StrExpBCD(B : BCD; Width : Byte) : string;
    {-Return B as a string in exponential format}
  var
    U : Dig;
    Buf : array[0..511] of Char;
    Res : string;
    BL, DH, DX, CX, DI, SIx, I, Ex : Integer;
    Neg : Boolean;

    procedure Put(Ch : Char);
    begin
      Buf[DI] := Ch;
      Inc(DI);
    end;

  begin
    Unpack(B, U);
    DH := 24;
    if Width <> 0 then begin
      DH := 8;
      if Width > 8 then
        DH := Width;
    end;
    BL := B[1];
    Neg := (BL and $80) <> 0;
    if BL = 0 then begin
      FillChar(U, SizeOf(U), 0);
      BL := $40;
    end;
    DI := 1;
    Buf[0] := Chr(DH);
    if DH > 24 then begin
      for I := 1 to DH - 24 do
        Put(' ');
      DH := 24;
    end;
    if Neg then
      Put('-')
    else
      Put(' ');
    SIx := MantDigits;
    CX := 17;
    if DH < 24 then begin
      DX := 24 - DH;                 {number of digits to drop}
      Dec(CX, DX);
      if RoundDig(U, DX) or (U[19] <> 0) then begin
        Inc(SIx);                    {MSD is in the overflow position}
        BL := (BL + 1) and $FF;
      end;
    end;
    Put(Chr(48 + U[SIx]));
    Dec(SIx);
    Put('.');
    for I := 1 to CX do begin
      Put(Chr(48 + U[SIx]));
      Dec(SIx);
    end;
    Put('E');
    Ex := (BL and $7F) - $40;
    if Ex < 0 then begin
      Put('-');
      Ex := -Ex;
    end
    else
      Put('+');
    Put(Chr(48 + Ex div 10));
    Put(Chr(48 + Ex mod 10));
    SetLength(Res, Ord(Buf[0]));
    Move(Buf[1], Res[1], Ord(Buf[0]));
    StrExpBCD := Res;
  end;

  procedure ValBCD(S : string; var B : BCD; var Code : Word);
    {-Convert a string to a BCD}
  var
    A : array[0..130] of Char;
    U : Dig;
    N, Len, BX, DI, CX, DX, D : Integer;
    SignMask, ExpSigned : Boolean;
    Err : Boolean;

    function IsDigit(Ch : Char) : Boolean;
    begin
      IsDigit := (Ch >= '0') and (Ch <= '9');
    end;

    procedure AddDigit(Ch : Char);
    begin
      D := Ord(Ch) and $0F;
      if DI - D = MantDigits then
        Exit;                        {leading zero}
      if DI <= 0 then
        Exit;                        {mantissa is full}
      U[DI] := D;
      Dec(DI);
    end;

    function ValPrimitive : Boolean;
      {-Returns True on error}
    var
      Any : Boolean;
      I : Integer;
    begin
      ValPrimitive := True;
      DI := MantDigits;
      DX := 0;
      CX := 0;
      SignMask := False;
      ExpSigned := False;
      if A[BX] = '+' then
        Inc(BX)
      else if A[BX] = '-' then begin
        SignMask := True;
        Inc(BX);
      end;
      if not IsDigit(A[BX]) then
        Exit;
      while A[BX] = '0' do
        Inc(BX);
      while IsDigit(A[BX]) do begin
        AddDigit(A[BX]);
        Inc(BX);
        Inc(CX);
      end;
      if A[BX] = '.' then begin
        Inc(BX);
        if CX = 0 then begin
          Inc(CX);
          repeat
            Dec(CX);
            if A[BX] <> '0' then
              Break;
            Inc(BX);
          until False;
        end;
        while IsDigit(A[BX]) do begin
          AddDigit(A[BX]);
          Inc(BX);
        end;
      end;
      if (A[BX] = 'e') or (A[BX] = 'E') then begin
        Inc(BX);
        if A[BX] = '+' then
          Inc(BX)
        else if A[BX] = '-' then begin
          ExpSigned := True;
          Inc(BX);
        end;
        if not IsDigit(A[BX]) then
          Exit;
        while IsDigit(A[BX]) do begin
          DX := (DX * 10 + (Ord(A[BX]) and $0F)) and $FFFF;
          Inc(BX);
        end;
      end;
      if ExpSigned then
        DX := (-DX) and $FFFF;
      DX := (DX + CX + $3F) and $FFFF;
      if DX > $7F then
        Exit;
      Any := False;
      for I := 1 to MantDigits do
        if U[I] <> 0 then
          Any := True;
      if Any and (DX <> 0) then begin
        U[0] := DX;
        if SignMask then
          U[0] := U[0] or $80;
      end;
      ValPrimitive := False;
    end;

  begin
    FillChar(U, SizeOf(U), 0);
    FillChar(A, SizeOf(A), 0);
    Len := Length(S);
    N := 0;
    if Len > 0 then begin
      if Len > 126 then
        Len := 126;
      if S[1] = '.' then begin
        A[0] := '0';
        N := 1;
      end;
      Move(S[1], A[N], Len);
      Inc(N, Len);
    end;
    A[N] := #0;
    BX := 0;
    while A[BX] = ' ' do
      Inc(BX);
    Code := 0;
    if A[BX] = #0 then
      Err := True
    else
      Err := ValPrimitive;
    if not Err then
      Err := A[BX] <> #0;
    if Err then
      Code := BX + 1;
    for N := 1 to 9 do
      B[N+1] := U[2*N-1] or (U[2*N] shl 4);
    if U[0] = 0 then
      FillChar(B, SizeOf(B), 0)
    else
      B[1] := U[0];
  end;

  procedure AbsBCD(B1 : BCD; var B2 : BCD);
    {-Returns absolute value of B1 in B2}
  begin
    B2 := B1;
    B2[1] := B2[1] and $7F;
  end;

  procedure IntBCD(B1 : BCD; var B2 : BCD);
    {-Returns the integer part of B1 in B2}
  begin
    T2 := B1;
    ActualIntBCD;
    SetUsers(B2);
  end;

  procedure FracBCD(B1 : BCD; var B2 : BCD);
    {-Returns the fractional part of B1 in B2}
  begin
    T2 := B1;
    T1 := T2;
    ActualIntBCD;
    NegReal(T2);
    AddPrim;
    SetUsers(B2);
  end;

  function TruncPrimitive(const B : BCD; var LastDigit : Integer) : LongInt;
    {-Truncate toward zero; LastDigit is the first digit dropped}
  var
    U : Dig;
    E, N, K, Idx : Integer;
    V : Int64;
  begin
    TruncPrimitive := 0;
    LastDigit := 0;
    E := B[1] and $7F;
    if E = 0 then
      Exit;
    N := E - $3F;
    if N < 0 then
      Exit;
    Unpack(B, U);
    V := 0;
    Idx := MantDigits;
    for K := 1 to N do begin
      if V > 214748365 then begin
        MathError;
        Exit;
      end;
      V := V * 10;
      if Idx >= 1 then
        V := V + U[Idx];
      Dec(Idx);
      if V >= 2147483648 then begin
        MathError;
        Exit;
      end;
    end;
    if Idx >= 1 then
      LastDigit := U[Idx];
    if (B[1] and $80) <> 0 then
      V := -V;
    TruncPrimitive := LongInt(V);
  end;

  function RoundBCD(B1 : BCD) : LongInt;
    {-Returns the value of B1 rounded to the nearest long integer}
  var
    L : LongInt;
    D : Integer;
    V : Int64;
  begin
    L := TruncPrimitive(B1, D);
    V := L;
    if D >= 5 then begin
      if (B1[1] and $80) <> 0 then
        Dec(V)
      else
        Inc(V);
    end;
    RoundBCD := LongInt(V and $FFFFFFFF);
  end;

  function TruncBCD(B1 : BCD) : LongInt;
    {-Returns the long integer part of B1 (truncated toward zero)}
  var
    D : Integer;
  begin
    TruncBCD := TruncPrimitive(B1, D);
  end;

  procedure AddBCD(B1, B2 : BCD; var B3 : BCD);
    {-Add B1 to B2 and put result in B3}
  begin
    T1 := B1;
    T2 := B2;
    if AddPrim then
      MathError;
    SetUsers(B3);
  end;

  procedure SubBCD(B1, B2 : BCD; var B3 : BCD);
    {-Subtract B2 from B1 and put result in B3}
  begin
    T1 := B1;
    T2 := B2;
    NegReal(T2);
    if AddPrim then
      MathError;
    SetUsers(B3);
  end;

  procedure MultBCD(B1, B2 : BCD; var B3 : BCD);
    {-Multiply B1 by B2 and put result in B3}
  begin
    T1 := B1;
    T2 := B2;
    MultPrim;
    SetUsers(B3);
  end;

  procedure DivBCD(B1, B2 : BCD; var B3 : BCD);
    {-Divide B1 by B2 and put result in B3}
  begin
    T1 := B2;
    T2 := B1;
    DivPrim;
    SetUsers(B3);
  end;

  function EqualBCD(B1, B2 : BCD) : Boolean;
    {-Returns true if B1 = B2}
  begin
    EqualBCD := CompReals(B1, B2) = 0;
  end;

  function NotEqualBCD(B1, B2 : BCD) : Boolean;
    {-Returns true if B1 <> B2}
  begin
    NotEqualBCD := CompReals(B1, B2) <> 0;
  end;

  function GreaterBCD(B1, B2 : BCD) : Boolean;
    {-Returns true if B1 > B2}
  begin
    GreaterBCD := CompReals(B1, B2) > 0;
  end;

  function GreaterEqualBCD(B1, B2 : BCD) : Boolean;
    {-Returns true if B1 >= B2}
  begin
    GreaterEqualBCD := CompReals(B1, B2) >= 0;
  end;

  function LessBCD(B1, B2 : BCD) : Boolean;
    {-Returns true if B1 < B2}
  begin
    LessBCD := CompReals(B1, B2) < 0;
  end;

  function LessEqualBCD(B1, B2 : BCD) : Boolean;
    {-Returns true if B1 <= B2}
  begin
    LessEqualBCD := CompReals(B1, B2) <= 0;
  end;

  {** transcendental functions **}

  procedure SqrBCD(B1 : BCD; var B2 : BCD);
    {-Returns the square of B1 in B2}
  begin
    T2 := B1;
    T1 := T2;
    MultPrim;
    SetUsers(B2);
  end;

  procedure ExpBCD(B1 : BCD; var B2 : BCD);
    {-Returns the exponential of B1 in B2. Valid range is -145.06 to 147.36;
      smaller values return 0, larger ones cause an overflow error.}
  var
    N : LongInt;
    N16 : Integer;
    QTab : array[0..2] of BCD;
  begin
    T2 := B1;
    if CompReals(T2, c_MaxX) > 0 then begin
      MathError;
      Exit;
    end;
    if CompReals(T2, c_MinX) < 0 then
      T2[1] := 0
    else begin
      QTab[0] := c_q0;
      QTab[1] := c_q1;
      QTab[2] := c_q2;
      T1 := c_a1;
      MultPrim;
      N := RoundBCD(T2);
      N16 := SmallInt(N and $FFFF);
      LongintToBCD(N, T4);
      T2 := T4;
      T1 := c_c1;
      MultPrim;
      NegReal(T2);
      T1 := T2;
      T2 := B1;
      AddPrim;
      T5 := T2;
      T2 := T4;
      T1 := c_c2;
      MultPrim;
      NegReal(T2);
      T1 := T5;
      AddPrim;
      T4 := T2;
      T1 := T2;
      MultPrim;
      T5 := T2;

      T1 := c_p2;
      MultPrim;
      T1 := c_p1;
      AddPrim;
      T1 := T5;
      MultPrim;
      T1 := c_p0;
      AddPrim;
      T1 := T4;
      MultPrim;
      T4 := T2;
      T2 := T5;

      PartialSums(QTab, 3, 2);

      T1 := c_q0;
      AddPrim;
      T1 := T4;
      NegReal(T1);
      AddPrim;
      T1 := T2;
      T2 := T4;
      DivPrim;
      T1 := c_a3;
      AddPrim;
      T1 := c_a4;
      MultPrim;

      if (N16 and 1) <> 0 then begin
        T1 := c_a2;
        if (N16 and $80) <> 0 then
          DivPrim
        else
          MultPrim;
      end;
      T2[1] := (T2[1] + (N16 div 2)) and $FF;
    end;
    SetUsers(B2);
  end;

  procedure LnBCD(B1 : BCD; var B2 : BCD);
    {-Returns the natural log of B1 in B2}
  var
    N : Integer;
    DTab, ETab : array[0..4] of BCD;
  begin
    T2 := B1;
    if (T2[1] = 0) or ((T2[1] and $80) <> 0) then begin
      MathError;                     {zero or negative argument}
      Exit;
    end;
    DTab[0] := c_d0; DTab[1] := c_d1; DTab[2] := c_d2; DTab[3] := c_d3; DTab[4] := c_d4;
    ETab[0] := c_e0; ETab[1] := c_e1; ETab[2] := c_e2; ETab[3] := c_e3; ETab[4] := c_e4;
    N := Integer(T2[1]) - $3F;
    T2[1] := $3F;
    if CompReals(T2, c_f0) < 0 then begin
      Dec(N);
      Inc(T2[1]);
    end;
    T4 := T2;
    T1 := c_f3;
    AddPrim;
    T5 := T2;

    T1 := c_a3;
    NegReal(T1);
    T2 := T4;
    AddPrim;
    T1 := c_a3;
    NegReal(T1);
    AddPrim;

    T1 := T5;
    DivPrim;

    T4 := T2;
    T1 := T2;
    MultPrim;
    T5 := T2;

    T1 := c_e4;
    MultPrim;
    PartialSums(ETab, 4, 3);
    T1 := c_e0;
    AddPrim;
    T6 := T2;

    T2 := T5;
    PartialSums(DTab, 5, 4);
    T1 := c_d0;
    AddPrim;
    T1 := T2;

    T2 := T6;
    DivPrim;
    T1 := T5;
    MultPrim;

    T1 := c_f1;
    AddPrim;
    T1 := T4;
    MultPrim;
    T4 := T2;

    LongintToBCD(N, T2);
    T1 := T4;
    AddPrim;
    T1 := c_f2;
    MultPrim;
    SetUsers(B2);
  end;

  procedure SqrtBCD(B1 : BCD; var B2 : BCD);
    {-Returns the square root of B1 in B2}
  var
    N, I : Integer;
  begin
    T2 := B1;
    if T2[1] <> 0 then begin
      if (T2[1] and $80) <> 0 then begin
        MathError;                   {negative argument}
        Exit;
      end;
      N := Integer(T2[1]) - $3F;
      T2[1] := $3F;
      T4 := T2;
      T1 := c_s1;
      MultPrim;
      T1 := c_s0;
      AddPrim;
      for I := 1 to 3 do begin
        T5 := T2;
        T1 := T5;
        T2 := T4;
        DivPrim;
        T1 := T5;
        AddPrim;
        T1 := c_a3;
        MultPrim;
      end;
      T5 := T2;
      T1 := T5;
      T2 := T4;
      DivPrim;
      T1 := T5;
      NegReal(T1);
      AddPrim;
      T1 := c_a3;
      MultPrim;
      T1 := T5;
      AddPrim;
      if Odd(N) then begin
        T1 := c_s2;
        MultPrim;
        Inc(N);
      end;
      T2[1] := (T2[1] + ((N and $FFFF) shr 1)) and $FF;
    end;
    SetUsers(B2);
  end;

var
  CosWanted, NegateFlag : Boolean;

  procedure SinCosPrimitive;
    {-Sine or cosine of T2 into T2; flags CosWanted and NegateFlag}
  var
    RTab : array[0..8] of BCD;
  begin
    AbsReal(T2);
    if CompReals(T2, c_MaxY) > 0 then begin
      MathError;
      Exit;
    end;
    RTab[0] := c_r1; RTab[1] := c_r1; RTab[2] := c_r2; RTab[3] := c_r3;
    RTab[4] := c_r4; RTab[5] := c_r5; RTab[6] := c_r6; RTab[7] := c_r7;
    RTab[8] := c_r8;
    T4 := T2;
    T1 := c_onepi;
    MultPrim;
    T1 := c_a3;
    AddPrim;
    if CosWanted then begin
      T1 := c_a3;
      AddPrim;
    end;
    ActualIntBCD;
    T5 := T2;
    T1 := c_a3;
    MultPrim;
    T1 := T2;
    ActualIntBCD;
    NegReal(T2);
    AddPrim;

    if CompReals(T2, c_eps) > 0 then
      NegateFlag := not NegateFlag;

    if CosWanted then begin
      T2 := T5;
      T1 := c_a3;
      NegReal(T1);
      AddPrim;
      T5 := T2;
    end;

    T2 := T5;
    T1 := c_b1;
    MultPrim;
    NegReal(T2);
    T1 := T4;
    AddPrim;
    T4 := T2;
    T2 := T5;
    T1 := c_b2;
    MultPrim;
    NegReal(T2);
    T1 := T4;
    AddPrim;
    T4 := T2;
    AbsReal(T2);
    if not (CompReals(T2, c_eps) < 0) then begin
      T1 := T2;
      MultPrim;
      T5 := T2;
      T1 := c_r8;
      MultPrim;
      PartialSums(RTab, 8, 7);
      T1 := c_f3;
      AddPrim;
      T1 := T4;
      MultPrim;
    end;
    if NegateFlag then
      NegReal(T2);
  end;

  procedure CosBCD(B1 : BCD; var B2 : BCD);
    {-Returns cosine of B1 in B2}
  begin
    T2 := B1;
    CosWanted := True;
    NegateFlag := False;
    SinCosPrimitive;
    SetUsers(B2);
  end;

  procedure SinBCD(B1 : BCD; var B2 : BCD);
    {-Returns sine of B1 in B2}
  begin
    T2 := B1;
    CosWanted := False;
    NegateFlag := T2[1] >= $80;
    SinCosPrimitive;
    SetUsers(B2);
  end;

  procedure ArcTanBCD(B1 : BCD; var B2 : BCD);
    {-Returns arc tangent of B1 in B2}
  var
    Sgn : Byte;
    P : BCD;
    GTab, HTab : array[0..7] of BCD;
  begin
    T2 := B1;
    if T2[1] <> 0 then begin
      GTab[0] := c_g0; GTab[1] := c_g1; GTab[2] := c_g2; GTab[3] := c_g3;
      GTab[4] := c_g4; GTab[5] := c_g5; GTab[6] := c_g6; GTab[7] := c_g7;
      HTab[0] := c_h0; HTab[1] := c_h1; HTab[2] := c_h2; HTab[3] := c_h3;
      HTab[4] := c_h4; HTab[5] := c_h5; HTab[6] := c_h6; HTab[7] := c_h7;
      Sgn := T2[1];
      AbsReal(T2);
      T4 := T2;
      T6[1] := 0;
      if CompReals(T2, c_f3) > 0 then begin
        T6 := c_pi4;
        T2 := T4;
        T1 := c_f3;
        AddPrim;
        T5 := T2;
        T2 := T4;
        T1 := c_f3;
        NegReal(T1);
        AddPrim;
        T1 := T5;
        DivPrim;
        T4 := T2;
      end;
      T1 := T4;
      MultPrim;
      T5 := T2;

      T1 := c_g7;
      MultPrim;
      PartialSums(GTab, 7, 6);
      T1 := c_g0;
      AddPrim;
      P := T2;

      T2 := T5;
      T1 := c_h7;
      MultPrim;
      PartialSums(HTab, 7, 6);
      T1 := c_h0;
      AddPrim;

      T1 := T2;
      T2 := P;
      DivPrim;
      T1 := T4;
      MultPrim;
      T1 := T6;
      AddPrim;

      if Sgn >= $80 then
        NegReal(T2);
    end;
    SetUsers(B2);
  end;

  function Form(Mask : string; B : BCD) : string;
    {-Returns a formatted string with digits from B merged into the Mask}
  type
    FillType = (Blank, Asterisk, Zero);
  const
    FormChars : string[8] = '#@*$-+,.';
    PlusArray : array[Boolean] of Char = ('+', '-');
    MinusArray : array[Boolean] of Char = (' ', '-');
    FillArray : array[FillType] of Char = (' ', '*', '0');
  var
    ExpB : Byte absolute B;  {B's sign/exponent byte}
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
    Blanks,                  {# of blanks returned by StrBcd}
    FirstDigit,              {pos. of first digit returned by Str}
    Extras,                  {# of extra digits needed for special cases}
    DigitPtr : Byte;         {pointer into temporary string of digits}
    I : Word;
  label
    EndFound,
    RedoCase,
    Done;
  begin
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
    Negative := (ExpB and $80) <> 0;
    ExpB := ExpB and $7F;

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
    S := StrBCD(B, Digits, Places);

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
    Form := Mask;
  end;

{$IFDEF InitAllUnits}
begin
{$ENDIF}
end.
