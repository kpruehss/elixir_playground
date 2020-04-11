defmodule Identicon do
  @moduledoc """
    Module to generate an Identicon based on a given string input (like your name)
  """

  @doc """
    The main pipeline. Supplying a string will generate a randomized Identicon based on the string's hash and save it to the root folder of the app
  """
  @spec main(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | byte,
              binary | []
            )
        ) :: :ok | {:error, atom}
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
    Writes the image to file as png, using the string input as file name
  """
  @spec save_image(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | byte,
              binary | []
            ),
          any
        ) :: :ok | {:error, atom}
  def save_image(image, input) do
    File.write("#{input}.png", image)
  end

  @doc """
    Using Erlang's egd, turn pixel_map into 250x250px Identicon. First three integers from hash are used as RGB values
  """
  @spec draw_image(Identicon.Image.t()) :: binary
  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn {start, stop} ->
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  @doc """
    Take image struct and calculate pixel_map of all even squares
  """
  @spec build_pixel_map(Identicon.Image.t()) :: Identicon.Image.t()
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map =
      Enum.map(
        grid,
        fn {_code, index} ->
          horizontal = rem(index, 5) * 50
          vertical = div(index, 5) * 50

          top_left = {horizontal, vertical}
          bottom_right = {horizontal + 50, vertical + 50}

          {top_left, bottom_right}
        end
      )

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  @doc """
    Remove odd-number squares from tuple. Only even squares will be colored
  """
  @spec filter_odd_squares(Identicon.Image.t()) :: Identicon.Image.t()
  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid =
      Enum.filter(grid, fn {code, _index} ->
        rem(code, 2) == 0
      end)

    %Identicon.Image{image | grid: grid}
  end

  @doc """
    Generate grid tuples for later use by Erlang's EGD. Tuples are chunked to 3 items per list and flattened, then turned into a tuple with value-index pairing
  """
  @spec build_grid(Identicon.Image.t()) :: Identicon.Image.t()
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten()
      |> Enum.with_index()

    %Identicon.Image{image | grid: grid}
  end

  @doc """
    Generate 5-square row based on 3-integer tuple. Values mirrored around 3rd integer in tuple
  """
  @spec mirror_row([...]) :: [...]
  def mirror_row(row) do
    [first, second | _tail] = row
    row ++ [second, first]
  end

  @doc """
    Use first three integers from hashed input to generate RGB values for Erlang's EDG
  """
  @spec pick_color(Identicon.Image.t()) :: Identicon.Image.t()
  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  @doc """
    Hash the input provided on startup into MD5 hash, turn into char-list
  """
  @spec hash_input(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | byte,
              binary | []
            )
        ) :: Identicon.Image.t()
  def hash_input(input) do
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    %Identicon.Image{hex: hex}
  end
end
