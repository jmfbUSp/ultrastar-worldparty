{*
    UltraStar WorldParty - Karaoke Game

	UltraStar WorldParty is the legal property of its developers,
	whose names	are too numerous to list here. Please refer to the
	COPYRIGHT file distributed with this source distribution.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. Check "LICENSE" file. If not, see
	<http://www.gnu.org/licenses/>.
 *}


unit UScreenOptionsWebcam;

interface

{$MODE OBJFPC}

{$I switches.inc}

uses
  sdl2,
  UMenu,
  UDisplay,
  UMusic,
  UFiles,
  UIni,
  UThemes;

type
  TScreenOptionsWebcam = class(TMenu)
    private
      PreVisualization: boolean;

      ID: integer;
      Resolution: integer;
      FPS: integer;
      Flip: integer;
      Brightness: integer;
      Saturation: integer;
      Hue: integer;
      Effect: integer;
    public
      constructor Create; override;
      function ParseInput(PressedKey: cardinal; CharCode: UCS4Char; PressedDown: boolean): boolean; override;
      procedure OnShow; override;
      function Draw: boolean; override;
      procedure DrawWebCamFrame;
      procedure ChangeElementAlpha;
  end;

implementation

uses
  dglOpenGL,
  UGraphic,
  ULanguage,
  UUnicodeUtils,
  UWebcam,
  SysUtils;

function TScreenOptionsWebcam.ParseInput(PressedKey: cardinal; CharCode: UCS4Char; PressedDown: boolean): boolean;
begin
  Result := true;
  if (PressedDown) then
  begin // Key Down
    // check special keys
    case PressedKey of
      SDLK_ESCAPE,
      SDLK_BACKSPACE :
        begin
          if (PreVisualization) then Webcam.Release;
          //Ini.Save;
          AudioPlayback.PlaySound(SoundLib.Back);
          FadeTo(@ScreenOptions);
          Ini.SaveWebcamSettings;
        end;
      SDLK_RETURN:
        begin
          if SelInteraction = 8 then
          begin
            PreVisualization := not PreVisualization;

            if (PreVisualization) then
            begin
              Ini.SaveWebcamSettings;
              Webcam.Restart;

              if (Webcam.Capture = nil) then
              begin
                PreVisualization := false;
                ScreenPopupError.ShowPopup(Language.Translate('SING_OPTIONS_WEBCAM_NO_WEBCAM'))
              end
            end
            else
            begin
               Webcam.Release;
               PreVisualization := false;
            end;

            ChangeElementAlpha;

            if (PreVisualization) then
              Button[0].Text[0].Text := Language.Translate('SING_OPTIONS_WEBCAM_DISABLE_PREVIEW')
            else
              Button[0].Text[0].Text := Language.Translate('SING_OPTIONS_WEBCAM_ENABLE_PREVIEW');
          end;

          if SelInteraction = 9 then
          begin
            AudioPlayback.PlaySound(SoundLib.Back);
            FadeTo(@ScreenOptions);
            Ini.SaveWebcamSettings;
            if (PreVisualization) then Webcam.Release;
          end;
        end;
      SDLK_DOWN:
        InteractNext;
      SDLK_UP :
        InteractPrev;
      SDLK_RIGHT:
        begin
          if (SelInteraction >= 0) and (SelInteraction <= 7) then
          begin
            AudioPlayback.PlaySound(SoundLib.Option);
            InteractInc;
          end;

          if (PreVisualization) then
            Ini.SaveWebcamSettings;

          // refresh webcam config
          if (SelInteraction = 0) or (SelInteraction = 1) and (PreVisualization) then
            Webcam.Restart;

      end;
      SDLK_LEFT:
        begin
          if (SelInteraction >= 0) and (SelInteraction <= 7) then
          begin
            AudioPlayback.PlaySound(SoundLib.Option);
            InteractDec;
          end;

          if (PreVisualization) then
            Ini.SaveWebcamSettings;

          // refresh webcam config
          if (SelInteraction = 0) or (SelInteraction = 1) and (PreVisualization) then
            Webcam.Restart;
        end;
    end;
  end;
end;

constructor TScreenOptionsWebcam.Create;
var
  WebcamsIDs: array[0..2] of UTF8String;
  IWebcamEffectTranslated: array [0..10] of UTF8String = ('NORMAL', 'GRAYSCALE', 'BLACK_WHITE', 'NEGATIVE', 'BINARY_IMAGE', 'DILATE', 'THRESHOLD', 'EDGES', 'GAUSSIAN_BLUR', 'EQUALIZED', 'ERODE');
