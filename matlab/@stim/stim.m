classdef stim
%Routines for creating stimuli and control files for binoc
%     stim.example uses this method to create simple expt
%     stim.BuildExpt builds real Expts of various types 
%     stim.rds  creates an RDS in matlab, and writes image to disk.
%     stim.SetOrder(stims, nrpts)  generates a pseudorandom order
%     stim.WriteOrder(basedir, stimorder) Writes the stimulus order file
%     stim.WriteStim(basedir, stimno, S, exvals) Writes a single stimN file
%
% So the following is the minimal code required to generate an experiment
% in matlab (see stim.example
%
%basedir='/local/expts/rds';
%S.st = 'rds';
%n = 0;
%for dx = -0.1:0.02:0.1
%  for ce = -1:2:1
%  S.dx = dx;
%  S.ce = ce;
%  stim.WriteStim(basedir,n,S, {'dx' 'ce'});
%end
%stim.WriteOrder(basedir,stim.SetOrder([0:n-1],5);

    properties
CurrentVersion = '1'
STIM_GRATING = 3;
end
methods (Static)
    AllS = BuildExpt(type, varargin); 
    AllS = example(varargin); 
    [b,l,r] = rds(sz,dxy,ndots,varargin);
    stimorder = SetOrder(stims, nr, varargin)
    WriteOrder(basedir, exptvars, name, stimorder, varargin);
    WriteStim(basedir, stimno, S, exvals, varargin);
end
end
