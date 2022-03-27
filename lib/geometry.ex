defmodule Vec2 do
  defstruct x: 0, y: 0

  def new(x, y) do
    %Vec2{x: x, y: y}
  end
end

defmodule Vec3 do
  defstruct x: 0, y: 0, z: 0

  def new(x, y, z) do
    %Vec3{x: x, y: y, z: z}
  end

  def cross(a, b) do
    Vec3.new(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
  end

  def sub(a, b) do
    Vec3.new(a.x - b.x, a.y - b.y, a.z - b.z)
  end

  def smult(%Vec3{} = a, k) do
    Vec3.new(a.x * k, a.y * k, a.z * k)
  end

  def norm(%Vec3{} = a) do
    :math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
  end

  def normalize(%Vec3{} = a, len \\ 1) do
    Vec3.smult(a, len / Vec3.norm(a))
  end

  def mult(%Vec3{} = a, %Vec3{} = b) do
    a.x * b.x + a.y * b.y + a.z * b.z
  end
end
