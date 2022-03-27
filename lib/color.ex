defmodule Color do
  defstruct r: 0, g: 0, b: 0, a: 255

  def white, do: %Color{r: 255, g: 255, b: 255}
  def red, do: %Color{r: 255}
  def green, do: %Color{g: 255}
  def blue, do: %Color{b: 255}
  def black, do: %Color{}
  def gray, do: %Color{r: 128, g: 128, b: 128}

  def random, do: %Color{r: :rand.uniform(255), g: :rand.uniform(255), b: :rand.uniform(255)}

  def rgb(r, g, b) when 0 <= r and r <= 255 and 0 <= g and g <= 255 and 0 <= b and b <= 255 do
    %Color{r: r, g: g, b: b}
  end

  def to_bytes(%Color{r: r, g: g, b: b, a: a}, :rgba), do: [b, g, r, a]
  def to_bytes(%Color{r: r, g: g, b: b}, :rgb), do: [b, g, r]
end
