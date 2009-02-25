## Copyright (C) 2004-2008  Carlo de Falco, Massimiliano Culpo
##
##  This file is part of 
##
##                   FPL - Fem PLotting package for octave
## 
##  FPL is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
## 
##  FPL is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
## 
##  You should have received a copy of the GNU General Public License
##  along with FPL; If not, see <http://www.gnu.org/licenses/>.
##
##
##  AUTHORS:
##  Carlo de Falco
##  Dublin City University
##  School of Mathemetical Sciences
##  Ireland
##
##  Culpo Massimiliano
##  Bergische Universitaet Wuppertal
##  Fachbereich C - Mathematik und Naturwissenschaften
##  Arbeitsgruppe fuer Angewandte MathematD-42119 Wuppertal  Gaussstr. 20 
##  D-42119 Wuppertal, Germany

## -*- texinfo -*-
## @deftypefn {Function File} {} FPL3dxoutputmesh ( @var{filename}, @
## @var{mesh} )
##
##  Outputs data in DX form.
##
## Variable must be a scalar, vector or tensor of doubles   
##
## @itemize @minus
##  @item @var{filename} = name of file to save (type string)
##  @item @var{mesh}     = PDE-tool like mesh
## @end itemize
## @end deftypefn


function FPL3dxoutputmesh(filename,mesh)

  nodes  = mesh.p';
  elem   = mesh.t(1:4,:)';

  fid    = fopen (filename,"w");
  nnodes = columns(mesh.p);
  nelem  = columns(mesh.t);

  fprintf(fid,"object ""pos""\nclass array type float rank 1 shape 3 items %d data follows",nnodes);
  for ii = 1:nnodes
    fprintf(fid,"\n");
    fprintf(fid,"    %e",nodes(ii,:));
  endfor

  ## In DX format nodes are numbered starting from zero,
  ## instead we want to number them starting from 1.
  if (min(min(elem))==1)
    elem = elem - 1;
  elseif(min(min(elem))~=0)
    error("WARNING: check tetrahedra structure");
  end                    

  fprintf(fid,"\n\nobject ""con""\nclass array type int rank 1 shape 4 items %d data follows",nelem);
  for ii = 1:nelem
    fprintf(fid,"\n");
    fprintf(fid,"      %d",elem(ii,:));
  endfor

  fprintf(fid,"\nattribute ""element type"" string ""tetrahedra""\nattribute ""ref"" string ""positions""\n\n");

  fprintf(fid,"object ""themesh"" class field\n");
  fprintf(fid,"component ""positions"" value ""pos""\n");
  fprintf(fid,"component ""connections"" value ""con""\n");

  fprintf(fid,"\nend\n");
  fclose (fid);

endfunction