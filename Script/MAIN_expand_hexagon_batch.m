%% 
% This script will enable users to first choose spawning points for a set images
% then perform hexagonal grid expansion on all these images

%% Open the file:
fn=uigetfile('../data/raw/*.tif','Select the image(s) to process','MultiSelect','on');

%% Select hexagonal grid to expand:
valid_expansion = zeros(1,numel(fn));
if ~iscell(fn)
    fn = {fn};
end
for i=1:numel(fn)
    % Set location but don't expand right away
    MAIN_locate_origin(fn{i},0);
    go_next = false;
    while ~go_next
        answer = questdlg('Will you spawn the hexagonal grid with this origin?','Confirm','Yes','Redo','Skip','Redo');
        switch answer
            case 'Yes'
                valid_expansion(i) = true;
                go_next = true;
            case 'Redo'
                MAIN_locate_origin(fn{i},0);
                go_next = false;
            case 'Skip'
                valid_expansion(i) = false;
                go_next = true;
        end
    end
    close(gcf);
end
%% Perform automatic spawn:
for i=1:numel(fn)
    if valid_expansion(i)
        expand_hexagon(fn{i});
    end
end