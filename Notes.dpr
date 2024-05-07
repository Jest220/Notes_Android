program Notes;

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {main},
  uNote in 'uNote.pas' {note};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tmain, main);
  Application.CreateForm(Tnote, note);
  Application.Run;
end.
