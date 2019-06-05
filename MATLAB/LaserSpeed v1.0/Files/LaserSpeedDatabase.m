function varargout = LaserSpeedDatabase(varargin)
% LASERSPEEDDATABASE MATLAB code for LaserSpeedDatabase.fig
%      LASERSPEEDDATABASE, by itself, creates a new LASERSPEEDDATABASE or raises the existing
%      singleton*.
%
%      H = LASERSPEEDDATABASE returns the handle to a new LASERSPEEDDATABASE or the handle to
%      the existing singleton*.
%
%      LASERSPEEDDATABASE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LASERSPEEDDATABASE.M with the given input arguments.
%
%      LASERSPEEDDATABASE('Property','Value',...) creates a new LASERSPEEDDATABASE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LaserSpeedDatabase_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LaserSpeedDatabase_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LaserSpeedDatabase

% Last Modified by GUIDE v2.5 26-Feb-2016 09:51:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @LaserSpeedDatabase_OpeningFcn, ...
    'gui_OutputFcn',  @LaserSpeedDatabase_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before LaserSpeedDatabase is made visible.
function LaserSpeedDatabase_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LaserSpeedDatabase (see VARARGIN)

% Choose default command line output for LaserSpeedDatabase
handles.output = hObject;
addpath(genpath('Files'));
addpath(genpath('Data'));

load('LASERSPEEDdb.mat'); % loads database file

handles.db = LASERSPEEDdb(2:end,2:end); % copys database for manipulation and removes header and first collumns

handles.names = [{'All'};sort(unique(LASERSPEEDdb(2:end,2)))]; % makes a list of all names, removing duplicates and sorts them by alphabetical order. and adds all as first option
handles.gender = {'All';'Male';'Female'};
handles.type = [{'All'};sort(unique(LASERSPEEDdb(2:end,7)))]; % makes a list of all vault types, removing duplicates and sorts them by alphabetical order. and adds all as first option
handles.saltos = [{'All'};cellstr(num2str(sort(unique(cell2mat(LASERSPEEDdb(2:end,8))))))]; % makes a list of all twist amounts, removing duplicates and sorts them by numerical order. and adds all as first option
handles.twists = [{'All'};cellstr(num2str(sort(unique(cell2mat(LASERSPEEDdb(2:end,9))))))]; % makes a list of all salto amounts, removing duplicates and sorts them by numerical order. and adds all as first option

% code below adds the lists constructed above to their respective menus
set(handles.NameMenu,'string',char(handles.names))
set(handles.GenderMenu,'string',char(handles.gender))
set(handles.TypeMenu,'string',char(handles.type))
set(handles.SaltoMenu,'string',char(handles.saltos))
set(handles.TwistsMenu,'string',char(handles.twists))

% initializing the selection variable with initial values
handles.selection = struct(...
    'Name',handles.names{get(handles.NameMenu,'value')},...
    'Gender',handles.gender{get(handles.GenderMenu,'value')},...
    'AgeMin',sscanf(get(handles.AgeMin,'String'),'%d'),...
    'AgeMax',sscanf(get(handles.AgeMax,'String'),'%d'),...
    'Type',handles.type{get(handles.TypeMenu,'value')},...
    'Saltos',handles.saltos{get(handles.SaltoMenu,'value')},...
    'Twists',handles.twists{get(handles.TwistsMenu,'value')});

% constructing table with all database entries
set(handles.uitable1,'ColumnName', LASERSPEEDdb(1,2:end));
set(handles.uitable1,'RowName', LASERSPEEDdb(2:end,1)) ;
set(handles.uitable1,'Data', handles.db);

% display LaserSpeed logo
axes(handles.LogoISLdb)
I=imread('Schermlogo.png');
hi = imagesc(I);
set(handles.LogoISLdb,'Color','none','handlevisibility','off','visible','off')

% display ISL logo on home button
[x,map]=imread('ButtonMatlab.png');
I2=imresize(x, [65 65]);
set(handles.HomeButton,'Units','Pixels','CData',I2)

[a,b] = size(handles.db);
handles.mask = ones(a,b); % the mask is an overlay for the main database. only those entries where every collumn in a row is true is shown.
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes LaserSpeedDatabase wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = LaserSpeedDatabase_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function AgeMin_Callback(hObject, eventdata, handles)
% hObject    handle to AgeMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AgeMin as text
%        str2double(get(hObject,'String')) returns contents of AgeMin as a double
handles.output = hObject;
val = uint8(str2double(get(hObject,'String'))); % value is read and converted to an integer value
if isinteger(val) && val >= 0 && val <= 120 && val <= handles.selection.AgeMax % allowed entries should be between 0 and 120 years. and the value should be smaller then the max age
    handles.selection.AgeMin = val; % if the entry is valid the minimum age is updated and the current value is displayed in the edit box
    set(hObject,'String',num2str(val))
