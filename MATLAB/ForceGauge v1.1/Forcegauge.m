function Forcegauge
% Known bugs:
%   *   The Mecmesin AFG 1000N forcegauge only starts sending data after the
%       first peak.
%   *   The current rate using the Mecmesin AFG 1000N in both automatic and manual mode is
%       10-11 Hz, there is currently no way to change this value.
%
% Preferred additional features:
%   *   Add support for manual frequencies (buttons are already in place
%       commented)
%
% Changelog:
%   *   9-1-'18 Erik vd Kerkhof
%           Added support to display us device names in COMport list
%           (disabled)
%           Sorted the functions used in alphabetical order
%

%% Forcegauge v1.1
clear variables global; close all; clc
addpath(genpath('icons'))
addpath(genpath('Imagefcn'))
addpath(genpath('Forcegauges'))
global handles measurement

%% GUI Creation
% Create a figure and axes
handles.fig = figure(...
    'Visible','off',...
    'NumberTitle','off',...
    'Resize','off',...
    'Color',[240 240 240]./255,...
    'Position',[100 100 960 540],...
    'MenuBar','figure',...
    'ToolBar','auto',...
    'DeleteFcn',@DeleteFcn);

% Create panels
% Connection panel
handles.connectionPanel = uipanel(...
    'Title','Connection',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[10 420 120 110]);

handles.btnConnect = uicontrol(...
    'Parent',handles.connectionPanel,...
    'Style', 'pushbutton',...
    'String', 'Connect',...
    'Position', [10 10 80 20],...
    'Callback', @BtnConnect_Callback);

handles.connectionStatus = uicontrol(...
    'Parent',handles.connectionPanel,...
    'Style','text',...
    'FontSize',12,...
    'String',char(9679),...
    'Position', [90 10 20 20]);

handles.popupCOMports = uicontrol(...
    'Parent',handles.connectionPanel,...
    'Style', 'popupmenu',...
    'String', {' '},...
    'Position', [10 40 80 20]);

handles.btnCheckCOM = uicontrol(...
    'Parent',handles.connectionPanel,...
    'Style', 'pushbutton', ...
    'String', '',...
    'Position', [90 40 20 20],...
    'Callback', @BtnCheckCOM_Callback);

handles.popupForcegauges = uicontrol(...
    'Parent',handles.connectionPanel,...
    'Style', 'popupmenu',...
    'String', {' '},...
    'Position', [10 70 80 20]);

% Control panel
handles.controlPanel = uipanel(...
    'Title','Controls',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[10 310 120 110]);

handles.manualText = uicontrol(...
    'Parent',handles.controlPanel,...
    'Style','text',...
    'String','Duration [s]:',...
    'HorizontalAlignment','left',...
    'Visible','off',...
    'Position', [10 65 70 20]);

handles.uiManualDuration = uicontrol(...
    'Parent',handles.controlPanel,...
    'Style','edit',...
    'String','--',...
    'Visible','off',...
    'Position', [80 70 30 20]);

% % handles.freqText = uicontrol(...
% %     'Parent',handles.controlPanel,...
% %     'Style','text',...
% %     'String','Freq [Hz]:',...
% %     'HorizontalAlignment','left',...
% %     'Visible','off',...
% %     'Position', [10 95 70 20]);
% %
% % handles.uiFrequency = uicontrol(...
% %     'Parent',handles.controlPanel,...
% %     'Style','edit',...
% %     'String','--',...
% %     'Visible','off',...
% %     'Position', [80 100 30 20]);

handles.modeSelect = uicontrol(...
    'Parent',handles.controlPanel,...
    'Style', 'popupmenu', ...
    'String', {'Automatic' 'Manual'},...
    'Position', [10 70 100 20],...
    'Callback', @ModeSelect_Callback);

handles.btnStartStop = uicontrol(...
    'Parent',handles.controlPanel,...
    'Style', 'pushbutton',...
    'String', 'Start Measurement',...
    'Position', [10 40 100 20],...
    'Callback', @BtnStartStop_Callback);

handles.btnSaveData = uicontrol(...
    'Parent',handles.controlPanel,...
    'Style', 'pushbutton',...
    'String', 'Save Data',...
    'Position', [10 10 100 20],...
    'Callback', @SaveFcn_Callback);

