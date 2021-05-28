function MAIN_manual_correction(raw_image)
    %% If no file entered then load:
    if ~exist('raw_image','var')
        raw_image=uigetfile('../data/raw/*.tif','Select the image(s) to process','MultiSelect','off');
    end
    if ~raw_image
        return;
    end
    %% Setup global variables:
    [~,fld_name] = fileparts(raw_image);
    listing = dir(fullfile('tmp',fld_name,['dat_probmap*.mat']));
    dat_probmap_list = [];
    for fidx = 1:numel(listing)
        if numel(listing(fidx).name>0)
            if get_num_from_string(listing(fidx).name)>0
                dat_probmap_list = [dat_probmap_list get_num_from_string(listing(fidx).name)];
            end
        end
    end
    dat_probmap_list = sort(dat_probmap_list);
    % Global variable:
    xy_pos = [];
    xy_idx = [];
    parent_idx = [];
    grid_size = 0;
    [I_circle,x0,y0,I_edge] = create_I_circle(10,0.7);  % default grid_size = 10
    maxIcircle = max(I_circle(:));
    score = [];
    % Offset for xy coordinate
    offset = 100;
    % Data used after alignment
    xy_pos_aligned = [];
    parent_idx_aligned = [];
    xy_idx_aligned = [];
    % Set delete level:
    xy_select=[];
    crr_deletelevel = 0;
    first_refreshed = true;
    % Load the latest data:
    latest_minus = 0;
    %% Load the latest data:
    load_data();    
    %% Load raw image and probability image
    I = imread(['../data/raw/' raw_image]); % Uint8
    I_alt = I; alt_name = ''; show_alt = false;
    I_probs = imread(['../data/probability_map/' raw_image]);
    I = imresize(I,size(I_probs));
    fmain=figure('Visible','on');
    axmain = gca;
    viewmode = 0;
    I_border_auto = [];  % Border generated automatically    
    I_facet_manual = []; % Facet label generated manually
    I_facet_auto = [];   % Facet mask generated automatically
    I_label_auto = [];   % Label mask (facet + border) generated automatically
    
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
    %% Load the data
    function load_data()
        if latest_minus<0
            latest_minus=0;
        end
        if latest_minus>numel(dat_probmap_list)
            latest_minus=numel(dat_probmap_list);
        end
        % Load the latest data:
        if numel(dat_probmap_list)
            fload = dat_probmap_list(end-latest_minus);
            datfile = load(fullfile('tmp',fld_name,['dat_probmap' num2str(fload)]),'xy_pos','grid_size','xy_idx','parent_idx','score','xymap');
        else
            msgbox('No data found. Do hexagon expansion first');
        end
        if numel(datfile)
            % Data loaded pre alignment
            xy_pos = datfile.xy_pos;
            xy_idx = datfile.xy_idx;
            parent_idx = datfile.parent_idx;
            grid_size = datfile.grid_size;
            [I_circle,x0,y0,I_edge] = create_I_circle(10,0.7);  % default grid_size = 10
            maxIcircle = max(I_circle(:));
            score = datfile.score;
        end
        % Offset for xy coordinate
        offset = 100;
        % Data used after alignment
            xy_pos_aligned = [];
            parent_idx_aligned = [];
            xy_idx_aligned = [];
        % Save data tip
        save('tmp_datatip.mat','xy_pos','xy_idx');
        % Reset delete level:
        xy_select=xy_pos(:,1)*0+1;
        crr_deletelevel = 0;
        first_refreshed = true;
    end
    load_alt_img(1);
    function load_alt_img(modifier)
        if ~exist('modifier','var')
            I_alt = I;
            alt_name = '';
            return;
        end
        % Find file in raw_stack folder:
        listing_tmp = dir(fullfile('../data/raw_stack',[fld_name '_*.tif']));
        if numel(listing_tmp)
            for i=1:numel(listing_tmp)
                if strcmp(listing_tmp(i).name,alt_name)
                    break;
                end
            end
            i = i + modifier;
            if i>numel(listing_tmp)
                i = numel(listing_tmp);
            end
            if i<1
                i = 1;
            end
            alt_name = listing_tmp(i).name;
            I_alt = imread(fullfile('../data/raw_stack/',alt_name));
        end
    end
    %% Show the data:
    function refreshed()
        if ~first_refreshed
            L = get(gca,{'xlim','ylim'});
        end
        hold off;
        if show_alt
            I_show = I_alt;
        else
            I_show = I;
        end
        if (viewmode<2)
            imshow(I_show,'Parent',axmain);hold on;
        else
            imshow(I_probs,'Parent',axmain);hold on;
        end
        
        if ~first_refreshed
            set(gca,{'xlim','ylim'},L);
        end
        idselect = (xy_select>0)|((xy_select<crr_deletelevel));
        
        % Plot predicted facets (g), added facets (r), removed facets (x)
        
        if (mod(viewmode,2) == 0)
            splot = [];
            scatter(xy_pos(1,2),xy_pos(1,1),140,'Marker','o','LineWidth',3,'MarkerEdgeColor',[1 0 1],'MarkerFaceColor','g','Parent',axmain);
            scatter(xy_pos([2 3],2),xy_pos([2 3],1),120,'Marker','o','LineWidth',3,'MarkerEdgeColor',[1 0 1],'MarkerFaceColor','g','Parent',axmain);
            scatter(xy_pos(xy_select==2,2),xy_pos(xy_select==2,1),120,'Marker','o','MarkerEdgeColor','r','MarkerFaceColor','r','Parent',axmain);
            scatter(xy_pos(~idselect,2),xy_pos(~idselect,1),50,'Marker','.','MarkerEdgeColor','r','MarkerFaceColor','r','Parent',axmain);
            splot = scatter(xy_pos(xy_select==1,2),xy_pos(xy_select==1,1),100,'Marker','o','MarkerEdgeColor','r','MarkerFaceColor','g','Parent',axmain);
        end
        
        dcm_obj = datacursormode(fmain);
        set(dcm_obj,'UpdateFcn',@NewCallback_axes);

        first_refreshed = false;
        
        strmessage = [];
        if show_alt
            strmessage = [strmessage 'Stack: ' alt_name '. '];
        end
        strmessage = [strmessage  num2str(sum(idselect)) 'eyes found'];
        title(strmessage,'Interpreter','none');
        
        save('tmp_datatip.mat','xy_pos','xy_idx');
    end
    %% Remove odd hexagon if needed
    function rm_region()
        % Update title:
        title('Select region to remove ommatidia');
        drawnow;
        % Select a free region
        roi = imfreehand(axmain);
        %try
            bw = createMask(roi);
            shappen = false;
            for i=1:size(xy_pos,1)
                if (round(xy_pos(i,1))<=size(bw,1))&((round(xy_pos(i,2))<=size(bw,2)))&(round(xy_pos(i,1))>0)&(round(xy_pos(i,2))>0)
                    if bw(round(xy_pos(i,1)),round(xy_pos(i,2)))
                        if ~shappen
                            crr_deletelevel = crr_deletelevel-1;
                            shappen = true;
                        end
                        xy_select(i)=crr_deletelevel;
                    end
                else
                    xy_select(i)=0;
                end
            end
            if shappen
                xy_select(xy_select<crr_deletelevel)=crr_deletelevel;
            end
            refreshed();
        %catch
        %end
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
            refreshed();
        end
    end
    %% Generate manual labels:
    function get_manual_mask()
        % Select manually added mask - only for nuclei
        idselect = find((xy_select==2)|((xy_select<crr_deletelevel)));
        I_facet_manual = I*0;
        for i = idselect(:)'
            I_facet_manual=filledcircle(grid_size*0.3,xy_pos(i,1),xy_pos(i,2),I_facet_manual,1);
        end
        I_facet_manual=I_facet_manual>0;
    end
    %% Get label from parameters
    function [I_facet_auto,I_border_auto]=get_label(idselect,offset,xy_idx,xy_pos)
        % Select automatically added mask
        totalstep  = 10;
        crrstep = 1;
        f = waitbar(crrstep/totalstep,'Exporting mask');
        % export facets mask and border
            I_facet_auto = zeros(size(I,1),size(I,2));
            I_border_auto = zeros(size(I,1),size(I,2));
            I_score_auto = zeros(size(I,1),size(I,2));
            xymap = zeros(offset*2, offset*2);
            for i=1:size(xy_idx,1)
                if ~isnan(xy_idx(i,1))
                    xymap(offset+xy_idx(i,1),offset+xy_idx(i,2))=i;
                end
            end
            for i=idselect(:)'
                if isnan(xy_idx(i,1))
                    display(['Skip: ' num2str(i)]);
                    continue;
                end
                parent_i = [xymap(offset+xy_idx(i,1)+1,offset+xy_idx(i,2)) ...
                    xymap(offset+xy_idx(i,1),offset+xy_idx(i,2)+1); ...
                    xymap(offset+xy_idx(i,1)-1,offset+xy_idx(i,2)) ...
                    xymap(offset+xy_idx(i,1),offset+xy_idx(i,2)-1)];
                waitbar(ceil(i/numel(idselect)*totalstep)/totalstep,f,'Exporting mask');
                for j=1:2
                    if any(idselect == parent_i(j,1)) && any(idselect == parent_i(j,2))
                        % Coordinate for current cell and parent cells
                        xy = [xy_pos(i,1) xy_pos(parent_i(j,1),1) xy_pos(parent_i(j,2),1) ...
                                xy_pos(i,2) xy_pos(parent_i(j,1),2) xy_pos(parent_i(j,2),2) 1];
                        [~,~,~,I_out_facet,I_out_edge] = transform_I([x0 y0],xy,I_circle,size(I_facet_auto),I_edge);
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
            % Close progress bar
                close(f);
    end
    %% Export labels:
    function export_label(msg)
        % Update title
        title('Remaping coordinate on hexagonal grid...');
        drawnow;
        % Make manual mask
        get_manual_mask;
        % Remap first, from automated one only
        idselect = find((xy_select>0)|(xy_select<crr_deletelevel));
        [xy_idx_,~] = remap_coordinate(xy_pos(idselect,:),xy_idx(1:3,:),size(I),grid_size);
        xy_idx(idselect,:)=xy_idx_;
        % Create label:
        idselect = find((xy_select==1)|(xy_select<crr_deletelevel));
        [I_facet_auto,I_border_auto]=get_label(idselect,offset,xy_idx,xy_pos);
        
            % Write omatidia's borders and facets
                I_label_auto = uint8(I_facet_auto);
                I_label_auto(I_border_auto)=2;
                
                Iouttmp = uint8(I_facet_auto<0)+2;
                Iouttmp(I_facet_auto)=0;
                Iouttmp(I_border_auto)=1;
                
                mkdir('../data/output_label');
                imwrite(Iouttmp,fullfile('../data/output_label/',[fld_name '.tif']),'WriteMode','overwrite','Compression','none');
                export_csv(xy_select,xy_idx,xy_pos);
                refreshed();
            % Close figure
                if nargin==0
                    msgbox('Successful');
                end
    end
    %% Export remapped label
    function export_label_realigned(msg)
        idselect = find((xy_select>0)|(xy_select<crr_deletelevel));
        % Label realigned mask
                [I_facet_auto,I_border_auto]=get_label(idselect,offset,xy_idx_aligned,xy_pos_aligned);
                I_facet_auto_ = I_facet_auto;
                I_border_auto_ = I_border_auto;
            % Make huge non-eye layer (not used for now)
                %I_non_eye = ~conv2(double(I_facet_auto_ | I_border_auto_),ones(30,30),'same');
            
            % Export omatidia's borders and facets
                % Export for weka classifier
                mkdir('../data/output_label');
                Iouttmp = uint8(I_facet_auto_<0)+2;
                Iouttmp(I_facet_auto_)=0;
                Iouttmp(I_border_auto_)=1;
                imwrite(Iouttmp,fullfile('../data/output_label/',[fld_name '.tif']),'WriteMode','overwrite','Compression','none');
                export_csv(xy_select,xy_idx_aligned,xy_pos_aligned);
                % Save to training folder if needed
                answer = questdlg('Save the aligned label and raw image to the training folder?','Next step','Yes','No','No');
                if strcmp(answer,'Yes')
                    mkdir('../data/training_label');
                    imwrite(Iouttmp,fullfile('../data/training_label/',[fld_name '.tif']),'WriteMode','overwrite','Compression','none');
                    mkdir('../data/training_raw');
                    imwrite(I,fullfile('../data/training_raw/',[fld_name '.tif']),'WriteMode','overwrite','Compression','none');
                end
                refreshed();
    end
    %% Align label:
    function [] = align_label()
        if ~numel(I_facet_auto)
            export_label('align');
        end
        datapts_location = fullfile('tmp',fld_name,'aligned_pts.mat');
        
        if exist(datapts_location,'file')
            load(datapts_location,'datapts');
            [Iout,datapts] = aligngui({I_label_auto,xy_pos},(I_facet_auto>0)+(I_border_auto>0)*0.5,I,datapts);
        else
            [Iout,datapts] = aligngui({I_label_auto,xy_pos},(I_facet_auto>0)+(I_border_auto>0)*0.5,I);
        end
        save(datapts_location,'datapts');
        
        % Select manually added mask and not align
            xy_pos_aligned = Iout{2};
            idselect = find((xy_select==2));
            xy_pos_aligned(idselect,:) = xy_pos(idselect,:);
        % Remap everything after alignment (automatic + manual)
            %answer = questdlg('Proceed with remapping and generating new aligned label?','Next step','Yes','No','Cancel','Cancel');
            answer = 'Yes';
            if strcmp(answer,'Yes')
                remap_coordinate_after_alignment;
                export_label_realigned;
            end
    end
    %% Remap everything:
    function [] = remap_coordinate_after_alignment()
        % title update
        title('Remaping coordinate on hexagonal grid...');
        drawnow;
        % Select all valid mask
            idselect = find((xy_select>0)|(xy_select<crr_deletelevel));
            [xy_idx_aligned_,~] = remap_coordinate(xy_pos_aligned(idselect,:),xy_idx(1:3,:),size(I),grid_size);
            xy_idx_aligned = xy_idx*0;
            xy_idx_aligned(idselect,:)=xy_idx_aligned_;
    end
    function [] = export_csv(xy_select,xy_pos,xy_idx)
        idselect = find((xy_select>0)|((xy_select<crr_deletelevel)));
        datamat = [xy_pos(idselect,:) xy_idx(idselect,:)];
        mkdir('../data/output_csv');
        dlmwrite(fullfile('../data/output_csv',[fld_name '.csv']),datamat,'\t');
    end
    %% set hotkey:
    function keypress(~, eventdata, ~)
        switch eventdata.Key
            case 'm'
                viewmode = mod(viewmode + 1,4);
                refreshed();
            case 'r'
                rm_region();
            case 'z'
                % undo
                if crr_deletelevel<0
                    crr_deletelevel=crr_deletelevel+1;
                    refreshed();
                end
            case 'x'
                % redo
                if crr_deletelevel>min(xy_select)
                    crr_deletelevel=crr_deletelevel-1;
                    refreshed();
                end
            case 'a'
                % add new cells
                add_region();
            case 'e'
                if strcmp(eventdata.Modifier,'control')
                    export_label();
                end
            case 'i'
                if strcmp(eventdata.Modifier,'control')
                    align_label();
                end
            case 'h'
                % save progress
                if strcmp(eventdata.Modifier,'control')
                    if exist(fullfile('tmp',fld_name,'saveprogress.mat'),'file')
                        if strcmp(questdlg('Overwrite progress?','Overwrite','Yes','No','No'),'Yes')
                            mkdir(fullfile('tmp',fld_name));
                            save(fullfile('tmp',fld_name,'saveprogress.mat'),'xy_pos','xy_select','crr_deletelevel');
                            refreshed();
                            msgbox('Save successfully');
                        end
                    else
                        mkdir(fullfile('tmp',fld_name));
                        save(fullfile('tmp',fld_name,'saveprogress.mat'),'xy_pos','xy_select','crr_deletelevel');
                        refreshed();
                        msgbox('Save successfully');
                    end
                end
            case 'l'
                % load progress
                try
                    if strcmp(eventdata.Modifier,'control')
                        load(fullfile('tmp',fld_name,'saveprogress.mat'),'xy_pos','xy_select','crr_deletelevel');
                        refreshed();
                    end
                catch
                    msgbox('No data found');
                end
            % Reset zoom
            case 'q'
                first_refreshed = 1;
                refreshed();
            case 'f1'
                msgbox({'-----   HOTKEY   -----'; ...
                    'Navigating:';...
                    '   M: toogle views';...
                    '   Right click: Zoom in/navigating while zooming:'
                    '   Arrow keys: navigating while zooming';...
                    '   Q: reset zooming';...
                    'Editing:';...
                    '   R: remove facets in selected region';...
                    '   A: add facets';...
                    '   Z: undo remove';...
                    '   X: redo remove';...
                    'Save load progress:';...
                    '   Ctrl+H: save progress';...
                    '   Ctrl+L: load progress';...
                    '   Ctrl+ arrow keys: Change between stack layer, if any';...
                    '       Left: prev stack';...
                    '       Right: next stack';...
                    '       Up/Down: Toogle between stacks and stiched image';...
                    'Export:';...
                    '   Ctrl+E: export labels';...
                    '   Ctrl+I: realign/remap/export labels';...
                    '   Ctrl+D: draw Antero-Postero direction';...
                    },'Help','modal');
        end
        if strfind(eventdata.Key,'arrow')
            if strcmp(eventdata.Modifier,'control')
                switch eventdata.Key
                    case 'leftarrow'
                        load_alt_img(-1);
                    case 'rightarrow'
                        load_alt_img(+1);
                    case 'uparrow'
                        show_alt = ~show_alt;
                    case 'downarrow'
                        show_alt = ~show_alt;
                end
                refreshed();
            else
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
    end
    %% Upon close: ask to save figures:
    function [] = CloseReqFcn(~,~)
        if crr_deletelevel~=0
            answer = questdlg('Save progress before exiting?','Closing figure','Yes','No','Cancel','Cancel');
        else
            % no changes, no saving
            delete(gcf);
            return;
        end
        switch answer
            case 'Yes'
                mkdir(fullfile('tmp',fld_name));
                save(fullfile('tmp',fld_name,'saveprogress.mat'),'xy_pos','xy_select','crr_deletelevel');
                refreshed();
                delete(gcf);
            case 'No'
                delete(gcf);
        end        
    end
    %% Right click to zoom in and double click to zoom out:
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