function [I1aligned, data] = aligngui(Iin, I1vis, I2, data, title)
% Input:
    % Iin:
    % Ilvis: image for alignment
    % I2: original image
    % data: data points for alignment
    % title: 
% aligngui Image registration GUI
    %% If image color: >> make gray
    if numel(size(I2))==3
        I2 = uint8(mean(I2,3));
    end
   
    %% create data
	self= struct;
    self.altpresstimer= [];
    self.altpresspos= [];
	self.zoomenabled= false;
	self.zoomratio= 1/6;
    self.dragging= 0; % 0 = mouse not down; 1 = mouse down; 2 = mouse down and dragging a point
	self.window= figure;
    self.imagesize= size(I2);
    self.points1= zeros(2,0);
    self.points2= zeros(2,0);
    self.impoints= [];
    self.registeredmode= true;
    self.axes= axes('Parent', self.window);
    self.image= [];
    self.ignoreNewPos= false;
    self.done= false;
    
    set(self.axes, 'UserData', {im2uint8(I1vis), im2uint8(I2)});
    if nargin >= 4 && ~isempty(data)
        self.points1= data.points1;
        self.points2= data.points2;
    end
    if nargin >= 5 && ~isempty(title)
        set(self.window, 'Name', title);
    end
    
	%% store cookie & bind event functions
	set(self.window, ...
        'Interruptible', 'off', ...
		'MenuBar', 'none', ...
		'UserData', self, ...
		'WindowButtonDownFcn', @mousePressed_, ...
        'WindowButtonUpFcn', @mouseReleased_, ...
        'WindowButtonMotionFcn', @mouseMotion_, ...
		'WindowKeyPressFcn', @keyPressed_);
    updateRegistration_(self.window);

    %% wait for completion
    while ~self.done
        uiwait(self.window);
        if ~ishandle(self.window)
            %% user quit
            I1aligned= [];
            return;
        end
        self= get(self.window, 'UserData');
    end
    
    %% make the final registered image
    delete(self.window);
    if iscell(Iin)
        I1aligned = cell(1,numel(Iin));
        for i=1:numel(Iin)
            if size(Iin{i},2)==2
                xy_pos = Iin{i};
                % Create image with value of omatidia index
                Itmp = double(I2*0);
                for j=1:size(xy_pos,1)
                    try 
                        Itmp(round(xy_pos(j,1))+[-2:2],round(xy_pos(j,2)+[-2:2])) = j/3000;
                    catch
                        'out of bound'
                    end
                end
                Itmp= imtransform(Itmp, self.tform, 'nearest', ...
                'XData', [1 size(I2,2)], 'YData', [1 size(I2,1)]);
                [uniqueval,uniquepos] = unique(Itmp);
                if numel(uniqueval)~=size(xy_pos,1)+1
                    'ops'
                end
                I1aligned{i} = xy_pos;
                uniquepos = uniquepos(uniqueval>0);
                uniqueval = uniqueval(uniqueval>0);
                newidx = round(uniqueval*3000);
                [xtmp,ytmp]=ind2sub(size(I2),uniquepos);
                I1aligned{i}(newidx,:)=[xtmp ytmp];
            else
                I1aligned{i}= imtransform(Iin{i}, self.tform, 'nearest', ...
                'XData', [1 size(I2,2)], 'YData', [1 size(I2,1)]);
            end
        end
    else
        I1aligned= imtransform(Iin, self.tform, 'nearest', ...
            'XData', [1 size(I2,2)], 'YData', [1 size(I2,1)]);
    end
    data= struct('points1', self.points1, ...
        'points2', self.points2);

