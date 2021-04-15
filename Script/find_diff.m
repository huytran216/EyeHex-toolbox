function [err,Isub1]=find_diff(I,Iround,x,y,hangle,hrotate,hsize)
    Isub1=twist_and_turn(Iround,hangle,hrotate,hsize);
    Isub1=Isub1>0;
    Isub2=I(x:x+size(Isub1,1)-1,y:y+size(Isub1,2)-1);
    if min(Isub2(:)>=0)
        err = sum(abs(~Isub2(Isub1)))/sum(Isub1(:));
    else
        err=1e5;
    end