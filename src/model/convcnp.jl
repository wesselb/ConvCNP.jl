export convcnp_1d

"""
    convcnp_1d(;
        receptive_field::Float32,
        num_layers::Integer,
        num_channels::Integer,
        points_per_unit::Float32,
        margin::Float32=receptive_field
    )

Construct a ConvCNP for one-dimensional data.

# Keywords
- `receptive_field::Float32`: Width of the receptive field.
- `num_layers::Integer`: Number of layers of the CNN, excluding an initial
    and final pointwise convolutional layer to change the number of channels
    appropriately.
- `num_channels::Integer`: Number of channels of the CNN.
- `margin::Float32=receptive_field`: Margin for the discretisation. See
    `UniformDiscretisation1d`.
"""
function convcnp_1d(;
    receptive_field::Float32,
    num_layers::Integer,
    num_channels::Integer,
    points_per_unit::Float32,
    margin::Float32=receptive_field
)
    dim_x = 1
    dim_y = 1
    scale = 2 / points_per_unit
    num_noise_channels, noise = build_noise_model(
        num_channels -> set_conv(num_channels, scale),
        dim_y=dim_y,
        noise_type="het"
    )
    decoder_conv = build_conv(
        receptive_field,
        num_layers,
        num_channels,
        points_per_unit =points_per_unit,
        dimensionality  =1,
        num_in_channels =dim_y + 1,  # Account for density channel.
        num_out_channels=num_noise_channels
    )
    return Model(
        FunctionalAggregator(
            UniformDiscretisation1d(
                points_per_unit,
                margin,
                decoder_conv.multiple  # Avoid artifacts when using up/down-convolutions.
            ),
            Chain(
                set_conv(dim_y + 1, scale),  # Account for density channel.
                Deterministic()
            )
        ),
        Chain(
            decoder_conv,
            noise
        )
    )
end