function tform= makeRegistrationTform_(p1, p2, I1, I2)
    N= size(p1,2);
    if N > 3
        %% Registration by thin-plate splines
        f= tpaps(p2, p1, 1);
        finv= @(Y,~) fminsearch(@(Xhat)sum((fnval(f,Xhat)-Y.').^2), Y.', ...
            optimset('Display', 'off')).';
        tform= maketform('custom', 2, 2, finv, @(X,~)fnval(f,X.').', []);
    else
        imsc= min(size(I2) ./ size(I1));
        if N == 3
            %% Full linear transform
            tform= maketform('affine', p1.', p2.');
        elseif N == 2
            %% Image size scaling + Rotate + Translate
            d1= diff([1 1i] * p1);
            theta1= -angle(d1);
            T1= [1/abs(d1) 0 0; 0 1/abs(d1) 0; 0 0 1] * ...
                [cos(theta1) -sin(theta1) 0; sin(theta1) cos(theta1) 0; 0 0 1] * ...
                [1 0 -p1(1,1); 0 1 -p1(2,1); 0 0 1];
            d2= diff([1 1i] * p2);
            theta2= -angle(d2);
            T2= [1/abs(d2) 0 0; 0 1/abs(d2) 0; 0 0 1] * ...
                [cos(theta2) -sin(theta2) 0; sin(theta2) cos(theta2) 0; 0 0 1] * ...
                [1 0 -p2(1,1); 0 1 -p2(2,1); 0 0 1];
            tform= maketform('affine', (T2 \ T1).');
        elseif N == 1
            %% Image size scaling + Translate
            tform= maketform('box', ...
                [1 1; fliplr(size(I1))] + [p1 p1].' - 1, ...
                [1 1; imsc*fliplr(size(I1))] + [p2 p2].' - 1 );
        else
            %% Image size scaling only
            tform= maketform('box', ...
                [1 1; fliplr(size(I1))], ...
                [1 1; imsc*fliplr(size(I1))] );
        end
    end

function updateRegistration_(window)
    self= get(window, 'UserData');
    if self.ignoreNewPos
        return;
    end
    I12= get(self.axes, 'UserData');
    
    if ~isempty(self.impoints)
        if self.registeredmode
            self.points2= cell2mat(arrayfun(@(h){h.getPosition().'}, self.impoints));
        else
            if self.dragging >= 1
                self.dragging= 2;
                set(window, 'UserData', self);
                return;
            end
            newpt1= cell2mat(arrayfun(@(h){h.getPosition().'}, self.impoints));
            changed= find(any(newpt1 ~= self.points1));
            self.points1= newpt1;
            self.points2(:,changed)= tformfwd(self.tform, newpt1(:,changed).');
        end
    end
    self.tform= makeRegistrationTform_(self.points1, self.points2, I12{1}, I12{2});
    
    if self.registeredmode
        if self.zoomenabled && self.dragging >= 1
            xd= max(1,min(size(I12{2},2), round(get(self.axes, 'XLim') + [-0.5 0.5])));
            yd= max(1,min(size(I12{2},1), round(get(self.axes, 'YLim') + [-0.5 0.5])));
            tformedI_sub= imtransform(I12{1}, self.tform, 'nearest', ...
                'XData', xd, 'YData', yd);
            tformedI= zeros(size(I12{2}));
            tformedI(yd(1):yd(2), xd(1):xd(2))= tformedI_sub;
            self.dragging= 2;
        else
            tformedI= imtransform(I12{1}, self.tform, 'nearest', ...
                'XData', [1 size(I12{2},2)], 'YData', [1 size(I12{2},1)]);
        end

        I= cat(3, tformedI, I12{2}, zeros(size(I12{2})));
        if isempty(self.image)
            self.image= imshow(I, 'Parent', self.axes);
            set(window,'units','normalized','outerposition',[0 0 1 1])
            set(self.axes, 'UserData', I12);
            if ~isempty(self.points2)
                self.impoints= impoint(self.axes, self.points2(:,1).');
                for i= 2:size(self.points2,2)
                    self.impoints(i)= impoint(self.axes, self.points2(:,i).');
                end
                arrayfun(@(h)setupImpoint_(h, window), self.impoints);
            end
        else
            set(self.image, 'CData', I);
        end
    end
    set(window, 'UserData', self);
    
function setupImpoint_(h, window)
    h.addNewPositionCallback(@(~) updateRegistration_(window));
    set(h, 'UIContextMenu', []);

function placeNewPoint_(window)
	%% get cookie
	self= get(window, 'UserData');
    %% place the new point
    h= impoint(self.axes);
    try
        h.getPosition();
    catch ME %#ok<NASGU>
        return;
    end
    
    %% hook it up to the rest of the system
    if isempty(self.impoints)
        self.impoints= h;
    else
        self.impoints(end+1)= h;
    end
    if self.registeredmode
        self.points1(:,end+1)= tforminv(self.tform, h.getPosition().');
        self.points2(:,end+1)= h.getPosition().';
    else
        self.points1(:,end+1)= h.getPosition().';
        self.points2(:,end+1)= tformfwd(self.tform, h.getPosition().');
    end
    setupImpoint_(h, window);
    set(self.window, 'UserData', self);
    
    %% redraw in case things changed
    %updateRegistration_(window);

function deletePoints_(window)
	%% get cookie
	self= get(window, 'UserData');
    %% place the new point
    h= imfreehand(self.axes);
    try
        mask= h.createMask();
    catch ME %#ok<NASGU>
        return;
    end

    %% find which points should be removed
    delete(h);
    if self.registeredmode
        pp= self.points2;
    else
        pp= self.points1;
    end
    keep= ~arrayfun( @(x,y)...
        mask(max(1,min(end,round(y))), max(1,min(end,round(x)))), ...
        pp(1,:), pp(2,:) );
    
    %% remove them
    self.points1= self.points1(:,keep);
    self.points2= self.points2(:,keep);
    arrayfun( @delete, self.impoints(~keep) );
    self.impoints= self.impoints(keep);
    set(self.window, 'UserData', self);

    %% redraw
    updateRegistration_(window);

function switchMode_(window)
	%% get cookie
	self= get(window, 'UserData');
    
    self.registeredmode= ~self.registeredmode;
    self.ignoreNewPos= true;
    set(self.window, 'UserData', self);
    if self.registeredmode
        p= self.points2;
    else
        p= self.points1;
        I12= get(self.axes, 'UserData');
        set(self.image, 'CData', repmat(I12{1}, [1 1 3]));
    end
    for i= 1:size(p,2)
        self.impoints(i).setPosition(p(:,i).');
    end
    self.ignoreNewPos= false;
    set(self.window, 'UserData', self);
    if self.registeredmode
        updateRegistration_(window);
    end
    if self.zoomenabled
        updateZoom_(window);
    else
        img= get(self.image, 'CData');
        imagesize= [size(img,1), size(img,2)];
        set(self.axes, ...
            'XLim', .5 + [0, imagesize(2)], 'YLim', .5 + [0, imagesize(1)]);
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

function updateZoom_(window, point)
	%% get cookie
	self= get(window, 'UserData');
	%% get mouse location
    if nargin < 2 || isempty(point)
        point= mean(get(findobj(window, 'Type', 'axes'), 'CurrentPoint'), 1);
    end
	pos= point([2, 1]);
	%% compute new viewport
    img= get(self.image, 'CData');
    imagesize= [size(img,1), size(img,2)];
	viewsize= imagesize .* self.zoomratio;
	viewlo= min(max(1, pos - .5 * viewsize), imagesize - viewsize);
	viewhi= viewlo + viewsize;
	%% set viewport
	set(self.axes, ...
		'XLim', -.5 + [viewlo(2), viewhi(2)], 'YLim', .5 + [viewlo(1), viewhi(1)]);
	
function helpDialog_()
    msg= { ...
        'Control point manipulation:', ...
        '    a: Place new control point', ...
        '    r: Delete control point', ...
        '    left click: Move control points', ...
        'Navigation:', ...
        '    m: Switch mode', ...
        '    z/right click: Zoom', ...
        '    hold right click: Pan', ...
        '    enter: Finish alignment for this frame', ...
        };
    msg2= strcat(msg,{'\n'});
    msg3= sprintf(strcat(msg2{:}));
    msgbox(msg3, 'Manual Alignment GUI');
            
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
	
function keyPressed_(window, event)
	%% process key press
	switch event.Key
        case 'r'
            deletePoints_(window);
        case 'a'
            placeNewPoint_(window);
        case 'm'
            switchMode_(window);
        case 'return'
            self= get(window, 'UserData');
            self.done= true;
            set(window, 'UserData', self);
            uiresume(window);
		case 'z'
			toggleZoom_(window);
        case 'f1'
            helpDialog_();
	end
	