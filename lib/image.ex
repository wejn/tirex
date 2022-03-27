defmodule Image do
  defstruct width: 0, height: 0, mode: :rgb, data: nil, v_flip: false, h_flip: false, rle: true

  # The 'data' is two-dimensional array. Think of it as array of pixel rows. In other words,
  # you address by height (y) first, then by width (x).
  #
  # Plus I'm silently assuming that the origin is top left corner.

  def create(width, height, mode \\ :rgb) when mode == :rgb or mode == :rgba do
    %Image{width: width, height: height, mode: mode, data: allocate_data(width, height)}
  end

  defp allocate_data(width, height) do
    :array.new(
      size: height,
      fixed: true,
      default:
        :array.new(
          size: width,
          fixed: true,
          default: Color.black()
        )
    )
  end

  def set(%Image{width: w, height: h, data: d} = img, x, y, c)
      when 0 <= x and 0 <= y and x < w and y < h do
    x = x_coord(img, x)
    y = y_coord(img, y)
    new_row = :array.set(x, c, :array.get(y, d))
    %Image{img | data: :array.set(y, new_row, d)}
  end

  def get(%Image{data: d} = img, x, y) do
    x = x_coord(img, x)
    y = y_coord(img, y)
    :array.get(x, :array.get(y, d))
  end

  # Translates coords to account for vertical / horizontal flipping
  defp x_coord(%Image{v_flip: true, width: w}, x), do: w - 1 - x
  defp x_coord(%Image{v_flip: false}, x), do: x
  defp y_coord(%Image{h_flip: true, height: h}, y), do: h - 1 - y
  defp y_coord(%Image{h_flip: false}, y), do: y

  def flip_vertically(%Image{v_flip: vf} = img) do
    %Image{img | v_flip: not vf}
  end

  def flip_horizontally(%Image{h_flip: hf} = img) do
    %Image{img | h_flip: not hf}
  end

  defp data_to_list(%Image{data: d}), do: :array.to_list(d) |> Enum.map(&:array.to_list/1)

  def to_list(%Image{v_flip: false, h_flip: false} = img), do: data_to_list(img)

  def to_list(%Image{v_flip: false, h_flip: true} = img),
    do: data_to_list(img) |> Enum.reverse()

  def to_list(%Image{v_flip: true, h_flip: false} = img),
    do: data_to_list(img) |> Enum.map(&Enum.reverse/1)

  def to_list(%Image{v_flip: true, h_flip: true} = img),
    do: data_to_list(img) |> Enum.reverse() |> Enum.map(&Enum.reverse/1)

  # Serializing to TGA format
  def to_tga_bytestream(%Image{width: w, height: h, mode: m} = img) do
    header = [
      # id length (char)
      0,
      # colormaptype
      0,
      # data type: uncompressed rgb (2), rle rgb (10)
      tga_datatype_for(img),
      # colormaporigin
      0,
      0,
      # colormaplength
      0,
      0,
      # colormapdepth
      0,
      # x origin
      0,
      0,
      # y origin
      0,
      0,
      # width
      rem(w, 256),
      div(w, 256),
      # height
      rem(h, 256),
      div(h, 256),
      # BPP
      tga_bpp_for_mode(m) * 8,
      # imagedescriptor (TL origin)
      0x20
    ]

    img_data =
      to_list(img)
      |> List.flatten()
      |> Enum.map(&Color.to_bytes(&1, m))
      |> tga_maybe_rle_compress(img)

    dev_area_ref = [0, 0, 0, 0]
    ext_area_ref = [0, 0, 0, 0]
    footer = String.to_charlist("TRUEVISION-XFILE.\0")
    IO.iodata_to_binary([header, img_data, dev_area_ref, ext_area_ref, footer])
  end

  defp tga_datatype_for(%Image{rle: true}), do: 10
  defp tga_datatype_for(%Image{rle: false}), do: 2

  defp tga_bpp_for_mode(:rgba), do: 4
  defp tga_bpp_for_mode(:rgb), do: 3

  defp tga_maybe_rle_compress(iolist, %Image{rle: false}), do: iolist

  defp tga_maybe_rle_compress(iolist, %Image{rle: true}) do
    chunker = fn
      element, nil ->
        {:cont, {element, 1}}

      element, {element, n} when n < 128 ->
        {:cont, {element, n + 1}}

      element, {prev, n} ->
        {:cont, [127 + n, prev], {element, 1}}

        # This doesn't take any advantage of the "raw" chunks (chunks of pixel data directly dumped to output).
        # In other words, everything is an RLE chunk.
    end

    after_func = fn {prev, n} -> {:cont, [127 + n, prev], nil} end

    Enum.chunk_while(iolist, nil, chunker, after_func)
  end
end
