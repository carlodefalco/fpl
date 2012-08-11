##  Copyright (C) 2012  Carlo de Falco
##  Copyright (C) 2008,2009,2010 Massimiliano Culpo
##
##  This file is part of:
##         FPL - Fem PLotting package for octave
##
##  FPL is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 3 of the License, or
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
##  author: Carlo de Falco     <cdf _AT_ users.sourceforge.net>
##  author: Massimiliano Culpo <culpo _AT_ users.sourceforge.net>

## -*- texinfo -*-
## @deftypefn {Function File} {} fpl_vtk_b64_write_field (@var{basename}, @
## @var{mesh}, @var{nodedata},  @var{celldata})
## 
## Output data field in binary serial XML-VTK UnstructuredGrid format.
##
## @var{basename} is a string containing the base-name of the (vtu) file
## where the data will be saved.
##
## @var{mesh} is a PDE-tool like mesh, like the ones generated by the
## "msh" package.
##
## @var{nodedata} and @var{celldata} are (Ndata x 2) cell arrays containing
## respectively <PointData> and <CellData> representing scalars or
## vectors:
## @itemize @minus
## @item @var{*data}@{:,1@} = variable data;
## @item @var{*data}@{:,2@} = variable names;
## @end itemize
##
##
## Example:
## @example
## %% generate msh1, node centered field nc1, cell centered field cc1
## fpl_vtk_b64_write_field ("example", msh1, @{nc1, "temperature"@}, @{cc1, "density"@});
## %% generate msh2, node centered field nc2
## fpl_vtk_b64_write_field ("example", msh2, @{nc2, "temperature"@}, @{@});
## @end example
##
## The difference between @code{fpl_vtk_write_field} and @code{fpl_vtk_b64_write_field}
## is that the former saves data in ASCII format while the latter uses base64-encoded 
## binary format. To save data in un-encoded binary format use @code{fpl_vtk_raw_write_field}.
##
## @seealso{fpl_dx_write_field, fpl_dx_write_series, @
##          fpl_vtk_assemble_series, fpl_vtk_write_field, @
##          fpl_vtk_raw_write_field} 
##
## @end deftypefn

function fpl_vtk_b64_write_field (basename, mesh, nodedata, celldata)

  ## Check input
  if (nargin != 4)
    print_usage ();
  endif

  if (! ischar (basename))
    error ("fpl_vtk_b64_write_field: basename should be a string");
  elseif (! isstruct (mesh))
    error ("fpl_vtk_b64_write_field: mesh should be a struct");
  elseif (! (iscell (nodedata) && iscell (celldata)))
    error ("fpl_vtk_b64_write_field: nodedata and celldata should be cell arrays");
  endif

  if (! exist ("base64_encode", "builtin"))
    warning ("fpl_vtk_b64_write_field: Octave >= 3.7 is required to save in binary format, your data will be saved as ascii");
    fpl_vtk_write_field (basename, mesh, nodedata, celldata, true);
    return;
  endif

  filename = [basename ".vtu"];

  if (! exist (filename, "file"))
    fid = fopen (filename, "w");

    ## Format
    fprintf (fid, "<?xml version=""1.0""?>\n");

    ## Start file
    fprintf (fid, "<VTKFile type=""UnstructuredGrid"" version=""0.1"" byte_order=""LittleEndian"">\n");

    ## Start Header
    fprintf (fid, "  <UnstructuredGrid>\n");
  else
    error ("fpl_vtk_b64_write_field: file %s exists", filename);
  endif    

  offset = 0;
  data   = "";

  p   = mesh.p;
  dim = rows (p); # 2D or 3D

  if dim == 2
    t = mesh.t (1:3,:);
  elseif dim == 3
    t = mesh.t (1:4,:);
  else
    error ("fpl_vtk_b64_write_field: neither 2D triangle nor 3D tetrahedral mesh");    
  endif
  
  t -= 1;
  
  nnodes = columns (p);
  nelems = columns (t);

  ## Piece 
  fprintf (fid, "    <Piece NumberOfPoints=""%d"" NumberOfCells=""%d"">\n", nnodes, nelems);

  ## Encode data-sets
  [data, offset] = print_data_points (fid, nodedata, nnodes, data, offset);
  [data, offset] = print_cell_data  (fid, celldata, nelems, data, offset);

  ## Encode mesh
  [data, offset] = print_grid (fid, dim, p, nnodes, t, nelems, data, offset);

  ## End Piece
  fprintf (fid, "    </Piece>\n");

  ## End Header
  fprintf (fid, "  </UnstructuredGrid>\n");

  ## Write data
  fprintf (fid, "  <AppendedData encoding=""base64"">\n");
  fprintf (fid, "_%s\n", data);
  fprintf (fid, "  </AppendedData>>\n");

  ## End file
  fprintf (fid, "</VTKFile>");
  fclose (fid);
	   
