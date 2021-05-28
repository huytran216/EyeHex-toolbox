function [newx,newy,newval,newImg,newImg_extra]=transform_I(xy0,xy1,I,sizeI1,I_extra)
    % Transform input I, from old project xy0=[x0, y0] to new projection xy1=[x1 y1]
    % Input:
    %   xy0: old coordinate (1x6)
    %   xy1: new coordinate (1x6)
    %   I: image to be transformed around the central pixel
    %   sizeI1: size of bigger frame to project to (in xy1 coordinate)
    % Output:
    %   newx: list of projected image's pixel position along x1 axis
    %   newy: list of projected image's pixel position along y1 axis
    %   newI: value of pixel
    
    % REQUIRED THAT xy0 and xy1 sets are ordered bases
    
    v1 = [xy0(2)-xy0(1)  xy0(5)-xy0(4)];
    v2 = [xy0(3)-xy0(1)  xy0(6)-xy0(4)];
    v0 = [xy0(1) xy0(4)];
    v1_ = [xy1(2)-xy1(1)  xy1(5)-xy1(4)];
    v2_ = [xy1(3)-xy1(1)  xy1(6)-xy1(4)];
    v0_ = [xy1(1) xy1(4)];
    B = [v1;v2]';
    i=0;
    newx=[];
    newy=[];
    newval=[];
    newval_extra = [];
    if ~exist('I_extra','var')
        I_extra = I;
    end
    newxy_rec = [];
    for j=1:numel(I)
        if ~isnan(I(j))
            % Get position of pixel index i
            [x,y]=ind2sub(size(I),j);
            xy=[x,y];
            % get coordinate in xy0
            ab = linsolve(B,(xy-v0)');
            % get coordinate in xy1
            newxy = ab(1)*v1_+ab(2)*v2_+v0_;
            % save
            if (newxy(1)>=1)&(newxy(1)<=sizeI1(1))&(newxy(2)>=1)&(newxy(2)<=sizeI1(2))
                i=i+1;
                newx(i)=round(newxy(1));
                newy(i)=round(newxy(2));
                newval(i) = I(j);
                newval_extra(i) = I_extra(j);
            end
            newxy_rec = [newxy_rec; newxy(:)'];
        end
    end
    
    if nargout>=4
        newImg=zeros(sizeI1);
        newImg_extra=zeros(sizeI1);
        for i=1:numel(newx)
            newImg(newx(i),newy(i))=newval(i);
            newImg_extra(newx(i),newy(i))=newval_extra(i);
        end
    end
end