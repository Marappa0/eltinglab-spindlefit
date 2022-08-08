classdef SpindleCurveApp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        GridLayout              matlab.ui.container.GridLayout
        LeftPanel               matlab.ui.container.Panel
        AutoCheckBox            matlab.ui.control.CheckBox
        ObjectSpinner           matlab.ui.control.Spinner
        ObjectSpinnerLabel      matlab.ui.control.Label
        TossDataButton          matlab.ui.control.Button
        GOLIterSpinner          matlab.ui.control.Spinner
        GOLIterSpinnerLabel     matlab.ui.control.Label
        framesLabel             matlab.ui.control.Label
        ToggleWaitButton        matlab.ui.control.StateButton
        PauseAnalysisButton     matlab.ui.control.StateButton
        AnalyzeAllFramesButton  matlab.ui.control.Button
        PreviewButton           matlab.ui.control.Button
        AddFrameDataButton      matlab.ui.control.Button
        FrameSpinner            matlab.ui.control.Spinner
        FrameSpinnerLabel       matlab.ui.control.Label
        VideoMontageButton      matlab.ui.control.Button
        GOLFactorSpinner        matlab.ui.control.Spinner
        GOLFactorSpinnerLabel   matlab.ui.control.Label
        ThresholdSpinner        matlab.ui.control.Spinner
        ThresholdSpinnerLabel   matlab.ui.control.Label
        ZstacksImagesButton     matlab.ui.control.Button
        ThresholdValueSlider    matlab.ui.control.Slider
        CreateTXTFileButton     matlab.ui.control.Button
        RightPanel              matlab.ui.container.Panel
        TabGroup                matlab.ui.container.TabGroup
        ImagesTab               matlab.ui.container.Tab
        PreviewAxes_2           matlab.ui.control.UIAxes
        ImageAxes               matlab.ui.control.UIAxes
        PreviewAxes             matlab.ui.control.UIAxes
        DataTab                 matlab.ui.container.Tab
        UITable                 matlab.ui.control.Table
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = private)
        filename
        pathname
        fileType
        imgMat
        threshold = 0
        GOLfactor = 4
        GOLiter = 1
        tableRow
        columnNames
        frame = 1
        numFrames
        spindleImage
        numDataPoints = 0
        objectNum = 1
        auto = true
        badFrames = []
    end
    
    methods (Access = private)
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
        end

        % Button pushed function: ZstacksImagesButton
        function ZstacksImagesButtonPushed(app, event)
            app.fileType = 1;
            [app.filename, app.pathname] = uigetfile('*.tif');
            app.imgMat = stack2Mat([app.pathname,app.filename]);
            imshow(app.imgMat, [], 'parent', app.ImageAxes)
        end

        % Value changed function: ThresholdValueSlider
        function ThresholdValueSliderValueChanged(app, event)
            app.threshold = app.ThresholdValueSlider.Value;
            app.ThresholdSpinner.Value = app.threshold;
            tempImgMat = applyThreshold(app.imgMat, app.threshold, app.GOLfactor, app.GOLiter);
            imshow(tempImgMat,'parent', app.PreviewAxes);
        end

        % Value changed function: ThresholdSpinner
        function ThresholdSpinnerValueChanged(app, event)
            app.threshold = app.ThresholdSpinner.Value;
            app.ThresholdValueSlider.Value = app.threshold;
            ThresholdValueSliderValueChanged(app)
        end

        % Value changed function: GOLFactorSpinner
        function GOLFactorSpinnerValueChanged(app, event)
            app.GOLfactor = app.GOLFactorSpinner.Value;
            ThresholdValueSliderValueChanged(app)
        end

        % Button pushed function: AddFrameDataButton
        function AddFrameDataButtonPushed(app, event)
            
            if app.fileType == 1
                [app.tableRow, app.columnNames, app.spindleImage] = CurveFitData([app.pathname,app.filename], app.threshold, app.GOLfactor, app.GOLiter, app.objectNum, app.auto);
                app.UITable.ColumnName = app.columnNames;
                app.UITable.Data = [app.UITable.Data; app.tableRow];
            else
                [app.tableRow, app.columnNames, app.spindleImage] = CurveFitData([app.pathname,app.filename], app.threshold, app.GOLfactor, app.GOLiter, app.objectNum, app.auto, app.frame);
                app.UITable.ColumnName = app.columnNames;
                app.UITable.Data(app.frame,:) = app.tableRow;
                if app.frame < app.numFrames
                    app.FrameSpinner.Value = app.FrameSpinner.Value+1;
                    FrameSpinnerValueChanged(app)
                end
            end

            app.numDataPoints = size(app.UITable.Data);
            app.UITable.RowName = 1:app.numDataPoints;
        end

        % Button pushed function: CreateTXTFileButton
        function CreateTXTFileButtonPushed(app, event)
            fid = fopen(app.filename + ".txt", 'wt');
            fprintf(fid, '%s\n', app.columnNames(1));
            fprintf(fid, '%.4f\n', app.UITable.Data(:,1));
            fprintf(fid, '%s\n', app.columnNames(2));
            fprintf(fid, '%.4f\n', app.UITable.Data(:,2));
            fprintf(fid, '%s\n', app.columnNames(3));
            fprintf(fid, '%.4f\n', app.UITable.Data(:,3));
            fprintf(fid, '%s\n', app.columnNames(4));
            fprintf(fid, '%.4f\n', app.UITable.Data(:,4));
            fprintf(fid, '%s\n', app.columnNames(5));
            fprintf(fid, '%.4f\n', app.UITable.Data(:,5));
            fprintf(fid, 'Bad Frames\n');
            fprintf(fid, '%d\n', app.badFrames);
            fclose(fid);
        end

        % Button pushed function: VideoMontageButton
        function VideoMontageButtonPushed(app, event)
            app.fileType = 2;
            app.FrameSpinner.Enable = "on";
            [app.filename, app.pathname] = uigetfile('*.tif');
            [app.imgMat, ~, ~, app.numFrames] = stack2Mat([app.pathname,app.filename], app.frame);
            app.FrameSpinner.Limits = [1,app.numFrames];
            app.framesLabel.Text = "/" + string(app.numFrames);
            imshow(app.imgMat, [], 'parent', app.ImageAxes);
        end

        % Value changed function: FrameSpinner
        function FrameSpinnerValueChanged(app, event)
            app.frame = app.FrameSpinner.Value;
            app.imgMat = stack2Mat([app.pathname,app.filename], app.frame);
            imshow(app.imgMat, [], 'parent', app.ImageAxes);
            ThresholdValueSliderValueChanged(app)
        end

        % Button pushed function: PreviewButton
        function PreviewButtonPushed(app, event)
            if app.fileType == 1
                [~,~, app.spindleImage] = CurveFitData([app.pathname,app.filename], app.threshold, app.GOLfactor, app.GOLiter, app.objectNum, app.auto);
                imshow(app.spindleImage, [], 'parent', app.PreviewAxes_2)
            else
                [~,~, app.spindleImage] = CurveFitData([app.pathname,app.filename], app.threshold, app.GOLfactor, app.GOLiter, app.objectNum, app.auto, app.frame);
                imshow(app.spindleImage, [], 'parent', app.PreviewAxes_2)
            end
        end

        % Button pushed function: AnalyzeAllFramesButton
        function AnalyzeAllFramesButtonPushed(app, event)
            while app.frame <= app.numFrames && app.PauseAnalysisButton.Value == false
                AddFrameDataButtonPushed(app)
                if app.ToggleWaitButton.Value == true
                    pause(0.5)
                end
                if app.frame == app.numFrames
                    app.PauseAnalysisButton.Value = true;
                end
                if size(app.UITable.Data, 1)>1 && (abs(app.UITable.Data(app.frame-1, 2)-app.UITable.Data(app.frame-2, 2))/app.UITable.Data(end, 2))>0.15
                    app.PauseAnalysisButton.Value = true;
                    app.FrameSpinner.Value = app.FrameSpinner.Value-1;
                    app.FrameSpinnerValueChanged(app)
                    app.PreviewButtonPushed(app)
                end
            end
        end

        % Value changed function: GOLIterSpinner
        function GOLIterSpinnerValueChanged(app, event)
            app.GOLiter = app.GOLIterSpinner.Value;
            ThresholdValueSliderValueChanged(app)
        end

        % Button pushed function: TossDataButton
        function TossDataButtonPushed(app, event)
            app.badFrames = [app.badFrames; app.frame];
            app.AddFrameDataButtonPushed(app)
        end

        % Value changed function: ObjectSpinner
        function ObjectSpinnerValueChanged(app, event)
            app.objectNum = app.ObjectSpinner.Value;
            app.PreviewButtonPushed(app)
        end

        % Value changed function: AutoCheckBox
        function AutoCheckBoxValueChanged(app, event)
            app.auto = app.AutoCheckBox.Value;
            if app.auto
                app.ObjectSpinner.Enable = "off";
            else
                app.ObjectSpinner.Enable = "on";
            end
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {321, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 781 480];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {321, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create CreateTXTFileButton
            app.CreateTXTFileButton = uibutton(app.LeftPanel, 'push');
            app.CreateTXTFileButton.ButtonPushedFcn = createCallbackFcn(app, @CreateTXTFileButtonPushed, true);
            app.CreateTXTFileButton.FontWeight = 'bold';
            app.CreateTXTFileButton.Position = [176 17 105 22];
            app.CreateTXTFileButton.Text = 'Create .TXT File';

            % Create ThresholdValueSlider
            app.ThresholdValueSlider = uislider(app.LeftPanel);
            app.ThresholdValueSlider.Limits = [1 65535];
            app.ThresholdValueSlider.MajorTicks = [];
            app.ThresholdValueSlider.ValueChangedFcn = createCallbackFcn(app, @ThresholdValueSliderValueChanged, true);
            app.ThresholdValueSlider.Position = [45 357 231 3];
            app.ThresholdValueSlider.Value = 1;

            % Create ZstacksImagesButton
            app.ZstacksImagesButton = uibutton(app.LeftPanel, 'push');
            app.ZstacksImagesButton.ButtonPushedFcn = createCallbackFcn(app, @ZstacksImagesButtonPushed, true);
            app.ZstacksImagesButton.Position = [37 425 106 22];
            app.ZstacksImagesButton.Text = 'Z-stacks/Images';

            % Create ThresholdSpinnerLabel
            app.ThresholdSpinnerLabel = uilabel(app.LeftPanel);
            app.ThresholdSpinnerLabel.HorizontalAlignment = 'right';
            app.ThresholdSpinnerLabel.Position = [68 379 59 22];
            app.ThresholdSpinnerLabel.Text = 'Threshold';

            % Create ThresholdSpinner
            app.ThresholdSpinner = uispinner(app.LeftPanel);
            app.ThresholdSpinner.Step = 100;
            app.ThresholdSpinner.Limits = [0 65535];
            app.ThresholdSpinner.RoundFractionalValues = 'on';
            app.ThresholdSpinner.ValueChangedFcn = createCallbackFcn(app, @ThresholdSpinnerValueChanged, true);
            app.ThresholdSpinner.Position = [142 379 100 22];

            % Create GOLFactorSpinnerLabel
            app.GOLFactorSpinnerLabel = uilabel(app.LeftPanel);
            app.GOLFactorSpinnerLabel.HorizontalAlignment = 'right';
            app.GOLFactorSpinnerLabel.Position = [17 298 68 22];
            app.GOLFactorSpinnerLabel.Text = 'GOL Factor';

            % Create GOLFactorSpinner
            app.GOLFactorSpinner = uispinner(app.LeftPanel);
            app.GOLFactorSpinner.ValueChangedFcn = createCallbackFcn(app, @GOLFactorSpinnerValueChanged, true);
            app.GOLFactorSpinner.Position = [100 298 41 22];
            app.GOLFactorSpinner.Value = 4;

            % Create VideoMontageButton
            app.VideoMontageButton = uibutton(app.LeftPanel, 'push');
            app.VideoMontageButton.ButtonPushedFcn = createCallbackFcn(app, @VideoMontageButtonPushed, true);
            app.VideoMontageButton.Position = [170 425 106 22];
            app.VideoMontageButton.Text = 'Video/Montage';

            % Create FrameSpinnerLabel
            app.FrameSpinnerLabel = uilabel(app.LeftPanel);
            app.FrameSpinnerLabel.HorizontalAlignment = 'right';
            app.FrameSpinnerLabel.Position = [20 242 40 22];
            app.FrameSpinnerLabel.Text = 'Frame';

            % Create FrameSpinner
            app.FrameSpinner = uispinner(app.LeftPanel);
            app.FrameSpinner.ValueChangedFcn = createCallbackFcn(app, @FrameSpinnerValueChanged, true);
            app.FrameSpinner.Enable = 'off';
            app.FrameSpinner.Position = [75 242 100 22];
            app.FrameSpinner.Value = 1;

            % Create AddFrameDataButton
            app.AddFrameDataButton = uibutton(app.LeftPanel, 'push');
            app.AddFrameDataButton.ButtonPushedFcn = createCallbackFcn(app, @AddFrameDataButtonPushed, true);
            app.AddFrameDataButton.Position = [20 88 117 22];
            app.AddFrameDataButton.Text = 'Add Frame Data';

            % Create PreviewButton
            app.PreviewButton = uibutton(app.LeftPanel, 'push');
            app.PreviewButton.ButtonPushedFcn = createCallbackFcn(app, @PreviewButtonPushed, true);
            app.PreviewButton.Position = [20 119 117 22];
            app.PreviewButton.Text = 'Preview';

            % Create AnalyzeAllFramesButton
            app.AnalyzeAllFramesButton = uibutton(app.LeftPanel, 'push');
            app.AnalyzeAllFramesButton.ButtonPushedFcn = createCallbackFcn(app, @AnalyzeAllFramesButtonPushed, true);
            app.AnalyzeAllFramesButton.Position = [20 56 117 22];
            app.AnalyzeAllFramesButton.Text = 'Analyze All Frames';

            % Create PauseAnalysisButton
            app.PauseAnalysisButton = uibutton(app.LeftPanel, 'state');
            app.PauseAnalysisButton.Text = 'Pause Analysis';
            app.PauseAnalysisButton.Position = [176 56 103 54];

            % Create ToggleWaitButton
            app.ToggleWaitButton = uibutton(app.LeftPanel, 'state');
            app.ToggleWaitButton.Text = 'Toggle Wait';
            app.ToggleWaitButton.Position = [176 119 103 22];

            % Create framesLabel
            app.framesLabel = uilabel(app.LeftPanel);
            app.framesLabel.Position = [179 242 124 22];
            app.framesLabel.Text = '# frames';

            % Create GOLIterSpinnerLabel
            app.GOLIterSpinnerLabel = uilabel(app.LeftPanel);
            app.GOLIterSpinnerLabel.HorizontalAlignment = 'right';
            app.GOLIterSpinnerLabel.Position = [164 298 53 22];
            app.GOLIterSpinnerLabel.Text = 'GOL Iter.';

            % Create GOLIterSpinner
            app.GOLIterSpinner = uispinner(app.LeftPanel);
            app.GOLIterSpinner.Limits = [1 10];
            app.GOLIterSpinner.ValueChangedFcn = createCallbackFcn(app, @GOLIterSpinnerValueChanged, true);
            app.GOLIterSpinner.Position = [232 298 44 22];
            app.GOLIterSpinner.Value = 1;

            % Create TossDataButton
            app.TossDataButton = uibutton(app.LeftPanel, 'push');
            app.TossDataButton.ButtonPushedFcn = createCallbackFcn(app, @TossDataButtonPushed, true);
            app.TossDataButton.Position = [20 17 117 22];
            app.TossDataButton.Text = 'Toss Data';

            % Create ObjectSpinnerLabel
            app.ObjectSpinnerLabel = uilabel(app.LeftPanel);
            app.ObjectSpinnerLabel.HorizontalAlignment = 'right';
            app.ObjectSpinnerLabel.Enable = 'off';
            app.ObjectSpinnerLabel.Position = [15 200 51 22];
            app.ObjectSpinnerLabel.Text = 'Object #';

            % Create ObjectSpinner
            app.ObjectSpinner = uispinner(app.LeftPanel);
            app.ObjectSpinner.Limits = [1 Inf];
            app.ObjectSpinner.ValueChangedFcn = createCallbackFcn(app, @ObjectSpinnerValueChanged, true);
            app.ObjectSpinner.Enable = 'off';
            app.ObjectSpinner.Position = [81 200 100 22];
            app.ObjectSpinner.Value = 1;

            % Create AutoCheckBox
            app.AutoCheckBox = uicheckbox(app.LeftPanel);
            app.AutoCheckBox.ValueChangedFcn = createCallbackFcn(app, @AutoCheckBoxValueChanged, true);
            app.AutoCheckBox.Text = 'Auto';
            app.AutoCheckBox.Position = [192 200 47 22];
            app.AutoCheckBox.Value = true;

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.RightPanel);
            app.TabGroup.Position = [6 6 448 468];

            % Create ImagesTab
            app.ImagesTab = uitab(app.TabGroup);
            app.ImagesTab.Title = 'Images';

            % Create PreviewAxes
            app.PreviewAxes = uiaxes(app.ImagesTab);
            app.PreviewAxes.XTick = [];
            app.PreviewAxes.YTick = [];
            app.PreviewAxes.Position = [1 11 218 226];

            % Create ImageAxes
            app.ImageAxes = uiaxes(app.ImagesTab);
            app.ImageAxes.XTick = [];
            app.ImageAxes.YTick = [];
            app.ImageAxes.Position = [1 215 218 218];

            % Create PreviewAxes_2
            app.PreviewAxes_2 = uiaxes(app.ImagesTab);
            app.PreviewAxes_2.XTick = [];
            app.PreviewAxes_2.YTick = [];
            app.PreviewAxes_2.Position = [218 113 218 226];

            % Create DataTab
            app.DataTab = uitab(app.TabGroup);
            app.DataTab.Title = 'Data';

            % Create UITable
            app.UITable = uitable(app.DataTab);
            app.UITable.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable.RowName = {};
            app.UITable.Position = [14 11 423 422];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SpindleCurveApp_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end