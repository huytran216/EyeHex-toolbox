function output_txt = NewCallback_axes(obj,event_obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).

pos = get(event_obj,'Position');
output_txt = {['X: ',num2str(pos(1),4)],...
    ['Y: ',num2str(pos(2),4)]};

if strcmp(class(event_obj.Target),'matlab.graphics.chart.primitive.Scatter')
    xy_tmp_info=load('tmp_datatip');
    if numel(xy_tmp_info.xy_idx_new)>0
        xy_tmp_info.xy_idx = xy_tmp_info.xy_idx_new;
    end
    xy_select = find((xy_tmp_info.xy_pos(:,1)==pos(2))&(xy_tmp_info.xy_pos(:,2)==pos(1)));
    if numel(xy_tmp_info.xy_idx(:,1))>xy_select
        output_txt{end+1} = ['Index: ',num2str(xy_select)];
        output_txt{end+1} = ['X_{hex}: ',num2str(xy_tmp_info.xy_idx(xy_select,1))];
        output_txt{end+1} = ['Y_{hex}: ',num2str(xy_tmp_info.xy_idx(xy_select,2))];
    else
        output_txt{end+1} = 'unlabeled';
    end
end
