/*

  Copyright (C) 2023 Carlo de Falco

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.

  Author: Carlo de Falco <carlo@guglielmo.lan>
  Created: 2023-03-30

*/

#include <iostream>
#include <map>
#include <vector>
#include <octave/oct.h>

void
vtkexport (const char *filename,
	   const double *X,
	   const double *Y,
	   const double *Z,
	   const std::map<std::string, const double*> & f,
	   octave_idx_type num_rows,
	   octave_idx_type num_cols,
	   octave_idx_type num_layers) {

  const octave_idx_type nml = (num_rows+1)*(num_cols+1)*(num_layers+1);
  std::ofstream ofs (filename, std::ofstream::out);
  octave_idx_type count{0};
  const double *jj;
  
  ofs <<
    "<VTKFile type=\"StructuredGrid\" version=\"StructuredGrid\" byte_order=\"LittleEndian\">\n\
    <StructuredGrid WholeExtent=\"0 " << num_rows << " 0 " << num_cols << " 0 " << num_layers << " \">\n \
      <Piece Extent=\"0 " << num_rows << " 0 " << num_cols << " 0 " << num_layers << " \">\n";

  ofs << "      <PointData Scalars=\"";
  for (auto const & ii : f) {
    ofs << ii.first << ",";
  }
  ofs  << "\">\n";

  for (auto const & ii : f) {
    ofs << "        <DataArray type=\"Float64\" Name=\"" << ii.first <<"\" format=\"ascii\">\n        ";
    for (count = 0, jj = ii.second; count < nml; ++jj, ++count) {
      ofs << *jj << " ";
    }
    ofs << std::endl << "        </DataArray>" << std::endl;
  }

  ofs << "      </PointData>\n";

  std::function<double (octave_idx_type)> get_z;
  get_z = [&Z] (octave_idx_type count) -> double { return 0; };
  if (num_layers > 0)
    get_z = [&Z] (octave_idx_type count) -> double { return Z[count]; };
  
  ofs << "      <Points>\n        <DataArray type=\"Float64\" NumberOfComponents=\"3\" format=\"ascii\">\n";

  count = 0;
  for (octave_idx_type ii = 0; ii < num_cols+1; ++ii) {
    ofs << "          ";
    for (octave_idx_type jj = 0; jj < num_rows+1; ++jj) {
      ofs << "          ";
      for (octave_idx_type kk = 0; kk < num_layers+1; ++kk) {	
	ofs << std::setprecision(16) << X[count] << " " << Y[count] << " " << get_z (count++)  << " ";
      }
      ofs << std::endl;
    }
  }
  ofs << "        </DataArray>\n      </Points>\n";


  ofs <<
    "    </Piece>\n\
  </StructuredGrid>\n\
</VTKFile>\n";

  ofs.close ();
};



DEFUN_DLD(fpl_vts_write_field, args, nargout,
          "-*- texinfo -*-\n\
@deftypefn {} {@var{retval} =} template (@var{input1}, @var{input2})\n\
@seealso{}\n\
@end deftypefn")
{
  octave_value_list retval;
  int nargin = args.length ();

  auto filename = args(0).string_value ();
  auto var_names = args(1).cell_value ();
  auto vars = args(2).cell_value ();
  auto X = args(3).array_value ();
  octave_idx_type num_rows = X.dim1 () - 1;
  auto Y = args(4).array_value ();
  octave_idx_type num_cols = Y.dim2 () - 1;
  Array<double> Z;
  octave_idx_type num_layers = 0;
  if (nargin > 5) {
    Z = args(5).array_value ();
    num_layers = Z.dim3 () - 1;
  }

  std::map<std::string, const double*> f;
  for (octave_idx_type jj = 0; jj < var_names.numel (); ++jj) {
    f[var_names (jj).string_value ()] = vars (jj).array_value ().data ();
  }

  std::cout << "num_rows " << num_rows << "num_cols" << num_cols << std::endl;
  vtkexport (filename.c_str (), X.data (), Y.data (), Z.data (), f, num_rows, num_cols, num_layers);
  return retval;
}
