"""rainfall noises"""
function rainfall_noises(sp, data::Dict, t::Int)    
        SDDP.parameterize(sp, collect(1:size(data["hydro"]["scenario_probabilities"],2)), data["hydro"]["scenario_probabilities"][cidx(t,data["hydro"]["size_inflow"][1]),:]) do ω
            for i in 1:data["hydro"]["nHyd"]
                JuMP.fix(sp[:inflow][i], data["hydro"]["Hydrogenerators"][i]["inflow"][t,ω]; force=true)
            end        
        end
    return nothing
end

"""creates hydro balance constraint"""
function constraint_hydro_balance(sp, data::Dict)    
    @constraints(sp, begin
        hydro_balance[i=1:data["hydro"]["nHyd"]], sp[:reservoir][i].out == sp[:reservoir][i].in + sp[:inflow][i] - sp[:outflow][i] - sp[:spill][i] + sum(sp[:outflow][j] + sp[:spill][j] for j in data["hydro"]["Hydrogenerators"][i]["upstrem_hydros"])
    end)
    return nothing
end

"""creates energy constraints which bind the discharge with the active energy injected to the grid"""
function constraint_hydro_generation(sp, data::Dict, pm::GenericPowerModel)
    @constraints(sp, begin
        turbine_energy[i=1:data["hydro"]["nHyd"]], var(pm, 0, 1, :pg)[data["hydro"]["Hydrogenerators"][i]["i_grid"]]*data["powersystem"]["baseMVA"] == 0.0036*sp[:outflow][i]*data["hydro"]["Hydrogenerators"][i]["production_factor"]
    end)
    return nothing
end