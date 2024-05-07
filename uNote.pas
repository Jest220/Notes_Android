unit uNote;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo, FMX.Edit, FMX.Objects, FMX.Layouts;

type
  Tnote = class(TForm)
    ToolBar1: TToolBar;
    Line1: TLine;
    Memo1: TMemo;
    Edit: TButton;
    Save: TButton;
    Memo2: TMemo;
    GoBack: TButton;
    Delete: TButton;
    Label2: TLabel;
    ToolBar2: TToolBar;
    Edit1: TEdit;
    Rectangle1: TRectangle;
    procedure EditClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure GoBackClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DeleteClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  note: Tnote;

implementation

{$R *.fmx}
{$R *.iPhone55in.fmx IOS}

uses uMain;



procedure Tnote.DeleteClick(Sender: TObject);
begin
  {если нажата кнопка удаления, то удаляется заметка, скрывается
  форма и показывается главная форма}
  with main do begin
    DeleteItem(ListBox1.Selected.ItemData.Detail);
    //содержание элемента поиска равно пустой строке
    SearchBox1.Text := '';
  end;
  main.Show;
  note.Hide;
end;

procedure Tnote.EditClick(Sender: TObject);
begin
  {разрешить редактировать содержание заметки и сделать
  активной только кнопку сохранения}
  Edit.Visible := False;
  Delete.Visible := False;
  Save.Visible := True;
  Memo1.ReadOnly := False;
  Edit1.ReadOnly := False;
end;



procedure Tnote.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  {если закрывается форма(в Windows нажатием на крестик, на Android нажатие на кнопку назад),
  то скрывается форма заметки и открывается главная форма}
  //содержание элемента поиска равно пустой строке
  with main do SearchBox1.Text := '';
  main.Show;
  note.Hide;
end;



procedure Tnote.GoBackClick(Sender: TObject);
begin
  {если нажата кнопка возвращения, то скрывается форма заметки и
  открывается главная форма}
  //содержание элемента поиска равно пустой строке
  with main do SearchBox1.Text := '';
  main.Show;
  note.Hide;
end;

procedure Tnote.SaveClick(Sender: TObject);
begin
  //если заголовок не пустой
  if Edit1.Text <> '' then begin
    {сделать активной только кнопки удаления и редактирования,
    запретить редактировать содержание заметки}
    Save.Visible := False;
    Edit.Visible := True;
    Delete.Visible := True;
    Memo1.ReadOnly := True;
    Edit1.ReadOnly := True;
    with main do begin
      //если заметки нет в таблице базы данных, то создать её
      if Label2.Text = 'Дата изменения: ' then begin
        //добавление заметки в таблицу
        FDQueryAdd.ParamByName('title').AsWideString := Edit1.Text;
        FDQueryAdd.ParamByName('content').AsWideString := Memo1.Text;
        FDQueryAdd.ExecSQL();
        //добавить дату в форму
        LoadBase;
        ListBox1.ItemIndex := 0;
        Label2.Text := 'Дата изменения: ' + Copy(ListBox1.Selected.ItemData.Detail, 0, 19);
      end
      //если заметка есть в таблице базы данных, то обновить данные в таблице
      else begin
        //изменение заметки в таблице
        FDQueryUpdate.ParamByName('title').AsWideString := Edit1.Text;
        FDQueryUpdate.ParamByName('content').AsWideString := Memo1.Text;
        FDQueryUpdate.ParamByName('date').AsWideString := DeFormat(Copy(ListBox1.Selected.ItemData.Detail, 0, 19)) + '%';
        FDQueryUpdate.ExecSQL();
        //изменить дату в форме
        LoadBase;
        ListBox1.ItemIndex := 0;
        Label2.Text := 'Дата изменения: ' + Copy(ListBox1.Selected.ItemData.Detail, 0, 19);
      end;
    end;
  end
  //если заголовок пустой, то выводится сообщение об ошибке
  else showmessage('Не введен заголовок.');

end;

end.
