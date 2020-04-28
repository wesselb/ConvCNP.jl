using Pkg

Pkg.activate(".")
Pkg.resolve()
Pkg.instantiate()

using ConvCNPs
using ConvCNPs.Experiment
using Flux
using Stheno
using Distributions

# Construct data generator.
scale = 0.5f0
process = GP(stretch(matern52(), 1 / 0.25), GPC())
data_gen = DataGenerator(
    process;
    batch_size=8,
    x=Uniform(-2, 2),
    num_context=DiscreteUniform(3, 50),
    num_target=DiscreteUniform(3, 50)
)

# Instantiate ConvCNP model.
arch = build_conv(4scale, 8, 32; points_per_unit=30f0, dimensionality=1)
model = convcnp_1d(arch; margin=2scale) |> gpu

# Configure training.
opt = ADAM(5e-4)
epochs = 50
num_batches = 2048
bson = "model_matern52.bson"

train!(
    model,
    data_gen,
    opt,
    bson=bson,
    batches_per_epoch=num_batches,
    epochs=epochs
)
eval_model(model, data_gen, epochs; num_batches=num_batches)