begin
  inherited Create;

  LoadFromTheme(Theme.OptionsWebcam);

  WebcamsIDs[0] := Language.Translate('OPTION_VALUE_OFF');
  WebcamsIDs[1] := '0';
  WebcamsIDs[2] := '1';
  ID := AddSelectSlide(Theme.OptionsWebcam.SelectWebcam, UIni.Ini.WebCamID, WebcamsIDs);
  Resolution := AddSelectSlide(Theme.OptionsWebcam.SelectResolution, UIni.Ini.WebcamResolution, IWebcamResolution);
  FPS := AddSelectSlide(Theme.OptionsWebcam.SelectFPS, UIni.Ini.WebCamFPS, IWebcamFPS);
  Flip := AddSelectSlide(Theme.OptionsWebcam.SelectFlip, UIni.Ini.WebCamFlip, IWebcamFlip, 'OPTION_VALUE_');
  Brightness := AddSelectSlide(Theme.OptionsWebcam.SelectBrightness, UIni.Ini.WebCamBrightness, IWebcamBrightness);
  Saturation := AddSelectSlide(Theme.OptionsWebcam.SelectSaturation, UIni.Ini.WebCamSaturation, IWebcamSaturation);
  Hue := AddSelectSlide(Theme.OptionsWebcam.SelectHue, UIni.Ini.WebCamHue, IWebcamHue);
  Effect := AddSelectSlide(Theme.OptionsWebcam.SelectEffect, UIni.Ini.WebCamEffect, IWebcamEffectTranslated, 'SING_OPTIONS_WEBCAM_EFFECT_');

  AddButton(Theme.OptionsWebcam.ButtonPreVisualization);

  AddButton(Theme.OptionsWebcam.ButtonExit);

  Interaction := 0;

  // new tests
  Ini.WebCamSaturation := 100;
  Ini.WebCamHue := 180;
  Ini.WebCamEffect := 0;
  {
  SelectsS[Saturation].Visible := false;
  SelectsS[Hue].Visible := false;
  SelectsS[Effect].Visible := false;
  }
end;

procedure TScreenOptionsWebcam.OnShow;
begin
  inherited;

  PreVisualization := false;

  ChangeElementAlpha;

  Button[0].Text[0].Text := Language.Translate('SING_OPTIONS_WEBCAM_ENABLE_PREVIEW');

  Interaction := 0;
end;

function TScreenOptionsWebcam.Draw: boolean;
var
  I: integer;
  Alpha: real;
begin

  if (PreVisualization) and (SelectsS[ID].SelectOptInt > 0) then
  begin
    try

     DrawWebCamFrame;
    except
      ;
    end;


    if (PreVisualization) then
      Alpha := 0.5
    else
      Alpha := 1;

    for I := 0 to High(SelectsS) do
    begin
      SelectsS[I].Tex_SelectS_ArrowL.Alpha := Alpha;
      SelectsS[I].Tex_SelectS_ArrowR.Alpha := Alpha;
    end;

  end
  else
    DrawBG;

  Result := DrawFG;
end;

procedure TScreenOptionsWebcam.ChangeElementAlpha;
var
  I, J: integer;
  Alpha: real;
begin

  if (PreVisualization) then
    Alpha := 0.5
  else
    Alpha := 1;

  for I := 0 to High(Text) do
    Text[I].Alpha := Alpha;

  for I := 0 to High(Statics) do
    Statics[I].Texture.Alpha := Alpha;

  for I := 0 to High(Button) do
  begin
    Button[I].Texture.Alpha := Alpha;

    for J := 0 to High(Button[I].Text) do
      Button[I].Text[J].Alpha := Alpha;
  end;

  for I := 0 to High(SelectsS) do
  begin
    SelectsS[I].Texture.Alpha := Alpha;
    SelectsS[I].TextureSBG.Alpha := Alpha;

    SelectsS[I].Tex_SelectS_ArrowL.Alpha := Alpha;
    SelectsS[I].Tex_SelectS_ArrowR.Alpha := Alpha;

    SelectsS[I].Text.Alpha := Alpha;

    for J := 0 to High(SelectsS[I].TextOpt) do
      SelectsS[I].TextOpt[J].Alpha := Alpha;

  end;


end;

procedure TScreenOptionsWebcam.DrawWebCamFrame;
begin

  Webcam.GetWebcamFrame;

  if (Webcam.TextureCam.TexNum > 0) then
  begin
    glColor4f(1, 1, 1, 1);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    glEnable(GL_TEXTURE_2D);

    glBindTexture(GL_TEXTURE_2D, Webcam.TextureCam.TexNum);
    glEnable(GL_BLEND);
    glBegin(GL_QUADS);

      glTexCoord2f(0, 0);
      glVertex2f(800,  0);
      glTexCoord2f(0, Webcam.TextureCam.TexH);
      glVertex2f(800,  600);
      glTexCoord2f( Webcam.TextureCam.TexW, Webcam.TextureCam.TexH);
      glVertex2f(0, 600);
      glTexCoord2f( Webcam.TextureCam.TexW, 0);
      glVertex2f(0, 0);

    glEnd;
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);

    // reset to default
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

  end;

end;

end.
