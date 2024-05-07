unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.IOUtils,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait,
  Data.DB, FireDAC.Comp.Client, FMX.ListBox, FMX.Layouts, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.UI, FMX.Edit, FMX.SearchBox;

type
  Tmain = class(TForm)
    ToolBar1: TToolBar;
    ButtonAdd: TButton;
    FDConnection1: TFDConnection;
    ListBox1: TListBox;
    FDQueryDelete: TFDQuery;
    FDQueryLoad: TFDQuery;
    Label1: TLabel;
    FDQueryAdd: TFDQuery;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    FDQueryUpdate: TFDQuery;
    ListBoxItem1: TListBoxItem;
    ListBoxItem2: TListBoxItem;
    SearchBox1: TSearchBox;
    FDCommandAdd: TFDCommand;
    procedure LoadBase;
    procedure FormActivate(Sender: TObject);
    procedure FDConnection1BeforeConnect(Sender: TObject);
    procedure FDConnection1AfterConnect(Sender: TObject);
    procedure ButtonAddClick(Sender: TObject);
    procedure ListBox1ItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure DeleteItem(date : string);
    function Format(date : string) : string;
    function DeFormat(date : string) : string;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  main: Tmain;

implementation

{$R *.fmx}
{$R *.iPhone55in.fmx IOS}
{$R *.LgXhdpiTb.fmx ANDROID}

uses uNote;



procedure Tmain.ButtonAddClick(Sender: TObject);
begin
  {в форме заметки сделать заголовок и контент пустыми,
  разрешить их редактирование, а также сделать только
  кнопку сохранения активной}
  with note do begin
    Save.Visible := True;
    Edit.Visible := False;
    Delete.Visible := False;
    Memo1.ReadOnly := False;
    Edit1.ReadOnly := False;
    Memo1.Text := '';
    Edit1.Text := '';
    Label2.Text := 'Дата изменения: ';
  end;
  //скрыть главное меню и показать окно с редактированием новой заметки
  note.Show;
  main.Hide;
end;

procedure Tmain.FDConnection1AfterConnect(Sender: TObject);
var s1 : string;
begin
  {создание новой таблицы в базе данных SQLite, если она не существует,
  со столбцами 'Title' - заголовок, 'Content' - содержание заметки,
  'date' - дата создания/редактирования заметки. 'Title' и 'date' не
  могут не иметь данных.}
  s1 := 'CREATE TABLE IF NOT EXISTS "Notes" ("Title"	TEXT NOT NULL,"Content"	TEXT,"date"	TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);';
  FDConnection1.ExecSQL(s1);
end;

procedure Tmain.FDConnection1BeforeConnect(Sender: TObject);
begin
  //подключение к базе данных SQLite/создание базы данных, если она не существует
  FDConnection1.Params.Values['Database'] :=
      TPath.Combine(TPath.GetDocumentsPath, 'NotesDB.db3');
end;

procedure Tmain.FormActivate(Sender: TObject);
begin
  //достать заметки из таблицы базы данных и отобразить их на главной форме
  LoadBase;
end;

procedure Tmain.ListBox1ItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
var
  ListItem : TListBoxItem;
begin
  //получение информации о заметке из базы данных
  ListItem := ListBox1.Selected;
  FDConnection1.Open();
  FDQueryLoad.SQL.Clear;
  FDQueryLoad.SQl.Text := 'SELECT * FROM Notes WHERE date LIKE :date';
  FDQueryLoad.ParamByName('date').AsString := DeFormat(ListItem.ItemData.Detail) + '%';
  FDQueryLoad.Open;
  {в форме заметки заголовок, содержание и дату достать из таблицы базы данных,
  запретить редактировать заголовок и содержание. сделать активными только
  кнопки редактирования и удаления}
  with note do begin
    Save.Visible := False;
    Edit.Visible := True;
    Delete.Visible := True;
    Memo1.ReadOnly := True;
    Edit1.ReadOnly := True;
    Memo1.Text := FDQueryLoad.FieldByName('Content').AsString;
    Edit1.Text := FDQueryLoad.FieldByName('Title').AsString;
    Label2.Text := 'Дата изменения: ' + Format(FDQueryLoad.FieldByName('date').AsString);
  end;
  FDQueryLoad.Close;
  FDConnection1.Close;
  //скрыть главное меню и показать окно с сохраненной заметкой
  note.show;
  main.hide;
end;

procedure Tmain.LoadBase;
var
  ListBoxItem : TListBoxItem; //текущая заметка
  str : string; //символ переноса строки
begin
  //получение всех заметок из таблицы, отсортированных по дате
  FDConnection1.Open();
  ListBox1.Clear;
  FDQueryLoad.SQL.Clear;
  FDQueryLoad.SQl.Text := 'SELECT * FROM Notes ORDER BY date DESC';
  FDQueryLoad.Open();
  while not FDQueryLoad.Eof do begin
    //если программа запущена в ОС Windows, то str = 13 + 10 символ юникода
    if TOSVersion.Platform = pfWindows then str := chr(13)+chr(10)
    // иначе str = 10 символу юникода
    else str := chr(10);
    //заполение элемента заметки данными
    ListBoxItem := TListBoxItem.Create(nil);
    ListBoxItem.ItemData.Text := FDQueryLoad.FieldByName('Title').AsString;
    //замена символа переноса строки пробелом
    ListBoxItem.ItemData.Detail := Format(FDQueryLoad.FieldByName('date').AsString) + ' ' + stringreplace(FDQueryLoad.FieldByName('Content').AsString, str, ' ', [rfReplaceAll]);
    ListBoxItem.ItemData.Accessory := TListBoxItemData.TAccessory.aMore;
    //добавление заметки в список заметок
    ListBox1.AddObject(ListBoxItem);
    FDQueryLoad.Next;
  end;
  FDQueryLoad.Close;
  FDConnection1.Close();
end;

procedure Tmain.DeleteItem(date : string);
begin
  //удаление заметки из таблицы базы данных по дате
  FDQueryDelete.ParamByName('date').AsString := DeFormat(date) + '%';
  FDQueryDelete.ExecSQL();
end;

function Tmain.Format(date : string) : string;
begin
  //форматировать строку даты в привычный пользователю вид
  Result := Copy(date, 9, 2) + '.' + Copy(date, 6, 2) + '.' + Copy(date, 0, 4) + Copy(date, 11, 9);
end;

function Tmain.DeFormat(date : string) : string;
begin
  //форматировать строку даты в понятный для SQL вид
  Result := Copy(date, 7, 4) + '-' + Copy(date, 4, 2) + '-' + Copy(date, 0, 2) + Copy(date, 11, 9);
end;

end.
