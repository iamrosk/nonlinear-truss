function [stress, mat_stiff, state] = ...
    material_routine(params, state, strain, analysis_type)
%% MATERIAL_ROUTINE Returns stress and material stiffness.
% Inputs:
% params - structure containing material parameters.
% strain - total strain.
% analysis_type - string ('elastic' or 'plastic') to decide if plasticity is allowed.
% el - element number.
%
% Output:
% stress - Kirchhoff stress.
% mat_stiffness - derivative of stress w.r.t. strain.
% params - updated input structure (Matlab sends a copy).

stress_trial = params.young * (strain - state.plast_strain);
trial_yield_f = eval_yield_func(stress_trial, ...
                                params.yield, ...
                                params.plast_mod, ...
                                state.harden_param);

if strcmp(analysis_type, 'elastic') || trial_yield_f <= 0
    stress = stress_trial;
    mat_stiff = params.young;
elseif strcmp(analysis_type, 'plastic') % trial_yield_f > 0 is implied.
    %% Inelastic part of return-mapping algorithm
    % Incremental plastic multiplier:
    incr_pl_mult = trial_yield_f / (params.young + params.plast_mod);
    Dstrain_pl = incr_pl_mult * stress_trial / ( abs(stress_trial) + 1.e-10 );
    stress = stress_trial - params.young * Dstrain_pl;
    state.plast_strain = state.plast_strain + Dstrain_pl;
    state.harden_param = state.harden_param + incr_pl_mult;
    % Algorithmic tangent modulus:
    mat_stiff = (params.young * params.plast_mod) / (params.young + params.plast_mod);
else
    error('/// Wrong analysis type value.')
end

end