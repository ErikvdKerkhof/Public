function varargout = LaserSpeedPlayer(varargin)
% LASERSPEEDPLAYER MATLAB code for LaserSpeedPlayer.fig
%      LASERSPEEDPLAYER, by itself, creates a new LASERSPEEDPLAYER or raises the existing
%      singleton*.
%
%      H = LASERSPEEDPLAYER returns the handle to a new LASERSPEEDPLAYER or the handle to
%      the existing singleton*.
%
%      LASERSPEEDPLAYER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LASERSPEEDPLAYER.M with the given input arguments.
%
%      LASERSPEEDPLAYER('Property','Value',...) creates a new LASERSPEEDPLAYER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LaserSpeedPlayer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LaserSpeedPlayer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LaserSpeedPlayer

% Last Modified by GUIDE v2.5 23-Feb-2016 18:37:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @LaserSpeedPlayer_OpeningFcn, ...
    'gui_OutputFcn',  @LaserSpeedPlayer_OutputFcn, ...
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


% --- Executes just before LaserSpeedPlayer is made visible.
function LaserSpeedPlayer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LaserSpeedPlayer (see VARARGIN)

% Choose default command line output for LaserSpeedPlayer
handles.output = hObject;
addpath(genpath('Files'));


%% hardcoded variables
handles.Filterwindow = 11; % number of samples over which the filter is applied
handles.minDistToPega = 0.2; % m 
handles.DistWindow = [-25 0]; % m
handles.SpeedWindow = [-3 12]; % m/s
handles.VideoFactor = 1;
handles.VSgraphLine = 2; % width of the line in the Dist-Spd graph

%%

% video axes settings
axes(handles.axesVideo)
set(handles.axesVideo,'Units','pixels','Layer','bottom')
axis off

% Speed-Distance graph settings
axes(handles.axesLaserVS)
ph = plot(0,0,'LineWidth',handles.VSgraphLine,'Color',[1 0 0]);
set(handles.axesLaserVS,'UserData',ph);
set(handles.axesLaserVS,'Color','none');
set(handles.axesLaserVS,'XLim',handles.DistWindow)
set(handles.axesLaserVS,'YLim',handles.SpeedWindow)
set(handles.axesLaserVS,'Layer','top')
set(handles.axesLaserVS,'Units','pixels')
set(handles.axesLaserVS.XLabel,'string','Distance [m]')
set(handles.axesLaserVS.YLabel,'string','Speed [m/s]')

handles.tLaser = [0 20];
handles.tVideo = [0 20];
axeslabels(handles) % label S-t and V-t graphs

% disable video controls until data is selected
set(handles.sliderVideo,'Enable','off');
set(handles.PlayPause,'Enable','off');
set(handles.PlayPause,'String','Play');

handles.currentFrame = 1;
handles.currentLaserIndex = 1;

% display LaserSpeed logo
axes(handles.LogoISLdb)
I=imread('Schermlogo.png');
hi = imagesc(I);
set(handles.LogoISLdb,'Color','none','handlevisibility','off','visible','off')

% display Home button
[x,map]=imread('ButtonMatlab.png');
I2=imresize(x, [65 65]);
set(handles.HomeButton,'Units','Pixels','CData',I2)

% Update handles structure
guidata(hObject, handles);



% UIWAIT makes LaserSpeedPlayer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LaserSpeedPlayer_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function sliderVideo_Callback(hObject, eventdata, handles)
% hObject    handle to sliderVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles = guidata(hObject);
handles.currentFrame = round(get(hObject,'Value'));
playback(handles)
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function sliderVideo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
set(hObject,'Min',1,'Max',2,'SliderStep',[1 5],'Value',1);
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in vidSpeedSelect.
function vidSpeedSelect_Callback(hObject, eventdata, handles)
% hObject    handle to vidSpeedSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns vidSpeedSelect contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vidSpeedSelect

