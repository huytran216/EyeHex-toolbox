function I_=hexagon(cote,x0,y0,I,val)
   %cote= side size;,(x0,y0) exagon center coordinates;
   x=cote*[-1 -0.5 0.5 1 0.5 -0.5 -1]+x0;
   y=cote*sqrt(3)*[0 -0.5 -0.5 0 0.5 0.5 0]+y0;
   I_=I;
   if ~exist('val','var')
       val=1;
   end
   for i=1:numel(x)-1
       lx = round(linspace(x(i),x(i+1),20));
       ly = round(linspace(y(i),y(i+1),20));
       for j=1:numel(lx)
           if (lx(j)>0)&&(ly(j)>0)
               I_(lx(j),ly(j))=val;
           end
       end
   end
   I_=I_(1:size(I,1),1:size(I,2));