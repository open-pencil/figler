defmodule Figler.Render.Shape.Outline do
  @moduledoc """
  Rounded polygon and star outlines, as Figma draws them. Each corner, convex or not, is rounded
  by a circular arc tangent to both edges, capped so that it and its neighbours fit along every
  edge; corner smoothing replaces the arc's ends with curves that ease into the edges.
  """

  @type point :: {float(), float()}
  @type command ::
          {:move_to, float(), float()}
          | {:line_to, float(), float()}
          | {:cubic_to, float(), float(), float(), float(), float(), float()}
          | :close

  @doc """
  The outline through `vertices` with each corner rounded by up to `radius` and smoothed by
  `smoothing` (0 to 1).
  """
  @spec polygon([point()], number(), number()) :: [command()]
  def polygon(vertices, radius, smoothing) do
    corners = corners(vertices, max(radius, 0.0))
    smoothing = max(0.0, fitted_smoothing(corners, smoothing))

    {commands, _current} =
      Enum.reduce(corners, {[], nil}, fn corner, {commands, current} ->
        corner_outline(corner, smoothing, commands, current)
      end)

    Enum.reverse([:close | commands])
  end

  defp corner_outline(%{radius: radius, turn: turn} = corner, _smoothing, commands, current)
       when radius <= 0 or turn <= 0,
       do: line_to(commands, current, corner.vertex)

  defp corner_outline(corner, smoothing, commands, current) do
    smooth = smooth_corner(corner, smoothing)

    {commands, _current} =
      line_to(commands, current, along(corner.vertex, neg(corner.incoming), smooth.p))

    cubics = corner_cubics(corner, smooth)
    {:cubic_to, _, _, _, _, x, y} = List.last(cubics)
    {Enum.reverse(cubics, commands), {x, y}}
  end

  # Corners whose rounding meets along an edge leave no line between them.
  defp line_to(commands, {cx, cy} = current, {x, y})
       when abs(x - cx) < 1.0e-6 and abs(y - cy) < 1.0e-6,
       do: {commands, current}

  defp line_to(commands, nil, {x, y}), do: {[{:move_to, x, y} | commands], {x, y}}
  defp line_to(commands, _current, {x, y}), do: {[{:line_to, x, y} | commands], {x, y}}

  # A corner turning by α keeps r·tan(α/2) of each edge, so on an edge of length L between
  # corners turning by α and β the radius is at most L / (tan(α/2) + tan(β/2)).
  defp corners(vertices, requested) do
    points = List.to_tuple(vertices)
    count = tuple_size(points)
    at = fn index -> elem(points, Integer.mod(index, count)) end

    shape =
      for index <- 0..(count - 1) do
        vertex = at.(index)
        incoming = unit(sub(vertex, at.(index - 1)))
        outgoing = unit(sub(at.(index + 1), vertex))
        turn = :math.acos(min(1.0, max(-1.0, dot(incoming, outgoing))))

        %{
          vertex: vertex,
          incoming: incoming,
          outgoing: outgoing,
          turn: turn,
          factor: :math.tan(turn / 2)
        }
      end
      |> List.to_tuple()

    edge_limit = fn index ->
      from = elem(shape, Integer.mod(index, count))
      to = elem(shape, Integer.mod(index + 1, count))
      factors = from.factor + to.factor
      if factors > 0, do: distance(from.vertex, to.vertex) / factors, else: :infinity
    end

    for index <- 0..(count - 1) do
      corner = elem(shape, index)
      # Numbers sort before atoms, so an edge with no limit never wins.
      radius = Enum.min([requested, edge_limit.(index - 1), edge_limit.(index)])

      corner
      |> Map.delete(:factor)
      |> Map.merge(%{radius: radius, extent: radius * corner.factor})
    end
  end

  # Figma lowers smoothing for the whole shape to what its tightest corner allows.
  defp fitted_smoothing(corners, smoothing) do
    points = List.to_tuple(corners)
    count = tuple_size(points)

    share = fn corner, neighbour ->
      distance(neighbour.vertex, corner.vertex) * corner.extent /
        (corner.extent + neighbour.extent)
    end

    corners
    |> Enum.with_index()
    |> Enum.reduce(min(max(smoothing, 0.0), 1.0), fn
      {%{extent: extent}, _index}, fitted when not (extent > 0) ->
        fitted

      {corner, index}, fitted ->
        budget =
          min(
            share.(corner, elem(points, Integer.mod(index - 1, count))),
            share.(corner, elem(points, Integer.mod(index + 1, count)))
          )

        min(fitted, budget / corner.extent - 1)
    end)
  end

  # The rectangle smoothing construction with the tangent length r·tan(α/2) in place of r and
  # α/2 in place of 45°.
  defp smooth_corner(%{radius: radius, extent: extent, turn: turn}, smoothing) do
    p = (1 + smoothing) * extent
    ease = turn * smoothing / 2
    to_ease = radius * :math.tan(ease / 2)
    c = to_ease * :math.cos(ease)
    d = to_ease * :math.sin(ease)
    arc_start = extent - radius * :math.sin(ease) - d
    b = (p - arc_start - c - d) / 3
    %{p: p, a: 2 * b, b: b, c: c, d: d, ease: ease}
  end

  defp corner_cubics(corner, %{p: p, a: a, b: b, c: c, d: d, ease: ease}) do
    %{vertex: vertex, incoming: incoming, outgoing: outgoing, radius: radius, turn: turn} = corner
    back = neg(incoming)
    start = along(vertex, back, p)
    finish = along(vertex, outgoing, p)
    arc_from = start |> along(incoming, a + b + c) |> along(inward(incoming, outgoing), d)
    arc_to = finish |> along(outgoing, -(a + b + c)) |> along(inward(outgoing, back), d)
    sweep = turn - 2 * ease

    [
      ease > 0 && cubic(along(start, incoming, a), along(start, incoming, a + b), arc_from),
      sweep > 0 && arc(arc_from, arc_to, corner, ease, sweep, radius),
      ease > 0 && cubic(along(finish, outgoing, -(a + b)), along(finish, outgoing, -a), finish)
    ]
    |> Enum.filter(& &1)
  end

  defp arc(from, to, %{incoming: incoming, outgoing: outgoing}, ease, sweep, radius) do
    handle = 4 / 3 * :math.tan(sweep / 4) * radius
    leaving = rotate(incoming, outgoing, ease)
    arriving = rotate(outgoing, incoming, ease)
    cubic(along(from, leaving, handle), along(to, arriving, -handle), to)
  end

  defp cubic({x1, y1}, {x2, y2}, {x, y}), do: {:cubic_to, x1, y1, x2, y2, x, y}

  # The perpendicular of `direction` on the side the outline turns towards.
  defp inward({dx, dy}, towards) do
    normal = {-dy, dx}
    if dot(normal, towards) < 0, do: {dy, -dx}, else: normal
  end

  defp rotate({dx, dy} = direction, towards, angle) do
    {nx, ny} = inward(direction, towards)
    {dx * :math.cos(angle) + nx * :math.sin(angle), dy * :math.cos(angle) + ny * :math.sin(angle)}
  end

  defp sub({ax, ay}, {bx, by}), do: {ax - bx, ay - by}
  defp neg({x, y}), do: {-x, -y}
  defp dot({ax, ay}, {bx, by}), do: ax * bx + ay * by
  defp along({x, y}, {dx, dy}, distance), do: {x + dx * distance, y + dy * distance}
  defp distance({ax, ay}, {bx, by}), do: :math.sqrt((bx - ax) ** 2 + (by - ay) ** 2)

  defp unit({x, y}) do
    length = :math.sqrt(x * x + y * y)
    if length > 0, do: {x / length, y / length}, else: {0.0, 0.0}
  end
end
