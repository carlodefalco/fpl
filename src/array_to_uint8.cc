/*
Copyright (C) 2012 Carlo de Falco

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Octave; see the file COPYING.  If not, see
<http://www.gnu.org/licenses/>.

Author: Carlo de Falco <carlo@guglielmo.local>
Created: 2012-08-04

*/

#include <octave/oct.h>

DEFUN_DLD(array_to_uint8,args,nargout,"\
undocumented internal function\n\
")
{
  octave_value_list retval;
  int nargin = args.length ();
  
  if (nargin != 1)
    print_usage ();
  else 
    {
      uint8NDArray out;

      if (! args(0).is_numeric_type ()) 
        error ("array_to_uint8: encoding is supported only for numeric arrays");
      else if (args(0).is_complex_type () 
          || args(0).is_sparse_type ())
        error ("array_to_uint8: encoding complex or sparse data is not supported");
      else if (args(0).is_integer_type ())
        {

#define MAKE_INT_BRANCH(X)                                              \
          if (args(0).is_ ## X ## _type ())                             \
            {                                                           \
              const X##NDArray in =                                     \
                args(0).  X## _array_value ();                          \
              octave_idx_type len =                                     \
                in.numel () * sizeof (X## _t) / sizeof (uint8_t);       \
              if (! error_state)                                        \
                {                                                       \
                out.resize1 (len);                                      \
                std::copy ((uint8_t*) in.data(),                        \
                           ((uint8_t*) in.data()) + len,                \
                           out.fortran_vec ());                         \
                retval(0) = octave_value (out);                         \
                }                                                       \
            }
                                          
          MAKE_INT_BRANCH(int8)
          else MAKE_INT_BRANCH(int16)
          else MAKE_INT_BRANCH(int32)
          else MAKE_INT_BRANCH(int64)
          else MAKE_INT_BRANCH(uint8)
          else MAKE_INT_BRANCH(uint16)
          else MAKE_INT_BRANCH(uint32)
          else MAKE_INT_BRANCH(uint64)

#undef MAKE_INT_BRANCH

           else
             panic_impossible ();
        }
      else if (args(0).is_single_type ())
        {
          const FloatNDArray in = 
            args(0).float_array_value ();
          octave_idx_type len =           
            in.numel () * sizeof (float) / sizeof (uint8_t);
          if (! error_state)                    
            {                                   
              out.resize1 (len);                
              std::copy ((uint8_t*) in.data(), 
                         ((uint8_t*) in.data()) + len, 
                         out.fortran_vec ());
              retval(0) = octave_value (out);
            }
        }
      else
        {
          const Array<double> in = args(0).array_value ();

          octave_idx_type len =           
            in.numel () * sizeof (double) / sizeof (uint8_t);
       
          if (! error_state)                    
            {                                   
              out.resize1 (len); 
              std::copy ((uint8_t*) in.data(), 
                         ((uint8_t*) in.data()) + len, 
                         out.fortran_vec ());
              retval(0) = octave_value (out);
            }
        }  
    }     
  return retval;
}