% Preview axes
handles.previewAxesLine = axes;
set(handles.previewAxesLine,'UserData',plot(0,0,'k'))
set(handles.previewAxesLine,...
    'Units','pixels',...
    'Position', [220 115 660 405],...
    'Box','off',...
    'XLim',[0 10],...controlPanel
    'YLim',[-1000 1000],...
    'XGrid','on',...
    'YGrid','on');
xlabel(handles.previewAxesLine,'Time [s]')
ylabel(handles.previewAxesLine,'Force [N]')

handles.previewAxesBar = axes(...
    'Units','pixels',...
    'Position', [900 115 30 405],...
    'Box','off',...
    'XLim',[0 1],...
    'YLim',[-1000 1000],...
    'XTick',[],...
    'YTick',[],...
    'XTickLabel',[],...
    'YTickLabel',[]);

ResetBarPlot

%% Initialize settings
[x,~] = imread('icon_refresh.png');
dims  = get(handles.btnCheckCOM,'position');
im    = imresize(x, dims(3:4));
set(handles.btnCheckCOM,'Units','Pixels','CData',im)
set(handles.connectionStatus,'ForeGroundColor','red')
UpdateCOMportList
UpdateForcegauges

measurement = struct(...
    'StartTime','',...
    'Frequency','',...
    'Time','',...
    'Data','');

handles.forcegauge = [];
set(findall(handles.controlPanel, '-property', 'enable'), 'enable', 'off')
set(handles.fig,'Name','Forcegauge v1.1','Visible','on');
end

%% Callbacks
function BtnCheckCOM_Callback(~,~)
UpdateCOMportList
end

function BtnConnect_Callback(~,~)
global handles
state = get(handles.btnConnect,'String');
switch state
    case 'Connect'
        optsCOM         = get(handles.popupCOMports,'String');
        valCOM          = get(handles.popupCOMports,'Value');
        selectionCOM    = optsCOM{valCOM};
%         ind             = strfind(selectionCOM,' - ');
%         com             = selectionCOM(1:ind(1)-1);
        
        optsFG          = get(handles.popupForcegauges,'String');
        valFG           = get(handles.popupForcegauges,'Value');
        selectionFG     = optsFG{valFG};
        
        try
            handles.forcegauge = eval(selectionFG);
            handles.forcegauge = handles.forcegauge.Connect(selectionCOM);
            set(handles.connectionStatus,'ForeGroundColor','green')
            set(handles.btnConnect,'String','Disconnect')
            set(findall(handles.controlPanel, '-property', 'enable'), 'enable', 'on')
            set(findall(handles.connectionPanel, '-property', 'enable'), 'enable', 'off')
            set([handles.connectionStatus, handles.btnConnect], 'enable', 'on')
        catch
            warning('error connecting')
        end
    case 'Disconnect'
        try
            handles.forcegauge.Close
            set(handles.btnConnect,'String','Connect')
            set(handles.connectionStatus,'ForeGroundColor','red')
            set(findall(handles.controlPanel, '-property', 'enable'), 'enable', 'off')
            set(findall(handles.connectionPanel, '-property', 'enable'), 'enable', 'on')
        catch
            warning('error disconnecting')
        end
end
end

function BtnStartStop_Callback(~,~)
global handles measurement
state = get(handles.btnStartStop,'String');
switch state
    case 'Start Measurement'
        if ~isempty(measurement.Data)
            button = questdlg('Would you  like to save your previous measurement or clear the data?','Confirmation Dialog',...
                'Save','Clear','Save');
            switch button
                case 'Save'
                    SaveFcn_Callback(0,0)
                case 'Clear'
                    measurement.Time = [];
                    measurement.Data = [];
                    measurement.Frequency = [];
                    measurement.StartTime = [];
            end
        end
        handles.forcegauge.StartAcquisition
        set(handles.btnStartStop,'String','Stop Measurement');
        measurement.StartTime = clock;
        ResetLinePlot
        ResetBarPlot
        set(findall(handles.controlPanel, '-property', 'enable'), 'enable', 'off')
        set(handles.btnStartStop, 'enable', 'on')
        set(handles.btnConnect, 'enable', 'off')
        items = get(handles.modeSelect ,'string');
        index = get(handles.modeSelect ,'value');
        
        switch items{index}
            case 'Manual'
                ManualDataAcquisition
            case 'Automatic'
                AutomaticDataAcquisition
        end
        
    case 'Stop Measurement'
        StopMeasuringFcn
