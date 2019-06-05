function varargout = LaserSpeedRecorder(varargin)
% LASERSPEEDRECORDER MATLAB code for LaserSpeedRecorder.fig
%      LASERSPEEDRECORDER, by itself, creates a new LASERSPEEDRECORDER or raises the existing
%      singleton*.
%
%      H = LASERSPEEDRECORDER returns the handle to a new LASERSPEEDRECORDER or the handle to
%      the existing singleton*.
%
%      LASERSPEEDRECORDER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LASERSPEEDRECORDER.M with the given input arguments.
%
%      LASERSPEEDRECORDER('Property','Value',...) creates a new LASERSPEEDRECORDER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LaserSpeedRecorder_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LaserSpeedRecorder_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LaserSpeedRecorder

% Last Modified by GUIDE v2.5 24-Feb-2016 12:43:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @LaserSpeedRecorder_OpeningFcn, ...
    'gui_OutputFcn',  @LaserSpeedRecorder_OutputFcn, ...
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


% --- Executes just before LaserSpeedRecorder is made visible.
function LaserSpeedRecorder_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LaserSpeedRecorder (see VARARGIN)

% Choose default command line output for LaserSpeedRecorder
addpath(genpath('Subfiles Recorder'));
addpath(genpath('Data'));
handles.output = hObject;

%% hardcoded variables
COMnum = 3;
handles.camConverter = 'MJPG';
handles.CamRes = '640x480';
%%
handles.colors = struct(   ...
    'red',         [255 0 0]./255,...
    'green',       [0 255 0]./255,...
    'orange',      [255 179 0]./255);

handles.parameters = struct(   ...
    'Name',         [],...
    'Gender',       [],...
    'Age',          [],...
    'Type',         [],...
    'Summersaults', [],...
    'Twists',       []);

% initialize classes
handles.laser = Laser;
handles.database = Database;

% initialize structs
handles.vidData =  struct('Time',[],'Data',[],'FrameRate',[]);
handles.laserData =  struct('Time',[],'Data',[],'Distance',[],'fs',[]);

handles.preview = false;

% detect cameras connected to pc
handles.camInfo = imaqhwinfo('winvideo');
camNames = char({'Detected Cameras' handles.camInfo.DeviceInfo.DeviceName});
set(handles.CamsDetected,'string',camNames)
handles.camSelection = [];

set(handles.PreviewAxes,'Color','none','handlevisibility','off','visible','off')

% create LaserSpeed logo
axes(handles.LogoISLdb)
I=imread('Schermlogo.png');
hi = imagesc(I);
set(handles.LogoISLdb,'Color','none','handlevisibility','off','visible','off')

% Home button
[x,map]=imread('ButtonMatlab.png');
I2=imresize(x, [65 65]);
set(handles.Home,'Units','Pixels','CData',I2)

% is theres no database yet, create a new one
if ~exist('LASERSPEEDdb.mat','file')
    handles.database.Empty;
    handles.database.Save;
end
load('LASERSPEEDdb.mat');
% if the database is empty prompt users to make new menu entries, else load
% available names and info
if size(LASERSPEEDdb,1)== 1
    handles.names = {'Please Add'};
    handles.type = {'Please Add'};
    handles.saltos = {'Please Add'};
    handles.twists = {'Please Add'};