% enables user to play video's at 1x, 0.5x or 0.2x normal speed
handles = guidata(hObject);
contents = cellstr(get(hObject,'String'));
VideoSpeed = contents{get(hObject,'Value')};
switch VideoSpeed
    case '1x'
        handles.VideoFactor = 1;
    case '0.5x'
        handles.VideoFactor = 0.5;
    case '0.2x'
        handles.VideoFactor = 0.2;
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function vidSpeedSelect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vidSpeedSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in PlayPause.
function PlayPause_Callback(hObject, eventdata, handles)
% hObject    handle to PlayPause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Plays video file, updates graphs accordingly. changes to pause button
% when playing video and when video is completes enables the user to reset
% the video to replay it
handles = guidata(hObject);
state = get(hObject,'String');
switch state
    case 'Play'
        set(hObject,'String','Pause')
        state = get(hObject,'String');
        while strcmpi(state,'Pause')
            t1 = tic;
            playback(handles)% plays the video and updates the graph
            set(handles.sliderVideo,'Value',handles.currentFrame)
            if handles.currentFrame < size(handles.vidData.Data,4) % runs until no available frames are remaining
                handles.currentFrame = handles.currentFrame+1;
                state = get(hObject,'String');
                guidata(hObject, handles);
                loopTime = toc(t1);
                pause(1/(handles.vidData.FrameRate*handles.VideoFactor)-loopTime) % pauses the loop, time depends on framerate and runtime of code
            else
                set(hObject,'String','Replay')
                state = get(hObject,'String');
            end
            
        end
    case 'Pause'
        % stops video at current time
        set(hObject,'String','Play')
    case 'Replay'
        % resets video
        handles.currentFrame = 1;
        set(handles.sliderVideo,'Value',handles.currentFrame)
        set(hObject,'String','Play')
        guidata(hObject, handles);
end


% --- Executes on button press in LoadData.
function LoadData_Callback(hObject, eventdata, handles)
% hObject    handle to LoadData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% opens interface where user can load data. automatically determines
% kinematic parameters and updates ST and VT graphs
handles = guidata(hObject);
try
    uiopen('load')
    if exist('laserData','var') &&  exist('vidData','var')
        handles.laserData = laserData;
        handles.vidData = vidData;
        
        % timeaxis
        handles.tLaser = (handles.laserData.Time - handles.laserData.Time(1)).*86400;
        handles.tVideo = (handles.vidData.Time - handles.vidData.Time(1)).*86400;
        handles.kinematics = Kinematics(laserData,handles);
        
        % plots
        axes(handles.axesST)
        hold on
        plot(handles.tLaser,handles.kinematics.sFilt)
        text(0,-2,sprintf('Starting Distance: %4.2f m from pegases',abs(min(handles.kinematics.sFilt))),'Parent',gca)
        plot([handles.tLaser(handles.currentLaserIndex) handles.tLaser(handles.currentLaserIndex)],get(handles.axesST,'YLim'));
        
        axes(handles.axesVT)
        hold on
        plot(handles.tLaser,handles.kinematics.vFilt)
        
        text(0,10,sprintf('Max: %4.2f m/s',handles.kinematics.vMax),'Parent',gca)
        text(handles.tLaser(find(handles.kinematics.vFilt == handles.kinematics.vMax)),0,'\uparrow','Parent',gca)
        plot([handles.tLaser(handles.currentLaserIndex) handles.tLaser(handles.currentLaserIndex)],get(handles.axesVT,'YLim'));
        
        axeslabels(handles)
        
        % set up the slider and enable video controls
        set(handles.sliderVideo,'Max',size(handles.vidData.Data,4));
        set(handles.sliderVideo,'SliderStep',[1/size(handles.vidData.Data,4) 5/size(handles.vidData.Data,4)]);
        set(handles.sliderVideo,'Enable','on');
        set(handles.PlayPause,'Enable','on');
        set(handles.FPSFeedback,'String',sprintf('%3.0f ',handles.vidData.FrameRate));
        UpdateTime(handles)
        
        axes(handles.axesVideo)
        image(handles.vidData.Data(:,:,:,1))
        axis off
    else
        fprintf(1,'ERROR: Requested data could not be found')
    end
catch e
    fprintf(1,'ERROR: Failed loading file')
end
guidata(hObject, handles);



