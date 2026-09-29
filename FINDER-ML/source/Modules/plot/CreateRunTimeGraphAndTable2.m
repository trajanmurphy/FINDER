function CreateRunTimeGraphAndTable

p0.results = "results";
p0.MOE = "Manual_Hyperparameter_Selection";
p0.CrossVal = "Kfold";
p0.Log = true;

CreateRunTimeGraph(p0);

end
%==========================================================================

function CreateRunTimeGraph(p0)
ep = 0.001;
close all

TablePath = fullfile("..",p0.results,p0.MOE, p0.CrossVal, "Tables");
load(fullfile(TablePath, 'RunTimeData.mat')); 
% if p0.Log
% p.Run_Times = log10(p.Run_Times);
% end
p.Log = p0.Log;

breaks = [1 2 3 6 9];
[f, ax] = CreateFigure(p);

LineColors = DefineLineColors;

for i = 1:length(p.Sources)

    Source = p.Sources(i);
    ibar = p.("is" + Source);
    barData = p.Run_Times(ibar,:);
    
b = bar(ax(i), p.DA(ibar), barData  ,...
    'FaceColor', 'flat', 'LineWidth', 0.1);
    for k = 1:length(b)
        b(k).BarWidth = (1+ep)*b(k).BarWidth;
        for j = 1:size(b(k).CData,1)
        b(k).CData(j,:) = LineColors(k,:); 
    end, end
% Set the axes limits and labels for each subplot
end

p.ax = ax;
FixAxes(p);
axes(ax(1));
SetLegend(p);

plotPath = replace(p.TablePath, 'Tables', 'Graphs');
if ~isfolder(plotPath), mkdir(plotPath), end
exportgraphics(f, fullfile(plotPath, 'Run_Times_Graph.pdf'));
close(f)

end

%==========================================================================
function [f, ax] = CreateFigure(p)

Units = arrayfun(@(x) sum(p.("is" + x)), p.Sources);
Margins = 0.05; 
WidthBetweenPlots = 0.045;
PlotWidthUnit  = (1-(2*Margins + (length(Units)-1)*WidthBetweenPlots))/sum(Units);
PlotWidths = PlotWidthUnit * Units;
Positions = [0.1, 0.3, 0.58];
PlotLefts = [0, cumsum(PlotWidths(1:end-1))];
PlotLefts = [Margins + PlotLefts(1) ...
            (2:length(Units))*WidthBetweenPlots + PlotLefts(2:end)];

f = figure('units','normalized','outerposition',[0 0.1 0.85 0.50]);

FirstLeft = Margins;
for i = 1:length(Units), ax(i) = subplot(1,length(Units),i); end
axBottomUnit = 0.35 * ax(1).Position(3);
figBottom = 0.5;

for i = 1:length(Units)
    ax(i).Position = [FirstLeft,...
        figBottom,...
        PlotWidths(i),...
        0.95-figBottom];
    FirstLeft = FirstLeft + PlotWidths(i) + WidthBetweenPlots;
end

end
%==========================================================================
function LineColors = DefineLineColors

blue = [0.12, 0.21, 1]; %MLS
red = [1, 0.04, 0.12]; %ACA
gold = [0.85, 0.67, 0.2]; %Benchmark
violet = [0.5, 0.1, 0.8]; %PCA
white = [1, 1, 1];

t0 = [0.3;0.7];
t1 = [0.4;0.8];
t2 = [0.4;0.7;1];

MLScolors = t1 .* blue;
ACAScolors = t1 .* red ;
ACALcolors = t0 .* white + (1-t0) .* red;
PCAcolors = t1 .* violet ; 
SVMcolors = t0 .* white + (1-t0) .* violet; 
Othercolors = t2 .* gold; 

LineColors = [MLScolors;
    ACAScolors;
    ACALcolors;
    PCAcolors;
    SVMcolors;
    Othercolors];

end
%==========================================================================

function FixAxes(p)

%% Global Axes Parameters
xFS = 11;
yFS = 16;
tFS = 17;
lFS = 10;

ylabelString = "Run Time (s)";
% switch p.Log
%     case false, ylabelString = "Run Time (s)";
%     case true, ylabelString = "Log Run Time (s)";
% end

ylabel(p.ax(1), ylabelString, 'FontSize', yFS, 'Interpreter', 'latex');

for i = 1:length(p.ax)
     title(p.ax(i), p.Sources(i), 'FontSize', tFS, 'Interpreter', 'latex');
     p.ax(i).XTickLabelRotation = 30;   
     set(p.ax(i), 'YGrid', 'on');
     p.ax(i).YAxis.FontSize = yFS - 3;
     p.ax(i).YLabel.FontSize = yFS;
     p.ax(i).XAxis.FontSize = xFS;
     p.ax(i).XAxis.TickLabelInterpreter = 'latex';
     p.ax(i).YAxis.TickLabelInterpreter = "latex";
     currentYLim = p.ax(i).YLim;
     zoom(p.ax(i), 1.2);
     p.ax(i).YLim = currentYLim;

     if p.Log
     YData = [p.ax(i).Children.YData];
     LogData = log10([min(YData), max(YData)]);
     LogWindow = [floor(min(LogData)), ceil(max(LogData))];
     p.ax(i).YLim = 10.^LogWindow;
     p.ax(i).YScale = "log";
     LogTicks = LogWindow(1):LogWindow(2);
     YTicks = 10.^LogTicks;
     YTickLabels = "$10^{" + string(LogTicks) + "}$";
     YTickLabels(1:2:end) = "";
     %YTickLabels([1 end]) = "";
     p.ax(i).YTick = YTicks;
     p.ax(i).YTickLabels = YTickLabels;
     %p.ax(i).YTickLabels = "$10^{" + string(p.ax(i).YTickLabels) + "}$";
     end
end



end
%==========================================================================
function SetLegend(p)

Margins = 0.13;
Nrows = 2;
Width = 1 - 2*Margins;
LegHeight = 0.0759;
LegBottom = 0.17 - 0.5*LegHeight;
Position = [Margins, LegBottom, Width, LegHeight];

Ncol = ceil(length(p.LegendString)/Nrows);

lFS = p.ax(1).XAxis.FontSize;

p.LegendString = replace(p.LegendString, "_", "-");

legend(p.LegendString, ...
    'Location', 'southoutside', ...
    'Orientation', 'Horizontal',...
    'Interpreter', 'latex', ...
    'FontSize', lFS, ...
    'NumColumns', Ncol, ...
    'Position',  Position);

end