function [rout,g,b] = imresize(varargin)
%IMRESIZE Resize image.
%   B = IMRESIZE(A,M,'method') returns an image matrix that is 
%   M times larger (or smaller) than the image A.  The image B
%   is computed by interpolating using the method in the string
%   'method'.  Possible methods are 'nearest' (nearest neighbor),
%   'bilinear' (binlinear interpolation), or 'bicubic' (bicubic 
%   interpolation). B = IMRESIZE(A,M) uses 'nearest' as the 
%   default interpolation scheme.
%
%   B = IMRESIZE(A,[MROWS NCOLS],'method') returns a matrix of 
%   size MROWS-by-NCOLS.
%
%   RGB1 = IMRESIZE(RGB,...) resizes the RGB truecolor image 
%   stored in the 3-D array RGB, and returns a 3-D array (RGB1).
%
%   When the image size is being reduced, IMRESIZE lowpass filters
%   the image before interpolating to avoid aliasing. By default,
%   this filter is designed using FIR1, but can be specified 
%   using IMRESIZE(...,'method',H).  The default filter is 11-by-11.
%   IMRESIZE(...,'method',N) uses an N-by-N filter.
%   IMRESIZE(...,'method',0) turns off the filtering.
%   Unless a filter H is specified, IMRESIZE will not filter
%   when 'nearest' is used.
%   
%   See also IMZOOM, FIR1, INTERP2.

%   Grandfathered Syntaxes:
%
%   [R1,G1,B1] = IMRESIZE(R,G,B,M,'method') or 
%   [R1,G1,B1] = IMRESIZE(R,G,B,[MROWS NCOLS],'method') resizes
%   the RGB image in the matrices R,G,B.  'bilinear' is the
%   default interpolation method.

%   Clay M. Thompson 7-7-92
%   Copyright (c) 1992 by The MathWorks, Inc.
%   $Revision: 5.4 $  $Date: 1996/10/16 20:33:27 $

[A,m,method,classIn,h] = parse_inputs(varargin{:});

threeD = (ndims(A)==3); % Determine if input includes a 3-D array

if threeD,
   r = resizeImage(A(:,:,1),m,method,h);
   g = resizeImage(A(:,:,2),m,method,h);
   b = resizeImage(A(:,:,3),m,method,h);
   if nargout==0, 
      imshow(r,g,b);
      return;
   elseif nargout==1,
      if strcmp(classIn,'uint8');
         rout = repmat(uint8(0),[size(r),3]);
         rout(:,:,1) = uint8(round(r*255));
         rout(:,:,2) = uint8(round(g*255));
         rout(:,:,3) = uint8(round(b*255));
      else
         rout = zeros([size(r),3]);
         rout(:,:,1) = r;
         rout(:,:,2) = g;
         rout(:,:,3) = b;
      end
   else % nargout==3
      if strcmp(classIn,'uint8')
         rout = uint8(round(r*255)); 
         g = uint8(round(g*255)); 
         b = uint8(round(b*255)); 
      else
         rout = r;        % g,b are already defined correctly above
      end
   end
else 
   r = resizeImage(A,m,method,h);
   if nargout==0,
      imshow(r);
      return;
   end
   if strcmp(classIn,'uint8')
      r = uint8(round(r*255)); 
   end
   rout = r;
end



