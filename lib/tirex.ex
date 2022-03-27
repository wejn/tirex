defmodule Tirex do
  @moduledoc """
  Documentation for Tirex.
  """

  def three_lines_image do
    img = Image.create(100, 100)

    img = Shapes.line(img, Vec2.new(13, 20), Vec2.new(80, 40), Color.white())
    img = Shapes.line(img, Vec2.new(20, 13), Vec2.new(40, 80), Color.red())
    img = Shapes.line(img, Vec2.new(80, 40), Vec2.new(13, 20), Color.red())

    img = Image.flip_horizontally(img)
    b = Image.to_tga_bytestream(img)
    File.write!('a.tga', b)
  end

  def waveform_test do
    obj = Wavefront.from_bytes(File.read!('african_head.obj'))
    IO.inspect(:array.size(obj.v))
    IO.inspect(:array.size(obj.vt))
    IO.inspect(:array.size(obj.vn))
    IO.inspect(:array.size(obj.f))
    IO.inspect(Wavefront.face(obj, 0))
  end

  def wireframe_drawing do
    width = height = 800
    img = Image.create(width + 1, height + 1)
    obj = Wavefront.from_bytes(File.read!('african_head.obj'))

    img =
      Range.new(0, Wavefront.nfaces(obj) - 1)
      |> Enum.map(fn x -> Wavefront.face(obj, x) end)
      |> Enum.reduce(img, fn [[v1 | _], [v2 | _], [v3 | _]], acc ->
        p1 = Vec2.new(trunc((v1.x + 1) * width / 2), trunc((v1.y + 1) * height / 2))
        p2 = Vec2.new(trunc((v2.x + 1) * width / 2), trunc((v2.y + 1) * height / 2))
        p3 = Vec2.new(trunc((v3.x + 1) * width / 2), trunc((v3.y + 1) * height / 2))
        acc = Shapes.line(acc, p1, p2, Color.white())
        acc = Shapes.line(acc, p2, p3, Color.white())
        acc = Shapes.line(acc, p3, p1, Color.white())
        acc
      end)

    img = Image.flip_horizontally(img)
    b = Image.to_tga_bytestream(img)
    File.write!('a.tga', b)
  end

  def triangles_drawing do
    width = height = 200
    img = Image.create(width, height)

    img = Shapes.triangle(img, Vec2.new(10, 70), Vec2.new(50, 160), Vec2.new(70, 80), Color.red())

    img =
      Shapes.triangle(img, Vec2.new(180, 50), Vec2.new(150, 1), Vec2.new(70, 180), Color.white())

    img =
      Shapes.triangle(
        img,
        Vec2.new(180, 150),
        Vec2.new(120, 160),
        Vec2.new(130, 180),
        Color.green()
      )

    img = Image.flip_horizontally(img)
    b = Image.to_tga_bytestream(img)
    File.write!('a.tga', b)
  end

  def flat_shading_render do
    width = height = 800
    img = Image.create(width, height)
    obj = Wavefront.from_bytes(File.read!('african_head.obj'))

    img =
      Range.new(0, Wavefront.nfaces(obj) - 1)
      |> Enum.map(fn x -> Wavefront.face(obj, x) end)
      |> Enum.reduce(img, fn [[v1 | _], [v2 | _], [v3 | _]], acc ->
        p1 = Vec2.new(trunc((v1.x + 1) * width / 2), trunc((v1.y + 1) * height / 2))
        p2 = Vec2.new(trunc((v2.x + 1) * width / 2), trunc((v2.y + 1) * height / 2))
        p3 = Vec2.new(trunc((v3.x + 1) * width / 2), trunc((v3.y + 1) * height / 2))

        Shapes.triangle(acc, p1, p2, p3, Color.random())
      end)

    img = Image.flip_horizontally(img)
    b = Image.to_tga_bytestream(img)
    File.write!('a.tga', b)
  end

  def lighted_shading_render(light \\ Vec3.new(0, 0, -1)) do
    width = height = 800
    img = Image.create(width, height)
    obj = Wavefront.from_bytes(File.read!('african_head.obj'))

    light = Vec3.normalize(light)

    img =
      Range.new(0, Wavefront.nfaces(obj) - 1)
      |> Enum.map(fn x -> Wavefront.face(obj, x) end)
      |> Enum.reduce(img, fn [[v1 | _], [v2 | _], [v3 | _]], acc ->
        p1 = Vec2.new(trunc((v1.x + 1) * width / 2), trunc((v1.y + 1) * height / 2))
        p2 = Vec2.new(trunc((v2.x + 1) * width / 2), trunc((v2.y + 1) * height / 2))
        p3 = Vec2.new(trunc((v3.x + 1) * width / 2), trunc((v3.y + 1) * height / 2))

        n = Vec3.normalize(Vec3.cross(Vec3.sub(v3, v1), Vec3.sub(v2, v1)))

        intensity = trunc(Vec3.mult(n, light) * 255)

        if intensity > 0 do
          Shapes.triangle(acc, p1, p2, p3, Color.rgb(intensity, intensity, intensity))
        else
          acc
        end
      end)

    img = Image.flip_horizontally(img)
    b = Image.to_tga_bytestream(img)
    File.write!('a.tga', b)
  end

  def zbuffered_shading_render(light \\ Vec3.new(0, 0, -1)) do
    width = height = 800
    img = Image.create(width, height)
    obj = Wavefront.from_bytes(File.read!('african_head.obj'))

    light = Vec3.normalize(light)

    zbuffer = :array.new(size: width * height, fixed: true, default: -1)

    {img, _} =
      Range.new(0, Wavefront.nfaces(obj) - 1)
      |> Enum.map(fn x -> Wavefront.face(obj, x) end)
      |> Enum.reduce({img, zbuffer}, fn [[v1 | _], [v2 | _], [v3 | _]], {acc, zb} ->
        p1 = Vec3.new(trunc((v1.x + 1) * width / 2), trunc((v1.y + 1) * height / 2), v1.z)
        p2 = Vec3.new(trunc((v2.x + 1) * width / 2), trunc((v2.y + 1) * height / 2), v2.z)
        p3 = Vec3.new(trunc((v3.x + 1) * width / 2), trunc((v3.y + 1) * height / 2), v3.z)

        n = Vec3.normalize(Vec3.cross(Vec3.sub(v3, v1), Vec3.sub(v2, v1)))

        intensity = trunc(Vec3.mult(n, light) * 255)

        if intensity > 0 do
          Shapes.triangle_zbuffer(acc, p1, p2, p3, zb, Color.rgb(intensity, intensity, intensity))
        else
          {acc, zb}
        end
      end)

    img = Image.flip_horizontally(img)
    b = Image.to_tga_bytestream(img)
    File.write!('a.tga', b)
  end
end

# Tirex.three_lines_image()
# Tirex.waveform_test()
# Tirex.wireframe_drawing()
# Tirex.triangles_drawing()
# Tirex.flat_shading_render()
# Tirex.lighted_shading_render()
Tirex.zbuffered_shading_render()
