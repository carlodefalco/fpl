function FPL2showmesh (varargin)

  %% -*- texinfo -*-
  %% @deftypefn {Function File} {} FPL2showmesh (@var{mesh1}, @
  %% @var{color1}, @ [@var{mesh2}, @var{color2}, ...])
  %% 
  %% Displays one or more 2-D triangulations using opendx.
  %%
  %% @seealso{MSH2Mgmsh, MSH2Mstructmesh}
  %% @end deftypefn

  ## This file is part of 
  ##
  ##            FPL
  ##            Copyright (C) 2004-2007  Carlo de Falco
  ##
  ##
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
  ##  along with FPL; if not, write to the Free Software
  ##  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
  ##  USA
  
  datalist = "";
  colorlist= "";

  for ii=1:2:nargin
    dataname{ii} = mktemp("/tmp",".dx");
    FPL2dxoutputdata(dataname{ii},varargin{ii}.p,varargin{ii}.t,...
		     varargin{ii}.p(1,:)','x',0,1,1);
    datalist = strcat (datalist, """", dataname{ii} ,"""");
    colorlist= strcat (colorlist, """", varargin{ii+1} ,"""");
  end
  scriptname = mktemp("/tmp",".net");
  
  showmesh = file_in_path(path,"FPL2showmesh.net");
  
  system (["cp " showmesh " " scriptname]);
  system (["sed -i \'s|__FILE__DX__|" datalist "|g\' " scriptname]);
  system (["sed -i \'s|__MESH__COLOR__|" colorlist "|g\' " scriptname]);

  command = ["dx -noConfirmedQuit  -noImageRWNetFile -program " scriptname " -execute -image  >& /dev/null & "];  
  system(command);


  function filename = mktemp (direct,ext);

    if (~exist(direct,"dir"))
      error("trying to save temporary file to non existing directory")
    end

    done=false;

    while ~done
      filename = [direct,"/FPL.",num2str(floor(rand*1e7)),ext];
      if ~exist(filename,"file")
	done =true;
      end
    end
  endfunction