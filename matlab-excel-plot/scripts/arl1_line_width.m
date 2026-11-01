function width = arl1_line_width(currentWidth)
% Current user default: fixed 0.8 pt for ARL1; no automatic thickening.
validateattributes(currentWidth,{'numeric'},{'scalar','real','finite','positive'});
width=0.8;
end
