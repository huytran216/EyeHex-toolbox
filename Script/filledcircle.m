function I=filledcircle(cote,x0,y0,I,val)
   %cote= side size;,(x0,y0) exagon center coordinates;
   if ~exist('val','var')
       val=1;
   end
   
   [ax,ay]=meshgrid(1:size(I,2),1:size(I,1));
   inner = (ay-x0).^2 + (ax-y0).^2 <=cote^2;
   I(inner)=val;
   
%    for i=1:size(I,1)
%        for j=1:size(I,2)
%            if (i-x0)^2+(j-y0)^2<=cote^2
%                I(i,j)=val;
%            end
%        end
%    end