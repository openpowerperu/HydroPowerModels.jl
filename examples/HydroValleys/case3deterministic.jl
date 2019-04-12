using Clp
using HydroPowerModels

########################################
#       Load Case
########################################
testcases_dir = joinpath(dirname(dirname(dirname(@__FILE__))), "testcases")
data = HydroPowerModels.parse_folder(joinpath(testcases_dir,"case3deterministic"))

########################################
#       Set Parameters
########################################
# model_constructor_grid may be for example: ACPPowerModel or DCPPowerModel
# optimizer may be for example: IpoptSolver(tol=1e-6) or Clp.Optimizer
params = create_param( stages = 3, 
                    model_constructor_grid  = DCPPowerModel,
                    post_method             = PowerModels.post_opf,
                    optimizer                  = Clp.Optimizer)

########################################
#       Build Model
########################################
m = hydrothermaloperation(data, params)

########################################
#       Solve
########################################
status = SDDP.train(m.policygraph;iteration_limit = 60);

########################################
#       Simulation
########################################
results = HydroPowerModels.simulate(m, 1);

########################################
#       Test
########################################
# objective
@test isapprox(sum(s[:stage_objective] for s in results[:simulations][1]),1504.17, atol=1e-2)

# solution
@test results[:simulations][1][1][:powersystem]["solution"]["gen"]["4"]["pg"] == 0
@test isapprox(results[:simulations][1][1][:powersystem]["solution"]["gen"]["2"]["pg"],0, atol=1e-2)
@test isapprox(results[:simulations][1][1][:powersystem]["solution"]["gen"]["3"]["pg"],0.74, atol=1e-2)
@test isapprox(results[:simulations][1][1][:powersystem]["solution"]["gen"]["1"]["pg"],0.25, atol=1e-2)