else
    handles.names = sort(unique(LASERSPEEDdb(2:end,2)));
    handles.type = sort(unique(LASERSPEEDdb(2:end,7)));
    handles.saltos = sort(unique(strtrim([cellstr(num2str((0:0.5:4)'));LASERSPEEDdb(2:end,8)])));
    handles.twists = sort(unique(strtrim([cellstr(num2str((0:0.5:4)'));LASERSPEEDdb(2:end,9)])));
end
handles.gender = {'Male';'Female'};
% load available info in menu's
set(handles.NameMenu,'string',char(handles.names))
set(handles.GenderMenu,'string',char(handles.gender))
set(handles.TypeMenu,'string',char(handles.type))
set(handles.SaltoMenu,'string',char(handles.saltos))
set(handles.TwistsMenu,'string',char(handles.twists))

handles.tStart = [];
handles.tStop = [];
handles.cam = [];

% Disable buttons that cant be used yet and update current laser settings
% fields
set(handles.FPSopts,'Enable','off')
set(handles.ConnectCamera,'Enable','off')
set(handles.selectedCMP,'String',num2str(COMnum))
set(handles.ConnectCamera,'String','Connect')
set(handles.ConnectLaser,'String','Connect')
set(handles.StartStopMeasurement,'String','Start Measurement')
UpdateCurStateLaser(handles)
set(findall(handles.MeasurementControls, '-property', 'Enable'), 'Enable', 'off')

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes LaserSpeedRecorder wait for user response (see UIRESUME)
% uiwait(handles.LaserSpeedRecorder);


% --- Outputs from this function are returned to the command line.
function varargout = LaserSpeedRecorder_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in ConnectCamera.
function ConnectCamera_Callback(hObject, eventdata, handles)
% hObject    handle to ConnectCamera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
state = get(hObject,'String');
switch state
    case 'Connect'
        set(hObject,'String','Disconnect') % update button text
        set(handles.CameraStatus,'Backgroundcolor',handles.colors.orange,'String','Connecting') % update status
        set(handles.StatusFeedback,'String','Connecting Camera')% update status
        handles.cam = videoinput('winvideo',get(handles.CamsDetected,'Value')-1,[handles.camConverter '_' handles.CamRes]); % connects selected camera with requested videoformat
        src = getselectedsource(handles.cam);
        src.FrameRate = handles.frameRates{get(handles.FPSopts,'Value')};
        handles.vidData.FrameRate = str2double(handles.frameRates{get(handles.FPSopts,'Value')}); % save selected framerate
        handles.cam.FramesPerTrigger = inf; % lets camera run infinately many frames, be careful to disconnect camera before buffer fills completely
        triggerconfig(handles.cam, 'Manual') % starts recording when measurement is started
        start(handles.cam)
        set(handles.FPSopts,'Enable','off') % makes user unable to change settings when connected
        set(handles.CamsDetected,'Enable','off')% makes user unable to change settings when connected
        set(handles.CameraStatus,'Backgroundcolor',handles.colors.green,'String','Connected')% update status
        set(handles.StatusFeedback,'String','Connected Camera')% update status
        set(handles.PRVCam,'Enable','on') % enable preview option
    case 'Disconnect'
        set(hObject,'String','Connect')% update button text
        % stops and deletes object
        stop(handles.cam)
        delete(handles.cam)
        % initialize new empty variable for reuse
        handles.cam = [];
        set(handles.CameraStatus,'Backgroundcolor',handles.colors.red,'String','Disconnected')% update status
        set(handles.StatusFeedback,'String','Disconnected Camera')% update status
        set(handles.FPSopts,'Enable','on') % makes user able to change settings when disconnected
        set(handles.CamsDetected,'Enable','on') % makes user able to change settings when disconnected
        set(handles.PRVCam,'Enable','off') % disable preview option
end
UpdateStatus(handles)
guidata(hObject, handles);


% --- Executes on button press in ConnectLaser.
function ConnectLaser_Callback(hObject, eventdata, handles)
% hObject    handle to ConnectLaser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
state = get(hObject,'String');
switch state
    case 'Connect'
        progressbar('Connecting Laser') % initialize progressbar
        set(handles.LaserStatus,'Backgroundcolor',handles.colors.orange,'String','Connecting')
        set(handles.StatusFeedback,'String','Connecting Laser')
        try
            global axesHandle
            axesHandle = handles.RTLaserData; % define handle for the realtime laser feedback to be used in <Laser class\Recievelaserdata>
            handles.laser.setCOMport(sscanf(get(handles.selectedCMP,'String'),'%d'));
            progressbar(0.1)% update progressbar
            handles.laser.ConnectLaser;
            progressbar(0.4)% update progressbar
            handles.laser.SetLaser
            handles.laser.LaserDistance;
            progressbar(0.8)% update progressbar
            set(handles.LaserStatus,'Backgroundcolor',handles.colors.green,'String','Connected')
            set(handles.StatusFeedback,'String','Connected Laser')
            set(findall(handles.LaserSettings, '-property', 'Enable'), 'Enable', 'off')% disable all buttons and fields in lasersettings panel
            set(handles.ConnectLaser,'Enable','on')% re-enables (dis)connect button
            set(handles.ConnectLaser,'String','Disconnect')
            set(handles.PilotLaserToggle,'Enable','on') % enables pilot-laser
            progressbar(0.99)% update progressbar
        catch e
            set(handles.LaserStatus,'Backgroundcolor',handles.colors.red,'String','Not connected')
            set(handles.StatusFeedback,'String','ERROR: Could not connect laser')
            delete(handles.laser.port)
        end
        progressbar(1)% close progressbar
    case 'Disconnect'
        set(hObject,'String','Connect')
        handles.laser.StopMeasurement; % stops measurement incase one is still running
        handles.laser.DisconnectLaser;
        set(handles.LaserStatus,'Backgroundcolor',handles.colors.red,'String','Disconnected')
        set(handles.StatusFeedback,'String','Disconnected Laser')
        set(findall(handles.LaserSettings, '-property', 'Enable'), 'Enable', 'on') % re-enables all buttons and fields in lasersettings panel
        set(handles.PilotLaserToggle,'Enable','off') % disables pilot-laser
        
end
UpdateStatus(handles)
guidata(hObject, handles);


% --- Executes on selection change in CamsDetected.
function CamsDetected_Callback(hObject, eventdata, handles)
% hObject    handle to CamsDetected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns CamsDetected contents as cell array
%        contents{get(hObject,'Value')} returns selected item from CamsDetected
handles = guidata(hObject);
try
    % try to select camera using selected videoformat. updates fps options
    % with found parameters. enables user to select one of the available
    % fps options
    handles.cam = videoinput('winvideo',get(hObject,'Value')-1,[handles.camConverter '_' handles.CamRes]);
    src = getselectedsource(handles.cam);
    handles.frameRates = set(src,'FrameRate');
    set(handles.FPSopts,'string',char(handles.frameRates))
    set(handles.FPSopts,'Enable','on')
    set(handles.ConnectCamera,'Enable','on')
catch e
    % error, camera is already in use or videoformat is unavailable
    fprintf(1,'ERROR: Could not select camera, change camera or contact InnoSportab ''s-Hertogenbosch.\n');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function CamsDetected_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CamsDetected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in FPSopts.
function FPSopts_Callback(hObject, eventdata, handles)
% hObject    handle to FPSopts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Hints: contents = cellstr(get(hObject,'String')) returns FPSopts contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FPSopts


% --- Executes during object creation, after setting all properties.
function FPSopts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FPSopts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in PilotLaserToggle.
function PilotLaserToggle_Callback(hObject, eventdata, handles)
% hObject    handle to PilotLaserToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
state = get(hObject,'Value');
% switches pilotlaser on and off, sets color of the text accordingly
switch state
    case 1
        handles.laser.PilotOn
        set(hObject,'ForegroundColor', handles.colors.green)
    case 0
        handles.laser.PilotOff
        set(hObject,'ForegroundColor', handles.colors.red)
end

% --- Executes on button press in PRVCam.
function PRVCam_Callback(hObject, eventdata, handles)
% hObject    handle to PRVCam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% lets user preview the camera onscreen, also removes preview and reinitializes
% axes if turned off
vidRes = handles.cam.VideoResolution;
nBands = handles.cam.NumberOfBands;
hImage = image( zeros(vidRes(2), vidRes(1), nBands),'Parent',handles.PreviewAxes);
state = get(hObject,'Value');
switch state
    case 1
        preview(handles.cam,hImage)
        handles.preview = true;
    case 0
        stoppreview(handles.cam)
        handles.preview = false;
        set(handles.PreviewAxes,'Color','none','handlevisibility','off','visible','off')
end

% --- Executes on button press in lsrCancel.
function lsrCancel_Callback(hObject, eventdata, handles)
% hObject    handle to lsrCancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
UpdateCurStateLaser(handles)

% --- Executes on button press in lsrUpdate.
function lsrUpdate_Callback(hObject, eventdata, handles)
% hObject    handle to lsrUpdate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% updates laser with new settings
handles = guidata(hObject);
handles.laser.desState = handles.laser.curState;
GetDesStateLaser(handles)
handles.laser.updateLaser
UpdateCurStateLaser(handles)
guidata(hObject, handles);

% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function lsrWmax_Callback(hObject, eventdata, handles)
% hObject    handle to lsrWmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lsrWmax as text
%        str2double(get(hObject,'String')) returns contents of lsrWmax as a double

% --- Executes during object creation, after setting all properties.
function lsrWmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lsrWmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lsrM_Callback(hObject, eventdata, handles)
% hObject    handle to lsrM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lsrM as text
%        str2double(get(hObject,'String')) returns contents of lsrM as a double

% --- Executes during object creation, after setting all properties.
function lsrM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lsrM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lsrFs_Callback(hObject, eventdata, handles)
% hObject    handle to lsrFs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lsrFs as text
%        str2double(get(hObject,'String')) returns contents of lsrFs as a double

% --- Executes during object creation, after setting all properties.
function lsrFs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lsrFs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lsrWmin_Callback(~, eventdata, handles)
% hObject    handle to lsrWmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lsrWmin as text
%        str2double(get(hObject,'String')) returns contents of lsrWmin as a double

% --- Executes during object creation, after setting all properties.
function lsrWmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lsrWmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lsrO_Callback(hObject, eventdata, handles)
% hObject    handle to lsrO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lsrO as text
%        str2double(get(hObject,'String')) returns contents of lsrO as a double

% --- Executes during object creation, after setting all properties.
function lsrO_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lsrO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lsrS_Callback(hObject, eventdata, handles)
% hObject    handle to lsrS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lsrS as text
%        str2double(get(hObject,'String')) returns contents of lsrS as a double

% --- Executes during object creation, after setting all properties.
function lsrS_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lsrS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function lsrAS_Callback(hObject, eventdata, handles)
% hObject    handle to lsrAS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lsrAS as text
%        str2double(get(hObject,'String')) returns contents of lsrAS as a double

% --- Executes during object creation, after setting all properties.
function lsrAS_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lsrAS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function selectedCMP_Callback(hObject, eventdata, handles)
% hObject    handle to selectedCMP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of selectedCMP as text
%        str2double(get(hObject,'String')) returns contents of selectedCMP as a double

% --- Executes during object creation, after setting all properties.
function selectedCMP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to selectedCMP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in StartStopMeasurement.
function StartStopMeasurement_Callback(hObject, eventdata, handles)
% hObject    handle to StartStopMeasurement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
state  = get(handles.OverallStatus,'String');
if strcmpi(state,'Ready!') % only available if both camera and laser are connected
    handles = guidata(hObject);
    val = get(hObject,'String');
    switch val
        case 'Start Measurement'
            progressbar('Starting measurement') % initialize progressbar
            
            if get(handles.PilotLaserToggle,'Value'); % switches off pilot-laser if active
                handles.laser.PilotOff
                set(handles.PilotLaserToggle,'Value',0,'ForegroundColor', handles.colors.red)
            end
            
            handles.laser.StartMeasurement; % starts laser
            
            if ~handles.preview % opens preview if not already opened
                vidRes = handles.cam.VideoResolution;
                nBands = handles.cam.NumberOfBands;
                hImage = image( zeros(vidRes(2), vidRes(1), nBands),'Parent',handles.PreviewAxes);
                preview(handles.cam,hImage)
                set(handles.PRVCam,'value',1);
                handles.preview = true;
            end
            
            progressbar(0.1) % updates progressbar
            handles.vidData =  struct('Time',[],'Data',[],'FrameRate',[]);
            handles.laserData =  struct('Time',[],'Data',[],'Distance',[],'fs',[]);
            m = 100*0.5;
            for i = 5:m-10
                pause(0.01)
                progressbar(i/m) % Update progress bar
            end
            progressbar(0.8)% updates progressbar
            handles.tStart = now; % official starting time, recorded data will be saved from this moment
            trigger(handles.cam) % starts camera
            progressbar(0.9)% updates progressbar
            set(handles.StatusFeedback,'String','Recording has started')% user feedback
            set(hObject,'String','Stop Measurement')
            
            % disables all buttons exept stop measurement
            set(findall(handles.CameraSettings, '-property', 'Enable'), 'Enable', 'off')
            set(findall(handles.LaserSettings, '-property', 'Enable'), 'Enable', 'off')
            set(findall(handles.AthletesInfo, '-property', 'Enable'), 'Enable', 'off')
            set(findall(handles.MeasurementControls, '-property', 'Enable'), 'Enable', 'off')
            set(handles.StartStopMeasurement,'Enable','on')
            set(handles.RecordingStatus,'Backgroundcolor',handles.colors.green)% set new status
            progressbar(0.99)% updates progressbar
            progressbar(1)% closes progressbar
            
        case 'Stop Measurement'
            handles.tStop = now; % official stopping time, recorded data will be saved up until this time
            set(handles.StatusFeedback,'String',sprintf('Stopping current measurement'))
            progressbar('Starting measurement')% initialize progressbar
            [data,~,abstime] = getdata(handles.cam); % import video data
            progressbar(0.1)% updates progressbar
            for i = 1:length(abstime) % convert imported times to time vector similar to laser
                handles.vidData.Time(i) = datenum(abstime(i).AbsTime);
            end
            handles.vidData.Data = data;
            handles.vidData.FrameRate = str2double(handles.frameRates{get(handles.FPSopts,'Value')}); % save used framerate during recording
            progressbar(0.15)% updates progressbar
            
            % resetting camera for new measurement
            stop(handles.cam) 
            delete(handles.cam)
            clear handles.cam
            handles.cam = videoinput('winvideo',get(handles.CamsDetected,'Value')-1,[handles.camConverter '_' handles.CamRes]);
            handles.cam.FramesPerTrigger = inf;
            triggerconfig(handles.cam, 'Manual')
            start(handles.cam)
            
            progressbar(0.2)% updates progressbar
            
                  m = 100*0.5;
            for i = 10:m-10 % pause 1 second to enable  all laserdata to be read from serial port
                pause(0.01)
                progressbar(i/m) % Update progress bar
            end      
            
            % only save laserdata recorded between times when started and
            % stopped
            iStart = FindClosest(handles.laser.Time,handles.tStart);
            iEnd = FindClosest(handles.laser.Time,handles.tStop);

            progressbar(0.8)% updates progressbar
            handles.laser.StopMeasurement;
            progressbar(0.85)% updates progressbar
            
            % import laserdata
            handles.laserData.Time = handles.laser.Time(iStart:iEnd,:); 
            handles.laserData.Data = handles.laser.Data(iStart:iEnd,:);
            handles.laserData.Distance = handles.laser.Distance;
            handles.laserData.fs = handles.laser.sampleFreq;
            
            % clear stored data in buffer and reset timer
            handles.laser.Data = [];
            handles.laser.Time = [];
            handles.laser.startTime = now;
            
            progressbar(0.9)% updates progressbar
            set(handles.StatusFeedback,'String','Recording has stopped')
            set(hObject,'String','Start Measurement')
            set(findall(handles.CameraSettings, '-property', 'Enable'), 'Enable', 'on')
            set(findall(handles.LaserSettings, '-property', 'Enable'), 'Enable', 'on')
            set(findall(handles.AthletesInfo, '-property', 'Enable'), 'Enable', 'on')
            set(findall(handles.MeasurementControls, '-property', 'Enable'), 'Enable', 'on')
            set(handles.RecordingStatus,'Backgroundcolor',handles.colors.red)
            progressbar(0.95)% updates progressbar
            progressbar(1)% closes progressbar
    end
    guidata(hObject, handles);
else
    set(handles.StatusFeedback,'String',sprintf('Unable to start measurement \nRequired devices are not connected'))
end

function AgeEdit_Callback(hObject, eventdata, handles)
% hObject    handle to AgeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AgeEdit as text
%        str2double(get(hObject,'String')) returns contents of AgeEdit as a double


% --- Executes during object creation, after setting all properties.
function AgeEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AgeEdit (see GCBO)
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


% --- Executes on button press in SaveBTN.
function SaveBTN_Callback(hObject, eventdata, handles)
% hObject    handle to SaveBTN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
% import userinput from menus and fields. convert to required format if
% necessary 
handles.parameters = struct(   ...
    'Name',         handles.names{get(handles.NameMenu,'Value')},...
    'Gender',       handles.gender{get(handles.GenderMenu,'Value')},...
    'Age',          uint8(str2double(get(handles.AgeEdit,'String'))),...
    'Type',         handles.type{get(handles.TypeMenu,'Value')},...
    'Summersaults', handles.saltos{get(handles.SaltoMenu,'Value')},...
    'Twists',       handles.twists{get(handles.TwistsMenu,'Value')});
SaveData(handles)

% --- Executes on button press in AddName.
function AddName_Callback(hObject, eventdata, handles)
% hObject    handle to AddName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
handles.names = addInput(handles.names);
set(handles.NameMenu,'string',char(handles.names))
guidata(hObject, handles);

% --- Executes on button press in AddType.
function AddType_Callback(hObject, eventdata, handles)
% hObject    handle to AddType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
handles.type = addInput(handles.type);
set(handles.TypeMenu,'string',char(handles.type))
guidata(hObject, handles);

% --- Executes on button press in AddTwists.
function AddTwists_Callback(hObject, eventdata, handles)
% hObject    handle to AddTwists (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
handles.twists = addInput(handles.twists);
set(handles.TwistsMenu,'string',char(handles.twists))
guidata(hObject, handles);

% --- Executes on button press in AddSalto.
function AddSalto_Callback(hObject, eventdata, handles)
% hObject    handle to AddSalto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
handles.saltos = addInput(handles.saltos);
set(handles.SaltoMenu,'string',char(handles.saltos))
guidata(hObject, handles);

% --- Executes on button press in Home.
function Home_Callback(hObject, eventdata, handles)
% hObject    handle to Home (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcf)
run LaserSpeed


% --- Executes when user attempts to close LaserSpeedRecorder.
function LaserSpeedRecorder_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to LaserSpeedRecorder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
stateLaser = get(handles.ConnectLaser,'String');
stateWebcam = get(handles.ConnectCamera,'String');
% if either laser or camera is connected, disconnect it
if strcmpi(stateLaser,'Disconnect')
    ConnectLaser_Callback(handles.ConnectLaser, eventdata, handles)
end
if strcmpi(stateWebcam,'Disconnect')
    ConnectCamera_Callback(handles.ConnectCamera, eventdata, handles)
end

delete(hObject);


function SaveData(handles)
% Database
UpdateDatabase(handles)
Identifier = handles.database.db{end,end}; % request constructed identifier for use in filename and user feedback
% Save Recorded Data
laserData = handles.laserData;
vidData = handles.vidData;

set(handles.StatusFeedback,'String',sprintf('Saving data to file'))
save([pwd '/Data/' Identifier '.mat'],'laserData','vidData')
set(handles.StatusFeedback,'String',sprintf(['Saved data to ' Identifier '.mat']))

function UpdateDatabase(handles)
set(handles.StatusFeedback,'String',sprintf('Updating database')) % user feedback
handles.database.Load;
handles.database.Append(handles.parameters);
handles.database.Save;

function cellArray = addInput(cellArray)
% opens a screen where users can insert new values to be used in athletes
% selection menus
if strcmp(cellArray{1},'Please Add')
    cellArray = [];
end
prompt = {'Enter new value:'};% 1x1 cell, since there is only one question
dlg_title = 'Input';
num_lines = 1; % number if questions
defaultans = {''};
answer = '';
while strcmp(answer,'')
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
end
cellArray = sort(unique([cellArray;answer])); % sorts the new input alphabeticcaly into the menu

function UpdateCurStateLaser(handles)
% updates edit fields in interface, doesnt update laser itself
set(handles.lsrAS,'String',handles.laser.curState.auto_start)
set(handles.lsrS,'String',handles.laser.curState.scaling)
set(handles.lsrO,'String',handles.laser.curState.offset)
set(handles.lsrWmin,'String',handles.laser.curState.window_start)
set(handles.lsrWmax,'String',handles.laser.curState.window_end)
set(handles.lsrFs,'String',handles.laser.curState.freq)
set(handles.lsrM,'String',handles.laser.curState.mean)
set(handles.lsrFreq,'String',sprintf('L: %4i fps',handles.laser.curState.freq))
set(handles.lsrRecordedFs,'String',sprintf('In: %4i fps',handles.laser.curState.freq/handles.laser.curState.mean))

function GetDesStateLaser(handles)
% reads the edit fields for laser settings, updates desired state variable
% accordingly
handles.laser.desState.auto_start = get(handles.lsrAS,'String');
handles.laser.desState.scaling = sscanf(get(handles.lsrS,'String'),'%f');
handles.laser.desState.offset = sscanf(get(handles.lsrO,'String'),'%f');
handles.laser.desState.window_start = sscanf(get(handles.lsrWmin,'String'),'%f');
handles.laser.desState.window_end = sscanf(get(handles.lsrWmax,'String'),'%f');
handles.laser.desState.freq = sscanf(get(handles.lsrFs,'String'),'%d');
handles.laser.desState.mean = sscanf(get(handles.lsrM,'String'),'%d');

function index = FindClosest(array,val)
% finds nearest value in array
difference = abs(array-val);
closest = min(difference);
index = find(difference == closest);

function UpdateStatus(handles)
% switches overall status feedback. if both devices are connected the field
% will turn green, else the field will turn red
if strcmpi(get(handles.CameraStatus,'String'),get(handles.LaserStatus,'String'))
    switch get(handles.CameraStatus,'String')
        case 'Connected'
            set(handles.StartStopMeasurement,'Enable','on')
            set(handles.SaveBTN,'Enable','on')
            set(handles.OverallStatus,'Backgroundcolor',handles.colors.green,'String','Ready!')
    end
else
    set(handles.StartStopMeasurement,'Enable','off')
    set(handles.SaveBTN,'Enable','off')
    set(handles.OverallStatus,'Backgroundcolor',handles.colors.red,'String',' ')
end
