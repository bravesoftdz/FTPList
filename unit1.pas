unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, db, DBGrids, Dialogs, Forms,
  sqldb, sqlite3conn, StdCtrls,
  SysUtils, Windows;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    Datasource1: TDatasource;
    DBGrid1: TDBGrid;
    Edit1: TEdit;
    SQLite3Connection1: TSQLite3Connection;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure CheckBox3Change(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure Edit1KeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ShowFTP;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  ODBCServerConnect: TSQLite3Connection;
  SQLMainQuery: TSQLQuery;
  SQLTrans: TSQLTransaction;
  USr: string;
  S: TResourceStream;
  F: TFileStream;

implementation

{$R *.lfm}
{$R mydata.rc}
{ TForm1 }

procedure GetUserNameEx(NameFormat: DWORD; lpNameBuffer: LPSTR; nSize: PULONG); stdcall;
  external 'secur32.dll' Name 'GetUserNameExA';


function LoggedOnUserNameEx(fFormat: DWORD): string;
  var
    UserName: array[0..250] of ansichar;
    Size:     DWORD;
  begin
    Size := 250;
    GetUserNameEx(fFormat, @UserName, @Size);
    Result := UserName;
  end;

procedure TForm1.ShowFTP;
  begin
    USr := LoggedOnUserNameEx(3);
    SQLMainQuery.Close;
    SQLMainQuery.SQL.Clear;

    SQLMainQuery.SQL.Text := ('SELECT Retailer FROM "Data"');
    SQLMainQuery.Open;
    SQLMainQuery.First;
    ComboBox1.Clear;
    while not SQLMainQuery.EOF do
      begin
      ComboBox1.Items.Add(UTF8Encode(SQLMainQuery.Fields[0].AsString));
      SQLMainQuery.Next;
      end;
    SQLMainQuery.Close;
    SQLMainQuery.SQL.Clear;
    if CheckBox1.Checked = True then
      SQLMainQuery.SQL.Text :=
        ('SELECT Active,Retailer,RetFTP as "FTP",Last as "LastName",Modded from "Data" WHERE Last='''
        + Copy(USr, 0, Pos(',', Usr) - 1) + '''')
    else
      SQLMainQuery.SQL.Text :=
        ('SELECT Active,Retailer,RetFTP as "FTP",Last as "LastName",Modded from "Data"');
    SQLMainQuery.Open;
    if CheckBox3.Checked = False then
      DBGrid1.DataSource.DataSet.FieldByName('Modded').Visible := False;
    Edit1.Clear;
  end;


procedure TForm1.FormCreate(Sender: TObject);
  begin
    //Выгружаем библеотеку SQLite
    S := TResourceStream.Create(HInstance, 'MYDATA', RT_PLUGPLAY);
      try
      F := TFileStream.Create(ExtractFilePath(ParamStr(0)) + 'sqlite3.dll', fmCreate);
        try
        F.CopyFrom(S, S.Size);
        finally
        F.Free;
        end;
      finally
      S.Free;
      end;
    //Выгрузили библеотеку SQLite

    ODBCServerConnect := TSQLite3Connection.Create(nil);
    SQLTrans     := TSQLTransaction.Create(nil);
    SQLMainQuery := TSQLQuery.Create(nil);

    ODBCServerConnect.DatabaseName :=
      '\\EUWINKIEFSV001\RetailerServices\Meetings.sqlite';
    ODBCServerConnect.Connected := True;
    SQLTrans.DataBase     := ODBCServerConnect;
    SQLMainQuery.PacketRecords := -1;
    SQLMainQuery.DataBase := ODBCServerConnect;
    SQLMainQuery.Transaction := SQLTrans;
    //Get Users
    SQLMainQuery.SQL.Clear;
    SQLMainQuery.SQL.Text := ('SELECT Last,First FROM "Emploee"');
    SQLMainQuery.Open;
    SQLMainQuery.First;
    ComboBox2.Clear;
    while not SQLMainQuery.EOF do
      begin
      ComboBox2.Items.Add(UTF8Encode(SQLMainQuery.Fields[0].AsString) +
        ', ' + UTF8Encode(SQLMainQuery.Fields[1].AsString));
      SQLMainQuery.Next;
      end;
    SQLMainQuery.Close;
    ODBCServerConnect.Connected := False;
    ComboBox2.ItemIndex := ComboBox2.Items.IndexOf(LoggedOnUserNameEx(3));
    if (Pos('Bryk', ComboBox2.Text) > 0) or (Pos('Pogorelov', ComboBox2.Text) > 0) or
      (Pos('Drobit', ComboBox2.Text) > 0) then
      begin
      ComboBox2.Visible := True;
      CheckBox2.Visible := True;
      Button3.Visible   := True;
      end;
    //Finish Get Users

    ODBCServerConnect.DatabaseName := '\\EUWINKIEFSV001\RetailerServices\FTPList.sqlite';
    ODBCServerConnect.Connected    := True;
    SQLMainQuery.SQL.Clear;

    if DataSource1.DataSet <> SQLMainQuery then
      DataSource1.DataSet := SQLMainQuery;
    ShowFTP;
  end;

procedure TForm1.FormDestroy(Sender: TObject);
  begin
    SQLMainQuery.Free;
    ODBCServerConnect.Free;
    DeleteFile(PChar(ExtractFilePath(ParamStr(0)) + 'sqlite3.dll'));
  end;

procedure TForm1.FormResize(Sender: TObject);
  begin
    DBGrid1.Width := Form1.Width - 20;
  end;

procedure TForm1.Button1Click(Sender: TObject);
  var
    Last, First: string;
    LocRet: boolean;
    Ac: String;
  begin
    if (Trim(ComboBox1.Text) <> '') and (Trim(Edit1.Text) <> '') then
      begin
      LocRet := DBGrid1.DataSource.DataSet.Locate('Retailer',
        ComboBox1.Text, [loCaseInsensitive, loPartialKey]);
      SQLMainQuery.Close;
      SQLMainQuery.SQL.Clear;
      Last  := Copy(USr, 0, Pos(',', Usr) - 1);
      First := Copy(USr, Pos(',', Usr) + 2, Length(Usr));

      if (ComboBox3.Text <> 'True') and (ComboBox3.Text <> 'False') then
        ComboBox3.Text := '0';
      if ComboBox3.Text = 'True' then
        Ac := '1'
      else
        Ac := '0';

      if (Combobox1.Items.IndexOf(ComboBox1.Text) > 0) or (LocRet = True) then
        SQLMainQuery.SQL.Text :=
          ('UPDATE "Data" SET "RetFTP" = ''' + Edit1.Text + ''',"Active"=' +
          Ac + ',"Modded"=''' + Last + ''' WHERE "Retailer" = ''' +
          ComboBox1.Text + '''')
      else
        SQLMainQuery.SQL.Text :=
          ('INSERT INTO "Data" (Retailer,RetFTP,Active,First,Last,Modded) VALUES (''' +
          ComboBox1.Text + ''',''' + Edit1.Text + ''',''' + Ac +
          ''',''' + First + ''',''' + Last + ''',''' + Last + ''')');

      SQLMainQuery.ExecSQL;
      SQLTrans.Commit;
      ShowFTP;
      end
    else
      ShowMessage('Поля Retailer и FTP должны быть заполненны !');
  end;

procedure TForm1.Button2Click(Sender: TObject);
  begin
    SQLMainQuery.Close;
    SQLMainQuery.SQL.Clear;
    SQLMainQuery.SQL.Text :=
      ('DELETE FROM "Data" WHERE "Retailer"=''' + ComboBox1.Text + '''');
    SQLMainQuery.ExecSQL;
    SQLTrans.Commit;
    ShowFTP;
  end;

procedure TForm1.Button3Click(Sender: TObject);
  var
    Last, Ret: string;
  begin
    Last := DBGrid1.DataSource.DataSet.Fields[2].AsString;
    Ret  := DBGrid1.DataSource.DataSet.Fields[0].AsString;
    SQLMainQuery.Close;
    SQLMainQuery.SQL.Clear;
    if CheckBox2.Checked = True then
      SQLMainQuery.SQL.Text :=
        ('UPDATE "Data" SET "Last" = ''' + Copy(ComboBox2.Text, 0,
        Pos(',', ComboBox2.Text) - 1) + ''',"First" = ''' +
        Copy(ComboBox2.Text, Pos(',', ComboBox2.Text) + 2, Length(ComboBox2.Text)) +
        ''',"Modded"= ''' + Copy(USr, 0, Pos(',', Usr) - 1) +
        ''' WHERE "Last" = ''' + Last + '''')
    else
      SQLMainQuery.SQL.Text :=
        ('UPDATE "Data" SET "Last" = ''' + Copy(ComboBox2.Text, 0,
        Pos(',', ComboBox2.Text) - 1) + ''',"First" = ''' +
        Copy(ComboBox2.Text, Pos(',', ComboBox2.Text) + 2, Length(ComboBox2.Text)) +
        ''',"Modded"= ''' + Copy(USr, 0, Pos(',', Usr) - 1) +
        ''' WHERE "Retailer" = ''' + Ret + '''');
    SQLMainQuery.ExecSQL;
    SQLTrans.Commit;
    ShowFTP;
  end;

procedure TForm1.CheckBox1Change(Sender: TObject);
  begin
    ShowFTP;
  end;

procedure TForm1.CheckBox3Change(Sender: TObject);
  begin
    if CheckBox3.Checked = True then
      DBGrid1.DataSource.DataSet.FieldByName('Modded').Visible := True
    else
      DBGrid1.DataSource.DataSet.FieldByName('Modded').Visible := False;
  end;

procedure TForm1.ComboBox1Change(Sender: TObject);
  begin
    if DBGrid1.DataSource.DataSet.Locate('Retailer', ComboBox1.Text,
      [loCaseInsensitive, loPartialKey]) then
      Edit1.Text := DBGrid1.DataSource.DataSet.Fields[2].AsString
    else
      Edit1.Text := '';
  end;

procedure TForm1.DBGrid1CellClick(Column: TColumn);
  begin
    Edit1.Text     := DBGrid1.DataSource.DataSet.Fields[2].AsString;
    ComboBox1.Text := DBGrid1.DataSource.DataSet.Fields[1].AsString;
    ComboBox3.Text := DBGrid1.DataSource.DataSet.Fields[0].AsString;
  end;

procedure TForm1.Edit1KeyPress(Sender: TObject; var Key: char);
  begin
    if key = #13 then
      begin
      Edit1.Text := StringReplace(Edit1.Text, '\', '/',
        [rfReplaceAll, rfIgnoreCase]);
      Button1Click(nil);
      ShowFTP;
      end;
  end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
  begin
    SQLMainQuery.Free;
    ODBCServerConnect.Free;
    DeleteFile(PChar(ExtractFilePath(ParamStr(0)) + 'sqlite3.dll'));
  end;

end.
