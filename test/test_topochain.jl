using Flux

l1 = Dense(32, 64)
l2 = Dense(64, 128)
l3 = Dense(128, 64)

topo = @functopo x => a => b => y

@testset "TopoChain" begin 
    model = TopoChain(topo, l1, l2, l3)

    @test model[2] == l2
    @test length(model) == 3
end
