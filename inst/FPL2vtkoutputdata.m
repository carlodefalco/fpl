## Copyright (C) 2008 Carlo de Falco
## 
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA


## -*- texinfo -*- 
## @deftypefn {Function File} {} FPL2vtkoutputdata ( @var{filename}, @
## @var{p}, @var{t}, @var{header}, @var{val_name}, @var{val_values}, @
## [ @var{val_name}, @var{val_values}, ...])
##
## Save data in VTK ASCII format.
##
## @itemize @minus
##  @item  @var{filename} = name of file to save into
##  @item  @var{p}, @var{t} = mesh node coordinates and connectivity
##  @item  @var{name} = name of a mesh variable
##  @item  @var{data} = nodal or elemental values of the variable 
## @end itemize
##
## @seealso{FPL2dxoutputdata}
## @end deftypefn

function FPL2vtkoutputdata (filename, p, t, header, varargin)

  fid = fopen (filename, "w");
  if ( fid )

    ## version ID
    if (!exist("vtkver"))
      vtkver = [3 0];
    endif

    fprintf (fid, "# vtk DataFile Version %d.%d\n", vtkver(1), vtkver(2));

    ## header
    if (!exist("header"))
      header = "";
    elseif (length(header) > 255)
      header (255:end) = [];
    endif
    
    fprintf (fid, "%s\n", header);

    ## File format: only ASCII supported for the moment
    fprintf (fid, "ASCII\n");
    
    ## Mesh: only triangles suported
    fprintf (fid, "DATASET UNSTRUCTURED_GRID\n");

    Nnodes = columns(p);
    fprintf (fid,"POINTS %d double\n", Nnodes);
    fprintf (fid,"%g %g 0\n", p);

    Nelem = columns(t);
    T     = zeros(4,Nelem);
    T(1,:)= 3;
    T(2:4,:) = t(1:3,:) -1;
    fprintf (fid,"CELLS %d %d\n", Nelem, Nelem*4);
    fprintf (fid,"%d %d %d %d\n", T);
    fprintf (fid,"CELL_TYPES %d \n", Nelem);
    fprintf (fid,"%d\n", 5*ones(Nelem,1));

    ## node data
    nfields = rows(nodedata);
    if nfields
      fprintf (fid,"POINT_DATA %d\n", Nnodes);
      for ifield = 1:nfields
	V = nodedata {ifield, 2};
	N = nodedata {ifield, 1};
	if (isvector (V))
	  fprintf (fid,"SCALARS %s double\nLOOKUP_TABLE default\n", N);
	  fprintf (fid,"%g\n", V);
	else
	  V(:,3) = 0;
	  fprintf (fid,"VECTORS %s double\nLOOKUP_TABLE default\n", N);
	  fprintf (fid,"%g %g %g\n", V);
	endif     
      endfor
    endif

    ## cell data
    nfields = rows(celldata);
    if nfields
      fprintf (fid,"CELL_DATA %d\n", Nelem);
      for ifield = 1:nfields
	V = celldata {ifield, 2};
	N = celldata {ifield, 1};
	if (isvector (V))
	  fprintf (fid,"SCALARS %s double\nLOOKUP_TABLE default\n", N);
	  fprintf (fid,"%g\n", V);
	else
	  V(:,3) = 0;
	  fprintf (fid,"VECTORS %s double\nLOOKUP_TABLE default\n", N);
	  fprintf (fid,"%g %g %g\n", V);
	endif
      endfor
    endif

    ## cleanup
    fclose (fid);
  else
    error(["FPL2vtkoutputdata: could not open file " filename]);
  endif
endfunction

