defmodule Wavefront do
  defstruct v: [], vt: [], vn: [], f: []

  def nfaces(%Wavefront{f: f}), do: :array.size(f)

  # returns: [[vert1, texture1, normal1], ..., [vert3, texture3, normal3]]
  def face(%Wavefront{f: f} = wf, n) do
    :array.get(n, f) |> Enum.map(fn x -> map_f_elem(x, wf) end)
  end

  # maps face's element to direct values (vertex, texture coords, normal coords)
  defp map_f_elem([v, vt, vn], %Wavefront{v: vs, vt: vts, vn: vns}) do
    [:array.get(v, vs), :array.get(vt, vts), :array.get(vn, vns)]
  end

  def from_bytes(bytes) do
    # first run through line_parser, then reverse and put into arrays

    wf = bytes |> String.split("\n") |> Enum.reduce(%Wavefront{}, &line_parser/2)

    %Wavefront{
      v: :array.from_list(Enum.reverse(wf.v)),
      vt: :array.from_list(Enum.reverse(wf.vt)),
      vn: :array.from_list(Enum.reverse(wf.vn)),
      f: :array.from_list(Enum.reverse(wf.f))
    }
  end

  defp line_parser("v " <> rest, %Wavefront{v: vert} = obj) do
    # vertex
    %Wavefront{obj | v: [parse_vec3(rest) | vert]}
  end

  defp line_parser("vn " <> rest, %Wavefront{vn: vert} = obj) do
    # vertex normal
    %Wavefront{obj | vn: [parse_vec3(rest) | vert]}
  end

  defp line_parser("vt " <> rest, %Wavefront{vt: vert} = obj) do
    # vertex texture
    %Wavefront{obj | vt: [parse_vec3(rest) | vert]}
  end

  defp line_parser("f " <> rest, %Wavefront{f: faces} = obj) do
    # face
    f = rest |> String.trim() |> String.split(" ", parts: 3) |> Enum.map(&parse_face_field/1)
    %Wavefront{obj | f: [f | faces]}
  end

  defp line_parser("s " <> _rest, %Wavefront{} = obj), do: obj

  defp line_parser("g " <> _rest, %Wavefront{} = obj), do: obj

  defp line_parser("#" <> _rest, %Wavefront{} = obj), do: obj

  defp line_parser("", %Wavefront{} = obj), do: obj

  defp line_parser(e, %Wavefront{} = obj) do
    IO.inspect("Invalid wavefront line: #{e}")
    obj
  end

  defp parse_face_field(str) do
    str
    |> String.trim()
    |> String.split("/", parts: 3)
    |> Enum.map(&Integer.parse/1)
    |> Enum.map(fn {x, ""} -> x - 1 end)
  end

  defp parse_vec3(str) do
    [x, y, z] =
      str
      |> String.trim()
      |> String.split(" ", parts: 3)
      |> Enum.map(&Float.parse/1)
      |> Enum.map(fn {x, ""} -> x end)

    Vec3.new(x, y, z)
  end
end
