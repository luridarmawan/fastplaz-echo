unit main;

{$mode objfpc}{$H+}

interface

uses
  fpjson,
  Classes, SysUtils, fastplaz_app, HTTPDefs, fastplaz_handler, html_lib, database_lib;

type

  { TMainModule }

  TMainModule = class(TMyCustomWebModule)
  private
    procedure BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
  public
    constructor CreateNew(AOwner: TComponent; CreateMode: integer); override;
    destructor Destroy; override;

    procedure Get; override;
    procedure Post; override;
  end;

implementation

uses json_lib, common;

constructor TMainModule.CreateNew(AOwner: TComponent; CreateMode: integer);
begin
  inherited CreateNew(AOwner, CreateMode);
  BeforeRequest := @BeforeRequestHandler;
end;

destructor TMainModule.Destroy;
begin
  inherited Destroy;
end;

// Init First
procedure TMainModule.BeforeRequestHandler(Sender: TObject; ARequest: TRequest);
begin
  Response.ContentType := 'application/json';
end;

// GET Method Handler
procedure TMainModule.Get;
var
  json: TJSONUtil;
  i: integer;
  s: string;
begin
  json := TJSONUtil.Create;
  json['code'] := Int16(0);
  json['sitename'] := string(Config.GetValue('systems/sitename', ''));

  // GET
  for i := 0 to Request.QueryFields.Count - 1 do
  begin
    s := Request.QueryFields.Names[i];
    if s <> '' then
      json['GET/' + s] := _GET[s];
  end;

  json['time'] := i2s(TimeUsage) + 'ms';
  Response.Content := json.AsJSON;
  json.Free;
end;

// POST Method Handler
// CURL example:
//   curl -X POST -H "Authorization: Basic dW5hbWU6cGFzc3dvcmQ=" "yourtargeturl"
procedure TMainModule.Post;
var
  json: TJSONObject;
  jd: TJSONData;
  ji: TJSONObject;
  i: integer;
  s: string;
begin
  json := TJSONObject.Create;
  json.Add('code', 0);
  json.Add('sitename', string(Config.GetValue('systems/sitename', '')));

  // GET
  if Request.QueryFields.Count > 0 then
  begin
    ji := TJSONObject.Create;
    for i := 0 to Request.QueryFields.Count - 1 do
    begin
      s := Request.QueryFields.Names[i];
      if (s <> '') and (ji.IndexOfName(s) < 0) then
        ji.Add(s, _GET[s]);
    end;
    if ji.Count > 0 then
      json.Add('GET', ji)
    else
      ji.Free;
  end;

  // POST
  if Request.ContentFields.Count > 0 then
  begin
    ji := TJSONObject.Create;
    for i := 0 to Request.ContentFields.Count - 1 do
    begin
      s := Request.ContentFields.Names[i];
      if (s <> '') and (ji.IndexOfName(s) < 0) then
        ji.Add(s, _POST[s]);
    end;
    if ji.Count > 0 then
      json.Add('POST', ji)
    else
      ji.Free;
  end;

  // REQUEST BODY
  if not Request.Content.IsEmpty then
  begin
    if IsJsonValid(Request.Content) then
    begin
      jd := GetJSON(Request.Content);
      json.Add('RAW_BODY', jd);
    end
    else
      json.Add('RAW_BODY', base64_encode(Request.Content));
  end;

  json.Add('time', i2s(TimeUsage) + 'ms');
  Response.Content := json.AsJSON;
  json.Free;
end;


end.

