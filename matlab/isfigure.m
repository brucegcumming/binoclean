function yesno = isfigure(h)
% function yesno = isfigure(h)
if ishandle(h)
    yesno = ~isempty(findobj(h,'flat','type','figure'));