else
    warning('invalid value entered')
    set(hObject,'String',num2str(handles.selection.AgeMin))
end
handles = DatabaseMod(handles,hObject);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function AgeMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AgeMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function AgeMax_Callback(hObject, eventdata, handles)
% hObject    handle to AgeMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AgeMax as text
%        str2double(get(hObject,'String')) returns contents of AgeMax as a double
handles = guidata(hObject);
val = uint8(str2double(get(hObject,'String')));% value is read and converted to an integer value
if isinteger(val) && val >= 0 && val <= 120 && val >= handles.selection.AgeMin % allowed entries should be between 0 and 120 years. and the value should be greater then the min age
    handles.selection.AgeMax = val;% if the entry is valid the maximum age is updated and the current value is displayed in the edit box
    set(hObject,'String',num2str(val))
else
    warning('invalid value entered')
    set(hObject,'String',num2str(handles.selection.AgeMax))
end
handles = DatabaseMod(handles,hObject);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function AgeMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AgeMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in NameMenu.
function NameMenu_Callback(hObject, eventdata, handles)
% hObject    handle to NameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns NameMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from NameMenu
handles = guidata(hObject);
handles.selection.Name = handles.names{get(hObject,'value')};
handles = DatabaseMod(handles,hObject);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function NameMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in GenderMenu.
function GenderMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GenderMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GenderMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GenderMenu
handles = guidata(hObject);
handles.selection.Gender = handles.gender{get(hObject,'value')};
handles = DatabaseMod(handles,hObject);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function GenderMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GenderMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SaltoMenu.
function SaltoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to SaltoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SaltoMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SaltoMenu
handles = guidata(hObject);
handles.selection.Saltos = handles.saltos{get(hObject,'value')};
handles = DatabaseMod(handles,hObject);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SaltoMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SaltoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in TwistsMenu.
function TwistsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to TwistsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns TwistsMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TwistsMenu
handles = guidata(hObject);
handles.selection.Twists = handles.twists{get(hObject,'value')};
handles = DatabaseMod(handles,hObject);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function TwistsMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TwistsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in TypeMenu.
function TypeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to TypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns TypeMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TypeMenu
handles = guidata(hObject);
handles.selection.Type = handles.type{get(hObject,'value')};
handles = DatabaseMod(handles,hObject);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function TypeMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function handles = DatabaseMod(handles,hObject)
% this script modifies the mask to represent the selection the user made. 
% inputs are all variables stored in the gui, and the handle of the field
% where a value had been changed
% output is the modified mask and updated table
% the switch case statement is used to only modify the changed value. this
% to improve runtime

tag = get(hObject,'tag');
switch tag
    case 'NameMenu'
        val = handles.selection.Name;
        if strcmpi(val,'All')
            handles.mask(:,1) = 1;
        else
            handles.mask(:,1) = strcmp(handles.db(:,1),val);
        end
    case 'GenderMenu'
        val = handles.selection.Gender;
        if strcmpi(val,'All')
            handles.mask(:,2) = 1;
        else
            handles.mask(:,2) = strcmp(handles.db(:,2),val);
        end
    case 'AgeMin'
        ages = cell2mat(handles.db(:,3));
        handles.mask(:,3) = 0;
        handles.mask(ages>=handles.selection.AgeMin & ages<=handles.selection.AgeMax,3) = 1;
    case 'AgeMax'
        ages = cell2mat(handles.db(:,3));
        handles.mask(:,3) = 0;
        handles.mask(ages>=handles.selection.AgeMin & ages<=handles.selection.AgeMax,3) = 1;
    case 'TypeMenu'
        val = handles.selection.Type;
        if strcmpi(val,'All')
            handles.mask(:,6) = 1;
        else
            handles.mask(:,6) = strcmp(handles.db(:,6),val);
        end
    case 'SaltoMenu'
        val = handles.selection.Saltos;
        if strcmpi(val,'All')
            handles.mask(:,7) = 1;
        else
            result = cellfun(@num2str, handles.db(:,7), 'UniformOutput', false);
            handles.mask(:,7) = strcmp(result,val);
        end
    case 'TwistsMenu'
        val = handles.selection.Twists;
        if strcmpi(val,'All')
            handles.mask(:,8) = 1;
        else
            result = cellfun(@num2str, handles.db(:,8), 'UniformOutput', false);
            handles.mask(:,8) = strcmp(result,val);
        end
end
index = find(all(handles.mask,2)); % only include entries which meet criteria
set(handles.uitable1,'Data', handles.db(index,:)); % update table with new masked database


% --- Executes on button press in HomeButton.
function HomeButton_Callback(hObject, eventdata, handles)
% hObject    handle to HomeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcf)
run LaserSpeed
