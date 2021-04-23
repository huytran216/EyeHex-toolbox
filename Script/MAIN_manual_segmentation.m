function MAIN_manual_segmentation(raw_image)
    %% If no file entered then load:
    if ~exist('raw_image','var')
        raw_image=uigetfile('../data/raw/*.tif','Select the image(s) to process','MultiSelect','off');
    end
    if ~raw_image
        return;
    end
    %% Load image and Setup global variables
    [~,fld_name] = fileparts(raw_image);
    % Set empty data shells
    xy_pos = [];
    I_sub = [];
    xy_idx = [];
    
    % Define index for segmentation patches
    crr_patch_idx = 0;      % Idx of the latest patch
    map_patch_idx = [];     % Patch index for each facets
    valid_patch_idx = [];   % Which index is valid (not deleted)
    color_patch_idx = rand(20,3);   % color map
    
    % Create images of 3 circles in grids
    grid_size = 10; % default grid size
    [I_circle,x0,y0,I_edge] = create_I_circle(grid_size,0.7);
    maxIcircle = max(I_circle(:));
    
    % Offset for xy coordinate
    offset = 100;
    % Save data tip
    save('tmp_datatip.mat','xy_pos','xy_idx');
    
    xy_select=[];
    crr_deletelevel = 0;
    crr_addlevel = 1;
    first_refreshed = true;
    %% Load raw image and probability image
    I_ori = imread(['../data/raw/' raw_image]); % Uint8
    I = I_ori;
    if size(I,3)==1
        % Make color image
        I = cat(3,I,I,I);
    end
    I_probs = mean(I(:,:,:),3);
    I = imresize(I,size(I_probs));
    fmain=figure('Visible','on');
    axmain = gca;
    viewmode = 2;                               % Show everything first
    I_border_auto = zeros(size(I,1),size(I,2)); % Border generated automatically    
    I_facet_auto = zeros(size(I,1),size(I,2));  % Facet mask generated automatically
    I_inout = zeros(size(I,1),size(I,2))+2;     % Inside region mask, positive (in) and negative (out)
    %% Set behavior:
    refreshed();
    hManager = uigetmodemanager(fmain);
    try
        set(hManager.WindowListenerHandles, 'Enable', 'off');  % HG1
    catch
        [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2
    end
    set(fmain, 'WindowKeyPressFcn', []);
    set(fmain, 'KeyPressFcn', @(hobj,evnt) keypress(hobj,evnt));
    set(fmain, 'CloseRequestFcn', @CloseReqFcn);
    set(fmain,'Visible','on')
    
    
    
    % set data (for mouse pan)
    self= struct;
    self.altpresstimer= [];
    self.altpresspos= [];
	self.zoomenabled= false;
	self.zoomratio= 1/4;
    self.dragging= 0; % 0 = mouse not down; 1 = mouse down; 2 = mouse down and dragging a point
	self.window= fmain;
    self.imagesize= size(I);
    self.points1= zeros(2,0);
    self.points2= zeros(2,0);
    self.impoints= [];
    self.registeredmode= true;
    self.axes= gca;
    self.image= I;
    self.ignoreNewPos= false;
    self.done= false;
    
    set(fmain,'UserData', self, ...
		'WindowButtonDownFcn', @mousePressed_, ...
        'WindowButtonUpFcn', @mouseReleased_, ...
        'WindowButtonMotionFcn', @mouseMotion_,...
        'Interruptible', 'off');
    %% Show the data:
    function refreshed()
        viewmode
        % Different view modes:
            % viewmode = 0: show raw image only + added points
            % viewmode = 1: show raw image only
            % viewmode = 2 (default): show raw image + added points + mask
        
        if ~first_refreshed
            L = get(gca,{'xlim','ylim'});
        end
        hold off;
        
        Itmp = I;
        
        I_facet_tmp = I_facet_auto*0;
        I_border_tmp = I_border_auto*0;
        
        for i=1:crr_patch_idx
            if (viewmode~=1)
                if valid_patch_idx(i)
                    % Draw picture
                    I_facet_tmp = I_facet_tmp | (I_facet_auto==i);
                    I_border_tmp = I_border_tmp | (I_border_auto==i);
                end
            end
        end
        
        % Show inout image
        if viewmode==2
            Itmp1 = Itmp(:,:,3);Itmp1(I_inout==0) = 1; Itmp(:,:,3) = Itmp1;
            Itmp1 = Itmp(:,:,1);Itmp1(I_inout==1) = 1; Itmp(:,:,1) = Itmp1;
        end
        % Show border image
        Itmp = bsxfun(@times, Itmp, cast(~I_border_tmp, 'like', Itmp));
        
        imshow(Itmp,'Parent',axmain);
        hold on;

        for i=1:crr_patch_idx
            idselect = (map_patch_idx == i);
            color = color_patch_idx(mod(i,size(color_patch_idx,1))+1,:);
            if (viewmode~=1)
                % Draw data points
                if valid_patch_idx(i)
                    scatter(xy_pos(idselect,2),xy_pos(idselect,1),120,'Marker','o','MarkerEdgeColor','r','MarkerFaceColor',color,'Parent',axmain); hold on;
                else
                    scatter(xy_pos(idselect,2),xy_pos(idselect,1),100,'Marker','.','MarkerEdgeColor','r','MarkerFaceColor',color,'Parent',axmain); hold on;
                end
            end
        end
        
        if ~first_refreshed
            set(gca,{'xlim','ylim'},L);
        end
        
        dcm_obj = datacursormode(fmain);
        set(dcm_obj,'UpdateFcn',@NewCallback_axes);

        first_refreshed = false;
        title(['Number of patches:' num2str(sum(valid_patch_idx>0))]);
        drawnow;
    end
    %% Remove odd hexagon if needed
    function rm_region()
        title('Select region to remove ommatidia');
        drawnow;
        % Select a free region
        roi = imfreehand(axmain);
        %try
            bw = createMask(roi);
            for i=1:size(xy_pos,1)
                % Look for cells in this removed region
                if (round(xy_pos(i,1))<=size(bw,1))&((round(xy_pos(i,2))<=size(bw,2)))&(round(xy_pos(i,1))>0)&(round(xy_pos(i,2))>0)
                    if bw(round(xy_pos(i,1)),round(xy_pos(i,2)))
                        valid_patch_idx(map_patch_idx(i))=0;
                    end
                end
            end
        refreshed();
    end
    %% add new cells
    function add_region()
        % Set title
        title('Select adjacement ommatidia. Press Enter to register inputs');
        drawnow;
        % Select a free region
        [xi,yi] = getpts(axmain);
        if numel(xi)
            xy_pos(end+1:end+numel(xi),:)=[yi xi];
            xy_select(end+1:end+numel(xi))=2;
            crr_patch_idx = crr_patch_idx + 1;       % Idx of the latest patch
            map_patch_idx(end+1:end+numel(xi)) = crr_patch_idx;    % Patch index
            valid_patch_idx(crr_patch_idx)=1;
            remap_coordinate_after_alignment(crr_patch_idx);
            refreshed();
        end
    end
%% Add inside region
    function add_inout_region(isin)
        switch isin
            case 0
                title('Select region inside the eye');
            case 1
                title('Select region outside the eye');
            case 2
                title('Select an inside/outside region to remove');
        end
        drawnow;
        % Select a free region
        roi = imfreehand(axmain);
        bw = createMask(roi);
        switch isin
            case 0
                I_inout(bw) = 0;
            case 1
                I_inout(bw) = 1;
            case 2
                I_inout(bw) = 2;
        end
        refreshed();
    end
%% Get label from parameters
    function [I_facet_auto,I_border_auto]=get_label(xy_select,offset,xy_idx,xy_pos)
        % Select automatically added mask
        idselect = find(~isnan(xy_select));
        % export facets mask and border
            I_facet_auto = zeros(size(I,1),size(I,2));
            I_border_auto = zeros(size(I,1),size(I,2));
            xymap = zeros(offset*2, offset*2);
            for i=1:size(xy_idx,1)
                xymap(offset+xy_idx(i,1),offset+xy_idx(i,2))=i;
            end
            for i=idselect(:)'
                parent_i = [xymap(offset+xy_idx(i,1)+1,offset+xy_idx(i,2)) ...
                    xymap(offset+xy_idx(i,1),offset+xy_idx(i,2)+1); ...
                    xymap(offset+xy_idx(i,1)-1,offset+xy_idx(i,2)) ...
                    xymap(offset+xy_idx(i,1),offset+xy_idx(i,2)-1)];
                for j=1:2
                    if any(idselect == parent_i(j,1)) && any(idselect == parent_i(j,2))
                        % Coordinate for current cell and parent cells
                        xy = [xy_pos(i,1) xy_pos(parent_i(j,1),1) xy_pos(parent_i(j,2),1) ...
                                xy_pos(i,2) xy_pos(parent_i(j,1),2) xy_pos(parent_i(j,2),2) 1];
                        [~,~,~,I_out_facet,I_out_edge] = transform_I_([x0 y0],xy,I_circle,size(I_facet_auto),I_edge);
                        I_facet_auto = I_facet_auto + (I_out_facet>maxIcircle*0.7);
                        I_border_auto = I_border_auto + (I_out_edge>maxIcircle*0.7);
                    end
                end
            end
            I_facet_auto = I_facet_auto>0;
            % Make line thicker
                linewidth = 2;
                xy_conv = ones(linewidth,linewidth);
                I_border_auto = conv2(double(I_border_auto),xy_conv,'same');
                I_border_auto = I_border_auto(1:size(I,1),1:size(I,2))>0;
                I_facet_auto = conv2(double(I_facet_auto),xy_conv,'same');
                I_facet_auto = I_facet_auto(1:size(I,1),1:size(I,2))>0;
                I_facet_auto(I_border_auto)=0;
    end
    %% Export remapped label
    function export_label()
        if ~numel(xy_pos)
            msgbox('Please mask something');
            return;
        end
        % Redo label:
        I_facet_auto = I_facet_auto*0;
        I_border_auto = I_border_auto*0;
                for i=1:crr_patch_idx
                    if valid_patch_idx(i)
                        remap_coordinate_after_alignment(i);
                    end
                end
        % Label realigned mask
                I_facet_tmp = I_facet_auto*0;
                I_border_tmp = I_border_auto*0;

                for i=1:crr_patch_idx
                    if valid_patch_idx(i)
                        % Draw picture
                        I_facet_tmp = I_facet_tmp | (I_facet_auto==i);
                        I_border_tmp = I_border_tmp | (I_border_auto==i);
                    end
                end
        
            % Export omatidia's borders and facets
                % Export for weka classifier
                mkdir('../data/training_raw');
                imwrite(I_ori,fullfile('../data/training_raw/',[fld_name '.tif']),'WriteMode','overwrite','Compression','none');
                Iouttmp = uint8(I_facet_tmp<0)+2;
                Iouttmp(I_facet_tmp)=0;
                Iouttmp(I_border_tmp)=1;
                mkdir('../data/training_label');
                imwrite(Iouttmp,fullfile('../data/training_label/',[fld_name '.tif']),'WriteMode','overwrite','Compression','none');
                if any(I_inout(:)~=2)
                    imwrite(uint8(I_inout),fullfile('../data/training_label/',[fld_name '_inout.tif']),'WriteMode','overwrite','Compression','none');
                end
            % Refresh screen:    
                refreshed();
                msgbox('Label exported');
            % Prepare probability_map folder
                mkdir('../data/probability_map');
    end
    %% Remap everything:
    function xy_idx_new = remap_coordinate_after_alignment(crr_patch_idx)
        title('Remaping coordinate on hexagonal grid...');
        drawnow;
        % Select all valid mask
            idselect = find(map_patch_idx == crr_patch_idx);
            xy_idx(idselect(1),:) = [0 0];
            xy_idx(idselect(2),:) = [1 0];
            xy_idx(idselect(3),:) = [0 1];
            % calculate average grid_size:
            grid_size_ = (sqrt(sum((xy_pos(idselect(1),:) - xy_pos(idselect(2),:)).^2)) ...
             + sqrt(sum((xy_pos(idselect(3),:) - xy_pos(idselect(1),:)).^2)) ...
             + sqrt(sum((xy_pos(idselect(3),:) - xy_pos(idselect(2),:)).^2)))/6;
            [xy_idx_new,~] = remap_coordinate(xy_pos(idselect,:),xy_idx(idselect(1:3),:),size(I),grid_size_);
            xy_idx(idselect,:) = xy_idx_new;
        % Create label:
            [I_facet_tmp,I_border_tmp] = get_label(xy_select(idselect),offset,xy_idx(idselect,:),xy_pos(idselect,:));
            I_facet_auto(I_facet_tmp)=crr_patch_idx;
            I_border_auto(I_border_tmp)=crr_patch_idx;
    end
    %% Save progress:
    function save_progress()
        mkdir('tmp',fld_name);
        save(fullfile('tmp',fld_name,'saveprogress_manual.mat'),...
            'xy_pos','xy_select',...
            'map_patch_idx','crr_patch_idx','valid_patch_idx',...
            'I_inout',...
            'I_facet_auto','I_border_auto');
    end
    %% set hotkey:
    function keypress(~, eventdata, ~)
        switch eventdata.Key
            case 'm'
                viewmode = mod(viewmode + 1,3);
                refreshed();
            case 'r'
                rm_region();
            case 'a'
                % add new cells
                add_region();
            case 'i'
                % add inside eye region
                add_inout_region(0);
            case 'o'
                % add outside eye region
                add_inout_region(1);
            case 'p'
                % remove inside/outside region
                add_inout_region(2);
            case 'e'
                if strcmp(eventdata.Modifier,'control')
                    export_label();
                end
            case 'h'
                % save progress
                if strcmp(eventdata.Modifier,'control')
                    save_progress();
                    refreshed();
                    msgbox('Save successfully');
                end
            case 'l'
                % load progress
                try
                    if strcmp(eventdata.Modifier,'control')
                        load(fullfile('tmp',fld_name,'saveprogress_manual.mat'),...
                            'xy_pos','xy_select',...
                            'map_patch_idx','crr_patch_idx','valid_patch_idx',...
                            'crr_inout_idx','valid_inout_idx','I_inout',...
                            'I_facet_auto','I_border_auto');
                        refreshed();
                    end
                catch
                    msgbox('No data found');
                end
            % Reset zoom
            case 'q'
                first_refreshed=true;
                refreshed();
            case 'f1'
                msgbox({'----  HOTKEY  ---- '; ...
                    'Navigating:';...
                    '   M: toogle views';...
                    '   Right click: Zoom in/navigating while zooming:'
                    '   Arrow keys: navigating while zooming';...
                    '   Q: reset zooming';...
                    'Editing:';...
                    '   R: remove facets in selected region';...
                    '   A: add facets';...
                    '   I: mark region inside the eye';... 
                    '   O: mark region outside the eye';... 
                    'Save load progress:';...
                    '   Ctrl+H: save progress';...
                    '   Ctrl+L: load progress';...
                    'Export:';...
                    '   Ctrl+E: export labels';...
                    },'Help','modal');
        end
        if strfind(eventdata.Key,'arrow')
            xax = get(gca,'xlim');
            yax = get(gca,'ylim');
            xlen = abs(diff(xax));
            ylen = abs(diff(yax));
            switch eventdata.Key
                case 'uparrow'
                    xax_new = xax;
                    yax_new = yax-ylen/5;
                case 'downarrow'
                    xax_new = xax;
                    yax_new = yax+ylen/5;
                case 'leftarrow'
                    xax_new = xax-xlen/5;
                    yax_new = yax;
                case 'rightarrow'
                    xax_new = xax+xlen/5;
                    yax_new = yax;
            end
            if xax_new(1)<0
                xax_new =[0 xlen];
            end
            if yax_new(1)<0
                yax_new =[0 ylen]; 
            end
            if xax_new(2)>size(I,2)
                xax_new =[size(I,2)-xlen size(I,2)]; 
            end
            if yax_new(2)>size(I,1)
                yax_new =[size(I,1)-ylen size(I,1)]; 
            end
            set(gca,'xlim',xax_new);
            set(gca,'ylim',yax_new);
        end
    end
    %% Upon close: ask to save figures:
    function [] = CloseReqFcn(~,~)
        if crr_patch_idx~=0
            answer = questdlg('Save progress before exiting?','Closing figure','Yes','No','Cancel','Cancel');
        else
            % no changes, no saving
            delete(gcf);
            return;
        end
        switch answer
            case 'Yes'
                save_progress();
                refreshed();
                delete(gcf);
            case 'No'
                delete(gcf);
        end        
    end
    %% Right click to zoom in and pan:
    function mousePressed_(window, ~)
        %% get point clicked
        point= mean(get(findobj(window, 'Type', 'axes'), 'CurrentPoint'), 1);
        %% get button
        self= get(window, 'UserData');
        switch get(window, 'SelectionType')
            case 'normal'
                self.dragging= 1;
                set(window, 'UserData', self);
            case 'alt'
                if ~self.zoomenabled
                    self.altpresstimer= [];
                    set(window, 'UserData', self);
                    toggleZoom_(window);
                else
                    self.altpresstimer= tic;
                    self.altpresspos= point;
                    set(window, 'UserData', self);
                end
        end
    end

    function mouseReleased_(window, ~)
        %% stop panning when zoomed in
        self= get(window, 'UserData');
        % get button
        switch get(window, 'SelectionType')
            case 'normal'
                dragging= self.dragging;
                self.dragging= 0;
                set(window, 'UserData', self);
                if dragging == 2
                    updateRegistration_(window);
                end
            case 'alt'
                if ~isempty(self.altpresstimer) || ~isempty(self.altpresspos)
                    self.altpresspos= [];
                    if ~isempty(self.altpresstimer)
                        self.altpresstimer= [];
                        set(window, 'UserData', self);
                        toggleZoom_(window);
                    else
                        set(window, 'UserData', self);
                    end
                end
        end
    end

    function mouseMotion_(window, ~)
        %% allow panning when zoomed in
        self= get(window, 'UserData');
        if ~isempty(self.altpresspos)
            % get point moved to
            ax= findobj(window, 'Type', 'axes');
            point= mean(get(ax, 'CurrentPoint'), 1);
            delta= point - self.altpresspos;
            xlim= get(ax, 'XLim');
            ylim= get(ax, 'YLim');
            point2= 0.5*[sum(xlim) sum(ylim) 0] - delta;
            updateZoom_(window, point2);
            if ~isempty(self.altpresstimer)
                self.altpresstimer= [];
                set(window, 'UserData', self);
            end
        end
    end

    function toggleZoom_(window)
        %% get cookie
        self= get(window, 'UserData');
        %% check if zoom is installed
        if self.zoomenabled
            %% it is, so disable disable zoom
            self.zoomenabled= false;
            %% and reset viewport
            img= get(self.image, 'CData');
            imagesize= [size(img,1), size(img,2)];
            set(self.axes, ...
                'XLim', .5 + [0, imagesize(2)], 'YLim', .5 + [0, imagesize(1)]);
        else
            %% it's not, so enable zoom
            self.zoomenabled= true;
            %% update zoom
            updateZoom_(window);
        end
        set(window, 'UserData', self);
    end

    function updateZoom_(window, point)
        %% get cookie
        self= get(window, 'UserData');
        %% get mouse location
        if nargin < 2 || isempty(point)
            point= mean(get(findobj(window, 'Type', 'axes'), 'CurrentPoint'), 1);
        end
        pos= point([2, 1]);
        %% compute new viewport
        img= self.image;
        imagesize= [size(img,1), size(img,2)];
        viewsize= imagesize .* self.zoomratio;
        viewlo= min(max(1, pos - .5 * viewsize), imagesize - viewsize);
        viewhi= viewlo + viewsize;
        %% set viewport
        set(self.axes, ...
            'XLim', -.5 + [viewlo(2), viewhi(2)], 'YLim', .5 + [viewlo(1), viewhi(1)]);
    end
end