function kinematics = Kinematics(laserData,handles)
% from laserdata extract distance and speed vectors aswell als filtered
% distance and speed vectors. from filtered data the maximum recorded speed
% is determined
%% Distance
kinematics.s = laserData.Data - laserData.Distance; % set pegases as origin. values range between -25m and 0
kinematics.s(kinematics.s>-handles.minDistToPega) = nan; % remove values that are within a range from the pegases

%% Speed
kinematics.v = [0;diff(kinematics.s)].*laserData.fs; % standard dist to speed conversion using dx/dt

%% Filtered Data
kinematics.sFilt = NaN(length(kinematics.s),1);
kinematics.vFilt = NaN(length(kinematics.s),1);

% Filtering using curve fitting over window defined in hardcoded
% variables. linear speed over this window is assumed
for i = ceil(0.5*handles.Filterwindow):length(kinematics.s)-floor(0.5*handles.Filterwindow)
    p = polyfit(handles.tLaser(i-floor(0.5*handles.Filterwindow):i+floor(0.5*handles.Filterwindow)),kinematics.s(i-floor(0.5*handles.Filterwindow):i+floor(0.5*handles.Filterwindow)),1);
    kinematics.sFilt(i) = handles.tLaser(i)*p(1)+p(2);
    kinematics.vFilt(i) = p(1);
end

% removing unrealistic speed values
kinematics.vFilt(kinematics.vFilt>handles.SpeedWindow(2)) = nan;
kinematics.vFilt(kinematics.vFilt<handles.SpeedWindow(1)) = nan;

% Maximum recorded speed
kinematics.vMax = max(kinematics.vFilt);

function playback(handles)
handles.currentLaserIndex = FindClosest(handles.tLaser,handles.tVideo(handles.currentFrame));
axes(handles.axesVideo)
image(handles.vidData.Data(:,:,:,handles.currentFrame)) % display new frame
axis off
axes(handles.axesLaserVS)
pHandle = get(handles.axesLaserVS,'UserData'); % displays recorded laserdata up to that frame
set(pHandle,'XData',handles.kinematics.sFilt(1:handles.currentLaserIndex));
set(pHandle,'YData',handles.kinematics.vFilt(1:handles.currentLaserIndex));
vLine(handles) % plots new vertical line in ST and VT graphs
UpdateTime(handles)

function index = FindClosest(array,val)
% finds the index of nearest value in array
difference = abs(array-val);
closest = min(difference);
index = find(difference == closest);

function axeslabels(handles)
% Labels Distance-time graph
set(handles.axesST,'XLim',[handles.tLaser(1)-1 handles.tLaser(end)+1])
set(handles.axesST,'YLim',[-25 0])
set(handles.axesST.Title,'string','Distance to pegases')
set(handles.axesST.XLabel,'string','Time [s]')
set(handles.axesST.YLabel,'string','Distance [m]')
% Labels Speed-time graph
set(handles.axesVT,'XLim',[handles.tLaser(1)-1 handles.tLaser(end)+1])
set(handles.axesVT,'YLim',[-3 12])
set(handles.axesVT.Title,'string','Speed')
set(handles.axesVT.XLabel,'string','Time [s]')
set(handles.axesVT.YLabel,'string','Speed [m/s]')


function vLine(handles)
% plots vertical line at current time in video
% get handles to the children of the axes
hChildren = get(handles.axesST,'Children');
set(hChildren(1),'XData',[handles.tLaser(handles.currentLaserIndex) handles.tLaser(handles.currentLaserIndex)])
hChildren = get(handles.axesVT,'Children');
set(hChildren(1),'XData',[handles.tLaser(handles.currentLaserIndex) handles.tLaser(handles.currentLaserIndex)])

function UpdateTime(handles)
% user-feedback of current time of frame
formatSpec ='%5.3f                     current time: %5.3f                     %5.3f';
set(handles.TimeFeedback,'String',sprintf(formatSpec,handles.tVideo(1),handles.tLaser(handles.currentLaserIndex),handles.tLaser(end)));


% --- Executes on button press in HomeButton.
function HomeButton_Callback(hObject, eventdata, handles)
% hObject    handle to HomeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcf)
run LaserSpeed