end
end

function ModeSelect_Callback(~,~)
global handles
opts = get(handles.modeSelect,'String');
val  = get(handles.modeSelect,'Value');
state = opts{val};
switch state
    case 'Manual'
        set(handles.controlPanel,'Position',[10 280 120 140]);
        set(handles.modeSelect,'Position',[10 100 100 20]);
        set([handles.manualText,handles.uiManualDuration],'Visible','on');
        %         set([handles.freqText,handles.uiFrequency],'Visible','on');
    case 'Automatic'
        set(handles.controlPanel,'Position',[10 310 120 110]);
        set(handles.modeSelect,'Position',[10 70 100 20]);
        set([handles.manualText,handles.uiManualDuration],'Visible','off');
        %         set([handles.freqText,handles.uiFrequency],'Visible','off');
end
end

function SaveFcn_Callback(~,~)
global measurement
fileName = num2str(fix(measurement.StartTime));
fileName(ismember(fileName,' ')) = [];
fid = fopen([fileName '.txt'], 'wt' );
fprintf(fid,'Recorded: %s\n'              ,datestr(measurement.StartTime));
fprintf(fid,'Samplefrequentie: %5.3f Hz\n',measurement.Frequency);
fprintf(fid,'Tijd(s)\tKracht(N)\n'        );
for i = 1:length(measurement.Time)
    fprintf(fid,'%5.3f\t%5.3f\n',measurement.Time(i),measurement.Data(i));
end
fclose(fid);
measurement.Time = [];
measurement.Data = [];
measurement.Frequency = [];
measurement.StartTime = [];
end

%% Methods
function AutomaticDataAcquisition
global handles
while (strcmp(get(handles.btnStartStop,'String'),'Stop Measurement'))
    try
        val = handles.forcegauge.GetData;
        UpdateLinePlot(val,clock)
        UpdateBarPlot(val)
        pause(1/10^12)
    catch
        disp('error in data acquisition');
    end
end
end

function coms = CheckCOMports
% Credit to Benjamin Avants
% Retrieved from: https://www.mathworks.com/matlabcentral/answers/110249-how-can-i-identify-com-port-devices-on-windows
Skey = 'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM';
% Find connected serial devices and clean up the output
[~, list] = dos(['REG QUERY ' Skey]);
list = strread(list,'%s','delimiter',' '); %#ok<*DSTRRD>
coms = 0;
for i = 1:numel(list)
    if strcmp(list{i}(1:3),'COM')
        if ~iscell(coms)
            coms = list(i);
        else
            coms{end+1} = list{i}; %#ok<*AGROW>
        end
    end
end
key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';
% Find all installed USB devices entries and clean up the output
[~, vals] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);
vals = textscan(vals,'%s','delimiter','\t');
vals = cat(1,vals{:});
out = 0;
% Find all friendly name property entries
for i = 1:numel(vals)
    if strcmp(vals{i}(1:min(12,end)),'FriendlyName')
        if ~iscell(out)
            out = vals(i);
        else
            out{end+1} = vals{i};
        end
    end
end
% Compare friendly name entries with connected ports and generate output
for i = 1:numel(coms)
    match = strfind(out,[coms{i},')']);
    ind = 0;
    for j = 1:numel(match)
        if ~isempty(match{j})
            ind = j;
        end
    end
    if ind ~= 0
        com = str2double(coms{i}(4:end));
        % Trim the trailing ' (COM##)' from the friendly name - works on ports from 1 to 99
        if com > 9
            length = 8;
        else
            length = 7;
        end
        devs{i,1} = out{ind}(27:end-length);
        devs{i,2} = coms{i};
    end
end
end

function DeleteFcn(~,~)
global handles
if ~isempty(handles.forcegauge)
    try
        handles.forcegauge.StopAcquisition;
    catch
    end
    try
        handles.forcegauge.Close;
    catch
    end
    clc
end
end

function ManualDataAcquisition
global handles
timer = tic;
duration = get(handles.uiManualDuration,'string');
if strcmp(duration,'--')
    msgbox('please enter a duration in seconds to measure');
elseif ~isnumeric(str2double(duration))
    msgbox('please enter an integer value');
