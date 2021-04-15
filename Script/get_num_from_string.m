function Num = get_num_from_string(A)
    B = regexp(A,'\d*','Match');
    if numel(B)
        Num=str2num(B{1});
    else
        Num=[];
    end