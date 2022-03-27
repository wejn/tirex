defmodule Shapes do
  def line(%Image{} = img, %Vec2{} = p1, %Vec2{} = p2, c) do
    line(img, p1.x, p1.y, p2.x, p2.y, c)
  end

  def line(%Image{} = img, x1, y1, x1, y1, c) do
    Image.set(img, x1, y1, c)
  end

  def line(%Image{} = img, x1, y1, x2, y2, c) when abs(x1 - x2) < abs(y1 - y2) do
    Range.new(y1, y2)
    |> Enum.reduce(img, fn y, acc ->
      t = (y - y1) / (y2 - y1)
      Image.set(acc, trunc(x1 * (1 - t) + x2 * t), y, c)
    end)
  end

  def line(%Image{} = img, x1, y1, x2, y2, c) do
    Range.new(x1, x2)
    |> Enum.reduce(img, fn x, acc ->
      t = (x - x1) / (x2 - x1)
      Image.set(acc, x, trunc(y1 * (1 - t) + y2 * t), c)
    end)
  end

  defp barycentric(a, b, c, p) do
    u =
      Vec3.cross(
        Vec3.new(c.x - a.x, b.x - a.x, a.x - p.x),
        Vec3.new(c.y - a.y, b.y - a.y, a.y - p.y)
      )

    if abs(u.z) < 1 do
      Vec3.new(-1, 1, 1)
    else
      Vec3.new(1 - (u.x + u.y) / u.z, u.y / u.z, u.x / u.z)
    end
  end

  defp pixel_pairs_from_bb(bbmin, bbmax) do
    for x <- Range.new(bbmin.x, bbmax.x), y <- Range.new(bbmin.y, bbmax.y), do: {x, y}
  end

  def triangle(
        %Image{} = img,
        %Vec2{x: p1x, y: p1y},
        %Vec2{x: p2x, y: p2y},
        %Vec2{x: p3x, y: p3y},
        c
      ) do
    triangle(img, Vec3.new(p1x, p1y, 0), Vec3.new(p2x, p2y, 0), Vec3.new(p3x, p3y, 0), c)
  end

  def triangle(%Image{} = img, %Vec3{} = p1, %Vec3{} = p2, %Vec3{} = p3, c) do
    {img, _} = triangle_zbuffer(img, p1, p2, p3, :array.new(default: -1), c)
    img
  end

  def triangle_zbuffer(%Image{} = img, %Vec3{} = p1, %Vec3{} = p2, %Vec3{} = p3, zbuffer, c) do
    # Figure out bounding box
    clamp = Vec2.new(img.width - 1, img.height - 1)

    bbmin =
      Vec2.new(
        max(0, Enum.min([clamp.x, p1.x, p2.x, p3.x])),
        max(0, Enum.min([clamp.x, p1.y, p2.y, p3.y]))
      )

    bbmax =
      Vec2.new(
        min(clamp.x, Enum.max([0, p1.x, p2.x, p3.x])),
        min(clamp.y, Enum.max([0, p1.y, p2.y, p3.y]))
      )

    # For all pixels in BB, do the dance
    pixel_pairs_from_bb(bbmin, bbmax)
    |> Enum.reduce({img, zbuffer}, fn {x, y}, {acc, zb} ->
      bc = barycentric(p1, p2, p3, Vec2.new(x, y))

      if bc.x < 0 or bc.y < 0 or bc.z < 0 do
        {acc, zb}
      else
        z = p1.z * bc.x + p2.z * bc.y + p3.z * bc.z
        idx = trunc(x + y * img.width)

        if :array.get(idx, zb) < z do
          zb = :array.set(idx, z, zb)
          {Image.set(acc, x, y, c), zb}
        else
          {acc, zb}
        end
      end
    end)
  end
end