endfunction

## Print Points and Cells Data
function [data, offset] = print_grid (fid, dim, p, nnodes, t, nelems, data, offset)
  
  if dim == 2
    p      = [p; zeros(1,nnodes)];
    eltype = 5;
  else
    eltype = 10;
  endif
  
  ## VTK-Points (mesh nodes)
  fprintf (fid, "    <Points>\n");
  fprintf (fid, "      <DataArray type=""Float64"" Name=""Array"" NumberOfComponents=""3"" format=""appended"" offset=""%d"" />\n", offset);  
  newdata = __array_to_uint8__(p)(:); 
  data = [data, base64_encode([__array_to_uint8__(int32 (numel (newdata)))(:); newdata])];
  offset = numel (data);

  fprintf (fid, "    </Points>\n");

  ## VTK-Cells (mesh elements)
  fprintf (fid, "    <Cells>\n");
  fprintf (fid, "      <DataArray type=""Int32"" Name=""connectivity"" format=""appended"" offset=""%d"" />\n", offset);
  newdata = __array_to_uint8__(int32 (t))(:); 
  data = [data, base64_encode([__array_to_uint8__(int32 (numel (newdata)))(:); newdata])];
  offset = numel (data);

  fprintf (fid, "      <DataArray type=""Int32"" Name=""offsets"" format=""appended"" offset=""%d"" />\n", offset);
  tmp = (dim+1):(dim+1):((dim+1)*nelems);
  newdata = __array_to_uint8__(int32 (tmp))(:); 
  data = [data, base64_encode([__array_to_uint8__(int32 (numel (newdata)))(:); newdata])];
  offset = numel (data);

  fprintf (fid, "      <DataArray type=""UInt8"" Name=""types"" format=""appended"" offset=""%d"" />\n", offset);
  tmp = eltype*ones(nelems,1);
  newdata = __array_to_uint8__(uint8 (tmp))(:); 
  data = [data, base64_encode([__array_to_uint8__(int32 (numel (newdata)))(:); newdata])];
  offset = numel (data);

  fprintf (fid, "    </Cells>\n");

endfunction

## Print DataPoints
function [data, offset] = print_data_points (fid, nodedata, nnodes, data, offset)
  
  ## # of data to print in 
  ## <PointData> field
  nvdata = size (nodedata, 1);  
  
  if (nvdata)
    fprintf (fid, "    <PointData>\n");   
    for ii = 1:nvdata    
      ndata     = nodedata{ii,1};
      ndataname = nodedata{ii,2};
      nsamples = rows (ndata);
      ncomp    = columns (ndata);
      if (nsamples != nnodes)
	error ("fpl_vtk_b64_write_field: wrong number of samples in <PointData> ""%s""", ndataname);
      endif
      fprintf (fid, "      <DataArray type=""Float64"" Name=""%s"" ", ndataname);
      fprintf (fid, "NumberOfComponents=""%d"" format=""appended"" offset=""%d"" />\n", ncomp, offset);
      newdata = __array_to_uint8__(ndata.')(:); 
      data = [data, base64_encode([__array_to_uint8__(int32 (numel (newdata)))(:); newdata])];
      offset = numel (data);
    endfor
    fprintf (fid, "    </PointData>\n");
  endif

endfunction

function [data, offset] = print_cell_data (fid, celldata, nelems, data, offset)
  
  ## # of data to print in 
  ## <CellData> field
  nvdata = size (celldata, 1); 

  if (nvdata)
    fprintf (fid, "<CellData>\n");
    for ii = 1:nvdata
      cdata     = celldata{ii,1};
      cdataname = celldata{ii,2};
      nsamples = rows (cdata);
      ncomp    = columns (cdata);
      if nsamples != nelems
	error ("fpl_vtk_b64_write_field: wrong number of samples in <CellData> ""%s""", cdataname);
      endif
      fprintf (fid, "      <DataArray type=""Float64"" Name=""%s"" ", cdataname);
      fprintf (fid, "NumberOfComponents=""%d"" format=""appended"" offset=""%d"" />\n", ncomp, offset);
      newdata = __array_to_uint8__(cdata.')(:);
      data = [data, base64_encode([__array_to_uint8__(int32 (numel (newdata)))(:); newdata])];
      offset = numel (data);
    endfor
    fprintf (fid, "    </CellData>\n"); 
  endif

endfunction