else
    duration = round(str2double(duration));
    while (toc(timer) < duration)
        try
            val = handles.forcegauge.GetData;
            UpdateLinePlot(val,clock)
            UpdateBarPlot(val)
        catch
            disp('error in data acquisition');
        end
    end
end
StopMeasuringFcn
end

function ResetBarPlot
global handles
axes(handles.previewAxesBar)
cla
hold on
patch('Faces',[1 2 3 4] ,'Vertices',[0 0; 0 1000; 1 1000; 1 0],'FaceVertexCData',[0; 1000; 1000; 0],'FaceColor','interp','FaceAlpha',0,'EdgeAlpha',0);
patch('Faces',[1 2 3 4] ,'Vertices',[0 0; 0 0; 1 0; 1 0],'FaceVertexCData',[0; 0; 0; 0],'FaceColor','interp');

set(handles.previewAxesBar,'XTick',[])
set(handles.previewAxesBar,'YTick',[])
set(handles.previewAxesBar,'XTickLabel',[])
set(handles.previewAxesBar,'YTickLabel',[])
plot([0 1],[0 0],'r')
end

function ResetLinePlot
global handles
axes(handles.previewAxesLine)
pHandle = get(handles.previewAxesLine,'UserData'); % displays recorded data
set(pHandle,'XData',0)
set(pHandle,'YData',0)
set(handles.previewAxesLine,'XLim',[0 10])
end

function StopMeasuringFcn
global handles measurement
handles.forcegauge.StopAcquisition;
set(handles.btnStartStop,'String','Start Measurement');
axes(handles.previewAxesLine)
pHandle = get(handles.previewAxesLine,'UserData'); % displays recorded data
measurement.Time = get(pHandle,'XData');
measurement.Data = get(pHandle,'YData');
measurement.Frequency = 1/(mean(diff(measurement.Time)));
set(findall(handles.controlPanel, '-property', 'enable'), 'enable', 'on')
set(handles.btnConnect, 'enable', 'on')
end

function UpdateBarPlot(curForce)
global handles
axes(handles.previewAxesBar)
pHandleBar = get(handles.previewAxesBar,'Children');
set(pHandleBar(2),'YData',[0, curForce, curForce, 0],'FaceVertexCData',[0; abs(curForce); abs(curForce); 0]);

pHandleLine = get(handles.previewAxesLine,'UserData'); % displays recorded data
yData = get(pHandleLine,'YData');
index = find(abs(yData) == max(abs(yData)),1);
maxForce = yData(index);

set(pHandleBar(1),'YData',[maxForce, maxForce]);
drawnow
end

function UpdateCOMportList
global handles
try
    coms = CheckCOMports;
    list = sort(coms);
%     devs = reshape(devs(~cellfun(@isempty,devs)),2,[])';
%     for i = 1:size(devs,1)
%         list{i} = [devs{i,2},' - ',devs{i,1}];
%     end
    set(handles.popupCOMports,'String',list)
catch
    warning('no serial devices connected')
end
end

function UpdateForcegauges
global handles
dirData = dir('Forcegauges/*.m');
list = {dirData.name};
list = strrep(list,'.m','');
set(handles.popupForcegauges,'string',list)
end

function UpdateLinePlot(curForce,Time)
global handles measurement
axes(handles.previewAxesLine)
pHandle = get(handles.previewAxesLine,'UserData'); % displays recorded data
x = get(pHandle,'XData');
y = get(pHandle,'YData');

curTime = etime(Time,measurement.StartTime);

if curTime>9
    dim = length(x)-1;
    x = [x(end-dim:end) curTime];
    y = [y(end-dim:end) curForce];
    set(handles.previewAxesLine,'XLim',[curTime-9 curTime+1])
else
    x = [x curTime];
    y = [y curForce];
end

set(pHandle,'XData',x)
set(pHandle,'YData',y)
drawnow
end

%% test functies
% function DatastreamTest(tStart)
% %testscript
% vals = [50,100,200,300,200,100,400,500,600,300,100,-100,-400,-700,-800,-500,0,200,400,500,600,800,900,800,850,900,800,700,400,300,200,100,0,0,0,0,200,300,400,600,700,800,800,800,800,650,0,0,0,0];
% for i = 1:length(vals)
%     a=tic;
%     UpdateLinePlot(vals(i),etime(clock,tStart))
%     UpdateBarPlot(vals(i))
%     pause(0.1-toc(a))
% end
% % end testscript
% end